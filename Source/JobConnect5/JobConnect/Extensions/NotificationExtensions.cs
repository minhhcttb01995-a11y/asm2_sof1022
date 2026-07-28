// [[FILE-HEADER-ADDED]]
// NotificationExtensions — các hàm mở rộng (extension method) trên AppDbContext giúp
// TẠO NHANH thông báo (Notification) cho một nhóm người dùng, dùng chung ở nhiều nơi
// (JobService, AuthService, các Controller...) thay vì phải viết lặp lại vòng lặp
// "lấy danh sách UserId rồi Add từng Notification" ở mỗi chỗ.
//
// Lưu ý: các hàm này CHỈ thêm Notification vào ChangeTracker (_db.Notifications.Add),
// KHÔNG tự gọi SaveChangesAsync — nơi gọi cần tự SaveChangesAsync() sau đó (để có thể
// gộp chung 1 lần lưu với các thay đổi khác nếu muốn). Việc đẩy real-time qua SignalR
// đã được xử lý tự động trong AppDbContext.Realtime.cs ngay khi SaveChangesAsync chạy.
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Extensions
{
    public static class NotificationExtensions
    {
        /// <summary>
        /// Gửi thông báo tới TOÀN BỘ Admin + Staff trong hệ thống (dùng khi có sự kiện cần
        /// đội ngũ quản trị/nhân viên biết ngay: tin tuyển dụng mới chờ duyệt, công ty mới
        /// đăng ký, v.v...).
        /// </summary>
        public static async Task NotifyAdminsAndStaffAsync(this AppDbContext db, string title, string? content, string type, int? relatedId = null)
        {
            var recipientIds = await db.Users
                .Where(u => u.Role == "Admin" || u.Role == "Staff")
                .Select(u => u.UserId)
                .ToListAsync();

            foreach (var userId in recipientIds)
            {
                db.Notifications.Add(new Notification
                {
                    UserId = userId,
                    Title = title,
                    Content = content,
                    Type = type,
                    RelatedId = relatedId,
                    CreatedAt = DateTime.Now
                });
            }
        }

        /// <summary>Gửi thông báo tới NHIỀU người dùng cụ thể theo danh sách UserId.</summary>
        public static void NotifyUsers(this AppDbContext db, IEnumerable<int> userIds, string title, string? content, string type, int? relatedId = null)
        {
            foreach (var userId in userIds.Distinct())
            {
                db.Notifications.Add(new Notification
                {
                    UserId = userId,
                    Title = title,
                    Content = content,
                    Type = type,
                    RelatedId = relatedId,
                    CreatedAt = DateTime.Now
                });
            }
        }

        /// <summary>Gửi thông báo tới 1 người dùng cụ thể.</summary>
        public static void NotifyUser(this AppDbContext db, int userId, string title, string? content, string type, int? relatedId = null)
            => db.NotifyUsers(new[] { userId }, title, content, type, relatedId);
    }
}
