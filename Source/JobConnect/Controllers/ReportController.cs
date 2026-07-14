using JobConnect.Data;
using JobConnect.Models;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize]
public class ReportController : Controller
{
    private readonly AppDbContext _context;
    private readonly ILogger<ReportController> _logger;
    private readonly IAntiforgery _antiforgery;

    public ReportController(AppDbContext context, ILogger<ReportController> logger, IAntiforgery antiforgery)
    {
        _context = context;
        _logger = logger;
        _antiforgery = antiforgery;
    }

    // GET: Report/Create
    [Authorize]
    public IActionResult Create(int? companyId = null, int? jobPostId = null)
    {
        ViewBag.CompanyId = companyId;
        ViewBag.JobPostId = jobPostId;
        return View();
    }

    // POST: Report/Create
    [HttpPost]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(int reportType, string reason, string? description, int? companyId = null, int? jobPostId = null)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId))
        {
            return RedirectToAction("Login", "Account");
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return RedirectToAction("Login", "Account");
        }

        // Determine reporter type
        var reporterType = user.Role == "Employer" ? ReporterType.Employer : ReporterType.Candidate;

        // Validate report type matches entity
        if (reportType == (int)ReportType.Company && companyId == null)
        {
            ModelState.AddModelError("", "Vui lòng chọn công ty để báo cáo.");
            ViewBag.CompanyId = companyId;
            ViewBag.JobPostId = jobPostId;
            return View();
        }

        if (reportType == (int)ReportType.JobPost && jobPostId == null)
        {
            ModelState.AddModelError("", "Vui lòng chọn tin tuyển dụng để báo cáo.");
            ViewBag.CompanyId = companyId;
            ViewBag.JobPostId = jobPostId;
            return View();
        }

        // Get entity name
        string? entityName = null;
        if (companyId.HasValue)
        {
            var company = await _context.Employers.FindAsync(companyId.Value);
            entityName = company?.CompanyName;
        }
        else if (jobPostId.HasValue)
        {
            var job = await _context.JobPosts.FindAsync(jobPostId.Value);
            entityName = job?.Title;
        }

        int reportType1 = reportType;
        var report = new Report
        {
            ReporterId = userId,
            ReporterType = (int)reporterType,
            ReportType = (ReportType)reportType1,
            JobPostId = jobPostId,
            CompanyId = companyId,
            ReportedEntityName = entityName,
            Reason = reason,
            Description = description,
            Status = (int)ReportStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reports.Add(report);
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã gửi báo cáo thành công. Chúng tôi sẽ xem xét và xử lý sớm.";
        return RedirectToAction("Index", "Home");
    }

    // POST: Report/CreateAjax  (dùng cho modal báo cáo, không chuyển trang)
    // Lưu ý: KHÔNG dùng [ValidateAntiForgeryToken] trực tiếp vì nó chạy TRƯỚC try/catch —
    // nếu token lỗi, exception sẽ rơi ra trang HTML thay vì JSON, khiến JS phía client
    // (res.json()) bị crash và hiện nhầm thông báo "Không thể kết nối máy chủ".
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> CreateAjax(int reportType, string reason, string? description, int? companyId = null, int? jobPostId = null)
    {
        try
        {
            try
            {
                await _antiforgery.ValidateRequestAsync(HttpContext);
            }
            catch (AntiforgeryValidationException)
            {
                return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang và thử lại." });
            }

            var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId))
            {
                return Json(new { success = false, message = "Vui lòng đăng nhập để gửi báo cáo." });
            }

            if (string.IsNullOrWhiteSpace(reason))
            {
                return Json(new { success = false, message = "Vui lòng nhập lý do báo cáo." });
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return Json(new { success = false, message = "Vui lòng đăng nhập để gửi báo cáo." });
            }

            var reporterType = user.Role == "Employer" ? ReporterType.Employer : ReporterType.Candidate;

            if (reportType == (int)ReportType.Company && companyId == null)
            {
                return Json(new { success = false, message = "Thiếu thông tin công ty để báo cáo." });
            }

            if (reportType == (int)ReportType.JobPost && jobPostId == null)
            {
                return Json(new { success = false, message = "Thiếu thông tin tin tuyển dụng để báo cáo." });
            }

            string? entityName = null;
            if (companyId.HasValue)
            {
                var company = await _context.Employers.FindAsync(companyId.Value);
                entityName = company?.CompanyName;
            }
            else if (jobPostId.HasValue)
            {
                var job = await _context.JobPosts.FindAsync(jobPostId.Value);
                entityName = job?.Title;
            }

            var report = new Report
            {
                ReporterId = userId,
                ReporterType = (int)reporterType,
                ReportType = (ReportType)reportType,
                JobPostId = jobPostId,
                CompanyId = companyId,
                ReportedEntityName = entityName,
                Reason = reason,
                Description = description,
                Status = (int)ReportStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            _context.Reports.Add(report);
            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Đã gửi báo cáo thành công." });
        }
        catch (Exception ex)
        {
            var detail = ex.InnerException?.Message ?? ex.Message;
            _logger.LogError(ex, "Lỗi khi gửi báo cáo qua CreateAjax");
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + detail });
        }
    }

    // GET: Report
    [Authorize(Roles = "Staff,Admin")]
    public async Task<IActionResult> Index(ReportStatus? status = null, int page = 1, int pageSize = 10)
    {
        var query = _context.Reports
            .Include(r => r.Reporter)
            .Include(r => r.JobPost)
            .Include(r => r.Company)
            .Include(r => r.ProcessedByStaff)
            .AsQueryable();

        if (status.HasValue)
        {
            query = query.Where(r => r.Status == status.Value);
        }

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var reports = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;
        ViewBag.StatusFilter = status;

        return View(reports);
    }

    // GET: Report/Details/5
    [Authorize(Roles = "Staff,Admin")]
    public async Task<IActionResult> Details(int id)
    {
        var report = await _context.Reports
            .Include(r => r.Reporter)
            .Include(r => r.JobPost)
            .Include(r => r.Company)
            .Include(r => r.ProcessedByStaff)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (report == null)
        {
            return NotFound();
        }

        return View(report);
    }

    // POST: Report/Process/5
    [HttpPost]
    [Authorize(Roles = "Staff,Admin")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Process(int id, ReportStatus status, string? note)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId))
        {
            return RedirectToAction(nameof(Index));
        }

        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.ApplicationUserId == userId);

        if (staff == null)
        {
            return RedirectToAction(nameof(Index));
        }

        var report = await _context.Reports
            .Include(r => r.JobPost)
            .Include(r => r.Company)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (report == null)
        {
            return NotFound();
        }

        report.Status = status;
        report.ProcessedByStaffId = staff.Id;
        report.ProcessNote = note;
        report.ProcessedAt = DateTime.UtcNow;

        // If resolved/rejected and involves violation, lock the entity
        if (status == ReportStatus.Resolved && report.ReportType == (int)ReportType.JobPost && report.JobPost != null)
        {
            report.JobPost.Status = "Locked";
        }

        if (status == ReportStatus.Resolved && report.ReportType == ReportType.Company && report.Company != null)
        {
            report.Company.IsLocked = true;
        }

        await _context.SaveChangesAsync();

        await LogActivityAsync("Processed Report", $"Processed report {id}. Status: {status}");

        TempData["Success"] = "Đã xử lý báo cáo thành công";
        return RedirectToAction(nameof(Index));
    }

    // POST: Report/Close/5
    [HttpPost]
    [Authorize(Roles = "Staff,Admin")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Close(int id)
    {
        var report = await _context.Reports.FindAsync(id);
        if (report == null)
        {
            return NotFound();
        }

        report.Status = ReportStatus.Resolved;
        report.ProcessedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await LogActivityAsync("Closed Report", $"Closed report {id}");

        TempData["Success"] = "Đã đóng báo cáo";
        return RedirectToAction(nameof(Index));
    }

    private async Task LogActivityAsync(string action, string? description = null)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId)) return;

        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.ApplicationUserId == userId);

        if (staff == null) return;

        var activityLog = new ActivityLog
        {
            StaffId = staff.Id,
            Action = action,
            Description = description,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
            UserAgent = Request.Headers["User-Agent"].ToString(),
            CreatedAt = DateTime.UtcNow
        };

        _context.ActivityLogs.Add(activityLog);
        await _context.SaveChangesAsync();
    }
}