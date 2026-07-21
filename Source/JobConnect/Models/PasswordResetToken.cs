// [MODEL-HEADER-ADDED]
// Bảng LƯU MÃ OTP/TOKEN dùng để đặt lại mật khẩu qua email: mỗi lần người dùng
// yêu cầu quên mật khẩu, hệ thống sinh 1 Code kèm thời hạn (ExpiresAt) và đánh
// dấu IsUsed sau khi dùng để tránh dùng lại token cũ.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class PasswordResetToken
{
    public int Id { get; set; }

    public string Email { get; set; } = null!;

    public string Code { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }

    public DateTime CreatedAt { get; set; }
}
