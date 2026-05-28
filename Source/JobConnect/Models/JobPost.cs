using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class JobPost
{
    [Key]
    public int JobID { get; set; }
    public int EmployerID { get; set; }
    public int? CategoryID { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Requirements { get; set; }
    public string? Benefits { get; set; }
    public decimal? SalaryMin { get; set; }
    public decimal? SalaryMax { get; set; }
    public bool SalaryNegotiable { get; set; } = false;
    public string JobType { get; set; } = "FullTime"; // FullTime | PartTime | Contract | Intern | Remote
    public string? Location { get; set; }
    public string? ExperienceLevel { get; set; } // Fresher | Junior | Middle | Senior | Manager
    public DateTime? Deadline { get; set; }
    public string Status { get; set; } = "Pending"; // Draft | Pending | Open | Closed | Rejected
    public int ViewCount { get; set; } = 0;
    public bool IsFeatured { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }
    public Employer Employer { get; set; } = null!;
    public Category? Category { get; set; }
    public ICollection<Application> Applications { get; set; } = new List<Application>();
    public ICollection<SavedJob> SavedJobs { get; set; } = new List<SavedJob>();
    // Helper property
    public string SalaryDisplay =>
        SalaryNegotiable ? "Thương lượng" :
        SalaryMin.HasValue && SalaryMax.HasValue
            ? $"{SalaryMin:N0} – {SalaryMax:N0} VND"
            : SalaryMin.HasValue ? $"Từ {SalaryMin:N0} VND" : "Thỏa thuận";
}