using JobConnect.Models;

namespace JobConnect.ViewModels;

public class HomeViewModel
{
    public List<JobPost> FeaturedJobs { get; set; } = new();
    public List<JobPost> LatestJobs { get; set; } = new();
    public List<Employer> TopCompanies { get; set; } = new();
    public List<Category> Industries { get; set; } = new();
    public List<Category> Locations { get; set; } = new();
    public int TotalJobs { get; set; }
    public int TotalCompanies { get; set; }
    public int TotalCandidates { get; set; }
}