using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class Report
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int ReporterId { get; set; }

    [Required]
    public ReporterType ReporterType { get; set; }

    [Required]
    public ReportType ReportType { get; set; }

    public int? JobPostId { get; set; }

    public int? CompanyId { get; set; }

    [StringLength(100)]
    public string? ReportedEntityName { get; set; }

    [Required]
    [StringLength(500)]
    public string Reason { get; set; } = string.Empty;

    [StringLength(2000)]
    public string? Description { get; set; }

    [Required]
    public ReportStatus Status { get; set; } = ReportStatus.Pending;

    public int? ProcessedByStaffId { get; set; }

    [StringLength(500)]
    public string? ProcessNote { get; set; }

    public DateTime? ProcessedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey(nameof(ReporterId))]
    public virtual User? Reporter { get; set; }

    public virtual JobPost? JobPost { get; set; }

    public virtual Employer? Company { get; set; }

    [ForeignKey(nameof(ProcessedByStaffId))]
    public virtual Staff? ProcessedByStaff { get; set; }
}

public enum ReporterType
{
    Candidate = 1,
    Employer = 2
}

public enum ReportType
{
    JobPost = 1,
    Company = 2,
    Spam = 3,
    Fraud = 4,
    InappropriateContent = 5,
    Other = 6
}

public enum ReportStatus
{
    Pending = 1,
    InProgress = 2,
    Resolved = 3,
    Rejected = 4
}
