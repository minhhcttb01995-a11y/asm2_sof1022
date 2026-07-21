// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// HomeController — TRANG CHỦ của website (route mặc định "/"):
//   • Index: hiển thị tin tuyển dụng nổi bật, công ty Hot, thống kê nhanh...
//   • Error: trang lỗi chung khi có exception (dùng bởi app.UseExceptionHandler
//     trong Program.cs khi chạy production).
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class HomeController : Controller
{
    private readonly AppDbContext _db;
    private readonly IStatusCatalogService _statusSvc;
    public HomeController(AppDbContext db, IStatusCatalogService statusSvc)
    {
        _db = db;
        _statusSvc = statusSvc;
    }

    public async Task<IActionResult> Index()
    {
        var visibleJobStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.JobPost);
        var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);

        var vm = new HomeViewModel
        {
            FeaturedJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => visibleJobStatuses.Contains(j.Status) && visibleEmployerStatuses.Contains(j.Employer.Status))
                .OrderByDescending(j => j.CreatedAt)
                .Take(24).ToListAsync(),

            LatestJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => visibleJobStatuses.Contains(j.Status) && visibleEmployerStatuses.Contains(j.Employer.Status))
                .OrderByDescending(j => j.CreatedAt)
                .Take(12).ToListAsync(),

            TopCompanies = await _db.Employers
                .Where(e => e.IsVerified && visibleEmployerStatuses.Contains(e.Status))
                .OrderByDescending(e => e.JobPosts.Count(j => visibleJobStatuses.Contains(j.Status)))
                .Take(8).ToListAsync(),

            TotalJobs = await _db.JobPosts.CountAsync(j => visibleJobStatuses.Contains(j.Status) && visibleEmployerStatuses.Contains(j.Employer.Status)),
            TotalCompanies = await _db.Employers.CountAsync(e => e.IsVerified && visibleEmployerStatuses.Contains(e.Status)),
            TotalCandidates = await _db.Users.CountAsync(u => u.Role == "Candidate"),
            Industries = await _db.Categories.Where(c => c.Type == "Industry").ToListAsync(),
            Locations = await _db.Categories.Where(c => c.Type == "Location").OrderBy(c => c.Name).ToListAsync()
        };
        return View(vm);
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error() => View();
}