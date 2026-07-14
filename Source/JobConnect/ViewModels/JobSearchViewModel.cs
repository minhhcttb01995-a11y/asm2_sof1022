namespace JobConnect.ViewModels;

public class JobSearchViewModel
{
    public string? Keyword { get; set; }
    public string? Location { get; set; }
    public string? JobType { get; set; }
    public string? ExperienceLevel { get; set; }
    public string? CategorySlug { get; set; }
    public decimal? SalaryMin { get; set; }
    public List<string>? Salary { get; set; }
    public List<int>? Category { get; set; }
    public string? SortBy { get; set; } = "newest";
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 12;
}