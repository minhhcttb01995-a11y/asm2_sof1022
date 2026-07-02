using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class User
{
    [Key]
    public int UserID { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "Candidate"; // Candidate | Employer | Admin
    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? AvatarURL { get; set; }
    public string Status { get; set; } = "Active"; // Active | Banned | Pending | Deleted
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    // OTP Email Verification
    public string? OtpCode { get; set; }
    public DateTime? OtpExpiry { get; set; }

    // Navigation
    public CandidateProfile? CandidateProfile { get; set; }
    public Employer? Employer { get; set; }
    public Staff? Staff { get; set; }
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<SavedJob> SavedJobs { get; set; } = new List<SavedJob>();
    public ICollection<SystemLog> SystemLogs { get; set; } = new List<SystemLog>();
    public ICollection<Message> SentMessages { get; set; } = new List<Message>();
    public ICollection<Message> ReceivedMessages { get; set; } = new List<Message>();
}