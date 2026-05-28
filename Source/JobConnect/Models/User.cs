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
    public string Status { get; set; } = "Active"; // Active | Banned | Pending
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public CandidateProfile? CandidateProfile { get; set; }
    public Employer? Employer { get; set; }
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<SavedJob> SavedJobs { get; set; } = new List<SavedJob>();
    public ICollection<SystemLog> SystemLogs { get; set; } = new List<SystemLog>();
}