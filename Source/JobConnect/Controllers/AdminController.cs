using JobConnect.Data;
using JobConnect.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Admin")]
public class AdminController : Controller
{
    private readonly AppDbContext _db;
    public AdminController(AppDbContext db) => _db = db;

    // GET /Admin/Dashboard
    public async Task<IActionResult> Dashboard()
    {
        ViewBag.UserCount = await _db.Users.CountAsync();
        ViewBag.JobCount = await _db.JobPosts.CountAsync();
        ViewBag.AppCount = await _db.Applications.CountAsync();
        ViewBag.EmployerCount = await _db.Employers.CountAsync();
        ViewBag.PendingJobs = await _db.JobPosts
            .Include(j => j.Employer)
            .Where(j => j.Status == "Pending")
            .OrderByDescending(j => j.CreatedAt)
            .Take(10).ToListAsync();
        return View();
    }

    // GET /Admin/Users
    public async Task<IActionResult> Users(string? keyword, string? role, int page = 1)
    {
        const int ps = 20;
        var q = _db.Users.AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword));
        if (!string.IsNullOrWhiteSpace(role)) q = q.Where(u => u.Role == role);
        var total = await q.CountAsync();
        var results = await q.OrderByDescending(u => u.CreatedAt)
                              .Skip((page - 1) * ps).Take(ps).ToListAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page;
        return View(results);
    }

    // POST /Admin/BanUser
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BanUser(int userId)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.Status = user.Status == "Active" ? "Banned" : "Active";
            await _db.SaveChangesAsync();
        }
        return RedirectToAction("Users");
    }

    // GET /Admin/Jobs
    public async Task<IActionResult> Jobs(string? status, int page = 1)
    {
        const int ps = 20;
        var q = _db.JobPosts.Include(j => j.Employer).AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) q = q.Where(j => j.Status == status);
        var total = await q.CountAsync();
        var results = await q.OrderByDescending(j => j.CreatedAt)
                              .Skip((page - 1) * ps).Take(ps).ToListAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page;
        ViewBag.Status = status;
        return View(results);
    }

    // POST /Admin/ApproveJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveJob(int jobId, string action)
    {
        var job = await _db.JobPosts.Include(j => j.Employer).FirstOrDefaultAsync(j => j.JobID == jobId);
        if (job != null)
        {
            job.Status = action == "approve" ? "Open" : "Rejected";
            job.UpdatedAt = DateTime.Now;
            _db.Notifications.Add(new Notification
            {
                UserID = job.Employer.UserID,
                Title = action == "approve"
                    ? $"Tin \"{job.Title}\" đã được duyệt!"
                    : $"Tin \"{job.Title}\" bị từ chối.",
                Type = "System",
                RelatedID = job.JobID
            });
            await _db.SaveChangesAsync();
        }
        return RedirectToAction("Jobs");
    }

    // GET /Admin/Companies
    public async Task<IActionResult> Companies(string? q, string? status, int page = 1)
    {
        var query = _db.Employers
            .Include(c => c.User)
            .Include(c => c.JobPosts)
            .AsQueryable();
        if (!string.IsNullOrEmpty(q))
            query = query.Where(c => c.CompanyName.Contains(q) || c.User.Email.Contains(q));
        if (status == "Verified")
            query = query.Where(c => c.IsVerified);
        else if (status == "Unverified")
            query = query.Where(c => !c.IsVerified);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;
        return View(await query.OrderByDescending(c => c.EmployerID)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    // POST /Admin/ApproveCompany
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveCompany(int id)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null) { c.IsVerified = true; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã xác minh công ty.";
        return RedirectToAction("Companies");
    }

    // POST /Admin/SuspendCompany
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SuspendCompany(int id)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null) { c.IsVerified = false; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã hủy xác minh công ty.";
        return RedirectToAction("Companies");
    }

    // GET /Admin/Blog
    public async Task<IActionResult> Blog(string? q, string? status, int page = 1)
    {
        var query = _db.BlogPosts.Include(p => p.Author).AsQueryable();
        if (!string.IsNullOrEmpty(q)) query = query.Where(p => p.Title.Contains(q));
        if (status == "Published") query = query.Where(p => p.IsPublished);
        else if (status == "Draft") query = query.Where(p => !p.IsPublished);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;
        return View(await query.OrderByDescending(p => p.PostID)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    public IActionResult BlogCreate() => View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogCreate(string Title, string? Slug, string? Excerpt,
        string? CoverURL, string Content, string Status)
    {
        var uid = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var slug = string.IsNullOrEmpty(Slug) ? Title.ToLower().Replace(" ", "-") : Slug;
        _db.BlogPosts.Add(new BlogPost
        {
            Title = Title,
            Slug = slug,
            Excerpt = Excerpt,
            CoverURL = CoverURL,
            Content = Content,
            IsPublished = Status == "Published",
            AuthorID = uid,
            PublishedAt = Status == "Published" ? DateTime.Now : null
        });
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã lưu bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogPublish(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post != null) { post.IsPublished = true; post.PublishedAt = DateTime.Now; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã đăng bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogDelete(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post != null) { _db.BlogPosts.Remove(post); await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã xóa bài viết.";
        return RedirectToAction("Blog");
    }

    // GET /Admin/Reports
    public async Task<IActionResult> Reports()
    {
        ViewBag.TotalUsers = await _db.Users.CountAsync();
        ViewBag.TotalJobs = await _db.JobPosts.CountAsync();
        ViewBag.TotalApps = await _db.Applications.CountAsync();
        ViewBag.TotalCompanies = await _db.Employers.CountAsync(c => c.IsVerified);

        // Đơn ứng tuyển 6 tháng gần nhất
        var sixMonths = DateTime.Now.AddMonths(-5);
        ViewBag.MonthlyApps = await _db.Applications
            .Where(a => a.AppliedAt >= sixMonths)
            .GroupBy(a => new { a.AppliedAt.Year, a.AppliedAt.Month })
            .Select(g => new { Month = g.Key.Month + "/" + g.Key.Year, Count = g.Count() })
            .OrderBy(g => g.Month)
            .Select(g => ValueTuple.Create(g.Month, g.Count))
            .ToListAsync();

        // Top 5 ngành nghề
        ViewBag.TopCategories = await _db.JobPosts
            .Where(j => j.Category != null)
            .GroupBy(j => j.Category!.Name)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();

        // Top 5 công ty
        ViewBag.TopCompanies = await _db.JobPosts
            .GroupBy(j => j.Employer.CompanyName)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();

        // Trạng thái đơn
        ViewBag.AppStatus = await _db.Applications
            .GroupBy(a => a.Status)
            .Select(g => ValueTuple.Create(g.Key, g.Count()))
            .ToListAsync();

        // 10 user mới nhất
        ViewBag.RecentUsers = await _db.Users
            .OrderByDescending(u => u.CreatedAt).Take(10).ToListAsync();

        return View();
    }
}