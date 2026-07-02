using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class SupportTicket
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public TicketType Type { get; set; }

    [Required]
    [StringLength(200)]
    public string Subject { get; set; } = string.Empty;

    [Required]
    [StringLength(5000)]
    public string Message { get; set; } = string.Empty;

    [Required]
    public TicketStatus Status { get; set; } = TicketStatus.Open;

    public int? AssignedToStaffId { get; set; }

    public TicketPriority Priority { get; set; } = TicketPriority.Medium;

    [StringLength(5000)]
    public string? StaffResponse { get; set; }

    public DateTime? AssignedAt { get; set; }

    public DateTime? ResolvedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(UserId))]
    public virtual User? User { get; set; }

    [ForeignKey(nameof(AssignedToStaffId))]
    public virtual Staff? AssignedToStaff { get; set; }
}

public enum TicketType
{
    AccountIssue = 1,
    JobPosting = 2,
    Application = 3,
    Billing = 4,
    Technical = 5,
    Other = 6
}

public enum TicketStatus
{
    Open = 1,
    InProgress = 2,
    Resolved = 3,
    Closed = 4
}

public enum TicketPriority
{
    Low = 1,
    Medium = 2,
    High = 3
}
