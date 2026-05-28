using JobConnect.Data;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class HomeController : Controller
{
    private readonly AppDbContext _db;
    public HomeController(AppDbContext db) => _db = db;

    public async Task<IActionResult> Index()
    {
        var vm = new HomeViewModel
        {
            FeaturedJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => j.Status == "Open" && j.IsFeatured)
                .OrderByDescending(j => j.CreatedAt)
                .Take(8).ToListAsync(),

            LatestJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => j.Status == "Open")
                .OrderByDescending(j => j.CreatedAt)
                .Take(12).ToListAsync(),

            TopCompanies = await _db.Employers
                .Where(e => e.IsVerified)
                .OrderByDescending(e => e.JobPosts.Count(j => j.Status == "Open"))
                .Take(8).ToListAsync(),

            TotalJobs = await _db.JobPosts.CountAsync(j => j.Status == "Open"),
            TotalCompanies = await _db.Employers.CountAsync(e => e.IsVerified),
            TotalCandidates = await _db.Users.CountAsync(u => u.Role == "Candidate"),
            Industries = await _db.Categories.Where(c => c.Type == "Industry").ToListAsync()
        };
        return View(vm);
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error() => View();
}