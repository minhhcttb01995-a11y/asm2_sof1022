// [[FILE-HEADER-ADDED]]
// ViewModel cho trang chủ (HomeController.Index): gom tin nổi bật, tin mới nhất,
// công ty hàng đầu, danh mục ngành nghề/địa điểm và vài số liệu thống kê tổng quan.
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