using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Employer")]
public class EmployerController : Controller
{
    private readonly AppDbContext _db;
    private readonly IJobService _jobSvc;
    private readonly IWebHostEnvironment _env;

    public EmployerController(AppDbContext db, IJobService jobSvc, IWebHostEnvironment env)
    {
        _db = db;
        _jobSvc = jobSvc;
        _env = env;
    }

    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    private async Task<Employer?> GetEmployerAsync()
        => await _db.Employers.FirstOrDefaultAsync(e => e.UserId == UserId);

    // GET /Employer/CandidateSkills/{profileId}
    public async Task<IActionResult> CandidateSkills(int profileId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CandidateSkills)
                .ThenInclude(cs => cs.Skill)
            .FirstOrDefaultAsync(p => p.ProfileId == profileId);

        if (profile == null) return NotFound();

        ViewBag.Employer = emp;
        return View(profile);
    }

    // GET /Employer/Dashboard
    public async Task<IActionResult> Dashboard()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var jobs = await _jobSvc.GetByEmployerAsync(emp.EmployerId);
        var now = DateTime.Now;
        var today = now.Date;
        var soonThreshold = now.AddDays(7);

        var allApplications = jobs.SelectMany(j => j.Applications).ToList();

        ViewBag.Employer = emp;
        ViewBag.JobCount = jobs.Count;

        // 1. Tổng số tin đang tuyển (Status = Active, chưa hết hạn)
        ViewBag.OpenCount = jobs.Count(j => j.Status == "Active" && (!j.Deadline.HasValue || j.Deadline.Value >= now));

        // 2. Tổng CV nhận được (đơn ứng tuyển có đính kèm CV)
        ViewBag.AppCount = allApplications.Count;
        ViewBag.TotalCvReceived = allApplications.Count(a => a.Cvid != null);

        // 3. CV hôm nay
        ViewBag.CvToday = allApplications.Count(a => a.AppliedAt.Date == today);

        // 4. Lượt xem tin (tổng ViewCount toàn bộ tin của NTD)
        ViewBag.TotalViews = jobs.Sum(j => j.ViewCount);

        // 5. Lượt Apply (tổng số lượt ứng tuyển ghi nhận được, kể cả tin đã đóng)
        ViewBag.TotalApplies = allApplications.Count;

        // 6. Tỷ lệ Apply/View
        int totalViews = jobs.Sum(j => j.ViewCount);
        ViewBag.ApplyViewRate = totalViews > 0
            ? Math.Round((double)allApplications.Count / totalViews * 100, 1)
            : 0;

        // 7. Tin hết hạn / 8. Tin sắp hết hạn (trong vòng 7 ngày tới)
        ViewBag.ExpiredCount = jobs.Count(j => j.Deadline.HasValue && j.Deadline.Value < now);
        ViewBag.ExpiringSoonCount = jobs.Count(j => j.Deadline.HasValue && j.Deadline.Value >= now && j.Deadline.Value <= soonThreshold);

        var expiringSoonJobs = jobs
            .Where(j => j.Deadline.HasValue && j.Deadline.Value >= now && j.Deadline.Value <= soonThreshold)
            .OrderBy(j => j.Deadline)
            .ToList();
        ViewBag.ExpiringSoonJobs = expiringSoonJobs;

        var expiringTransactions = await _db.Transactions
            .Include(t => t.Package)
            .Where(t => t.EmployerId == emp.EmployerId
                        && t.Status == "Completed"
                        && t.ExpiredAt.HasValue
                        && t.ExpiredAt.Value >= now
                        && t.ExpiredAt.Value <= soonThreshold)
            .OrderBy(t => t.ExpiredAt)
            .ToListAsync();
        ViewBag.ExpiringTransactions = expiringTransactions;

        await CreateExpiryReminderNotificationsAsync(emp, expiringSoonJobs, expiringTransactions);

        return View(jobs);
    }

    private async Task CreateExpiryReminderNotificationsAsync(Employer emp, List<JobPost> expiringSoonJobs, List<Transaction> expiringTransactions)
    {
        var today = DateTime.Now.Date;
        var newNotifications = new List<Notification>();

        foreach (var job in expiringSoonJobs)
        {
            bool already = await _db.Notifications.AnyAsync(n =>
                n.UserId == emp.UserId && n.Type == "JobExpiring" &&
                n.RelatedId == job.JobId && n.CreatedAt.Date == today);

            if (!already)
            {
                newNotifications.Add(new Notification
                {
                    UserId = emp.UserId,
                    Title = "Tin \"" + job.Title + "\" sap het han",
                    Content = "Tin tuyen dung \"" + job.Title + "\" se het han vao " + job.Deadline?.ToString("dd/MM/yyyy") + ". Vui long gia han neu ban van con nhu cau tuyen dung.",
                    Type = "JobExpiring",
                    RelatedId = job.JobId,
                    CreatedAt = DateTime.Now
                });
            }
        }

        foreach (var trans in expiringTransactions)
        {
            bool already = await _db.Notifications.AnyAsync(n =>
                n.UserId == emp.UserId && n.Type == "PackageExpiring" &&
                n.RelatedId == trans.TransId && n.CreatedAt.Date == today);

            if (!already)
            {
                newNotifications.Add(new Notification
                {
                    UserId = emp.UserId,
                    Title = "Goi dich vu \"" + trans.Package?.Name + "\" sap het han",
                    Content = "Goi dich vu \"" + trans.Package?.Name + "\" cua ban se het han vao " + trans.ExpiredAt?.ToString("dd/MM/yyyy") + ". Vui long gia han de tiep tuc su dung day du tinh nang dang tin.",
                    Type = "PackageExpiring",
                    RelatedId = trans.TransId,
                    CreatedAt = DateTime.Now
                });
            }
        }

        if (newNotifications.Count > 0)
        {
            _db.Notifications.AddRange(newNotifications);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<IActionResult> JobStats()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var jobs = await _jobSvc.GetByEmployerAsync(emp.EmployerId);

        var stats = jobs
            .Select(j => new JobStatRow
            {
                JobId = j.JobId,
                Title = j.Title ?? string.Empty,
                Status = j.Status,
                Deadline = j.Deadline,
                ViewCount = j.ViewCount,
                ApplyCount = j.Applications.Count,
                ConversionRate = j.ViewCount > 0
                    ? Math.Round((double)j.Applications.Count / j.ViewCount * 100, 1)
                    : 0
            })
            .OrderByDescending(s => s.ConversionRate)
            .ToList();

        ViewBag.Employer = emp;
        return View(stats);
    }

    public async Task<IActionResult> ExportApplicationsCsv(int jobId, string? status = null)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var job = await _db.JobPosts.FirstOrDefaultAsync(j => j.JobId == jobId && j.EmployerId == emp.EmployerId);
        if (job == null) return NotFound();

        var query = _db.Applications
            .Include(a => a.CandidateProfile!).ThenInclude(p => p!.User)
            .Where(a => a.JobId == jobId);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);

        var apps = await query.OrderByDescending(a => a.AppliedAt).ToListAsync();

        var sb = new System.Text.StringBuilder();
        string Esc(string? s) => "\"" + (s ?? "").Replace("\"", "\"\"") + "\"";

        sb.AppendLine(string.Join(",", "Ho ten", "Email", "So dien thoai", "So nam kinh nghiem",
            "Muc luong mong muon", "Ngay nop", "Trang thai", "Thu gioi thieu"));

        foreach (var a in apps)
        {
            var u = a.CandidateProfile?.User;
            sb.AppendLine(string.Join(",",
                Esc(u?.FullName),
                Esc(u?.Email),
                Esc(a.CandidateProfile?.Phone),
                Esc(a.CandidateProfile?.ExperienceYears.ToString()),
                Esc(a.CandidateProfile?.DesiredSalary?.ToString("N0")),
                Esc(a.AppliedAt.ToString("dd/MM/yyyy HH:mm")),
                Esc(a.Status),
                Esc(a.CoverLetter)));
        }

        var bytes = new byte[] { 0xEF, 0xBB, 0xBF }
            .Concat(System.Text.Encoding.UTF8.GetBytes(sb.ToString()))
            .ToArray();

        var fileName = "UngVien_" + (job.Title ?? "job").Replace(" ", "_") + "_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
        return File(bytes, "text/csv; charset=utf-8", fileName);
    }

    public async Task<IActionResult> PrintApplications(int jobId, string? status = null)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var job = await _db.JobPosts
            .Include(j => j.Employer)
            .FirstOrDefaultAsync(j => j.JobId == jobId && j.EmployerId == emp.EmployerId);
        if (job == null) return NotFound();

        var query = _db.Applications
            .Include(a => a.CandidateProfile!).ThenInclude(p => p!.User)
            .Where(a => a.JobId == jobId);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);

        var apps = await query.OrderByDescending(a => a.AppliedAt).ToListAsync();

        ViewBag.Job = job;
        ViewBag.Employer = emp;
        return View(apps);
    }

    // GET /Employer/PostJob
    public async Task<IActionResult> PostJob()
    {
        ViewBag.Categories = await _db.Categories
            .Where(c => c.Type == "Industry")
            .ToListAsync();

        var emp = await GetEmployerAsync();
        ViewBag.CompanySize = emp?.CompanySize;

        return View(new JobPost());
    }

    // POST /Employer/PostJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PostJob(JobPost model)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return NotFound();

        // Loại các field không do người dùng nhập khỏi việc validate
        ModelState.Remove(nameof(JobPost.EmployerId));
        ModelState.Remove(nameof(JobPost.Status));
        // QUAN TRỌNG: Employer là navigation property non-nullable (Employer = null!).
        // Form không gửi field này lên nên MVC tự coi là "required" và luôn báo lỗi,
        // khiến ModelState.IsValid = false -> đây là lý do nút "Gửi tin để duyệt" không hoạt động.
        ModelState.Remove(nameof(JobPost.Employer));
        ModelState.Remove(nameof(JobPost.Category));
        ModelState.Remove(nameof(JobPost.Applications));
        ModelState.Remove(nameof(JobPost.Messages));
        ModelState.Remove(nameof(JobPost.Reports));
        ModelState.Remove(nameof(JobPost.SavedJobs));

        if (string.IsNullOrWhiteSpace(model.Title))
        {
            ModelState.AddModelError(nameof(JobPost.Title), "Vui lòng nhập tiêu đề công việc.");
        }

        if (!ModelState.IsValid)
        {
            ViewBag.Categories = await _db.Categories
                .Where(c => c.Type == "Industry")
                .ToListAsync();
            return View(model);
        }

        model.EmployerId = emp.EmployerId;
        model.Status = "Pending";
        await _jobSvc.CreateAsync(model);

        TempData["Success"] = "Tin tuyển dụng đã được gửi duyệt!";
        return RedirectToAction("Dashboard");
    }

    // GET /Employer/ManageApplications?jobId=5&status=Pending
    public async Task<IActionResult> ManageApplications(int jobId = 0, string? status = null)
    {
        if (jobId == 0) return RedirectToAction("Dashboard");

        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var job = await _db.JobPosts
            .Include(j => j.Employer)
            .FirstOrDefaultAsync(j => j.JobId == jobId && j.EmployerId == emp.EmployerId);

        if (job == null) return NotFound();

        var query = _db.Applications
            .Include(a => a.CandidateProfile!).ThenInclude(p => p!.User)
            .Include(a => a.Cv)
            .Where(a => a.JobId == jobId);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);

        var apps = await query
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        ViewBag.Job = job;
        return View(apps);
    }

    // ====================== DOWNLOAD CV ======================
    // GET /Employer/DownloadCv?cvId=123
    public async Task<IActionResult> DownloadCv(int cvId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return Forbid();

        // Lấy CV + kiểm tra quyền qua Application và Job
        var cv = await _db.CvFiles
            .Include(c => c.Applications)           // Nếu có navigation ICollection<Application>
            .FirstOrDefaultAsync(c => c.Cvid == cvId);

        if (cv == null) return NotFound("Không tìm thấy CV.");

        // Kiểm tra xem CV này có thuộc đơn ứng tuyển của Job do Employer này đăng không
        var hasPermission = await _db.Applications
            .AnyAsync(a => a.Cvid == cvId
                        && a.Job != null
                        && a.Job.EmployerId == emp.EmployerId);

        if (!hasPermission)
            return Forbid("Bạn không có quyền tải CV này.");

        var relPath = cv.FilePath?.TrimStart('/') ?? string.Empty;
        var fullPath = Path.Combine(_env.WebRootPath,
            relPath.Replace('/', Path.DirectorySeparatorChar));

        if (!System.IO.File.Exists(fullPath))
            return NotFound("File CV không tồn tại trên server.");

        var contentType = GetContentType(Path.GetExtension(fullPath));
        var fileName = string.IsNullOrEmpty(cv.FileName)
            ? Path.GetFileName(fullPath)
            : cv.FileName;

        return PhysicalFile(fullPath, contentType, fileName);
    }

    private string GetContentType(string extension)
    {
        return extension.ToLower() switch
        {
            ".pdf" => "application/pdf",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".doc" => "application/msword",
            _ => "application/octet-stream"
        };
    }

    // POST /Employer/UpdateApplicationStatus
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateApplicationStatus(int appId, string status, int jobId)
    {
        var app = await _db.Applications
            .Include(a => a.CandidateProfile)
            .Include(a => a.Job)
            .FirstOrDefaultAsync(a => a.AppID == appId);

        if (app == null) return NotFound();

        app.Status = status;
        app.UpdatedAt = DateTime.Now;

        _db.Notifications.Add(new Notification
        {
            UserId = app.CandidateProfile?.UserId ?? 0,
            Title = $"Đơn ứng tuyển \"{app.Job?.Title}\" đã được cập nhật: {status}",
            Type = "Application",
            RelatedId = app.JobId,
            CreatedAt = DateTime.Now
        });

        await _db.SaveChangesAsync();

        TempData["Success"] = "Cập nhật trạng thái thành công!";
        return RedirectToAction("ManageApplications", new { jobId });
    }

    // GET /Employer/EditJob/5
    [HttpGet]
    public async Task<IActionResult> EditJob(int id)
    {
        var job = await _db.JobPosts.FindAsync(id);
        if (job == null) return NotFound();

        var vm = new PostJobViewModel
        {
            JobId = job.JobId,
            Title = job.Title,
            Description = job.Description,
            Requirements = job.Requirements,
            Benefits = job.Benefits,
            Location = job.Location,
            SalaryMin = job.SalaryMin,
            SalaryMax = job.SalaryMax,
            JobType = job.JobType,
            ExperienceLevel = job.ExperienceLevel,
            Deadline = job.Deadline,
            Status = job.Status,
            CategoryID = job.CategoryID
        };

        ViewBag.Categories = new SelectList(await _db.Categories
            .Where(c => c.Type == "Industry").ToListAsync(),
            "CategoryID", "Name", vm.CategoryID);

        var emp = await GetEmployerAsync();
        ViewBag.CompanySize = emp?.CompanySize;

        return View(vm);
    }

    // POST /Employer/EditJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> EditJob(PostJobViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = new SelectList(await _db.Categories
                .Where(c => c.Type == "Industry").ToListAsync(),
                "CategoryID", "Name", model.CategoryID);
            return View(model);
        }

        var job = await _db.JobPosts.FindAsync(model.JobId);
        if (job == null) return NotFound();

        job.Title = model.Title;
        job.Description = model.Description;
        job.Requirements = model.Requirements;
        job.Benefits = model.Benefits;
        job.Location = model.Location;
        job.SalaryMin = model.SalaryMin;
        job.SalaryMax = model.SalaryMax;
        job.JobType = model.JobType;
        job.ExperienceLevel = model.ExperienceLevel;
        job.Deadline = model.Deadline;
        job.Status = model.Status;
        job.CategoryID = model.CategoryID;
        job.UpdatedAt = DateTime.Now;

        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật tin tuyển dụng.";
        return RedirectToAction("Dashboard");
    }

    // GET /Employer/CompanyProfile
    public async Task<IActionResult> CompanyProfile()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");
        return View(emp);
    }

    // POST /Employer/CompanyProfile
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CompanyProfile(Employer model, List<CompanyHighlight>? highlights)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return NotFound();

        emp.CompanyName = model.CompanyName;
        emp.TaxCode = model.TaxCode;
        emp.Industry = model.Industry;
        emp.CompanySize = model.CompanySize;
        emp.Address = model.Address;
        emp.Website = model.Website;
        emp.Description = model.Description;

        emp.WhyWorkHereItems = highlights?
            .Where(h => !string.IsNullOrWhiteSpace(h.Title))
            .Select(h => new CompanyHighlight
            {
                Icon = string.IsNullOrWhiteSpace(h.Icon) ? "star" : h.Icon.Trim(),
                Title = h.Title.Trim(),
                Description = h.Description?.Trim() ?? string.Empty,
                IsHighlighted = h.IsHighlighted
            })
            .ToList() ?? new List<CompanyHighlight>();

        // Xử lý upload Logo & Cover từ base64
        if (!string.IsNullOrEmpty(model.LogoUrl) && model.LogoUrl.StartsWith("data:"))
        {
            try { emp.LogoUrl = await _jobSvc.SaveImageFromDataUriAsync(model.LogoUrl, "uploads/company/logo"); }
            catch { /* ignore */ }
        }
        else if (!string.IsNullOrEmpty(model.LogoUrl))
        {
            emp.LogoUrl = model.LogoUrl;
        }

        if (!string.IsNullOrEmpty(model.CoverURL) && model.CoverURL.StartsWith("data:"))
        {
            try { emp.CoverURL = await _jobSvc.SaveImageFromDataUriAsync(model.CoverURL, "uploads/company/cover"); }
            catch { /* ignore */ }
        }
        else if (!string.IsNullOrEmpty(model.CoverURL))
        {
            emp.CoverURL = model.CoverURL;
        }

        await _db.SaveChangesAsync();
        TempData["Success"] = "Cập nhật hồ sơ công ty thành công!";
        return RedirectToAction("CompanyProfile");
    }

    // ====================== MY PROFILE (thông tin cá nhân NTD) ======================

    // GET /Employer/MyProfile
    public async Task<IActionResult> MyProfile()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == UserId);
        if (user == null) return NotFound();

        ViewBag.Employer = emp;
        return View(user);
    }

    // POST /Employer/MyProfile
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> MyProfile(User model, string? gender, string? cccd)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == UserId);
        if (user == null) return NotFound();

        var emp = await GetEmployerAsync();

        if (string.IsNullOrWhiteSpace(model.FullName))
        {
            TempData["Error"] = "Họ tên không được để trống.";
            return RedirectToAction("MyProfile");
        }

        if (!string.IsNullOrWhiteSpace(cccd))
        {
            var cccdTrimmed = cccd.Trim();
            if (!System.Text.RegularExpressions.Regex.IsMatch(cccdTrimmed, @"^\d{9}(\d{3})?$"))
            {
                TempData["Error"] = "Số CCCD không hợp lệ (phải gồm 9 hoặc 12 chữ số).";
                return RedirectToAction("MyProfile");
            }

            if (emp != null && await _db.Employers.AnyAsync(e => e.CCCD == cccdTrimmed && e.EmployerId != emp.EmployerId))
            {
                TempData["Error"] = "Số CCCD này đã được sử dụng bởi tài khoản khác.";
                return RedirectToAction("MyProfile");
            }
        }

        user.FullName = model.FullName.Trim();
        user.PhoneNumber = model.PhoneNumber?.Trim();

        if (emp != null)
        {
            emp.Gender = string.IsNullOrWhiteSpace(gender) ? null : gender.Trim();
            emp.CCCD = string.IsNullOrWhiteSpace(cccd) ? null : cccd.Trim();
        }

        // Xử lý upload avatar từ base64
        if (!string.IsNullOrEmpty(model.AvatarUrl) && model.AvatarUrl.StartsWith("data:"))
        {
            try { user.AvatarUrl = await _jobSvc.SaveImageFromDataUriAsync(model.AvatarUrl, "uploads/users/avatar"); }
            catch { /* ignore */ }
        }
        else if (!string.IsNullOrEmpty(model.AvatarUrl))
        {
            user.AvatarUrl = model.AvatarUrl;
        }

        user.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        TempData["Success"] = "Cập nhật hồ sơ cá nhân thành công!";
        return RedirectToAction("MyProfile");
    }

    // ====================== INTERVIEW ACTIONS ======================

    // GET: /Employer/ScheduleInterview
    [HttpGet]
    public async Task<IActionResult> ScheduleInterview(int appId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.Job).ThenInclude(j => j!.Employer)
            .Include(a => a.CandidateProfile).ThenInclude(p => p!.User)
            .FirstOrDefaultAsync(a => a.AppID == appId && a.Job!.EmployerId == emp.EmployerId);

        if (app == null) return NotFound();

        ViewBag.Application = app;
        ViewBag.Employer = emp;
        return View(new Interview { AppID = appId, InterviewDate = DateTime.Now.AddDays(1) });
    }

    // POST: /Employer/ScheduleInterview
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ScheduleInterview(Interview model)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.Job).ThenInclude(j => j!.Employer)
            .Include(a => a.CandidateProfile).ThenInclude(p => p!.User)
            .FirstOrDefaultAsync(a => a.AppID == model.AppID && a.Job!.EmployerId == emp.EmployerId);

        if (app == null) return NotFound();

        if (ModelState.IsValid)
        {
            var existing = await _db.Interviews.FirstOrDefaultAsync(i => i.AppID == model.AppID);
            if (existing != null)
            {
                existing.InterviewDate = model.InterviewDate;
                existing.Location = model.Location;
                existing.Notes = model.Notes;
                existing.CreatedAt = DateTime.Now;
            }
            else
            {
                model.CreatedAt = DateTime.Now;
                _db.Interviews.Add(model);
            }

            app.Status = "Interview";
            app.UpdatedAt = DateTime.Now;

            _db.Notifications.Add(new Notification
            {
                UserId = app.CandidateProfile?.UserId ?? 0,
                Title = $"Thư mời phỏng vấn: {app.Job?.Title}",
                Content = $"Bạn nhận được lời mời phỏng vấn.\nThời gian: {model.InterviewDate:dd/MM/yyyy HH:mm}\nĐịa điểm/Hình thức: {model.Location}\nGhi chú: {model.Notes}",
                Type = "Application",
                RelatedId = app.JobId,
                CreatedAt = DateTime.Now
            });

            await _db.SaveChangesAsync();
            TempData["Success"] = "Đã gửi lời mời phỏng vấn thành công!";
            return RedirectToAction("Interviews");
        }

        ViewBag.Application = app;
        ViewBag.Employer = emp;
        return View(model);
    }

    // POST: /Employer/RejectApplication
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RejectApplication(int appId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.Job)
            .Include(a => a.CandidateProfile)
            .FirstOrDefaultAsync(a => a.AppID == appId && a.Job!.EmployerId == emp.EmployerId);

        if (app == null) return NotFound();

        app.Status = "Rejected";
        app.UpdatedAt = DateTime.Now;

        _db.Notifications.Add(new Notification
        {
            UserId = app.CandidateProfile?.UserId ?? 0,
            Title = $"Kết quả ứng tuyển: {app.Job?.Title}",
            Content = $"Rất tiếc, hồ sơ của bạn chưa phù hợp với vị trí {app.Job?.Title} ở thời điểm hiện tại. Chúc bạn may mắn trong các đợt tuyển dụng sau.",
            Type = "Application",
            RelatedId = app.JobId,
            CreatedAt = DateTime.Now
        });

        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã từ chối đơn ứng tuyển.";
        return RedirectToAction("ManageApplications", new { jobId = app.JobId });
    }

    // GET: /Employer/Interviews
    [HttpGet]
    public async Task<IActionResult> Interviews()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var interviews = await _db.Interviews
            .Include(i => i.Application).ThenInclude(a => a!.Job)
            .Include(i => i.Application).ThenInclude(a => a!.CandidateProfile)
            .Where(i => i.Application!.Job!.EmployerId == emp.EmployerId)
            .OrderByDescending(i => i.InterviewDate)
            .ToListAsync();

        return View(interviews);
    }

    // GET: /Employer/EditInterview
    [HttpGet]
    public async Task<IActionResult> EditInterview(int id)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var interview = await _db.Interviews
            .Include(i => i.Application).ThenInclude(a => a!.Job)
            .Include(i => i.Application).ThenInclude(a => a!.CandidateProfile)
            .FirstOrDefaultAsync(i => i.InterviewId == id && i.Application!.Job!.EmployerId == emp.EmployerId);

        if (interview == null) return NotFound();

        return View(interview);
    }

    // POST: /Employer/EditInterview
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditInterview(Interview model)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var interview = await _db.Interviews
            .Include(i => i.Application).ThenInclude(a => a!.Job)
            .Include(i => i.Application).ThenInclude(a => a!.CandidateProfile)
            .FirstOrDefaultAsync(i => i.InterviewId == model.InterviewId && i.Application!.Job!.EmployerId == emp.EmployerId);

        if (interview == null) return NotFound();

        if (ModelState.IsValid)
        {
            interview.InterviewDate = model.InterviewDate;
            interview.Location = model.Location;
            interview.Notes = model.Notes;

            _db.Notifications.Add(new Notification
            {
                UserId = interview.Application?.CandidateProfile?.UserId ?? 0,
                Title = $"Cập nhật lịch phỏng vấn: {interview.Application?.Job?.Title}",
                Content = $"Nhà tuyển dụng đã cập nhật lại lịch phỏng vấn của bạn.\nThời gian mới: {model.InterviewDate:dd/MM/yyyy HH:mm}\nĐịa điểm/Hình thức: {model.Location}\nGhi chú: {model.Notes}",
                Type = "Application",
                RelatedId = interview.Application?.JobId,
                CreatedAt = DateTime.Now
            });

            await _db.SaveChangesAsync();
            TempData["Success"] = "Đã cập nhật lịch phỏng vấn!";
            return RedirectToAction("Interviews");
        }

        return View(interview);
    }

    // POST: /Employer/DeleteInterview
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteInterview(int id)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var interview = await _db.Interviews
            .Include(i => i.Application).ThenInclude(a => a!.Job)
            .Include(i => i.Application).ThenInclude(a => a!.CandidateProfile)
            .FirstOrDefaultAsync(i => i.InterviewId == id && i.Application!.Job!.EmployerId == emp.EmployerId);

        if (interview == null) return NotFound();

        var app = interview.Application;

        if (app != null)
        {
            app.Status = "Reviewing";
            app.UpdatedAt = DateTime.Now;

            _db.Notifications.Add(new Notification
            {
                UserId = app.CandidateProfile?.UserId ?? 0,
                Title = $"Hủy lịch phỏng vấn: {app.Job?.Title}",
                Content = $"Nhà tuyển dụng đã hủy lịch phỏng vấn cho vị trí {app.Job?.Title}.",
                Type = "Application",
                RelatedId = app.JobId,
                CreatedAt = DateTime.Now
            });
        }

        _db.Interviews.Remove(interview);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã hủy lịch phỏng vấn!";
        return RedirectToAction("Interviews");
    }
}