// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// AdminController — [Authorize(Roles = "Admin")]: TRANG QUẢN TRỊ DÀNH RIÊNG CHO ADMIN
// (quyền cao nhất hệ thống, khác StaffDashboardController dùng chung cho cả Staff).
// Các nhóm chức năng chính:
//   • Dashboard: thống kê tổng quan hệ thống theo khoảng thời gian (period).
//   • Users/UserDetail/CreateUser/BanUser/DeleteUser/DeletedUsers/RestoreUser/
//     PermanentDeleteUser: quản lý toàn bộ tài khoản người dùng (xóa mềm + khôi phục
//     + xóa vĩnh viễn).
//   • Jobs/DeleteJob/SetJobStatus/FixOrphanEmployers: quản lý tin tuyển dụng ở tầm hệ thống.
//   • Companies/CreateCompany/CompanyDetail/ApproveCompany/SuspendCompany/LockCompany/
//     DeleteCompany: duyệt/khóa/xóa công ty (Employer).
//   • Hot/ToggleJobFeatured/ToggleCompanyFeatured: quản lý mục "Hot" trên trang chủ
//     (tin/công ty nổi bật).
//   • PostJobForEmployer: Admin đăng tin THAY cho 1 nhà tuyển dụng cụ thể.
//   • EmployerApplications/FixCvApplication: xử lý sự cố liên quan hồ sơ ứng tuyển.
//   • Blog/BlogCreate/BlogEdit/BlogPublish: quản lý bài viết Blog.
// Đây là 1 trong các controller lớn nhất hệ thống (>1600 dòng) — nên khi sửa, tìm
// đúng action bằng tên method thay vì đọc tuần tự toàn bộ file.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Extensions;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Admin")]
public class AdminController : Controller
{
    private readonly AppDbContext _db;
    private readonly IJobService _jobSvc;
    private readonly ISkillService _skillSvc;
    private readonly IStatusCatalogService _statusSvc;
    private readonly ICodeGeneratorService _codeGen;
    private readonly IAntiforgery _antiforgery;
    public AdminController(AppDbContext db, IJobService jobSvc, ISkillService skillSvc, IStatusCatalogService statusSvc, ICodeGeneratorService codeGen, IAntiforgery antiforgery) { _db = db; _jobSvc = jobSvc; _skillSvc = skillSvc; _statusSvc = statusSvc; _codeGen = codeGen; _antiforgery = antiforgery; }

    public IActionResult Index() => RedirectToAction("Dashboard");

