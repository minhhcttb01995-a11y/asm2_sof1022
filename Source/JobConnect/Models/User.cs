using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class User
{
    public int UserId { get; set; }

    /// <summary>Mã người dùng - tự tăng theo UserId (VD: UV000042, NTD000022).</summary>
    public string? UserCode { get; set; }

    public string Email { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public string Role { get; set; } = null!;

    public string FullName { get; set; } = null!;

    public string? PhoneNumber { get; set; }

    public string? AvatarUrl { get; set; }

    // Compatibility alias for views expecting AvatarURL
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? AvatarURL
    {
        get => AvatarUrl;
        set => AvatarUrl = value;
    }

    // Some views expect a DeletedAt column
    public DateTime? DeletedAt { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public string? OtpCode { get; set; }

    public DateTime? OtpExpiry { get; set; }

    public virtual ICollection<BlogPost> BlogPosts { get; set; } = new List<BlogPost>();

    public virtual CandidateProfile? CandidateProfile { get; set; }

    public virtual Employer? Employer { get; set; }

    public virtual ICollection<Message> MessageReceivers { get; set; } = new List<Message>();

    public virtual ICollection<Message> MessageSenders { get; set; } = new List<Message>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<SavedJob> SavedJobs { get; set; } = new List<SavedJob>();

    public virtual Staff? Staff { get; set; }

    public virtual ICollection<SupportTicket> SupportTickets { get; set; } = new List<SupportTicket>();

    public virtual ICollection<SystemLog> SystemLogs { get; set; } = new List<SystemLog>();
}
