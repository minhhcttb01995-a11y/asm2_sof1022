using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels.Staff;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Staff,Admin")]
public class StaffDashboardController : Controller
{
    private readonly AppDbContext _context;
    private readonly ILogger<StaffDashboardController> _logger;

    public StaffDashboardController(AppDbContext context, ILogger<StaffDashboardController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // ==================== HELPER METHODS ====================

    // Lấy Staff hiện tại từ User logged in
    private async Task<Staff?> GetCurrentStaffAsync()
    {
        var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (int.TryParse(userIdStr, out int userId))
        {
            return await _context.Staff.Include(s => s.User).FirstOrDefaultAsync(s => s.ApplicationUserId == userId);
        }
        return null;
    }

    // Ghi ActivityLog
    private async Task LogActivityAsync(Staff staff, string action, string description)
    {
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
        _context.ActivityLogs.Add(new ActivityLog
        {
            StaffId = staff.Id,
            Action = action,
            Description = description,
            IpAddress = ipAddress,
            CreatedAt = DateTime.Now
        });
        await _context.SaveChangesAsync();
    }

    // GET: StaffDashboard
    public async Task<IActionResult> Index()
    {
        var viewModel = new StaffDashboardViewModel
        {
            TotalCompanies = await _context.Employers.CountAsync(),
            TotalJobPosts = await _context.JobPosts.CountAsync(),
            TotalOpenJobPosts = await _context.JobPosts.CountAsync(j => j.Status == "Open"),
            TotalCandidates = await _context.CandidateProfiles.CountAsync(),
            TotalCvFiles = await _context.CvFiles.CountAsync(),
            PendingJobPostsCount = await _context.JobPosts.CountAsync(j => j.Status == "Pending"),
            PendingCompaniesCount = await _context.Employers.CountAsync(e => e.IsLocked == false && e.IsVerified == false),
            TotalReports = await _context.Reports.CountAsync(),
            PendingReports = await _context.Reports.CountAsync(r => r.Status == ReportStatus.Pending),
            OpenTickets = await _context.SupportTickets.CountAsync(t => t.Status == TicketStatus.Open)
        };

        // Chart: phân bố tin tuyển dụng theo ngành nghề (Category Type = "Industry")
        viewModel.JobDistribution = await _context.JobPosts
            .Include(j => j.Category)
            .Where(j => j.Category != null && j.Category.Type == "Industry")
            .GroupBy(j => j.Category!.Name)
            .Select(g => new JobDistributionItem
            {
                Industry = g.Key,
                Count = g.Count()
            })
            .OrderByDescending(x => x.Count)
            .Take(8)
            .ToListAsync();

        // Recent activities
        viewModel.RecentActivities = await _context.ActivityLogs
            .Include(al => al.Staff)
            .OrderByDescending(al => al.CreatedAt)
            .Take(10)
            .Select(al => new RecentActivityViewModel
            {
                Id = al.Id,
                StaffName = al.Staff != null ? al.Staff.FullName : "Unknown",
                Action = al.Action,
                CreatedAt = al.CreatedAt
            })
            .ToListAsync();

        // Pending job posts
        viewModel.PendingJobPosts = await _context.JobPosts
            .Include(j => j.Employer)
            .Where(j => j.Status == "Pending")
            .OrderByDescending(j => j.CreatedAt)
            .Take(5)
            .Select(j => new PendingJobPostViewModel
            {
                Id = j.JobID,
                Title = j.Title,
                CompanyName = j.Employer != null ? j.Employer.CompanyName : "Unknown",
                CreatedAt = j.CreatedAt
            })
            .ToListAsync();

        // Pending companies
        viewModel.PendingCompanies = await _context.Employers
            .Include(e => e.User)
            .Where(e => e.IsLocked == false && e.IsVerified == false)
            .OrderByDescending(e => e.CreatedAt)
            .Take(5)
            .Select(e => new PendingCompanyViewModel
            {
                Id = e.EmployerID,
                CompanyName = e.CompanyName,
                Email = e.User != null ? e.User.Email : "",
                CreatedAt = e.CreatedAt
            })
            .ToListAsync();

        return View(viewModel);
    }

    // ==================== QUẢN LÝ NGƯỜI DÙNG ====================

    // GET: StaffDashboard/Candidates
    public async Task<IActionResult> Candidates(string? keyword, string? status, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Users.Include(u => u.CandidateProfile).Where(u => u.Role == "Candidate").AsQueryable();

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            query = query.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(u => u.Status == status);
        }

        var total = await query.CountAsync();
        var candidates = await query.OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Keyword = keyword;
        ViewBag.Status = status;

        return View(candidates);
    }

