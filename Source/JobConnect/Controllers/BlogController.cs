using JobConnect.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class BlogController : Controller
{
    private readonly AppDbContext _db;
    public BlogController(AppDbContext db) => _db = db;

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
        var post = await _db.BlogPosts
            .Include(p => p.Author)
            .FirstOrDefaultAsync(p => p.Slug == slug && p.IsPublished);

        if (post == null) return NotFound();
        return View(post);
    }
}