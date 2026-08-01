// [SERVICE-IFACE-HEADER-ADDED]
// Interface cho dịch vụ GỬI EMAIL (dùng để gửi OTP xác thực, gửi thông báo...).
// Cài đặt bởi Emailservice.cs (dùng SMTP Gmail, cấu hình trong appsettings.json
// mục EmailSettings).
namespace JobConnect.Services;

public interface IEmailService
{
    Task SendAsync(string toEmail, string subject, string htmlBody);
}
