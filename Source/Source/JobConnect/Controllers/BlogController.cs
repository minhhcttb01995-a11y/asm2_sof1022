using JobConnect.Data;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class BlogController : Controller
{
    private readonly AppDbContext _db;
    private readonly ILogger<BlogController> _logger;
    public BlogController(AppDbContext db, ILogger<BlogController> logger) { _db = db; _logger = logger; }

    // GET /Blog
    public async Task<IActionResult> Index(int page = 1)
    {
        const int pageSize = 9;
        var total = await _db.BlogPosts.CountAsync(p => p.IsPublished);
        var results = await _db.BlogPosts
            .Include(p => p.Author)
            .Where(p => p.IsPublished)
            .OrderByDescending(p => p.PublishedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        return View(results);
    }

    // GET /Blog/Detail/slug
    public async Task<IActionResult> Detail(string slug)
    {
        if (string.IsNullOrWhiteSpace(slug))
        {
            _logger.LogWarning("Blog Detail called without slug");
            TempData["Error"] = "Yêu cầu chưa chỉ định slug bài viết.";
            return RedirectToAction("Index");
        }

        var normalized = slug.Trim();
        var post = await _db.BlogPosts
            .Include(p => p.Author)
            .FirstOrDefaultAsync(p => p.Slug == normalized && p.IsPublished);

        if (post == null)
        {
            _logger.LogWarning("Blog post not found for slug '{slug}'", slug);
            TempData["Error"] = $"Không tìm thấy bài viết với slug '{slug}'.";
            return RedirectToAction("Index");
        }
        return View(post);
    }
}