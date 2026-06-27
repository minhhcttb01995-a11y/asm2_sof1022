using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class PasswordResetToken
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(6)]
    public string Code { get; set; } = string.Empty;   // 6 chữ số

    public DateTime ExpiresAt { get; set; }            // hết hạn sau 10 phút

    public bool IsUsed { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.Now;
}