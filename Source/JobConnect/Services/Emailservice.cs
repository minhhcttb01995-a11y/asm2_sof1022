using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;

namespace JobConnect.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _cfg;
    public EmailService(IConfiguration cfg) => _cfg = cfg;

    public async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        var s = _cfg.GetSection("EmailSettings");
        var smtp = new SmtpClient(s["SmtpServer"])
        {
            Port = int.Parse(s["SmtpPort"] ?? "587"),
            Credentials = new NetworkCredential(s["SenderEmail"], s["SenderPassword"]),
            EnableSsl = bool.Parse(s["EnableSsl"] ?? "true"),
            DeliveryMethod = SmtpDeliveryMethod.Network
        };

        var msg = new MailMessage
        {
            From = new MailAddress(s["SenderEmail"]!, s["SenderName"] ?? "JobConnect"),
            Subject = subject,
            Body = htmlBody,
            IsBodyHtml = true
        };
        msg.To.Add(toEmail);

        await smtp.SendMailAsync(msg);
    }
}