// ═══════════════════════════════════════════════════════════════════════════
// NotificationHub — SignalR Hub dùng để đẩy THÔNG BÁO THỜI GIAN THỰC (real-time)
// từ server xuống trình duyệt, KHÔNG cần người dùng bấm F5 hay chờ polling.
//
// Cách hoạt động:
//   1) Trình duyệt (JS) kết nối tới "/hubs/notifications" (xem file
//      wwwroot/js/notifications-realtime.js).
//   2) SignalR tự động biết kết nối đó thuộc về User nào nhờ Cookie đăng nhập
//      hiện có (vì Hub có [Authorize], và ASP.NET Core mặc định lấy UserId từ
//      claim ClaimTypes.NameIdentifier — CHÍNH LÀ claim mà AccountController
//      đã gán khi đăng nhập, nên KHÔNG cần cấu hình thêm IUserIdProvider).
//   3) Khi có Notification MỚI được lưu vào DB (bất kể tạo ở đâu: AdminController,
//      EmployerController, StaffDashboardController, JobService...), AppDbContext
//      (xem Data/AppDbContext.Realtime.cs) sẽ tự động gọi
//      Clients.User(userId).SendAsync("ReceiveNotification", ...) để đẩy xuống
//      đúng người dùng đó ở MỌI tab/thiết bị đang mở.
//
// Hub này không cần method nào cả vì mọi việc đẩy tin đều đi từ server (qua
// IHubContext<NotificationHub>), trình duyệt chỉ CẦN LẮNG NGHE (client.on(...)).
// ═══════════════════════════════════════════════════════════════════════════
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace JobConnect.Hubs;

[Authorize]
public class NotificationHub : Hub
{
}
