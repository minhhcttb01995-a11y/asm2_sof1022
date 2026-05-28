using JobConnect.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class CompanyController : Controller
{
    private readonly AppDbContext _db;
    public CompanyController(AppDbContext db) => _db = db;

    // GET /Company
    public async Task<IActionResult> Index(string? keyword, string? industry, int page = 1)
    {
        const int pageSize = 12;
        var q = _db.Employers.AsQueryable();

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
        var emp = await _db.Employers
            .Include(e => e.User)
            .FirstOrDefaultAsync(e => e.EmployerID == id);

        if (emp == null) return NotFound();

        var jobs = await _db.JobPosts
            .Where(j => j.EmployerID == id && j.Status == "Open")
            .OrderByDescending(j => j.CreatedAt)
            .ToListAsync();

        ViewBag.Jobs = jobs;
        return View(emp);
    }
}