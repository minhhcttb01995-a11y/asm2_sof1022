// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// ChatController — [Authorize]: TÍNH NĂNG NHẮN TIN giữa các User (VD: nhà tuyển dụng
// nhắn tin ứng viên, ứng viên nhắn Staff hỗ trợ):
//   • Index/Conversation/GetMessagesJson/Send: danh sách hội thoại, xem 1 hội thoại,
//     lấy tin nhắn mới dạng JSON (dùng cho polling/AJAX phía client), gửi tin nhắn mới.
//   • Contacts: [Authorize(Roles = "Admin")] — Admin xem danh bạ toàn hệ thống.
//   • StartWithUser/StartConversation: khởi tạo hội thoại mới với 1 user/staff cụ thể.
//   • StaffConversations: [Authorize(Roles = "Staff,Admin")] — Staff xem các hội thoại hỗ trợ.
// ═══════════════════════════════════════════════════════════════════════════
using Microsoft.AspNetCore.Antiforgery;
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
    private readonly IAntiforgery _antiforgery;

    public ChatController(AppDbContext db, IAntiforgery antiforgery)
    {
        _db = db;
        _antiforgery = antiforgery;
    }

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
    private string UserRole => User.FindFirst(ClaimTypes.Role)?.Value ?? "";

    // GET /Chat - List of conversations
    public async Task<IActionResult> Index()
    {
        var conversations = await _db.Messages
            .Where(m => m.SenderId == UserId || m.ReceiverId == UserId)
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();

        // Group by conversation (sender-receiver pair)
        var groupedConversations = conversations
            .GroupBy(m => m.SenderId == UserId ? m.ReceiverId : m.SenderId)
            .Select(g => new
            {
                OtherUserId = g.Key,
                OtherUser = g.First().SenderId == UserId ? g.First().Receiver : g.First().Sender,
                LastMessage = g.OrderByDescending(m => m.CreatedAt).First(),
                UnreadCount = g.Count(m => m.ReceiverId == UserId && !m.IsRead)
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
            .Where(m => (m.SenderId == UserId && m.ReceiverId == userId) ||
                       (m.SenderId == userId && m.ReceiverId == UserId))
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();

        // Mark received messages as read
        var unreadMessages = messages.Where(m => m.ReceiverId == UserId && !m.IsRead).ToList();
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
            .Where(m => ((m.SenderId == UserId && m.ReceiverId == userId) ||
                        (m.SenderId == userId && m.ReceiverId == UserId)) &&
                        m.MessageId > afterId)
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();

        var unread = messages.Where(m => m.ReceiverId == UserId && !m.IsRead).ToList();
        if (unread.Count > 0)
        {
            foreach (var msg in unread) msg.IsRead = true;
            await _db.SaveChangesAsync();
        }

        var result = messages.Select(m => new
        {
            id = m.MessageId,
            content = m.Content,
            createdAt = m.CreatedAt.ToString("HH:mm"),
            isOwn = m.SenderId == UserId
        });

        return Json(new { success = true, messages = result });
    }

    // POST /Chat/Send - Send a message
    // Lưu ý: validate token thủ công bên trong try/catch (không dùng attribute trực tiếp)
    // để lỗi token/DB luôn trả về JSON, tránh JS phía client bị crash khi parse HTML lỗi.
    [HttpPost]
    public async Task<IActionResult> Send(int receiverId, string content, int? jobId = null)
    {
        try
        {
            try
            {
                await _antiforgery.ValidateRequestAsync(HttpContext);
            }
            catch (AntiforgeryValidationException)
            {
                return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang và thử lại." });
            }

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
                SenderId = UserId,
                ReceiverId = receiverId,
                Content = content,
                JobId = jobId,
                CreatedAt = DateTime.Now,
                IsRead = false
            };

            _db.Messages.Add(message);
            await _db.SaveChangesAsync();

            return Json(new { success = true, messageId = message.MessageId });
        }
        catch (Exception ex)
        {
            var detail = ex.InnerException?.Message ?? ex.Message;
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + detail });
        }
    }

    // GET /Chat/Contacts - Admin: browse Staff only to start a new chat
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Contacts(string? search)
    {
        var query = _db.Users
            .Include(u => u.Staff)
            .Where(u => u.UserId != UserId && u.Role == "Staff" && u.DeletedAt == null);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(u => u.FullName.ToLower().Contains(s) || u.Email.ToLower().Contains(s));
        }

        var users = await query.OrderBy(u => u.FullName).ToListAsync();

        ViewBag.Search = search;
        return View(users);
    }

    // GET /Chat/StartWithUser/{userId} - Start (or open) a conversation with any user
    public async Task<IActionResult> StartWithUser(int userId)
    {
        var target = await _db.Users.FindAsync(userId);
        if (target == null)
        {
            TempData["Error"] = "Người dùng không tồn tại";
            return RedirectToAction("Index");
        }

        return RedirectToAction("Conversation", new { userId });
    }

    // GET /Chat/StartConversation/{staffId} - Start a new conversation with staff
    public async Task<IActionResult> StartConversation(int staffId, int? jobId = null)
    {
        var staff = await _db.Users
            .Include(u => u.Staff)
            .FirstOrDefaultAsync(u => u.UserId == staffId && u.Role == "Staff");

        if (staff == null)
        {
            TempData["Error"] = "Nhân viên không tồn tại";
            return RedirectToAction("Index", "Home");
        }

        // Check if conversation already exists
        var existingMessage = await _db.Messages
            .Where(m => (m.SenderId == UserId && m.ReceiverId == staffId) ||
                       (m.SenderId == staffId && m.ReceiverId == UserId))
            .FirstOrDefaultAsync();

        if (existingMessage != null)
        {
            return RedirectToAction("Conversation", new { userId = staffId });
        }

        // Create first message
        var message = new Message
        {
            SenderId = UserId,
            ReceiverId = staffId,
            Content = $"Xin chào, tôi cần hỗ trợ{(jobId.HasValue ? " về tin tuyển dụng" : "")}.",
            JobId = jobId,
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
            .Where(m => m.SenderId == UserId || m.ReceiverId == UserId)
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .Include(m => m.Job)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();

        var groupedConversations = conversations
            .GroupBy(m => m.SenderId == UserId ? m.ReceiverId : m.SenderId)
            .Select(g => new
            {
                OtherUserId = g.Key,
                OtherUser = g.First().SenderId == UserId ? g.First().Receiver : g.First().Sender,
                LastMessage = g.OrderByDescending(m => m.CreatedAt).First(),
                UnreadCount = g.Count(m => m.ReceiverId == UserId && !m.IsRead)
            })
            .OrderByDescending(c => c.LastMessage.CreatedAt)
            .ToList();

        ViewBag.Conversations = groupedConversations;
        return View();
    }
}