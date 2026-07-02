namespace JobConnect.ViewModels.Staff;

public class StaffDashboardViewModel
{
    // Statistics
    public int TotalCompanies { get; set; }
    public int TotalOpenJobPosts { get; set; }   // Chỉ tin đang mở (Status = "Open")
    public int TotalJobPosts { get; set; }        // Tất cả tin (dùng nội bộ nếu cần)
    public int TotalCandidates { get; set; }
    public int TotalCvFiles { get; set; }
    public int PendingJobPostsCount { get; set; }
    public int PendingCompaniesCount { get; set; }
    public int TotalReports { get; set; }
    public int PendingReports { get; set; }
    public int OpenTickets { get; set; }

    // Recent activities
    public List<RecentActivityViewModel> RecentActivities { get; set; } = new();
    public List<PendingJobPostViewModel> PendingJobPosts { get; set; } = new();
    public List<PendingCompanyViewModel> PendingCompanies { get; set; } = new();

    // Chart data: phân bố tin theo ngành nghề
    public List<JobDistributionItem> JobDistribution { get; set; } = new();
}

public class JobDistributionItem
{
    public string Industry { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class RecentActivityViewModel
{
    public int Id { get; set; }
    public string StaffName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class PendingJobPostViewModel
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class PendingCompanyViewModel
{
    public int Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}