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
