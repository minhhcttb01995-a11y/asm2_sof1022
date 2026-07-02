using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Models;

namespace JobConnect.Controllers;

[Authorize]
public class ChatController : Controller
{
    private readonly AppDbContext _db;

    public ChatController(AppDbContext db)
    {
        _db = db;
    }

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
    private string UserRole => User.FindFirst(ClaimTypes.Role)?.Value ?? "";

    // GET /Chat - List of conversations
    public async Task<IActionResult> Index()
    {
        var conversations = await _db.Messages
            .Where(m => m.SenderID == UserId || m.ReceiverID == UserId)
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();

        // Group by conversation (sender-receiver pair)
        var groupedConversations = conversations
            .GroupBy(m => m.SenderID == UserId ? m.ReceiverID : m.SenderID)
            .Select(g => new
            {
                OtherUserId = g.Key,
                OtherUser = g.First().SenderID == UserId ? g.First().Receiver : g.First().Sender,
                LastMessage = g.OrderByDescending(m => m.CreatedAt).First(),
                UnreadCount = g.Count(m => m.ReceiverID == UserId && !m.IsRead)
            })
            .OrderByDescending(c => c.LastMessage.CreatedAt)
            .ToList();

        ViewBag.Conversations = groupedConversations;

        // If no conversations, get available staff
        if (!groupedConversations.Any())
        {
            var availableStaff = await _db.Users
                .Include(u => u.Staff)
                .Where(u => u.Role == "Staff" && u.Status == "Active")
                .ToListAsync();
            ViewBag.AvailableStaff = availableStaff;
        }

        return View();
    }

    // GET /Chat/Conversation/{userId} - Chat with specific user
    public async Task<IActionResult> Conversation(int userId)
    {
        var otherUser = await _db.Users.FindAsync(userId);
        if (otherUser == null)
        {
            return NotFound();
        }

        // Get messages between current user and other user
        var messages = await _db.Messages
            .Where(m => (m.SenderID == UserId && m.ReceiverID == userId) ||
                       (m.SenderID == userId && m.ReceiverID == UserId))
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();

        // Mark received messages as read
        var unreadMessages = messages.Where(m => m.ReceiverID == UserId && !m.IsRead).ToList();
        foreach (var msg in unreadMessages)
        {
            msg.IsRead = true;
        }
        await _db.SaveChangesAsync();

        ViewBag.OtherUser = otherUser;
        ViewBag.Messages = messages;
        ViewBag.CurrentUserId = UserId;
        return View();
    }

    // GET /Chat/GetMessagesJson - Poll for new messages (for near real-time updates)
    [HttpGet]
    public async Task<IActionResult> GetMessagesJson(int userId, int afterId = 0)
    {
        var messages = await _db.Messages
            .Where(m => ((m.SenderID == UserId && m.ReceiverID == userId) ||
                        (m.SenderID == userId && m.ReceiverID == UserId)) &&
                        m.MessageID > afterId)
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();

        var unread = messages.Where(m => m.ReceiverID == UserId && !m.IsRead).ToList();
        if (unread.Count > 0)
        {
            foreach (var msg in unread) msg.IsRead = true;
            await _db.SaveChangesAsync();
        }

        var result = messages.Select(m => new
        {
            id = m.MessageID,
            content = m.Content,
            createdAt = m.CreatedAt.ToString("HH:mm"),
            isOwn = m.SenderID == UserId
        });

        return Json(new { success = true, messages = result });
    }

    // POST /Chat/Send - Send a message
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Send(int receiverId, string content, int? jobId = null)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return Json(new { success = false, message = "Nội dung tin nhắn không được để trống" });
        }

        var receiver = await _db.Users.FindAsync(receiverId);
        if (receiver == null)
        {
            return Json(new { success = false, message = "Người nhận không tồn tại" });
        }

        var message = new Message
        {
            SenderID = UserId,
            ReceiverID = receiverId,
            Content = content,
            JobID = jobId,
            CreatedAt = DateTime.Now,
            IsRead = false
        };

        _db.Messages.Add(message);
        await _db.SaveChangesAsync();

        return Json(new { success = true, messageId = message.MessageID });
    }

    // GET /Chat/StartConversation/{staffId} - Start a new conversation with staff
    public async Task<IActionResult> StartConversation(int staffId, int? jobId = null)
    {
        var staff = await _db.Users
            .Include(u => u.Staff)
            .FirstOrDefaultAsync(u => u.UserID == staffId && u.Role == "Staff");

        if (staff == null)
        {
            TempData["Error"] = "Nhân viên không tồn tại";
            return RedirectToAction("Index", "Home");
        }

        // Check if conversation already exists
        var existingMessage = await _db.Messages
            .Where(m => (m.SenderID == UserId && m.ReceiverID == staffId) ||
                       (m.SenderID == staffId && m.ReceiverID == UserId))
            .FirstOrDefaultAsync();

        if (existingMessage != null)
        {
            return RedirectToAction("Conversation", new { userId = staffId });
        }

        // Create first message
        var message = new Message
        {
            SenderID = UserId,
            ReceiverID = staffId,
            Content = $"Xin chào, tôi cần hỗ trợ{(jobId.HasValue ? " về tin tuyển dụng" : "")}.",
            JobID = jobId,
            CreatedAt = DateTime.Now,
            IsRead = false
        };

        _db.Messages.Add(message);
        await _db.SaveChangesAsync();

        return RedirectToAction("Conversation", new { userId = staffId });
    }

    // GET /Chat/StaffConversations - Staff view of all conversations
    [Authorize(Roles = "Staff,Admin")]
    public async Task<IActionResult> StaffConversations()
    {
        var conversations = await _db.Messages
            .Where(m => m.SenderID == UserId || m.ReceiverID == UserId)
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();

        var groupedConversations = conversations
            .GroupBy(m => m.SenderID == UserId ? m.ReceiverID : m.SenderID)
            .Select(g => new
            {
                OtherUserId = g.Key,
                OtherUser = g.First().SenderID == UserId ? g.First().Receiver : g.First().Sender,
                LastMessage = g.OrderByDescending(m => m.CreatedAt).First(),
                UnreadCount = g.Count(m => m.ReceiverID == UserId && !m.IsRead)
            })
            .OrderByDescending(c => c.LastMessage.CreatedAt)
            .ToList();

        ViewBag.Conversations = groupedConversations;
        return View();
    }
}
