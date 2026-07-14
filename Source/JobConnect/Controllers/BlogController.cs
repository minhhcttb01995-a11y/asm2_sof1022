using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

public class BlogController : Controller
{
    private readonly AppDbContext _db;
    private readonly ILogger<BlogController> _logger;
    private readonly IStatusCatalogService _statusSvc;
    private readonly ICodeGeneratorService _codeGen;
    public BlogController(AppDbContext db, ILogger<BlogController> logger, IStatusCatalogService statusSvc, ICodeGeneratorService codeGen)
    {
        _db = db;
        _logger = logger;
        _statusSvc = statusSvc;
        _codeGen = codeGen;
    }

    // GET /Blog
    public async Task<IActionResult> Index(int page = 1)
    {
        const int pageSize = 9;
        var visibleBlogStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.BlogPost);

        var total = await _db.BlogPosts.CountAsync(p => p.Status != null && visibleBlogStatuses.Contains(p.Status));
        var results = await _db.BlogPosts
            .Include(p => p.Author)
            .Where(p => p.Status != null && visibleBlogStatuses.Contains(p.Status))
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

        var visibleBlogStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.BlogPost);
        var normalized = slug.Trim();
        var post = await _db.BlogPosts
            .Include(p => p.Author)
            .FirstOrDefaultAsync(p => p.Slug == normalized && p.Status != null && visibleBlogStatuses.Contains(p.Status));

        if (post == null)
        {
            _logger.LogWarning("Blog post not found for slug '{slug}'", slug);
            TempData["Error"] = $"Không tìm thấy bài viết với slug '{slug}'.";
            return RedirectToAction("Index");
        }
        return View(post);
    }

    // ====================== ADMIN BLOG MANAGEMENT ======================

    // GET /Admin/Blog
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> AdminIndex(string? keyword, string? status, int page = 1)
    {
        const int pageSize = 20;
        var query = _db.BlogPosts.Include(p => p.Author).AsQueryable();

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            query = query.Where(p => p.Title.Contains(keyword) || p.Slug.Contains(keyword));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(p => p.Status == status);
        }

        var total = await query.CountAsync();
        var posts = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Keyword = keyword;
        ViewBag.Status = status;
        ViewBag.Statuses = await _db.StatusCatalogs
            .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

        return View(posts);
    }

    // GET /Admin/Blog/Create
    [Authorize(Roles = "Admin,Staff")]
    public IActionResult Create()
    {
        ViewBag.Statuses = _db.StatusCatalogs
            .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
            .OrderBy(s => s.Name)
            .ToList();
        return View(new BlogPost());
    }

    // POST /Admin/Blog/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Create(BlogPost model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Statuses = _db.StatusCatalogs
                .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
                .OrderBy(s => s.Name)
                .ToList();
            return View(model);
        }

        // Validate status exists in StatusCatalog
        var statusExists = await _db.StatusCatalogs
            .AnyAsync(s => s.EntityType == StatusEntityTypes.BlogPost && s.Code == model.Status && s.IsActive);

        if (!statusExists)
        {
            ModelState.AddModelError("Status", "Trạng thái không hợp lệ!");
            ViewBag.Statuses = _db.StatusCatalogs
                .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
                .OrderBy(s => s.Name)
                .ToList();
            return View(model);
        }

        model.CreatedAt = DateTime.Now;
        model.UpdatedAt = DateTime.Now;
        model.BlogCode = await _codeGen.GenerateBlogCodeAsync();

        // Set PublishedAt if status is Published
        if (model.Status == "Published")
        {
            model.PublishedAt = DateTime.Now;
        }

        _db.BlogPosts.Add(model);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã tạo bài viết thành công!";
        return RedirectToAction("AdminIndex");
    }

    // GET /Admin/Blog/Edit/5
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Edit(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post == null) return NotFound();

        ViewBag.Statuses = _db.StatusCatalogs
            .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
            .OrderBy(s => s.Name)
            .ToList();

        return View(post);
    }

    // POST /Admin/Blog/Edit
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Edit(BlogPost model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Statuses = _db.StatusCatalogs
                .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
                .OrderBy(s => s.Name)
                .ToList();
            return View(model);
        }

        var post = await _db.BlogPosts.FindAsync(model.PostId);
        if (post == null) return NotFound();

        // Validate status exists in StatusCatalog
        var statusExists = await _db.StatusCatalogs
            .AnyAsync(s => s.EntityType == StatusEntityTypes.BlogPost && s.Code == model.Status && s.IsActive);

        if (!statusExists)
        {
            ModelState.AddModelError("Status", "Trạng thái không hợp lệ!");
            ViewBag.Statuses = _db.StatusCatalogs
                .Where(s => s.EntityType == StatusEntityTypes.BlogPost && s.IsActive)
                .OrderBy(s => s.Name)
                .ToList();
            return View(model);
        }

        post.Title = model.Title;
        post.Slug = model.Slug;
        post.Content = model.Content;
        post.Excerpt = model.Excerpt;
        post.CoverURL = model.CoverURL;
        post.Status = model.Status;
        post.UpdatedAt = DateTime.Now;

        // Update PublishedAt if status changed to Published
        if (model.Status == "Published" && post.PublishedAt == null)
        {
            post.PublishedAt = DateTime.Now;
        }

        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật bài viết thành công!";
        return RedirectToAction("AdminIndex");
    }

    // POST /Admin/Blog/Delete/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Delete(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post == null) return NotFound();

        _db.BlogPosts.Remove(post);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã xóa bài viết thành công!";
        return RedirectToAction("AdminIndex");
    }

    // POST /Admin/Blog/ChangeStatus/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> ChangeStatus(int postId, string newStatus)
    {
        var post = await _db.BlogPosts.FindAsync(postId);
        if (post == null) return NotFound();

        // Validate status exists in StatusCatalog
        var statusExists = await _db.StatusCatalogs
            .AnyAsync(s => s.EntityType == StatusEntityTypes.BlogPost && s.Code == newStatus && s.IsActive);

        if (!statusExists)
        {
            TempData["Error"] = "Trạng thái không hợp lệ!";
            return RedirectToAction("AdminIndex");
        }

        post.Status = newStatus;
        post.UpdatedAt = DateTime.Now;

        // Update PublishedAt if status changed to Published
        if (newStatus == "Published" && post.PublishedAt == null)
        {
            post.PublishedAt = DateTime.Now;
        }

        await _db.SaveChangesAsync();

        TempData["Success"] = $"Đã cập nhật trạng thái bài viết thành: {newStatus}";
        return RedirectToAction("AdminIndex");
    }
}