    // GET /Admin/CandidateSkills/{profileId}
    public async Task<IActionResult> CandidateSkills(int profileId)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CandidateSkills)
                .ThenInclude(cs => cs.Skill)
            .FirstOrDefaultAsync(p => p.ProfileId == profileId);

        if (profile == null) return NotFound();

        return View(profile);
    }

    // =====================================================================
    // THAY THẾ action Dashboard() trong AdminController.cs
    // (chỉ thay phần Dashboard, giữ nguyên toàn bộ các action khác)
    // =====================================================================

    // GET /Admin/Dashboard
    public async Task<IActionResult> Dashboard(string period = "month")
    {
        // ── 1. KPI Cards ──────────────────────────────────────────────
        ViewBag.CandidateCount = await _db.Users.CountAsync(u => u.Role == "Candidate");
        ViewBag.EmployerCount = await _db.Employers.CountAsync();
        ViewBag.StaffCount = await _db.Staff.CountAsync();
        ViewBag.CompanyCount = await _db.Employers.CountAsync(e => e.IsVerified);
        ViewBag.JobCount = await _db.JobPosts.CountAsync();
        ViewBag.CvCount = await _db.CvFiles.CountAsync();
        ViewBag.AppCount = await _db.Applications.CountAsync();
        ViewBag.UserCount = await _db.Users.CountAsync();
        ViewBag.BannedCount = await _db.Users.CountAsync(u => u.Status == "Banned");

        // tin tuyển dụng
        ViewBag.OpenJobCount = await _db.JobPosts.CountAsync(j => j.Status == "Active");
        ViewBag.PendingJobCount = await _db.JobPosts.CountAsync(j => j.Status == "Pending");

        // đơn ứng tuyển theo status
        ViewBag.AppPending = await _db.Applications.CountAsync(a => a.Status == "Pending");
        ViewBag.AppAccepted = await _db.Applications.CountAsync(a => a.Status == "Accepted");
        ViewBag.AppRejected = await _db.Applications.CountAsync(a => a.Status == "Rejected");
        ViewBag.AppInterview = await _db.Applications.CountAsync(a => a.Status == "Interview");

        // ── 2. Biểu đồ tăng trưởng theo period ───────────────────────
        ViewBag.Period = period;

        if (period == "year")
        {
            // 12 tháng của năm hiện tại
            int year = DateTime.Now.Year;
            var months = Enumerable.Range(1, 12).ToList();

            var usersByMonth = await _db.Users
                .Where(u => u.CreatedAt.Year == year)
                .GroupBy(u => u.CreatedAt.Month)
                .Select(g => new { Month = g.Key, Count = g.Count() })
                .ToListAsync();

            var jobsByMonth = await _db.JobPosts
                .Where(j => j.CreatedAt.Year == year)
                .GroupBy(j => j.CreatedAt.Month)
                .Select(g => new { Month = g.Key, Count = g.Count() })
                .ToListAsync();

            var appsByMonth = await _db.Applications
                .Where(a => a.AppliedAt.Year == year)
                .GroupBy(a => a.AppliedAt.Month)
                .Select(g => new { Month = g.Key, Count = g.Count() })
                .ToListAsync();

            ViewBag.ChartLabels = months.Select(m => $"T{m}").ToArray();
            ViewBag.ChartUsers = months.Select(m => usersByMonth.FirstOrDefault(x => x.Month == m)?.Count ?? 0).ToArray();
            ViewBag.ChartJobs = months.Select(m => jobsByMonth.FirstOrDefault(x => x.Month == m)?.Count ?? 0).ToArray();
            ViewBag.ChartApps = months.Select(m => appsByMonth.FirstOrDefault(x => x.Month == m)?.Count ?? 0).ToArray();
        }
        else if (period == "week")
        {
            // 7 ngày gần nhất
            var days = Enumerable.Range(0, 7).Select(i => DateTime.Now.Date.AddDays(-6 + i)).ToList();
            var from = days.First();

            var usersByDay = await _db.Users
                .Where(u => u.CreatedAt >= from)
                .GroupBy(u => u.CreatedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            var jobsByDay = await _db.JobPosts
                .Where(j => j.CreatedAt >= from)
                .GroupBy(j => j.CreatedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            var appsByDay = await _db.Applications
                .Where(a => a.AppliedAt >= from)
                .GroupBy(a => a.AppliedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            ViewBag.ChartLabels = days.Select(d => d.ToString("dd/MM")).ToArray();
            ViewBag.ChartUsers = days.Select(d => usersByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
            ViewBag.ChartJobs = days.Select(d => jobsByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
            ViewBag.ChartApps = days.Select(d => appsByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
        }
        else
        {
            // Mặc định: 30 ngày gần nhất — nhóm theo tuần (4–5 điểm)
            var from = DateTime.Now.Date.AddDays(-29);
            var weeks = Enumerable.Range(0, 5).Select(i => from.AddDays(i * 6)).ToList();

            var usersByDay = await _db.Users
                .Where(u => u.CreatedAt >= from)
                .GroupBy(u => u.CreatedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            var jobsByDay = await _db.JobPosts
                .Where(j => j.CreatedAt >= from)
                .GroupBy(j => j.CreatedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            var appsByDay = await _db.Applications
                .Where(a => a.AppliedAt >= from)
                .GroupBy(a => a.AppliedAt.Date)
                .Select(g => new { Day = g.Key, Count = g.Count() })
                .ToListAsync();

            // Nhóm theo từng ngày trong 30 ngày
            var days = Enumerable.Range(0, 30).Select(i => from.AddDays(i)).ToList();
            ViewBag.ChartLabels = days.Select(d => d.ToString("dd/MM")).ToArray();
            ViewBag.ChartUsers = days.Select(d => usersByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
            ViewBag.ChartJobs = days.Select(d => jobsByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
            ViewBag.ChartApps = days.Select(d => appsByDay.FirstOrDefault(x => x.Day == d)?.Count ?? 0).ToArray();
        }

        // ── 3. Biểu đồ tròn: phân bố tin theo ngành ──────────────────
        ViewBag.IndustryLabels = await _db.JobPosts
            .Where(j => j.Category != null && j.Category.Type == "Industry")
            .GroupBy(j => j.Category!.Name)
            .Select(g => g.Key)
            .Take(6).ToListAsync();

        ViewBag.IndustryCounts = await _db.JobPosts
            .Where(j => j.Category != null && j.Category.Type == "Industry")
            .GroupBy(j => j.Category!.Name)
            .Select(g => g.Count())
            .Take(6).ToListAsync();

        // ── 4. Bảng danh sách nhanh ───────────────────────────────────
        ViewBag.PendingJobs = await _db.JobPosts
            .Include(j => j.Employer)
            .Where(j => j.Status == "Pending")
            .OrderByDescending(j => j.CreatedAt)
            .Take(8).ToListAsync();

        ViewBag.NewUsers = await _db.Users
            .OrderByDescending(u => u.CreatedAt)
            .Take(5).ToListAsync();

        ViewBag.NewApps = await _db.Applications
            .Include(a => a.CandidateProfile)
            .Include(a => a.Job).ThenInclude(j => j!.Employer)
            .OrderByDescending(a => a.AppliedAt)
            .Take(5).ToListAsync();

        // ── 5. Tăng trưởng so với tháng trước ────────────────────────
        var thisMonthStart = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
        var lastMonthStart = thisMonthStart.AddMonths(-1);

        int newUsersThisMonth = await _db.Users.CountAsync(u => u.CreatedAt >= thisMonthStart);
        int newUsersLastMonth = await _db.Users.CountAsync(u => u.CreatedAt >= lastMonthStart && u.CreatedAt < thisMonthStart);
        int newJobsThisMonth = await _db.JobPosts.CountAsync(j => j.CreatedAt >= thisMonthStart);
        int newJobsLastMonth = await _db.JobPosts.CountAsync(j => j.CreatedAt >= lastMonthStart && j.CreatedAt < thisMonthStart);
        int newAppsThisMonth = await _db.Applications.CountAsync(a => a.AppliedAt >= thisMonthStart);
        int newAppsLastMonth = await _db.Applications.CountAsync(a => a.AppliedAt >= lastMonthStart && a.AppliedAt < thisMonthStart);

        ViewBag.NewUsersThisMonth = newUsersThisMonth;
        ViewBag.NewJobsThisMonth = newJobsThisMonth;
        ViewBag.NewAppsThisMonth = newAppsThisMonth;

        // % tăng trưởng (tránh chia 0)
        ViewBag.UserGrowth = newUsersLastMonth > 0
            ? Math.Round((newUsersThisMonth - newUsersLastMonth) * 100.0 / newUsersLastMonth, 1)
            : (newUsersThisMonth > 0 ? 100.0 : 0);
        ViewBag.JobGrowth = newJobsLastMonth > 0
            ? Math.Round((newJobsThisMonth - newJobsLastMonth) * 100.0 / newJobsLastMonth, 1)
            : (newJobsThisMonth > 0 ? 100.0 : 0);
        ViewBag.AppGrowth = newAppsLastMonth > 0
            ? Math.Round((newAppsThisMonth - newAppsLastMonth) * 100.0 / newAppsLastMonth, 1)
            : (newAppsThisMonth > 0 ? 100.0 : 0);

        return View();
    }

    // ====================== USERS ======================

    public async Task<IActionResult> Users(string? keyword, string? role, int page = 1)
    {
        const int ps = 20;
        var q = _db.Users.Where(u => u.Status != "Deleted").AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword) || (u.UserCode != null && u.UserCode.Contains(keyword)));
        if (!string.IsNullOrWhiteSpace(role))
            q = q.Where(u => u.Role == role);
        var total = await q.CountAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page; ViewBag.Keyword = keyword; ViewBag.Role = role;

        // Load status options from StatusCatalog for each role
        ViewBag.CandidateStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Candidate);
        ViewBag.EmployerStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Employer);
        ViewBag.StaffStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Staff);

        return View(await q.OrderByDescending(u => u.CreatedAt).Skip((page - 1) * ps).Take(ps).ToListAsync());
    }

    public async Task<IActionResult> UserDetail(int id)
    {
        var user = await _db.Users
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.CvFiles)
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.Applications).ThenInclude(a => a.Job)
            .Include(u => u.Employer).ThenInclude(e => e!.JobPosts)
            .FirstOrDefaultAsync(u => u.UserId == id);
        if (user == null) return NotFound();

        // Load status options from StatusCatalog
        ViewBag.CandidateStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Candidate);
        ViewBag.EmployerStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Employer);
        ViewBag.StaffStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Staff);

        return View(user);
    }

    // GET /Admin/EditCandidateProfile/{id}
    public async Task<IActionResult> EditCandidateProfile(int id)
    {
        var profile = await _db.CandidateProfiles.FindAsync(id);
        if (profile == null) return NotFound();
        return View(profile);
    }

    // POST /Admin/EditCandidateProfile/{id}
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> EditCandidateProfile(int id, CandidateProfile model)
    {
        var profile = await _db.CandidateProfiles.FindAsync(id);
        if (profile == null) return NotFound();

        // Cac navigation property (User, CvFiles, Applications, CandidateSkills) khong duoc submit tu form
        // nen can loai khoi ModelState de tranh loi "Field required" gia do non-nullable reference type
        ModelState.Remove(nameof(model.User));
        ModelState.Remove(nameof(model.CvFiles));
        ModelState.Remove(nameof(model.Applications));
        ModelState.Remove(nameof(model.CandidateSkills));

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        profile.FullName = model.FullName;
        profile.Phone = model.Phone;
        profile.DateOfBirth = model.DateOfBirth;
        profile.Gender = model.Gender;
        profile.Address = model.Address;
        profile.ExperienceYears = model.ExperienceYears;
        profile.DesiredSalary = model.DesiredSalary;
        profile.Summary = model.Summary;
        // Không còn checkbox "Đang tìm việc" trên form nữa nên không ghi đè IsOpenToWork

        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã cập nhật thông tin ứng viên thành công.";
        return RedirectToAction("UserDetail", new { id = profile.UserId });
    }

    public IActionResult CreateUser() => View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateUser(string fullName, string email, string password, string role, string? companyName)
    {
        if (await _db.Users.AnyAsync(u => u.Email == email))
        {
            ModelState.AddModelError("", "Email đã tồn tại.");
            return View();
        }
        if (role == "Employer" && string.IsNullOrWhiteSpace(companyName))
        {
            TempData["Error"] = "Vui lòng nhập tên công ty khi tạo tài khoản Nhà tuyển dụng.";
            return RedirectToAction("Users");
        }

        var user = new User
        {
            FullName = fullName,
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = role,
            Status = "Active",
            CreatedAt = DateTime.Now
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        // Mã người dùng: tự tăng theo UserId
        user.UserCode = _codeGen.GenerateUserCode(role, user.UserId);
        await _db.SaveChangesAsync();

        if (role == "Candidate")
        {
            _db.CandidateProfiles.Add(new CandidateProfile { UserId = user.UserId, FullName = fullName });
            await _db.SaveChangesAsync();
        }
        else if (role == "Employer")
        {
            // QUAN TRỌNG: tạo user Employer bắt buộc phải có Employer (hồ sơ công ty) đi kèm,
            // nếu không công ty sẽ "biến mất" khỏi trang Quản lý công ty dù tài khoản vẫn tồn tại.
            _db.Employers.Add(new Employer
            {
                UserId = user.UserId,
                CompanyCode = await _codeGen.GenerateCompanyCodeAsync(),
                CompanyName = companyName!.Trim(),
                IsVerified = false,
                Status = "Pending",
                CreatedAt = DateTime.Now
            });
            await _db.SaveChangesAsync();
        }
        TempData["Success"] = $"Đã tạo tài khoản {email} thành công!";
        return RedirectToAction("Users");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BanUser(int userId, string? returnUrl)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.Status = user.Status == "Active" ? "Banned" : "Active";
            user.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();
            TempData["Success"] = user.Status == "Banned"
                ? $"Đã khoá tài khoản {user.Email}."
                : $"Đã mở khoá tài khoản {user.Email}.";
        }
        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction("Users");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteUser(int userId)
    {
        var user = await _db.Users
            .Include(u => u.Staff)
            .Include(u => u.CandidateProfile)
            .Include(u => u.Employer)
            .FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null) return NotFound();
        if (user.Role == "Admin") { TempData["Error"] = "Không thể xóa tài khoản Admin."; return RedirectToAction("Users"); }

        var email = user.Email;

        // Xóa vĩnh viễn khỏi CSDL cùng các dữ liệu liên quan trực tiếp
        if (user.Staff != null) _db.Staff.Remove(user.Staff);
        if (user.CandidateProfile != null) _db.CandidateProfiles.Remove(user.CandidateProfile);
        if (user.Employer != null) _db.Employers.Remove(user.Employer);

        _db.Users.Remove(user);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            TempData["Error"] = $"Không thể xóa vĩnh viễn tài khoản {email} vì vẫn còn dữ liệu liên quan (đơn ứng tuyển, tin tuyển dụng, tin nhắn...). Hãy xử lý/xóa các dữ liệu đó trước.";
            return RedirectToAction("Users");
        }

        TempData["Success"] = $"Đã xóa vĩnh viễn tài khoản {email} khỏi hệ thống.";
        return RedirectToAction("Users");
    }

    // ====================== USERS ĐÃ XÓA ======================

    public async Task<IActionResult> DeletedUsers(string? keyword, int page = 1)
    {
        const int ps = 20;
        var q = _db.Users.Where(u => u.Status == "Deleted").AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword) || (u.UserCode != null && u.UserCode.Contains(keyword)));
        var total = await q.CountAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page; ViewBag.Keyword = keyword;
        return View(await q.OrderByDescending(u => u.DeletedAt).Skip((page - 1) * ps).Take(ps).ToListAsync());
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> RestoreUser(int userId)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null) return NotFound();
        if (user.Status != "Deleted") { TempData["Error"] = "Tài khoản này không ở trạng thái đã xóa."; return RedirectToAction("DeletedUsers"); }

        user.Status = "Active";
        user.DeletedAt = null;
        user.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã khôi phục tài khoản {user.Email}.";
        return RedirectToAction("DeletedUsers");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PermanentDeleteUser(int userId)
    {
        var user = await _db.Users
            .Include(u => u.Staff)
            .Include(u => u.CandidateProfile)
            .Include(u => u.Employer)
            .FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null) return NotFound();
        if (user.Status != "Deleted") { TempData["Error"] = "Chỉ có thể xóa vĩnh viễn tài khoản đang ở trạng thái đã xóa."; return RedirectToAction("DeletedUsers"); }

        if (user.Staff != null) _db.Staff.Remove(user.Staff);
        if (user.CandidateProfile != null) _db.CandidateProfiles.Remove(user.CandidateProfile);
        if (user.Employer != null) _db.Employers.Remove(user.Employer);

        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã xóa vĩnh viễn tài khoản {user.Email}.";
        return RedirectToAction("DeletedUsers");
    }

    // ====================== JOBS ======================

    // ====================== PATCH: thay thế action Jobs() và thêm DeleteJob() ======================
    // Tìm action Jobs() cũ trong AdminController.cs, thay bằng đoạn này:

    public async Task<IActionResult> Jobs(string? status, string? q, int page = 1)
    {
        const int ps = 20;
        var query = _db.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Applications)
            .AsQueryable();

        // Search by title or JobId
        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(j => j.Title.Contains(q) || j.JobId.ToString() == q || (j.JobCode != null && j.JobCode.Contains(q)));
        }

        // Filter by status
        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(j => j.Status == status);
        }

        var total = await query.CountAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page;
        ViewBag.Status = status;
        ViewBag.Q = q;

        // Load status options from StatusCatalog for JobPost
        ViewBag.JobPostStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.JobPost);

        return View(await query.OrderByDescending(j => j.CreatedAt)
                           .Skip((page - 1) * ps).Take(ps).ToListAsync());
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteJob(int jobId, string? filterStatus)
    {
        var job = await _db.JobPosts
            .Include(j => j.Applications)
            .FirstOrDefaultAsync(j => j.JobId == jobId);

        if (job == null) return NotFound();

        // Xóa các đơn ứng tuyển liên quan
        if (job.Applications.Any())
            _db.Applications.RemoveRange(job.Applications);

        _db.JobPosts.Remove(job);
        await _db.SaveChangesAsync();

        TempData["Success"] = $"Đã xóa tin \"{job.Title}\" và {job.Applications.Count} đơn ứng tuyển liên quan.";
        return RedirectToAction("Jobs", new { status = filterStatus });
    }
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SetJobStatus(int jobId, string status, string? filterStatus)
    {
        var job = await _db.JobPosts.FindAsync(jobId);
        if (job == null) return NotFound();

        job.Status = status;
        job.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        var msg = status switch
        {
            "Active" => $"Đã duyệt tin \"{job.Title}\".",
            "Rejected" => $"Đã từ chối tin \"{job.Title}\".",
            "Banned" => $"Đã khóa tin \"{job.Title}\".",
            _ => $"Đã cập nhật trạng thái tin \"{job.Title}\" thành {status}."
        };
        TempData["Success"] = msg;
        return RedirectToAction("Jobs", new { status = filterStatus });
    }

    // ====================== COMPANIES ======================

    /// <summary>
    /// Khắc phục dữ liệu cũ: các tài khoản Role=Employer được tạo trước khi có logic bắt buộc
    /// tạo kèm Employer (công ty) sẽ bị "mồ côi" — có tài khoản đăng nhập nhưng không xuất hiện
    /// trong Quản lý công ty. Hàm này quét và tự tạo hồ sơ công ty placeholder (trạng thái Pending)
    /// cho các tài khoản đó để admin vào sửa lại thông tin công ty cho đúng.
    /// </summary>
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> FixOrphanEmployers()
    {
        var orphanUsers = await _db.Users
            .Where(u => u.Role == "Employer" && !_db.Employers.Any(e => e.UserId == u.UserId))
            .ToListAsync();

        foreach (var u in orphanUsers)
        {
            _db.Employers.Add(new Employer
            {
                UserId = u.UserId,
                CompanyCode = await _codeGen.GenerateCompanyCodeAsync(),
                CompanyName = $"[Chưa đặt tên] {u.FullName}",
                IsVerified = false,
                Status = "Pending",
                CreatedAt = DateTime.Now
            });
        }

        if (orphanUsers.Count > 0) await _db.SaveChangesAsync();

        TempData["Success"] = orphanUsers.Count > 0
            ? $"Đã tạo hồ sơ công ty cho {orphanUsers.Count} tài khoản nhà tuyển dụng bị thiếu công ty. Vui lòng vào từng công ty để cập nhật lại tên/thông tin cho đúng."
            : "Không có tài khoản nhà tuyển dụng nào bị thiếu công ty.";
        return RedirectToAction("Companies");
    }

    public async Task<IActionResult> Companies(string? q, string? status, int page = 1)
    {
        var query = _db.Employers.Include(c => c.User).Include(c => c.JobPosts).AsQueryable();
        if (!string.IsNullOrEmpty(q))
            query = query.Where(c => c.CompanyName.Contains(q) || c.User!.Email.Contains(q) || (c.CompanyCode != null && c.CompanyCode.Contains(q)));
        if (status == "Verified") query = query.Where(c => c.IsVerified);
        else if (status == "Unverified") query = query.Where(c => !c.IsVerified);
        else if (status == "Locked") query = query.Where(c => c.IsLocked);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;

        // Load status options from StatusCatalog for Employer
        ViewBag.EmployerStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.Employer);

        // Số tài khoản Employer bị "mồ côi" (thiếu Employer/công ty) để cảnh báo admin trên UI
        ViewBag.OrphanEmployerCount = await _db.Users
            .Where(u => u.Role == "Employer" && !_db.Employers.Any(e => e.UserId == u.UserId))
            .CountAsync();

        return View(await query.OrderByDescending(c => c.EmployerId).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    // GET: hiển thị modal tạo công ty mới (dùng chung view Companies, chỉ cần action POST)
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateCompany(string contactName, string email, string password, string companyName, string? industry, string? address, string? taxCode)
    {
        if (await _db.Users.AnyAsync(u => u.Email == email))
        {
            TempData["Error"] = "Email này đã được sử dụng cho tài khoản khác.";
            return RedirectToAction("Companies");
        }
        if (string.IsNullOrWhiteSpace(companyName))
        {
            TempData["Error"] = "Vui lòng nhập tên công ty.";
            return RedirectToAction("Companies");
        }

        var user = new User
        {
            FullName = contactName,
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = "Employer",
            Status = "Active",
            CreatedAt = DateTime.Now
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        user.UserCode = _codeGen.GenerateUserCode("Employer", user.UserId);

        _db.Employers.Add(new Employer
        {
            UserId = user.UserId,
            CompanyCode = await _codeGen.GenerateCompanyCodeAsync(),
            CompanyName = companyName.Trim(),
            Industry = industry,
            Address = address,
            TaxCode = taxCode,
            IsVerified = false,
            Status = "Pending",
            CreatedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();

        TempData["Success"] = $"Đã tạo công ty \"{companyName}\" và tài khoản nhà tuyển dụng {email} thành công!";
        return RedirectToAction("Companies");
    }

    public async Task<IActionResult> CompanyDetail(int id)
    {
        var emp = await _db.Employers
            .Include(e => e.User).Include(e => e.JobPosts)
            .FirstOrDefaultAsync(e => e.EmployerId == id);
        if (emp == null) return NotFound();
        return View(emp);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveCompany(int id)
    {
        var c = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerId == id);
        if (c != null)
        {
            c.IsVerified = true;
            c.Status = "Verified";
            if (c.User != null) c.User.Status = "Verified";
            await _db.SaveChangesAsync();
        }
        TempData["Success"] = "Đã xác minh công ty.";
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SuspendCompany(int id)
    {
        var c = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerId == id);
        if (c != null)
        {
            c.IsVerified = false;
            c.Status = "Pending";
            if (c.User != null) c.User.Status = "Pending";
            await _db.SaveChangesAsync();
        }
        TempData["Success"] = "Đã hủy xác minh công ty.";
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> LockCompany(int id, string? returnUrl)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null)
        {
            c.IsLocked = !c.IsLocked;
            await _db.SaveChangesAsync();
            TempData["Success"] = c.IsLocked
                ? $"Đã khoá công ty \"{c.CompanyName}\"."
                : $"Đã mở khoá công ty \"{c.CompanyName}\".";
        }
        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteCompany(int id)
    {
        var c = await _db.Employers.Include(e => e.JobPosts).FirstOrDefaultAsync(e => e.EmployerId == id);
        if (c == null) return NotFound();
        _db.JobPosts.RemoveRange(c.JobPosts);
        _db.Employers.Remove(c);
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã xóa công ty \"{c.CompanyName}\" và toàn bộ tin tuyển dụng liên quan.";
        return RedirectToAction("Companies");
    }

    // ====================== HOT / NỔI BẬT ======================

    public async Task<IActionResult> Hot(string? tab, string? q, int page = 1)
    {
        const int ps = 15;
        tab = string.IsNullOrWhiteSpace(tab) ? "jobs" : tab;

        // ----- Tin tuyển dụng hot: ưu tiên IsFeatured, sau đó ViewCount, chỉ tin đang hoạt động -----
        var jobQuery = _db.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Applications)
            .Where(j => j.Status == "Active")
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
            jobQuery = jobQuery.Where(j => j.Title.Contains(q) || (j.JobCode != null && j.JobCode.Contains(q)));

        var jobTotal = await jobQuery.CountAsync();
        var hotJobs = await jobQuery
            .OrderByDescending(j => j.IsFeatured)
            .ThenByDescending(j => j.ViewCount)
            .ThenByDescending(j => j.CreatedAt)
            .Skip(tab == "jobs" ? (page - 1) * ps : 0)
            .Take(tab == "jobs" ? ps : ps)
            .ToListAsync();

        // ----- Công ty hot: ưu tiên IsFeatured, sau đó số lượng tin đang hoạt động -----
        var companyQuery = _db.Employers
            .Include(c => c.User)
            .Include(c => c.JobPosts)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
            companyQuery = companyQuery.Where(c => c.CompanyName.Contains(q) || (c.CompanyCode != null && c.CompanyCode.Contains(q)));

        var companyTotal = await companyQuery.CountAsync();
        var hotCompanies = (await companyQuery.ToListAsync())
            .OrderByDescending(c => c.IsFeatured)
            .ThenByDescending(c => c.JobPosts.Count(j => j.Status == "Active"))
            .ThenByDescending(c => c.IsVerified)
            .Skip(tab == "companies" ? (page - 1) * ps : 0)
            .Take(ps)
            .ToList();

        ViewBag.Tab = tab;
        ViewBag.Q = q;
        ViewBag.Page = page;
        ViewBag.JobTotalPages = (int)Math.Ceiling(jobTotal / (double)ps);
        ViewBag.CompanyTotalPages = (int)Math.Ceiling(companyTotal / (double)ps);
        ViewBag.HotJobsCount = await _db.JobPosts.CountAsync(j => j.IsFeatured);
        ViewBag.HotCompaniesCount = await _db.Employers.CountAsync(c => c.IsFeatured);
        ViewBag.HotCompanies = hotCompanies;

        return View(hotJobs);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleJobFeatured(int jobId, string? q, int page = 1)
    {
        var job = await _db.JobPosts.FindAsync(jobId);
        if (job == null) return NotFound();

        job.IsFeatured = !job.IsFeatured;
        job.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        TempData["Success"] = job.IsFeatured
            ? $"Đã đánh dấu tin \"{job.Title}\" là Hot."
            : $"Đã bỏ đánh dấu Hot cho tin \"{job.Title}\".";
        return RedirectToAction("Hot", new { tab = "jobs", q, page });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleCompanyFeatured(int employerId, string? q, int page = 1)
    {
        var c = await _db.Employers.FindAsync(employerId);
        if (c == null) return NotFound();

        c.IsFeatured = !c.IsFeatured;
        c.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        TempData["Success"] = c.IsFeatured
            ? $"Đã đánh dấu công ty \"{c.CompanyName}\" là Hot."
            : $"Đã bỏ đánh dấu Hot cho công ty \"{c.CompanyName}\".";
        return RedirectToAction("Hot", new { tab = "companies", q, page });
    }

    // ============== ĐĂNG TIN HỘ NHÀ TUYỂN DỤNG ==============

    public async Task<IActionResult> PostJobForEmployer(int id)
    {
        var employer = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerId == id);
        if (employer == null) return NotFound();
        ViewBag.Employer = employer;
        ViewBag.Categories = await _db.Categories.ToListAsync();
        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PostJobForEmployer(
        int employerId, string title, string? description, string? requirements,
        string? benefits, decimal? salaryMin, decimal? salaryMax,
        bool salaryNegotiable, string jobType, string? location,
        string? experienceLevel, DateTime? deadline, int? categoryId, bool isDraft)
    {
        var employer = await _db.Employers.FindAsync(employerId);
        if (employer == null) return NotFound();
        var job = new JobPost
        {
            EmployerId = employerId,
            JobCode = await _codeGen.GenerateJobCodeAsync(),
            Title = title,
            Description = description,
            Requirements = requirements,
            Benefits = benefits,
            SalaryMin = salaryMin,
            SalaryMax = salaryMax,
            SalaryNegotiable = salaryNegotiable,
            JobType = jobType,
            Location = location,
            ExperienceLevel = experienceLevel,
            Deadline = deadline,
            CategoryID = categoryId,
            Status = isDraft ? "Draft" : "Active",
            CreatedAt = DateTime.Now
        };
        _db.JobPosts.Add(job);
        await _db.SaveChangesAsync();
        _db.Notifications.Add(new Notification
        {
            UserId = employer.UserId,
            Title = "Admin đã đăng tin tuyển dụng hỗ trợ bạn",
            Content = $"Tin \"{title}\" đã được Admin đăng với trạng thái {(isDraft ? "Nháp" : "Đang mở")}.",
            Type = "System",
            RelatedId = job.JobId
        });
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã đăng tin \"{title}\" cho {employer.CompanyName} thành công!";
        return RedirectToAction("CompanyDetail", new { id = employerId });
    }

    // ============== HỖ TRỢ ỨNG VIÊN / CV ==============

    public async Task<IActionResult> EmployerApplications(int id, string? status)
    {
        var employer = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerId == id);
        if (employer == null) return NotFound();
        var query = _db.Applications
            .Include(a => a.CandidateProfile).ThenInclude(c => c!.User)
            .Include(a => a.Job)
            .Include(a => a.Cv)
            .Where(a => a.Job!.EmployerId == id)
            .AsQueryable();
        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);
        ViewBag.Employer = employer;
        ViewBag.FilterStatus = status;
        return View(await query.OrderByDescending(a => a.AppliedAt).ToListAsync());
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> FixCvApplication(int applicationId, string action, int employerId)
    {
        var app = await _db.Applications
            .Include(a => a.CandidateProfile).ThenInclude(c => c!.User)
            .Include(a => a.Job)
            .FirstOrDefaultAsync(a => a.AppID == applicationId);
        if (app == null)
        {
            TempData["Error"] = "Không tìm thấy đơn ứng tuyển.";
            return RedirectToAction("EmployerApplications", new { id = employerId });
        }
        string msg;
        switch (action)
        {
            case "reset":
                app.Status = "Pending";
                app.Cvid = null;
                app.UpdatedAt = DateTime.Now;
                msg = $"Đã reset CV đơn của {app.CandidateProfile?.User?.FullName}. Ứng viên có thể nộp lại.";
                if (app.CandidateProfile != null)
                {
                    _db.Notifications.Add(new Notification
                    {
                        UserId = app.CandidateProfile!.UserId,
                        Title = "Admin đã hỗ trợ reset CV của bạn",
                        Content = $"CV ở đơn ứng tuyển vị trí \"{app.Job?.Title}\" đã được Admin reset. Vui lòng nộp lại CV mới.",
                        Type = "System",
                        RelatedId = app.AppID
                    });
                }
                break;
            case "delete":
                _db.Applications.Remove(app);
                msg = $"Đã xóa đơn ứng tuyển của {app.CandidateProfile?.User?.FullName}.";
                break;
            case "approve":
                app.Status = "Accepted";
                app.UpdatedAt = DateTime.Now;
                msg = $"Đã duyệt đơn ứng tuyển của {app.CandidateProfile?.User?.FullName}.";
                if (app.CandidateProfile != null)
                {
                    _db.Notifications.Add(new Notification
                    {
                        UserId = app.CandidateProfile!.UserId,
                        Title = "Đơn ứng tuyển được chấp nhận",
                        Content = $"Admin đã duyệt đơn ứng tuyển vị trí \"{app.Job?.Title}\" của bạn.",
                        Type = "System",
                        RelatedId = app.AppID
                    });
                }
                break;
            default:
                TempData["Error"] = "Hành động không hợp lệ.";
                return RedirectToAction("EmployerApplications", new { id = employerId });
        }
        await _db.SaveChangesAsync();
        TempData["Success"] = msg;
        return RedirectToAction("EmployerApplications", new { id = employerId });
    }

    // ====================== BLOG ======================

    public async Task<IActionResult> Blog(string? q, string? status, int page = 1)
    {
        var query = _db.BlogPosts.Include(p => p.Author).AsQueryable();
        if (!string.IsNullOrEmpty(q)) query = query.Where(p => p.Title.Contains(q) || (p.BlogCode != null && p.BlogCode.Contains(q)));
        if (status == "Published") query = query.Where(p => p.IsPublished);
        else if (status == "Draft") query = query.Where(p => !p.IsPublished);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;

        // Load status options from StatusCatalog for BlogPost
        ViewBag.BlogPostStatuses = await _statusSvc.GetActiveByEntityTypeAsync(StatusEntityTypes.BlogPost);

        return View(await query.OrderByDescending(p => p.PostId).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    public IActionResult BlogCreate() => View();

    public async Task<IActionResult> BlogEdit(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post == null) return NotFound();
        return View(post);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogEdit(int PostID, string Title, string? Slug, string? Excerpt, string? CoverURL, string Content, string Status)
    {
        var post = await _db.BlogPosts.FindAsync(PostID);
        if (post == null) return NotFound();
        post.Title = Title;
        post.Slug = string.IsNullOrEmpty(Slug) ? SlugHelper.ToSlug(Title) : SlugHelper.ToSlug(Slug);
        post.Excerpt = Excerpt;
        post.Content = Content;
        post.IsPublished = Status == "Published";
        post.PublishedAt = post.IsPublished ? (post.PublishedAt ?? DateTime.Now) : null;
        if (!string.IsNullOrEmpty(CoverURL) && CoverURL.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            try { post.CoverURL = await _jobSvc.SaveImageFromDataUriAsync(CoverURL, "uploads/blog/cover"); }
            catch { }
        }
        else post.CoverURL = CoverURL;
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã cập nhật bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogCreate(string Title, string? Slug, string? Excerpt, string? CoverURL, string Content, string Status)
    {
        int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int uid);
        var slug = string.IsNullOrEmpty(Slug) ? SlugHelper.ToSlug(Title) : SlugHelper.ToSlug(Slug);
        string? coverPath = CoverURL;
        if (!string.IsNullOrEmpty(CoverURL) && CoverURL.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            try { coverPath = await _jobSvc.SaveImageFromDataUriAsync(CoverURL, "uploads/blog/cover"); }
            catch { coverPath = null; }
        }
        _db.BlogPosts.Add(new BlogPost
        {
            BlogCode = await _codeGen.GenerateBlogCodeAsync(),
            Title = Title,
            Slug = slug,
            Excerpt = Excerpt,
            CoverURL = coverPath,
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

    // ====================== REPORTS ======================

    public async Task<IActionResult> Reports()
    {
        ViewBag.TotalUsers = await _db.Users.CountAsync();
        ViewBag.TotalJobs = await _db.JobPosts.CountAsync();
        ViewBag.TotalApps = await _db.Applications.CountAsync();
        // TotalCompanies = số công ty ĐÃ XÁC MINH (đúng với label "Công ty đã duyệt" trên giao diện).
        // Thêm TotalCompaniesAll = tổng toàn bộ công ty để tránh nhầm lẫn khi đối chiếu số liệu.
        ViewBag.TotalCompanies = await _db.Employers.CountAsync(c => c.IsVerified);
        ViewBag.TotalCompaniesAll = await _db.Employers.CountAsync();
        var sixMonths = DateTime.Now.AddMonths(-5);
        ViewBag.MonthlyApps = await _db.Applications
            .Where(a => a.AppliedAt >= sixMonths)
            .GroupBy(a => new { a.AppliedAt.Year, a.AppliedAt.Month })
            .Select(g => new { Month = g.Key.Month + "/" + g.Key.Year, Count = g.Count() })
            .OrderBy(g => g.Month)
            .Select(g => ValueTuple.Create(g.Month, g.Count))
            .ToListAsync();
        ViewBag.TopCategories = await _db.JobPosts
            .Where(j => j.Category != null)
            .GroupBy(j => j.Category!.Name)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();
        ViewBag.TopCompanies = await _db.JobPosts
            .GroupBy(j => j.Employer.CompanyName)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();
        ViewBag.AppStatus = await _db.Applications
            .GroupBy(a => a.Status)
            .Select(g => ValueTuple.Create(g.Key, g.Count()))
            .ToListAsync();
        ViewBag.RecentUsers = await _db.Users
            .OrderByDescending(u => u.CreatedAt).Take(10).ToListAsync();
        return View();
    }

    // ====================== SKILLS ======================

    // GET /Admin/Skills
    public async Task<IActionResult> Skills(string? category, string? keyword, int page = 1)
    {
        var skills = await _skillSvc.GetAllAsync();

        // Filter by category
        if (!string.IsNullOrEmpty(category) && Enum.TryParse<SkillCategory>(category, out var cat))
        {
            skills = skills.Where(s => s.CategoryId == (int)cat).ToList();
        }

        // Filter by keyword
        if (!string.IsNullOrEmpty(keyword))
        {
            skills = skills.Where(s => s.Name.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                                      (s.Description != null && s.Description.Contains(keyword, StringComparison.OrdinalIgnoreCase)))
                          .ToList();
        }

        // Pagination
        const int pageSize = 10;
        var pagedSkills = skills.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        var totalPages = (int)Math.Ceiling(skills.Count / (double)pageSize);

        ViewBag.Skills = pagedSkills;
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.CategoryFilter = category;
        ViewBag.KeywordFilter = keyword;
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();

        return View();
    }

    // GET /Admin/Skill/Create
    public IActionResult SkillCreate()
    {
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View();
    }

    // POST /Admin/Skill/Create
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillCreate(Skill model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
            return View(model);
        }

        var result = await _skillSvc.CreateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã tạo kỹ năng mới thành công!";
            return RedirectToAction("Skills");
        }

        TempData["Error"] = "Tên kỹ năng đã tồn tại!";
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(model);
    }

    // GET /Admin/Skill/Edit/5
    public async Task<IActionResult> SkillEdit(int id)
    {
        var skill = await _skillSvc.GetByIdAsync(id);
        if (skill == null)
            return NotFound();

        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(skill);
    }

    // POST /Admin/Skill/Edit
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillEdit(Skill model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
            return View(model);
        }

        var result = await _skillSvc.UpdateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã cập nhật kỹ năng thành công!";
            return RedirectToAction("Skills");
        }

        TempData["Error"] = "Tên kỹ năng đã tồn tại hoặc có lỗi xảy ra!";
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(model);
    }

    // POST /Admin/Skill/Delete/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillDelete(int id)
    {
        var result = await _skillSvc.DeleteAsync(id);
        if (result)
        {
            TempData["Success"] = "Đã xóa kỹ năng thành công!";
        }
        else
        {
            TempData["Error"] = "Không thể xóa kỹ năng này (đang được sử dụng bởi ứng viên)!";
        }
        return RedirectToAction("Skills");
    }

    // POST /Admin/Skill/Toggle/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillToggle(int id)
    {
        var result = await _skillSvc.ToggleActiveAsync(id);
        if (result)
        {
            TempData["Success"] = "Đã thay đổi trạng thái kỹ năng!";
        }
        else
        {
            TempData["Error"] = "Có lỗi xảy ra!";
        }
        return RedirectToAction("Skills");
    }

    // ====================== STATUS CATALOG (Trạng thái do Admin quản lý) ======================
    // Áp dụng cho: Candidate, Employer, Staff, Company, JobPost

    // GET /Admin/Statuses
    public async Task<IActionResult> Statuses(string? entityType, string? keyword)
    {
        var statuses = await _statusSvc.GetAllAsync(entityType, keyword);

        ViewBag.Statuses = statuses;
        ViewBag.EntityTypeFilter = entityType;
        ViewBag.KeywordFilter = keyword;
        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;

        return View();
    }

    // GET /Admin/StatusCreate
    public IActionResult StatusCreate()
    {
        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
        return View();
    }

    // POST /Admin/StatusCreate
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> StatusCreate(StatusCatalog model)
    {
        ModelState.Remove(nameof(StatusCatalog.CreatedAt));

        if (!ModelState.IsValid)
        {
            ViewBag.EntityTypes = StatusEntityTypes.All;
            ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
            return View(model);
        }

        var result = await _statusSvc.CreateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã thêm trạng thái mới thành công!";
            return RedirectToAction("Statuses");
        }

        TempData["Error"] = "Mã trạng thái (Code) đã tồn tại cho đối tượng này!";
        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
        return View(model);
    }

    // GET /Admin/StatusEdit/5
    public async Task<IActionResult> StatusEdit(int id)
    {
        var status = await _statusSvc.GetByIdAsync(id);
        if (status == null)
            return NotFound();

        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
        return View(status);
    }

    // POST /Admin/StatusEdit
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> StatusEdit(StatusCatalog model)
    {
        ModelState.Remove(nameof(StatusCatalog.CreatedAt));

        if (!ModelState.IsValid)
        {
            ViewBag.EntityTypes = StatusEntityTypes.All;
            ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
            return View(model);
        }

        var result = await _statusSvc.UpdateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã cập nhật trạng thái thành công!";
            return RedirectToAction("Statuses");
        }

        TempData["Error"] = "Mã trạng thái (Code) đã tồn tại hoặc có lỗi xảy ra!";
        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.EntityTypeLabels = StatusEntityTypes.Labels;
        return View(model);
    }

    // POST /Admin/StatusDelete/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> StatusDelete(int id)
    {
        var (success, error, recordCount) = await _statusSvc.DeleteAsync(id);
        if (success)
        {
            TempData["Success"] = "Đã xóa trạng thái thành công!";
        }
        else
        {
            TempData["Error"] = error ?? "Không thể xóa trạng thái mặc định của hệ thống!";
        }
        return RedirectToAction("Statuses");
    }

    // POST /Admin/StatusToggle/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> StatusToggle(int id)
    {
        var result = await _statusSvc.ToggleActiveAsync(id);
        if (result)
        {
            TempData["Success"] = "Đã thay đổi trạng thái hiển thị!";
        }
        else
        {
            TempData["Error"] = "Có lỗi xảy ra!";
        }
        return RedirectToAction("Statuses");
    }

    // ====================== CATEGORIES (Industry) ======================

    // GET /Admin/Categories
    public async Task<IActionResult> Categories(string? keyword, string? type, int page = 1)
    {
        int pageSize = 10;
        var query = _db.Categories.AsQueryable();

        // Filter by type (default to Industry)
        if (string.IsNullOrEmpty(type))
        {
            type = "Industry";
        }
        query = query.Where(c => c.Type == type);

        // Search by keyword
        if (!string.IsNullOrEmpty(keyword))
        {
            query = query.Where(c => c.Name.Contains(keyword) || c.Slug.Contains(keyword));
        }

        var totalItems = await query.CountAsync();
        var categories = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.Categories = categories;
        ViewBag.KeywordFilter = keyword;
        ViewBag.TypeFilter = type;
        ViewBag.Page = page;
        ViewBag.PageSize = pageSize;
        ViewBag.TotalItems = totalItems;
        ViewBag.TotalPages = (int)Math.Ceiling((double)totalItems / pageSize);

        return View();
    }

    // GET /Admin/Category/Create
    public IActionResult CategoryCreate()
    {
        ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
        return View();
    }

    // POST /Admin/Category/Create
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryCreate(Category model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        // Check if slug exists
        if (await _db.Categories.AnyAsync(c => c.Slug == model.Slug))
        {
            TempData["Error"] = "Slug đã tồn tại!";
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        model.CreatedAt = DateTime.Now;
        // model.UpdatedAt không gán khi tạo mới

        _db.Categories.Add(model);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã tạo danh mục thành công!";
        return RedirectToAction("Categories", new { type = model.Type });
    }

    // GET /Admin/Category/Edit/5
    public async Task<IActionResult> CategoryEdit(int id)
    {
        var category = await _db.Categories.FindAsync(id);
        if (category == null) return NotFound();

        ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
        return View(category);
    }

    // POST /Admin/Category/Edit
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryEdit(Category model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        var category = await _db.Categories.FindAsync(model.CategoryID);
        if (category == null) return NotFound();

        // Check if slug exists (excluding current)
        if (await _db.Categories.AnyAsync(c => c.Slug == model.Slug && c.CategoryID != model.CategoryID))
        {
            TempData["Error"] = "Slug đã tồn tại!";
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        category.Name = model.Name;
        category.Type = model.Type;
        category.Slug = model.Slug;
        category.UpdatedAt = DateTime.Now;

        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật danh mục thành công!";
        return RedirectToAction("Categories", new { type = category.Type });
    }

    // POST /Admin/Category/Delete/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryDelete(int id)
    {
        var category = await _db.Categories.FindAsync(id);
        if (category == null) return NotFound();

        _db.Categories.Remove(category);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã xóa danh mục thành công!";
        return RedirectToAction("Categories", new { type = category.Type });
    }

    // ====================== ENTITY STATUS MANAGEMENT ======================
    // Lưu ý: các action dưới đây validate token thủ công trong try/catch (không dùng
    // [ValidateAntiForgeryToken] trực tiếp) để đảm bảo luôn trả JSON, không rơi ra
    // trang lỗi HTML khiến JS phía client (response.json()) bị crash.

    // POST /Admin/ChangeUserStatus
    [HttpPost]
    public async Task<IActionResult> ChangeUserStatus(int userId, string newStatus)
    {
        try
        {
            try { await _antiforgery.ValidateRequestAsync(HttpContext); }
            catch (AntiforgeryValidationException) { return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang." }); }

            var user = await _db.Users.FindAsync(userId);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy người dùng" });

            // Validate status exists in StatusCatalog
            var entityType = user.Role == "Candidate" ? StatusEntityTypes.Candidate :
                            user.Role == "Employer" ? StatusEntityTypes.Employer :
                            user.Role == "Staff" ? StatusEntityTypes.Staff : "User";

            var statusExists = await _db.StatusCatalogs
                .AnyAsync(s => s.EntityType == entityType && s.Code == newStatus && s.IsActive);

            if (!statusExists)
            {
                return Json(new { success = false, message = "Trạng thái không hợp lệ!" });
            }

            user.Status = newStatus;
            user.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();

            return Json(new { success = true, message = $"Đã cập nhật trạng thái người dùng thành: {newStatus}" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // POST /Admin/ChangeEmployerStatus
    [HttpPost]
    public async Task<IActionResult> ChangeEmployerStatus(int employerId, string newStatus)
    {
        try
        {
            try { await _antiforgery.ValidateRequestAsync(HttpContext); }
            catch (AntiforgeryValidationException) { return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang." }); }

            var employer = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerId == employerId);
            if (employer == null) return Json(new { success = false, message = "Không tìm thấy nhà tuyển dụng" });

            // Validate status exists in StatusCatalog
            var statusExists = await _db.StatusCatalogs
                .AnyAsync(s => s.EntityType == StatusEntityTypes.Employer && s.Code == newStatus && s.IsActive);

            if (!statusExists)
            {
                return Json(new { success = false, message = "Trạng thái không hợp lệ!" });
            }

            // Update both Employer and associated User status
            employer.Status = newStatus;
            if (employer.User != null)
            {
                employer.User.Status = newStatus;
                employer.User.UpdatedAt = DateTime.Now;
            }

            // Đồng bộ 2 cờ boolean legacy (IsVerified/IsLocked) theo Status mới,
            // tránh lệch dữ liệu khiến bộ lọc "Đã xác minh/Chưa xác minh/Đã khoá" sai.
            employer.IsVerified = newStatus is "Verified" or "Active";
            employer.IsLocked = newStatus == "Banned";

            employer.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();

            return Json(new { success = true, message = $"Đã cập nhật trạng thái nhà tuyển dụng thành: {newStatus}" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // POST /Admin/ChangeJobPostStatus
    [HttpPost]
    public async Task<IActionResult> ChangeJobPostStatus(int jobId, string newStatus)
    {
        try
        {
            try { await _antiforgery.ValidateRequestAsync(HttpContext); }
            catch (AntiforgeryValidationException) { return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang." }); }

            var job = await _db.JobPosts.FindAsync(jobId);
            if (job == null) return Json(new { success = false, message = "Không tìm thấy tin tuyển dụng" });

            // Validate status exists in StatusCatalog
            var statusExists = await _db.StatusCatalogs
                .AnyAsync(s => s.EntityType == StatusEntityTypes.JobPost && s.Code == newStatus && s.IsActive);

            if (!statusExists)
            {
                return Json(new { success = false, message = "Trạng thái không hợp lệ!" });
            }

            job.Status = newStatus;
            job.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();

            return Json(new { success = true, message = $"Đã cập nhật trạng thái tin tuyển dụng thành: {newStatus}" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // POST /Admin/ChangeBlogPostStatus
    [HttpPost]
    public async Task<IActionResult> ChangeBlogPostStatus(int postId, string newStatus)
    {
        try
        {
            try { await _antiforgery.ValidateRequestAsync(HttpContext); }
            catch (AntiforgeryValidationException) { return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang." }); }

            var blog = await _db.BlogPosts.FindAsync(postId);
            if (blog == null) return Json(new { success = false, message = "Không tìm thấy bài viết" });

            // Validate status exists in StatusCatalog
            var statusExists = await _db.StatusCatalogs
                .AnyAsync(s => s.EntityType == StatusEntityTypes.BlogPost && s.Code == newStatus && s.IsActive);

            if (!statusExists)
            {
                return Json(new { success = false, message = "Trạng thái không hợp lệ!" });
            }

            blog.Status = newStatus;
            blog.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();

            return Json(new { success = true, message = $"Đã cập nhật trạng thái bài viết thành: {newStatus}" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // POST /Admin/ChangeJobStatus
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangeJobStatus(int jobId, string newStatus)
    {
        var job = await _db.JobPosts.FindAsync(jobId);
        if (job == null) return NotFound();

        // Validate status exists in StatusCatalog
        var statusExists = await _db.StatusCatalogs
            .AnyAsync(s => s.EntityType == StatusEntityTypes.JobPost && s.Code == newStatus && s.IsActive);

        if (!statusExists)
        {
            TempData["Error"] = "Trạng thái không hợp lệ!";
            return RedirectToAction("Jobs");
        }

        job.Status = newStatus;
        job.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        TempData["Success"] = $"Đã cập nhật trạng thái tin tuyển dụng thành: {newStatus}";
        return RedirectToAction("Jobs");
    }

    // POST /Admin/ChangeBlogStatus
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangeBlogStatus(int postId, string newStatus)
    {
        var blog = await _db.BlogPosts.FindAsync(postId);
        if (blog == null) return NotFound();

        // Validate status exists in StatusCatalog
        var statusExists = await _db.StatusCatalogs
            .AnyAsync(s => s.EntityType == StatusEntityTypes.BlogPost && s.Code == newStatus && s.IsActive);

        if (!statusExists)
        {
            TempData["Error"] = "Trạng thái không hợp lệ!";
            return RedirectToAction("Blog");
        }

        blog.Status = newStatus;
        blog.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        TempData["Success"] = $"Đã cập nhật trạng thái bài viết thành: {newStatus}";
        return RedirectToAction("Blog");
    }
}