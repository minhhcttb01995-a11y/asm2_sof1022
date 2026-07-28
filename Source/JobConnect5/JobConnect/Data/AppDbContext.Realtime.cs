// ═══════════════════════════════════════════════════════════════════════════
// AppDbContext.Realtime — PHẦN MỞ RỘNG (partial class) của AppDbContext, KHÔNG
// đụng vào file AppDbContext.cs đã scaffold từ database (Database First).
//
// Mục đích: bất kể Notification mới được tạo ở ĐÂU trong code (AdminController,
// EmployerController, StaffDashboardController, JobService...), miễn là nó được
// lưu qua "_db.Notifications.Add(...)" rồi "SaveChangesAsync()", đoạn code dưới
// đây sẽ TỰ ĐỘNG phát hiện và đẩy real-time xuống đúng người dùng đó qua
// SignalR — không cần sửa lại hàng chục nơi đang tạo Notification.
//
// Cách làm: override SaveChangesAsync — trước khi lưu, ghi nhớ lại các
// Notification nào đang ở trạng thái "Added" (mới thêm, chưa có trong DB); sau
// khi lưu thành công (đã có NotifId), gửi từng cái qua Hub.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Hubs;
using JobConnect.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Data;

public partial class AppDbContext
{
    // Có thể null nếu AppDbContext được khởi tạo bằng constructor không truyền Hub
    // (vd: `new AppDbContext()` ở nơi nào đó không qua DI) — khi đó chỉ đơn giản
    // là bỏ qua bước đẩy real-time, không lỗi.
    private readonly IHubContext<NotificationHub>? _notificationHub;

    // Constructor MỚI: được Dependency Injection ưu tiên chọn (vì có nhiều tham
    // số hơn và cả 2 tham số đều có sẵn trong DI container: DbContextOptions từ
    // AddDbContext<AppDbContext>, và IHubContext<NotificationHub> tự có sau khi
    // gọi builder.Services.AddSignalR() trong Program.cs).
    public AppDbContext(DbContextOptions<AppDbContext> options, IHubContext<NotificationHub> notificationHub)
        : base(options)
    {
        _notificationHub = notificationHub;
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Lấy trước danh sách Notification MỚI (state = Added) trước khi SaveChanges,
        // vì sau khi lưu EF Core sẽ đổi state của chúng sang Unchanged.
        var newNotifications = ChangeTracker.Entries<Notification>()
            .Where(e => e.State == EntityState.Added)
            .Select(e => e.Entity)
            .ToList();

        var result = await base.SaveChangesAsync(cancellationToken);

        if (_notificationHub != null && newNotifications.Count > 0)
        {
            foreach (var n in newNotifications)
            {
                try
                {
                    await _notificationHub.Clients
                        .User(n.UserId.ToString())
                        .SendAsync("ReceiveNotification", new
                        {
                            notifId = n.NotifId,
                            title = n.Title,
                            content = n.Content,
                            type = n.Type,
                            relatedId = n.RelatedId,
                            createdAt = n.CreatedAt.ToString("HH:mm dd/MM/yyyy")
                        }, cancellationToken);
                }
                catch
                {
                    // Không để lỗi đẩy real-time (vd: mất kết nối SignalR tạm thời)
                    // làm hỏng luồng nghiệp vụ chính (Notification đã lưu DB thành công rồi).
                }
            }
        }

        return result;
    }
}
