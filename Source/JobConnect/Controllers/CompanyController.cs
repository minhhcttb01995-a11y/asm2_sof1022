// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// CompanyController — trang CÔNG KHAI danh sách & chi tiết CÔNG TY (Employer):
//   • Index: danh sách công ty, lọc theo từ khóa/ngành nghề.
//   • Detail: trang chi tiết 1 công ty (thông tin, tin đang tuyển, why-work-here...).
//   • ToggleFollow: người dùng đã đăng nhập bấm theo dõi/bỏ theo dõi công ty.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

public class CompanyController : Controller
{
    private readonly AppDbContext _db;
    private readonly IStatusCatalogService _statusSvc;
    public CompanyController(AppDbContext db, IStatusCatalogService statusSvc)
    {
        _db = db;
        _statusSvc = statusSvc;
    }

    // GET /Company
    public async Task<IActionResult> Index(string? keyword, string? industry, int page = 1)
    {
        const int pageSize = 12;
        var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);

        var q = _db.Employers
            .Where(e => !e.IsLocked && visibleEmployerStatuses.Contains(e.Status))   // ← Không hiện công ty bị khoá hoặc chờ duyệt
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(e => e.CompanyName.Contains(keyword));

        if (!string.IsNullOrWhiteSpace(industry))
            q = q.Where(e => e.Industry == industry);

        var total = await q.CountAsync();
        var results = await q.OrderByDescending(e => e.IsVerified)
                              .Skip((page - 1) * pageSize).Take(pageSize)
                              .ToListAsync();

        ViewBag.Keyword = keyword;
        ViewBag.Industry = industry;
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Industries = await _db.Categories.Where(c => c.Type == "Industry").ToListAsync();
        return View(results);
    }

    // GET /Company/Detail/5
    public async Task<IActionResult> Detail(int id)
    {
        var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);
        var visibleJobStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.JobPost);

        var emp = await _db.Employers
            .Include(e => e.User)
            .FirstOrDefaultAsync(e => e.EmployerId == id && !e.IsLocked && visibleEmployerStatuses.Contains(e.Status));  // ← Ẩn nếu bị khoá hoặc chờ duyệt

        if (emp == null) return NotFound();

        var jobs = await _db.JobPosts
            .Where(j => j.EmployerId == id && visibleJobStatuses.Contains(j.Status))
            .OrderByDescending(j => j.CreatedAt)
            .ToListAsync();

        emp.WhyWorkHereItems = await _db.CompanyHighlights
            .Where(h => h.EmployerId == id)
            .ToListAsync();

        bool isFollowing = false;
        if (User.Identity?.IsAuthenticated == true)
        {
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out int userId);
            isFollowing = await _db.CompanyFollows
                .AnyAsync(f => f.UserId == userId && f.EmployerId == id);
        }

        ViewBag.Jobs = jobs;
        ViewBag.IsFollowing = isFollowing;
        ViewBag.FollowerCount = await _db.CompanyFollows.CountAsync(f => f.EmployerId == id);
        return View(emp);
    }

    // POST /Company/ToggleFollow/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleFollow(int id, string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated != true)
            return RedirectToAction("Login", "Account", new { returnUrl = $"/Company/Detail/{id}" });

        if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out int userId))
            return RedirectToAction("Login", "Account", new { returnUrl = $"/Company/Detail/{id}" });

        var existing = await _db.CompanyFollows
            .FirstOrDefaultAsync(f => f.UserId == userId && f.EmployerId == id);

        if (existing != null)
        {
            _db.CompanyFollows.Remove(existing);
        }
        else
        {
            _db.CompanyFollows.Add(new CompanyFollow
            {
                UserId = userId,
                EmployerId = id,
                CreatedAt = DateTime.Now
            });
        }

        await _db.SaveChangesAsync();

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            return Redirect(returnUrl);

        return RedirectToAction("Detail", new { id });
    }
}