    // GET: StaffDashboard/Employers
    public async Task<IActionResult> Employers(string? keyword, string? status, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Employers.Include(e => e.User).AsQueryable();

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            query = query.Where(e => e.CompanyName.Contains(keyword) || e.User!.Email.Contains(keyword));
        }

        if (status == "Verified")
        {
            query = query.Where(e => e.IsVerified);
        }
        else if (status == "Unverified")
        {
            query = query.Where(e => !e.IsVerified);
        }
        else if (status == "Locked")
        {
            query = query.Where(e => e.IsLocked);
        }

        var total = await query.CountAsync();
        var employers = await query.OrderByDescending(e => e.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Keyword = keyword;
        ViewBag.Status = status;

        return View(employers);
    }

    // GET: StaffDashboard/UserDetail/{id}
    public async Task<IActionResult> UserDetail(int id)
    {
        var user = await _context.Users
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.CvFiles)
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.Applications).ThenInclude(a => a.Job)
            .Include(u => u.Employer).ThenInclude(e => e!.JobPosts)
            .FirstOrDefaultAsync(u => u.UserID == id);

        if (user == null) return NotFound();

        return View(user);
    }

    // POST: StaffDashboard/ToggleUserStatus
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleUserStatus(int userId, string? returnUrl)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        // Không cho phép Staff khóa chính mình
        if (currentStaff.ApplicationUserId == user.UserID)
        {
            TempData["Error"] = "Bạn không thể khóa tài khoản của mình.";
            return RedirectToAction(user.Role == "Candidate" ? "Candidates" : "Employers");
        }

        var newStatus = user.Status == "Active" ? "Banned" : "Active";
        var action = newStatus == "Banned" ? "LOCK_USER" : "UNLOCK_USER";
        var description = newStatus == "Banned"
            ? $"Khóa tài khoản {user.Email} ({user.Role})"
            : $"Mở khóa tài khoản {user.Email} ({user.Role})";

        user.Status = newStatus;
        user.UpdatedAt = DateTime.Now;

        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, action, description);

        TempData["Success"] = newStatus == "Banned"
            ? $"Đã khóa tài khoản {user.Email}."
            : $"Đã mở khóa tài khoản {user.Email}.";

        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction(user.Role == "Candidate" ? "Candidates" : "Employers");
    }

    // POST: StaffDashboard/ToggleEmployerLock
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleEmployerLock(int employerId, string? returnUrl)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var employer = await _context.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerID == employerId);
        if (employer == null) return NotFound();

        employer.IsLocked = !employer.IsLocked;
        var action = employer.IsLocked ? "LOCK_EMPLOYER" : "UNLOCK_EMPLOYER";
        var description = employer.IsLocked
            ? $"Khóa công ty {employer.CompanyName}"
            : $"Mở khóa công ty {employer.CompanyName}";

        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, action, description);

        TempData["Success"] = employer.IsLocked
            ? $"Đã khóa công ty {employer.CompanyName}."
            : $"Đã mở khóa công ty {employer.CompanyName}.";

        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction("Employers");
    }

    // ==================== DUYỆT NỘI DUNG ====================

    // GET: StaffDashboard/PendingCompanies
    public async Task<IActionResult> PendingCompanies(int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Employers
            .Include(e => e.User)
            .Where(e => !e.IsVerified && !e.IsLocked)
            .AsQueryable();

        var total = await query.CountAsync();
        var companies = await query.OrderByDescending(e => e.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;

        return View(companies);
    }

    // POST: StaffDashboard/ApproveCompany
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveCompany(int employerId)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var employer = await _context.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerID == employerId);
        if (employer == null) return NotFound();

        employer.IsVerified = true;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "VERIFY_EMPLOYER", $"Xác minh công ty {employer.CompanyName}");

        // Gửi thông báo cho employer
        _context.Notifications.Add(new Notification
        {
            UserID = employer.UserID,
            Title = "Công ty đã được xác minh",
            Content = $"Công ty {employer.CompanyName} của bạn đã được xác minh bởi Admin.",
            Type = "System",
            IsRead = false,
            CreatedAt = DateTime.Now
        });
        await _context.SaveChangesAsync();

        TempData["Success"] = $"Đã xác minh công ty {employer.CompanyName}.";
        return RedirectToAction("PendingCompanies");
    }

    // POST: StaffDashboard/RejectCompany
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> RejectCompany(int employerId, string reason)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var employer = await _context.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerID == employerId);
        if (employer == null) return NotFound();

        employer.IsLocked = true;
        employer.User!.Status = "Banned";
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "REJECT_EMPLOYER", $"Từ chối công ty {employer.CompanyName}. Lý do: {reason}");

        // Gửi thông báo cho employer
        _context.Notifications.Add(new Notification
        {
            UserID = employer.UserID,
            Title = "Công ty bị từ chối",
            Content = $"Công ty {employer.CompanyName} của bạn bị từ chối. Lý do: {reason}",
            Type = "System",
            IsRead = false,
            CreatedAt = DateTime.Now
        });
        await _context.SaveChangesAsync();

        TempData["Success"] = $"Đã từ chối công ty {employer.CompanyName}.";
        return RedirectToAction("PendingCompanies");
    }

    // GET: StaffDashboard/PendingJobs
    public async Task<IActionResult> PendingJobs(string? industry, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Category)
            .Where(j => j.Status == "Pending")
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(industry))
        {
            query = query.Where(j => j.Category != null && j.Category.Name == industry);
        }

        var total = await query.CountAsync();
        var jobs = await query.OrderByDescending(j => j.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Industry = industry;
        ViewBag.Industries = await _context.Categories.Where(c => c.Type == "Industry").Select(c => c.Name).Distinct().ToListAsync();

        return View(jobs);
    }

    // GET: StaffDashboard/JobDetail/{id}
    public async Task<IActionResult> JobDetail(int id)
    {
        var job = await _context.JobPosts
            .Include(j => j.Employer).ThenInclude(e => e!.User)
            .Include(j => j.Category)
            .FirstOrDefaultAsync(j => j.JobID == id);

        if (job == null) return NotFound();

        return View(job);
    }

    // POST: StaffDashboard/ApproveJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveJob(int jobId)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var job = await _context.JobPosts.Include(j => j.Employer).FirstOrDefaultAsync(j => j.JobID == jobId);
        if (job == null) return NotFound();

        job.Status = "Open";
        job.UpdatedAt = DateTime.Now;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "APPROVE_JOB", $"Duyệt tin tuyển dụng: {job.Title}");

        // Gửi thông báo cho employer
        if (job.Employer != null)
        {
            _context.Notifications.Add(new Notification
            {
                UserID = job.Employer.UserID,
                Title = "Tin tuyển dụng đã được duyệt",
                Content = $"Tin \"{job.Title}\" đã được duyệt và đang hiển thị.",
                Type = "System",
                IsRead = false,
                CreatedAt = DateTime.Now
            });
            await _context.SaveChangesAsync();
        }

        TempData["Success"] = $"Đã duyệt tin \"{job.Title}\".";
        return RedirectToAction("PendingJobs");
    }

    // POST: StaffDashboard/RejectJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> RejectJob(int jobId, string reason)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var job = await _context.JobPosts.Include(j => j.Employer).FirstOrDefaultAsync(j => j.JobID == jobId);
        if (job == null) return NotFound();

        job.Status = "Rejected";
        job.UpdatedAt = DateTime.Now;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "REJECT_JOB", $"Từ chối tin: {job.Title}. Lý do: {reason}");

        // Gửi thông báo cho employer
        if (job.Employer != null)
        {
            _context.Notifications.Add(new Notification
            {
                UserID = job.Employer.UserID,
                Title = "Tin tuyển dụng bị từ chối",
                Content = $"Tin \"{job.Title}\" bị từ chối. Lý do: {reason}",
                Type = "System",
                IsRead = false,
                CreatedAt = DateTime.Now
            });
            await _context.SaveChangesAsync();
        }

        TempData["Success"] = $"Đã từ chối tin \"{job.Title}\".";
        return RedirectToAction("PendingJobs");
    }

    // POST: StaffDashboard/HideJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> HideJob(int jobId)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var job = await _context.JobPosts.FirstOrDefaultAsync(j => j.JobID == jobId);
        if (job == null) return NotFound();

        job.Status = "Closed";
        job.UpdatedAt = DateTime.Now;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "HIDE_JOB", $"Ẩn tin: {job.Title}");

        TempData["Success"] = $"Đã ẩn tin \"{job.Title}\".";
        return RedirectToAction("PendingJobs");
    }

    // ==================== XỬ LÝ BÁO CÁO ====================

    // GET: StaffDashboard/Reports
    public async Task<IActionResult> Reports(string? status, string? type, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Reports
            .Include(r => r.Reporter)
            .Include(r => r.JobPost)
            .Include(r => r.Company)
            .Include(r => r.ProcessedByStaff)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<ReportStatus>(status, out var reportStatus))
            {
                query = query.Where(r => r.Status == reportStatus);
            }
        }

        if (!string.IsNullOrWhiteSpace(type))
        {
            if (Enum.TryParse<ReportType>(type, out var reportType))
            {
                query = query.Where(r => r.ReportType == reportType);
            }
        }

        var total = await query.CountAsync();
        var reports = await query.OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Status = status;
        ViewBag.Type = type;

        return View(reports);
    }

    // GET: StaffDashboard/ReportDetail/{id}
    public async Task<IActionResult> ReportDetail(int id)
    {
        var report = await _context.Reports
            .Include(r => r.Reporter)
            .Include(r => r.JobPost).ThenInclude(j => j!.Employer)
            .Include(r => r.Company)
            .Include(r => r.ProcessedByStaff)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (report == null) return NotFound();

        return View(report);
    }

    // POST: StaffDashboard/ProcessReport
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ProcessReport(int reportId, string action, string? note, bool? hideJob)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var report = await _context.Reports
            .Include(r => r.JobPost)
            .FirstOrDefaultAsync(r => r.Id == reportId);
        if (report == null) return NotFound();

        report.ProcessedByStaffId = currentStaff.Id;
        report.ProcessNote = note;
        report.ProcessedAt = DateTime.Now;

        if (action == "Resolve")
        {
            report.Status = ReportStatus.Resolved;
            await LogActivityAsync(currentStaff, "RESOLVE_REPORT", $"Đóng báo cáo #{reportId}");
        }
        else if (action == "Reject")
        {
            report.Status = ReportStatus.Rejected;
            await LogActivityAsync(currentStaff, "REJECT_REPORT", $"Từ chối báo cáo #{reportId}");
        }
        else if (action == "InProgress")
        {
            report.Status = ReportStatus.InProgress;
            await LogActivityAsync(currentStaff, "PROCESS_REPORT", $"Bắt đầu xử lý báo cáo #{reportId}");
        }

        await _context.SaveChangesAsync();

        // Nếu có yêu cầu ẩn tin tuyển dụng
        if (hideJob == true && report.JobPost != null)
        {
            report.JobPost.Status = "Closed";
            report.JobPost.UpdatedAt = DateTime.Now;
            await _context.SaveChangesAsync();
            await LogActivityAsync(currentStaff, "HIDE_JOB", $"Ẩn tin từ báo cáo #{reportId}");
        }

        TempData["Success"] = "Đã cập nhật trạng thái báo cáo.";
        return RedirectToAction("Reports");
    }

    // ==================== HỖ TRỢ TICKET ====================

    // GET: StaffDashboard/Tickets
    public async Task<IActionResult> Tickets(string? status, string? type, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.SupportTickets
            .Include(t => t.User)
            .Include(t => t.AssignedToStaff)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<TicketStatus>(status, out var ticketStatus))
            {
                query = query.Where(t => t.Status == ticketStatus);
            }
        }

        if (!string.IsNullOrWhiteSpace(type))
        {
            if (Enum.TryParse<TicketType>(type, out var ticketType))
            {
                query = query.Where(t => t.Type == ticketType);
            }
        }

        var total = await query.CountAsync();
        var tickets = await query.OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Status = status;
        ViewBag.Type = type;

        return View(tickets);
    }

    // GET: StaffDashboard/TicketDetail/{id}
    public async Task<IActionResult> TicketDetail(int id)
    {
        var ticket = await _context.SupportTickets
            .Include(t => t.User)
            .Include(t => t.AssignedToStaff)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket == null) return NotFound();

        return View(ticket);
    }

    // POST: StaffDashboard/AssignTicket
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> AssignTicket(int ticketId)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null) return NotFound();

        ticket.AssignedToStaffId = currentStaff.Id;
        ticket.Status = TicketStatus.InProgress;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "ASSIGN_TICKET", $"Nhận ticket #{ticketId}");

        TempData["Success"] = "Đã nhận ticket.";
        return RedirectToAction("TicketDetail", new { id = ticketId });
    }

    // POST: StaffDashboard/ReplyTicket
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ReplyTicket(int ticketId, string response)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null) return NotFound();

        ticket.StaffResponse = response;
        ticket.Status = TicketStatus.Resolved;
        ticket.ResolvedAt = DateTime.Now;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "REPLY_TICKET", $"Trả lời ticket #{ticketId}");

        // Gửi thông báo cho user
        _context.Notifications.Add(new Notification
        {
            UserID = ticket.UserId,
            Title = "Ticket đã được giải quyết",
            Content = $"Ticket của bạn đã được giải quyết. Trả lời: {response}",
            Type = "System",
            IsRead = false,
            CreatedAt = DateTime.Now
        });
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã gửi trả lời.";
        return RedirectToAction("TicketDetail", new { id = ticketId });
    }

    // POST: StaffDashboard/CloseTicket
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CloseTicket(int ticketId)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null) return NotFound();

        ticket.Status = TicketStatus.Closed;
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "CLOSE_TICKET", $"Đóng ticket #{ticketId}");

        TempData["Success"] = "Đã đóng ticket.";
        return RedirectToAction("Tickets");
    }

    // ==================== QUẢN LÝ DANH MỤC & SKILL ====================

    // GET: StaffDashboard/Categories
    public async Task<IActionResult> Categories(string? type, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Categories.AsQueryable();

        if (!string.IsNullOrWhiteSpace(type))
        {
            query = query.Where(c => c.Type == type);
        }

        var total = await query.CountAsync();
        var categories = await query.OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Type = type;

        return View(categories);
    }

    // POST: StaffDashboard/CreateCategory
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateCategory(string name, string type, string slug, string? description)
    {
        if (await _context.Categories.AnyAsync(c => c.Slug == slug))
        {
            TempData["Error"] = "Slug đã tồn tại.";
            return RedirectToAction("Categories");
        }

        _context.Categories.Add(new Category
        {
            Name = name,
            Type = type,
            Slug = slug,
            Description = description,
            CreatedAt = DateTime.Now
        });
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã tạo danh mục.";
        return RedirectToAction("Categories", new { type });
    }

    // POST: StaffDashboard/EditCategory
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> EditCategory(int categoryId, string name, string type, string slug, string? description)
    {
        var category = await _context.Categories.FindAsync(categoryId);
        if (category == null) return NotFound();

        if (await _context.Categories.AnyAsync(c => c.Slug == slug && c.CategoryID != categoryId))
        {
            TempData["Error"] = "Slug đã tồn tại.";
            return RedirectToAction("Categories");
        }

        category.Name = name;
        category.Type = type;
        category.Slug = slug;
        category.Description = description;
        category.UpdatedAt = DateTime.Now;
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật danh mục.";
        return RedirectToAction("Categories", new { type });
    }

    // POST: StaffDashboard/DeleteCategory
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteCategory(int categoryId)
    {
        var category = await _context.Categories.FindAsync(categoryId);
        if (category == null) return NotFound();

        _context.Categories.Remove(category);
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã xóa danh mục.";
        return RedirectToAction("Categories");
    }

    // GET: StaffDashboard/Skills
    public async Task<IActionResult> Skills(string? category, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.Skills.AsQueryable();

        if (!string.IsNullOrWhiteSpace(category) && Enum.TryParse<SkillCategory>(category, out var skillCategory))
        {
            query = query.Where(s => s.Category == skillCategory);
        }

        var total = await query.CountAsync();
        var skills = await query.OrderBy(s => s.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Category = category;

        return View(skills);
    }

    // POST: StaffDashboard/CreateSkill
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateSkill(string name, string category, string? description)
    {
        if (await _context.Skills.AnyAsync(s => s.Name == name))
        {
            TempData["Error"] = "Tên kỹ năng đã tồn tại.";
            return RedirectToAction("Skills");
        }

        // Map string to SkillCategory enum
        SkillCategory skillCategory;
        if (category == "Programming")
            skillCategory = SkillCategory.Programming;
        else if (category == "SoftSkills")
            skillCategory = SkillCategory.SoftSkills;
        else if (category == "Language")
            skillCategory = SkillCategory.Language;
        else if (category == "Management")
            skillCategory = SkillCategory.Management;
        else
            skillCategory = SkillCategory.Other;

        _context.Skills.Add(new Skill
        {
            Name = name,
            Category = skillCategory,
            Description = description,
            IsActive = true
        });
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã tạo kỹ năng.";
        return RedirectToAction("Skills");
    }

    // POST: StaffDashboard/ToggleSkill
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleSkill(int skillId)
    {
        var skill = await _context.Skills.FindAsync(skillId);
        if (skill == null) return NotFound();

        skill.IsActive = !skill.IsActive;
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật trạng thái kỹ năng.";
        return RedirectToAction("Skills");
    }

    // POST: StaffDashboard/DeleteSkill
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteSkill(int skillId)
    {
        var skill = await _context.Skills.FindAsync(skillId);
        if (skill == null) return NotFound();

        _context.Skills.Remove(skill);
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã xóa kỹ năng.";
        return RedirectToAction("Skills");
    }

    // ==================== QUẢN LÝ BLOG ====================

    // GET: StaffDashboard/Blog
    public async Task<IActionResult> Blog(string? status, int page = 1)
    {
        const int pageSize = 10;
        var query = _context.BlogPosts.Include(b => b.Author).AsQueryable();

        if (status == "Published")
        {
            query = query.Where(b => b.IsPublished);
        }
        else if (status == "Draft")
        {
            query = query.Where(b => !b.IsPublished);
        }

        var total = await query.CountAsync();
        var posts = await query.OrderByDescending(b => b.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
        ViewBag.Page = page;
        ViewBag.Status = status;

        return View(posts);
    }

    // GET: StaffDashboard/BlogEditor/{id?}
    public async Task<IActionResult> BlogEditor(int? id)
    {
        if (id.HasValue)
        {
            var post = await _context.BlogPosts.FindAsync(id.Value);
            if (post == null) return NotFound();
            return View(post);
        }
        return View();
    }

    // POST: StaffDashboard/SaveBlog
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveBlog(int? postId, string title, string slug, string? excerpt, string? coverUrl, string content, string status)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        BlogPost post;
        if (postId.HasValue)
        {
            post = await _context.BlogPosts.FindAsync(postId.Value);
            if (post == null) return NotFound();
        }
        else
        {
            post = new BlogPost { AuthorID = currentStaff.ApplicationUserId };
            _context.BlogPosts.Add(post);
        }

        post.Title = title;
        post.Slug = string.IsNullOrEmpty(slug) ? title.ToLower().Replace(" ", "-") : slug;
        post.Excerpt = excerpt;
        post.Content = content;
        post.CoverURL = coverUrl;
        post.IsPublished = status == "Published";
        post.PublishedAt = post.IsPublished ? (post.PublishedAt ?? DateTime.Now) : null;
        post.UpdatedAt = DateTime.Now;

        await _context.SaveChangesAsync();
        TempData["Success"] = postId.HasValue ? "Đã cập nhật bài viết." : "Đã tạo bài viết.";
        return RedirectToAction("Blog");
    }

    // POST: StaffDashboard/ToggleBlogPublish
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleBlogPublish(int postId)
    {
        var post = await _context.BlogPosts.FindAsync(postId);
        if (post == null) return NotFound();

        post.IsPublished = !post.IsPublished;
        post.PublishedAt = post.IsPublished ? (post.PublishedAt ?? DateTime.Now) : null;
        await _context.SaveChangesAsync();

        TempData["Success"] = post.IsPublished ? "Đã đăng bài viết." : "Đã ẩn bài viết.";
        return RedirectToAction("Blog");
    }

    // POST: StaffDashboard/DeleteBlog
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteBlog(int postId)
    {
        var post = await _context.BlogPosts.FindAsync(postId);
        if (post == null) return NotFound();

        _context.BlogPosts.Remove(post);
        await _context.SaveChangesAsync();

        TempData["Success"] = "Đã xóa bài viết.";
        return RedirectToAction("Blog");
    }

    // ==================== GỬI THÔNG BÁO ====================

    // GET: StaffDashboard/SendNotification
    public IActionResult SendNotification()
    {
        return View();
    }

    // POST: StaffDashboard/SendNotification
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SendNotification(string title, string content, string target)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        IQueryable<User> usersQuery;
        if (target == "Candidate")
        {
            usersQuery = _context.Users.Where(u => u.Role == "Candidate");
        }
        else if (target == "Employer")
        {
            usersQuery = _context.Users.Where(u => u.Role == "Employer");
        }
        else
        {
            usersQuery = _context.Users;
        }

        var users = await usersQuery.ToListAsync();
        var notifications = users.Select(u => new Notification
        {
            UserID = u.UserID,
            Title = title,
            Content = content,
            Type = "System",
            IsRead = false,
            CreatedAt = DateTime.Now
        }).ToList();

        _context.Notifications.AddRange(notifications);
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "SEND_NOTIFICATION", $"Gửi thông báo hàng loạt đến {target}: {notifications.Count} người");

        TempData["Success"] = $"Đã gửi thông báo đến {notifications.Count} người.";
        return RedirectToAction("SendNotification");
    }

    // ==================== HỒ SƠ CÁ NHÂN ====================

    // GET: StaffDashboard/Profile
    public async Task<IActionResult> Profile()
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        return View(currentStaff);
    }

    // POST: StaffDashboard/UpdateProfile
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProfile(string fullName, string phone, string position, string department)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        currentStaff.FullName = fullName;
        currentStaff.Phone = phone;
        currentStaff.Position = position;
        currentStaff.Department = department;

        if (currentStaff.User != null)
        {
            currentStaff.User.FullName = fullName;
            currentStaff.User.PhoneNumber = phone;
        }

        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "UPDATE_PROFILE", "Cập nhật hồ sơ cá nhân");

        TempData["Success"] = "Đã cập nhật hồ sơ.";
        return RedirectToAction("Profile");
    }

    // POST: StaffDashboard/ChangePassword
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangePassword(string currentPassword, string newPassword)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        if (currentStaff.User == null)
        {
            TempData["Error"] = "Không tìm thấy thông tin user.";
            return RedirectToAction("Profile");
        }

        if (!BCrypt.Net.BCrypt.Verify(currentPassword, currentStaff.User.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu hiện tại không đúng.";
            return RedirectToAction("Profile");
        }

        currentStaff.User.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "CHANGE_PASSWORD", "Đổi mật khẩu");

        TempData["Success"] = "Đã đổi mật khẩu.";
        return RedirectToAction("Profile");
    }

    // POST: StaffDashboard/UpdateAvatar
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateAvatar(IFormFile avatar)
    {
        var currentStaff = await GetCurrentStaffAsync();
        if (currentStaff == null) return Unauthorized();

        if (avatar == null || avatar.Length == 0)
        {
            TempData["Error"] = "Vui lòng chọn file ảnh.";
            return RedirectToAction("Profile");
        }

        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "avatars");
        Directory.CreateDirectory(uploadsFolder);

        var uniqueFileName = Guid.NewGuid().ToString() + Path.GetExtension(avatar.FileName);
        var filePath = Path.Combine(uploadsFolder, uniqueFileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await avatar.CopyToAsync(stream);
        }

        var avatarUrl = $"/uploads/avatars/{uniqueFileName}";
        currentStaff.Avatar = avatarUrl;
        if (currentStaff.User != null)
        {
            currentStaff.User.AvatarURL = avatarUrl;
        }

        await _context.SaveChangesAsync();
        await LogActivityAsync(currentStaff, "UPDATE_AVATAR", "Đổi avatar");

        TempData["Success"] = "Đã cập nhật avatar.";
        return RedirectToAction("Profile");
    }
}