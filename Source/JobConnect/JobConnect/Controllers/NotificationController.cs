// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// NotificationController — [Authorize]: API nhỏ phục vụ CHUÔNG THÔNG BÁO trên header
// (gọi bằng AJAX/JS, không phải trang riêng):
//   • UnreadCount: đếm số thông báo chưa đọc (hiển thị badge số đỏ).
//   • Recent: lấy danh sách thông báo gần đây để đổ vào dropdown.
//   • MarkAllRead: đánh dấu tất cả đã đọc.
// ═══════════════════════════════════════════════════════════════════════════
using System.Security.Claims;
using JobConnect.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

[Authorize]
public class NotificationController : Controller
{
    private readonly AppDbContext _db;

    public NotificationController(AppDbContext db)
    {
        _db = db;
    }

    private int CurrentUserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    [HttpGet]
    [Route("Notification/UnreadCount")]
    public async Task<IActionResult> UnreadCount()
    {
        var count = await _db.Notifications.CountAsync(n => n.UserId == CurrentUserId && !n.IsRead);
        return Json(new { count });
    }

    [HttpGet]
    [Route("Notification/Recent")]
    public async Task<IActionResult> Recent()
    {
        var notifications = await _db.Notifications
            .Where(n => n.UserId == CurrentUserId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(10)
            .ToListAsync();

        ViewBag.ShowViewAllLink = User.IsInRole("Candidate");
        return PartialView("_NotificationDropdown", notifications);
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Notification/MarkAllRead")]
    public async Task<IActionResult> MarkAllRead()
    {
        var unread = await _db.Notifications
            .Where(n => n.UserId == CurrentUserId && !n.IsRead)
            .ToListAsync();

        if (unread.Count > 0)
        {
            unread.ForEach(n => n.IsRead = true);
            await _db.SaveChangesAsync();
        }

        return Json(new { success = true });
    }
}