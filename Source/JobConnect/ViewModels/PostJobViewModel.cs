namespace JobConnect.ViewModels;

public class PostJobViewModel
{
    public int JobId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Requirements { get; set; }
    public string? Benefits { get; set; }
    public string? Location { get; set; }
    public decimal? SalaryMin { get; set; }
    public decimal? SalaryMax { get; set; }
    public string JobType { get; set; } = "FullTime";
    public string? ExperienceLevel { get; set; }
    public DateTime? Deadline { get; set; }
    public string Status { get; set; } = "Pending";
    public int? CategoryID { get; set; }
}