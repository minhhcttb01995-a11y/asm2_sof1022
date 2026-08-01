// ═══════════════════════════════════════════════════════════════════════════
// AdminNotificationHelper — Hàm dùng CHUNG để tạo thông báo gửi tới TẤT CẢ
// tài khoản có Role = "Admin" HOẶC "Staff" trong hệ thống. Dùng ở những chỗ
// Admin/Nhân viên cần biết NGAY khi có sự kiện mới xảy ra, ví dụ:
//   • Có tin tuyển dụng MỚI được đăng (JobService.CreateAsync)
//   • Có nhà tuyển dụng/công ty MỚI đăng ký (AuthService.RegisterEmployerAsync)
//
// Lưu ý quan trọng: hàm này CHỈ "Add" vào DbContext (_db.Notifications.Add),
// KHÔNG tự gọi SaveChangesAsync — người gọi phải tự SaveChangesAsync() sau đó.
// Sở dĩ như vậy vì AppDbContext đã được nối với SignalR (xem
// Data/AppDbContext.Realtime.cs): mỗi lần SaveChangesAsync() chạy, mọi
// Notification mới thêm sẽ TỰ ĐỘNG được đẩy REAL-TIME xuống đúng Admin/Staff
// đang online, không cần đợi họ F5 hay tự làm mới trang.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Helpers;

public static class AdminNotificationHelper
{
    // Giữ nguyên tên "NotifyAdminsAsync" (đã được gọi ở nhiều nơi) nhưng mở rộng
    // để gửi cho CẢ Admin và Staff — vì cả 2 vai trò đều cần biết ngay khi có
    // tin tuyển dụng mới / nhà tuyển dụng mới đăng ký cần duyệt.
    public static async Task NotifyAdminsAsync(
        this AppDbContext db,
        string title,
        string? content,
        string type,
        int? relatedId = null)
    {
        var recipientIds = await db.Users
            .Where(u => u.Role == "Admin" || u.Role == "Staff")
            .Select(u => u.UserId)
            .ToListAsync();

        var now = DateTime.Now;
        foreach (var userId in recipientIds)
        {
            db.Notifications.Add(new Notification
            {
                UserId = userId,
                Title = title,
                Content = content,
                Type = type,
                RelatedId = relatedId,
                IsRead = false,
                CreatedAt = now
            });
        }
    }
}

