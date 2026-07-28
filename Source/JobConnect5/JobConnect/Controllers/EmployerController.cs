// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// EmployerController — [Authorize(Roles = "Employer")]: TRANG QUẢN LÝ DÀNH CHO
// NHÀ TUYỂN DỤNG sau khi đăng nhập. Các nhóm chức năng chính:
//   • Dashboard/JobStats: thống kê tổng quan (số tin đăng, số đơn ứng tuyển...).
//   • PostJob/EditJob: đăng tin tuyển dụng mới / chỉnh sửa tin đã đăng.
//   • ManageApplications/UpdateApplicationStatus(Ajax)/CandidateDetail/CandidateSkills:
//     xem & xử lý danh sách ứng viên đã nộp đơn cho 1 tin, đổi trạng thái đơn.
//   • DownloadCv/ViewCv: tải/xem CV ứng viên đã nộp.
//   • ExportApplicationsCsv/PrintApplications: xuất danh sách ứng viên ra CSV / bản in.
//   • ScheduleInterview/EditInterview/DeleteInterview/RejectApplication: quản lý lịch phỏng vấn.
//   • CompanyProfile/MyProfile: chỉnh sửa hồ sơ công ty / hồ sơ cá nhân người đại diện.
// Đây là controller lớn (>1000 dòng) — dùng Ctrl+F theo tên action để tìm nhanh.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Helpers;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
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
    private readonly IGeminiService _aiService;
    private readonly IEmailService _emailService;
    private readonly ICvTextExtractionService _cvTextExtractor;
    private readonly ILocalCvMatchService _localMatchService;

    public EmployerController(AppDbContext db, IJobService jobSvc, IWebHostEnvironment env, IGeminiService aiService, IEmailService emailService, ICvTextExtractionService cvTextExtractor, ILocalCvMatchService localMatchService)
    {
        _db = db;
        _jobSvc = jobSvc;
        _env = env;
        _aiService = aiService;
        _emailService = emailService;
        _cvTextExtractor = cvTextExtractor;
        _localMatchService = localMatchService;
    }

    /// <summary>Quay lại đúng trang/bộ lọc đang xem thay vì luôn nhảy về mặc định.</summary>
    private IActionResult RedirectBackOrTo(string fallbackAction)
    {
        var referer = Request.Headers["Referer"].ToString();
        return !string.IsNullOrEmpty(referer) ? Redirect(referer) : RedirectToAction(fallbackAction);
    }
    private IActionResult RedirectBackOrTo(string fallbackAction, object routeValues)
    {
        var referer = Request.Headers["Referer"].ToString();
        return !string.IsNullOrEmpty(referer) ? Redirect(referer) : RedirectToAction(fallbackAction, routeValues);
    }

    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    private async Task<Employer?> GetEmployerAsync()
        => await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.UserId == UserId);

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

    // GET /Employer/CandidateDetail/{appId}
    // Trang xem chi tiết đầy đủ ứng viên (thông tin cá nhân, kỹ năng, CV, đơn ứng tuyển)
    // gắn với 1 đơn ứng tuyển cụ thể để đảm bảo NTD chỉ xem được ứng viên đã ứng tuyển vào job của mình.
    public async Task<IActionResult> CandidateDetail(int appId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.Job)
            .Include(a => a.Cv)
            .Include(a => a.CandidateProfile).ThenInclude(p => p.User)
            .Include(a => a.CandidateProfile).ThenInclude(p => p.CandidateSkills).ThenInclude(cs => cs.Skill)
            .Include(a => a.CandidateProfile).ThenInclude(p => p.CvFiles)
            .FirstOrDefaultAsync(a => a.AppID == appId && a.Job.EmployerId == emp.EmployerId);

        if (app == null) return NotFound();

        ViewBag.Employer = emp;
        return View(app);
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

        await CreateExpiryReminderNotificationsAsync(emp, expiringSoonJobs);

        return View(jobs);
    }

    // GET /Employer/ManageJobs
    // Trang riêng để QUẢN LÝ danh sách tin đã đăng (sửa/xóa/xem đơn ứng tuyển),
    // tách khỏi Dashboard (Dashboard giờ chỉ còn hiển thị số liệu thống kê tổng quan).
    public async Task<IActionResult> ManageJobs()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var jobs = await _jobSvc.GetByEmployerAsync(emp.EmployerId);

        ViewBag.Employer = emp;
        return View(jobs);
    }

    private async Task CreateExpiryReminderNotificationsAsync(Employer emp, List<JobPost> expiringSoonJobs)
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

    /// <summary>
    /// Kiểm tra logic Lương tối thiểu/tối đa — chặn CỨNG các trường hợp dữ liệu vô lý
    /// (âm, Min &gt; Max). Đây là lớp phòng thủ server-side, độc lập với JS ở client,
    /// vì client-side validate luôn có thể bị bỏ qua (tắt JS, gọi thẳng API/form POST).
    /// Ghi lỗi thẳng vào ModelState với key "SalaryMin"/"SalaryMax" để View hiển thị được
    /// qua &lt;span asp-validation-for="SalaryMin"&gt; nếu view có dùng, đồng thời cũng khiến
    /// ModelState.IsValid = false để chặn lưu xuống DB.
    /// </summary>
    private void ValidateSalaryLogic(decimal? salaryMin, decimal? salaryMax)
    {
        if (salaryMin.HasValue && salaryMin.Value < 0)
        {
            ModelState.AddModelError("SalaryMin", "Lương tối thiểu không được là số âm.");
        }
        if (salaryMax.HasValue && salaryMax.Value < 0)
        {
            ModelState.AddModelError("SalaryMax", "Lương tối đa không được là số âm.");
        }
        if (salaryMin.HasValue && salaryMax.HasValue && salaryMin.Value > salaryMax.Value)
        {
            ModelState.AddModelError("SalaryMin",
                $"Lương tối thiểu ({salaryMin:N0} VNĐ) đang lớn hơn lương tối đa ({salaryMax:N0} VNĐ) — dữ liệu sai logic, vui lòng nhập lại.");
        }
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

        // Nhà tuyển dụng phải bổ sung ĐẦY ĐỦ thông tin cá nhân + công ty trước
        // khi được phép đăng tin tuyển dụng.
        if (!ProfileCompletionHelper.IsEmployerProfileComplete(emp))
        {
            await ProfileCompletionHelper.RemindIncompleteAsync(
                _db, emp.UserId,
                title: "Hồ sơ nhà tuyển dụng chưa đầy đủ",
                content: "Bạn cần bổ sung đầy đủ thông tin cá nhân (giới tính, CCCD) và thông tin công ty (mã số thuế, lĩnh vực, địa chỉ) trước khi có thể sử dụng đầy đủ các chức năng, bao gồm đăng tin tuyển dụng.");
            await _db.SaveChangesAsync();

            TempData["Error"] = "Bạn cần bổ sung đầy đủ thông tin cá nhân và công ty trước khi đăng tin tuyển dụng.";
            return RedirectToAction("CompanyProfile");
        }

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

        // ─── Kiểm tra logic Lương (server-side, không tin tuyệt đối vào JS client) ───
        // Đây là lớp chặn CUỐI CÙNG: dù JS bị tắt/can thiệp DevTools, request POST trực tiếp
        // (Postman, script...) vẫn không thể tạo được tin có lương sai logic.
        ValidateSalaryLogic(model.SalaryMin, model.SalaryMax);

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
        return RedirectToAction("ManageJobs");
    }

    // GET /Employer/ManageApplications?jobId=5&status=Pending
    public async Task<IActionResult> ManageApplications(int jobId = 0, string? status = null)
    {
        if (jobId == 0) return RedirectToAction("ManageJobs");

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

        // Tổng số đơn ứng tuyển thực tế (không áp dụng bộ lọc trạng thái) để phân biệt
        // giữa "chưa có đơn nào" và "lọc không ra kết quả nào".
        var totalApplicationsCount = await _db.Applications.CountAsync(a => a.JobId == jobId);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);

        var apps = await query
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        // Tính nhanh % phù hợp (thuật toán so khớp cục bộ, ưu tiên theo danh mục Skill có sẵn, không gọi AI)
        // để hiển thị ngay trong danh sách.
        var knownSkillNames = await _db.Skills.Where(s => s.IsActive).Select(s => s.Name).ToListAsync();

        var quickMatchResults = new Dictionary<int, LocalCvMatchResult>();
        foreach (var app in apps)
        {
            var cv = app.Cv;
            if (cv == null)
            {
                quickMatchResults[app.AppID] = new LocalCvMatchResult { LooksLikeCv = false, Reason = "Đơn này chưa đính kèm CV." };
                continue;
            }

            var absolutePath = Path.Combine(_env.WebRootPath, cv.FilePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
            if (!System.IO.File.Exists(absolutePath))
            {
                quickMatchResults[app.AppID] = new LocalCvMatchResult { LooksLikeCv = false, Reason = "Không tìm thấy file CV." };
                continue;
            }

            var cvText = await _cvTextExtractor.ExtractTextAsync(absolutePath);
            quickMatchResults[app.AppID] = _localMatchService.CalculateMatch(
                cvText, job.Title ?? "", job.Description ?? "", job.Requirements ?? "", knownSkillNames);
        }

        ViewBag.QuickMatchResults = quickMatchResults;
        ViewBag.Job = job;
        ViewBag.TotalApplicationsCount = totalApplicationsCount;
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

    // ====================== XEM TRƯỚC CV (không tải về) ======================
    // GET /Employer/ViewCv?cvId=123
    public async Task<IActionResult> ViewCv(int cvId)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return NotFound("Bạn chưa đăng ký tài khoản nhà tuyển dụng.");

        var cv = await _db.CvFiles.FirstOrDefaultAsync(c => c.Cvid == cvId);
        if (cv == null) return NotFound("Không tìm thấy CV.");

        var hasPermission = await _db.Applications
            .AnyAsync(a => a.Cvid == cvId
                        && a.Job != null
                        && a.Job.EmployerId == emp.EmployerId);

        if (!hasPermission)
            return NotFound("Bạn không có quyền xem CV này.");

        var relPath = cv.FilePath?.TrimStart('/') ?? string.Empty;
        var fullPath = Path.Combine(_env.WebRootPath,
            relPath.Replace('/', Path.DirectorySeparatorChar));

        if (!System.IO.File.Exists(fullPath))
            return NotFound("File CV không tồn tại trên server.");

        var contentType = GetContentType(Path.GetExtension(fullPath));

        // Đọc toàn bộ file vào bộ nhớ và trả về bằng File() thay vì PhysicalFile()
        // để tránh mọi vấn đề liên quan tới header Content-Disposition/Range thủ công.
        // Không truyền fileDownloadName => trình duyệt sẽ hiển thị trực tiếp (inline)
        // thay vì tải về, đặc biệt là với PDF.
        var fileBytes = await System.IO.File.ReadAllBytesAsync(fullPath);
        return File(fileBytes, contentType);
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
        // [FIX-BẢO MẬT - IDOR] Trước đây action này KHÔNG kiểm tra đơn ứng tuyển có
        // thuộc về tin của CHÍNH nhà tuyển dụng đang đăng nhập hay không — ai cũng có
        // thể gọi trực tiếp action này (vd: qua Postman) với appId bất kỳ để đổi trạng
        // thái đơn ứng tuyển của Employer KHÁC. Thêm chặn giống bản AJAX
        // (UpdateApplicationStatusAjax) đã làm đúng.
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.CandidateProfile)
            .Include(a => a.Job)
            .FirstOrDefaultAsync(a => a.AppID == appId && a.Job != null && a.Job.EmployerId == emp.EmployerId);

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
        return RedirectBackOrTo("ManageApplications", new { jobId });
    }

    // POST /Employer/UpdateApplicationStatusAjax
    // Cập nhật trạng thái đơn ứng tuyển trực tiếp từ dropdown trong bảng (không reload trang)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateApplicationStatusAjax(int appId, string status)
    {
        try
        {
            var emp = await GetEmployerAsync();
            if (emp == null) return Json(new { success = false, message = "Bạn chưa đăng ký tài khoản nhà tuyển dụng." });

            var validStatuses = new[] { "Pending", "Reviewing", "Interview", "Accepted", "Rejected" };
            if (!validStatuses.Contains(status))
                return Json(new { success = false, message = "Trạng thái không hợp lệ." });

            var app = await _db.Applications
                .Include(a => a.CandidateProfile)
                .Include(a => a.Job)
                .FirstOrDefaultAsync(a => a.AppID == appId && a.Job != null && a.Job.EmployerId == emp.EmployerId);

            if (app == null) return Json(new { success = false, message = "Không tìm thấy đơn ứng tuyển." });

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

            var labels = new Dictionary<string, string>
            {
                ["Pending"] = "Chờ xét duyệt",
                ["Reviewing"] = "Đang xem xét",
                ["Interview"] = "Mời phỏng vấn",
                ["Accepted"] = "Đã nhận",
                ["Rejected"] = "Từ chối"
            };

            return Json(new { success = true, message = "Đã cập nhật trạng thái thành công!", status, label = labels.GetValueOrDefault(status, status) });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // Chỉ cho phép Sửa khi tin CHƯA TỪNG hiển thị công khai (Chờ duyệt / Bị từ chối).
    // Tin đã "Đang mở" (Active) — kể cả đã hết hạn — coi như đã dùng lượt đăng trả phí
    // và đã lên sóng thật, nên KHÔNG cho sửa nữa để tránh nhà tuyển dụng lợi dụng sửa
    // nội dung/gia hạn tin cũ nhằm né phải trả phí đăng tin mới. Muốn thay đổi thì phải
    // xóa tin cũ và đăng tin mới (trả phí như bình thường).
    private static bool CanEditJob(JobPost job)
    {
        bool isExpired = job.Deadline.HasValue && job.Deadline.Value < DateTime.Now;

        // RULE CUỐI: "đã từng hiển thị công khai" (Active, hoặc đã hết hạn dù đang ở
        // status nào) → khóa Sửa hoàn toàn, chỉ còn Xóa tin / đăng tin mới (trả phí).
        // "Chưa từng hiển thị công khai" (Pending, Rejected) và CHƯA hết hạn → sửa tự do.
        // Hết hạn luôn khóa Sửa bất kể status, để chặn việc NTD cố tình chờ tin hết hạn
        // (không còn là "Active" nữa) rồi sửa để né rule, sau đó tự gia hạn lại.
        if (isExpired) return false;

        return job.Status == "Pending" || job.Status == "Rejected";
    }

    // Gửi thông báo tới TOÀN BỘ Admin + Staff khi Nhà tuyển dụng vừa Sửa hoặc Xóa
    // một tin tuyển dụng, để họ biết mà theo dõi/duyệt lại. RelatedId = JobId để
    // bấm vào thông báo là dẫn thẳng tới tin đó (nếu tin bị xóa thì trang chi tiết
    // sẽ tự báo không tìm thấy, không ảnh hưởng gì).
    private async Task NotifyAdminsAndStaffAsync(JobPost job, string title, string content)
    {
        var recipientIds = await _db.Users
            .Where(u => u.Role == "Admin" || u.Role == "Staff")
            .Select(u => u.UserId)
            .ToListAsync();

        if (recipientIds.Count == 0) return;

        var notifications = recipientIds.Select(uid => new Notification
        {
            UserId = uid,
            Title = title,
            Content = content,
            Type = "System",
            RelatedId = job.JobId,
            IsRead = false,
            CreatedAt = DateTime.Now
        });

        _db.Notifications.AddRange(notifications);
        await _db.SaveChangesAsync();
    }

    // GET /Employer/EditJob/5
    [HttpGet]
    public async Task<IActionResult> EditJob(int id)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var job = await _db.JobPosts.FindAsync(id);
        if (job == null) return NotFound();

        // [FIX-BẢO MẬT - IDOR] Trước đây action này KHÔNG kiểm tra tin có thuộc về
        // chính nhà tuyển dụng đang đăng nhập hay không — nghĩa là bất kỳ Employer nào
        // cũng có thể sửa/xem tin của Employer KHÁC chỉ bằng cách đổi "id" trên URL
        // (/Employer/EditJob/123). Thêm chặn này để chỉ chủ tin mới sửa được, giống
        // với cách DeleteJob() đã làm đúng từ trước.
        if (job.EmployerId != emp.EmployerId)
        {
            TempData["Error"] = "Không tìm thấy tin tuyển dụng hoặc bạn không có quyền sửa tin này.";
            return RedirectToAction("ManageJobs");
        }

        if (!CanEditJob(job))
        {
            TempData["Error"] = "Tin đã hiển thị công khai (Đang mở) hoặc đã hết hạn thì không thể sửa. Vui lòng xóa tin và đăng tin mới (trả phí) nếu muốn thay đổi nội dung hoặc gia hạn.";
            return RedirectToAction("ManageJobs");
        }

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

        ViewBag.CompanySize = emp.CompanySize;

        return View(vm);
    }

    // POST /Employer/EditJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> EditJob(PostJobViewModel model)
    {
        // ─── Kiểm tra logic Lương (server-side, không tin tuyệt đối vào JS client) ───
        ValidateSalaryLogic(model.SalaryMin, model.SalaryMax);

        if (!ModelState.IsValid)
        {
            ViewBag.Categories = new SelectList(await _db.Categories
                .Where(c => c.Type == "Industry").ToListAsync(),
                "CategoryID", "Name", model.CategoryID);
            return View(model);
        }

        var job = await _db.JobPosts.FindAsync(model.JobId);
        if (job == null) return NotFound();

        // [FIX-BẢO MẬT - IDOR] Xem giải thích ở EditJob() GET phía trên — đây là chỗ
        // nguy hiểm hơn vì có thể POST trực tiếp (không cần qua GET) để sửa tin của
        // Employer khác nếu thiếu kiểm tra này.
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");
        if (job.EmployerId != emp.EmployerId)
        {
            TempData["Error"] = "Không tìm thấy tin tuyển dụng hoặc bạn không có quyền sửa tin này.";
            return RedirectToAction("ManageJobs");
        }

        if (!CanEditJob(job))
        {
            TempData["Error"] = "Tin đã hiển thị công khai (Đang mở) hoặc đã hết hạn thì không thể sửa. Vui lòng xóa tin và đăng tin mới (trả phí) nếu muốn thay đổi nội dung hoặc gia hạn.";
            return RedirectToAction("ManageJobs");
        }

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
        job.CategoryID = model.CategoryID;
        job.UpdatedAt = DateTime.Now;

        // Job đang ở Pending/Rejected (điều kiện CanEditJob) tức là CHƯA từng hiển thị
        // công khai — nhà tuyển dụng KHÔNG được tự đặt "Active" để né việc duyệt.
        // Chọn Active thì bị hạ về lại "Pending" chờ duyệt; chỉ Draft/Paused (tự ẩn)
        // hoặc giữ nguyên Pending/Rejected mới được áp dụng như đã chọn.
        job.Status = model.Status == "Active" ? "Pending" : model.Status;

        await _db.SaveChangesAsync();

        // Báo cho Admin + Staff biết tin này vừa được Nhà tuyển dụng sửa lại, kèm
        // trạng thái hiện tại (chỉ thật sự cần duyệt lại nếu đang ở "Pending").
        var companyName = emp.CompanyName ?? "Nhà tuyển dụng";
        var statusNote = job.Status == "Pending" ? "và đang chờ duyệt lại" : $"(trạng thái hiện tại: {job.Status})";
        await NotifyAdminsAndStaffAsync(
            job,
            "Tin tuyển dụng vừa được sửa lại",
            $"{companyName} vừa sửa lại tin \"{job.Title}\" {statusNote}. Bấm vào để xem chi tiết.");

        TempData["Success"] = "Đã cập nhật tin tuyển dụng.";
        return RedirectToAction("ManageJobs");
    }

    // POST /Employer/DeleteJob
    // Xóa MỀM: chỉ đổi Status thành "Deleted" để ẩn khỏi Dashboard và trang công khai,
    // KHÔNG xóa record trong DB — giữ nguyên lịch sử lượt xem/đơn ứng tuyển để còn
    // đối soát/thống kê sau này. Đây là tin đã "dùng xong" (dù đang mở hay bị từ chối),
    // nếu muốn đăng nội dung khác thì tạo tin mới (trả phí) như bình thường.
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteJob(int id)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var job = await _db.JobPosts.FindAsync(id);

        // Chỉ được xóa tin của CHÍNH mình — chặn trường hợp cố tình gọi thẳng
        // action với id của tin thuộc nhà tuyển dụng khác.
        if (job == null || job.EmployerId != emp.EmployerId)
        {
            TempData["Error"] = "Không tìm thấy tin tuyển dụng hoặc bạn không có quyền xóa tin này.";
            return RedirectToAction("ManageJobs");
        }

        job.Status = "Deleted";
        job.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();

        // Báo cho Admin + Staff biết tin này vừa bị Nhà tuyển dụng xóa.
        await NotifyAdminsAndStaffAsync(
            job,
            "Tin tuyển dụng vừa bị xóa",
            $"{emp.CompanyName} vừa xóa tin \"{job.Title}\".");

        TempData["Success"] = $"Đã xóa tin \"{job.Title}\".";
        return RedirectToAction("ManageJobs");
    }

    // GET /Employer/CompanyProfile
    public async Task<IActionResult> CompanyProfile()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        // Load danh sách "Mục nổi bật" từ DB (navigation này không được Include trong GetEmployerAsync)
        emp.WhyWorkHereItems = await _db.CompanyHighlights
            .Where(h => h.EmployerId == emp.EmployerId)
            .ToListAsync();

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

        // Xóa các "Mục nổi bật" cũ và thêm lại danh sách mới.
        // Lưu ý: emp.WhyWorkHereItems là navigation KHÔNG được Include trong GetEmployerAsync(),
        // nên gán thẳng một List mới vào đó sẽ không được EF Core track -> SaveChanges không lưu gì cả.
        // Phải thao tác trực tiếp trên DbSet<CompanyHighlight> để đảm bảo được lưu.
        var oldHighlights = await _db.CompanyHighlights
            .Where(h => h.EmployerId == emp.EmployerId)
            .ToListAsync();
        _db.CompanyHighlights.RemoveRange(oldHighlights);

        var newHighlights = highlights?
            .Where(h => !string.IsNullOrWhiteSpace(h.Title))
            .Select(h => new CompanyHighlight
            {
                EmployerId = emp.EmployerId,
                Icon = string.IsNullOrWhiteSpace(h.Icon) ? "star" : h.Icon.Trim(),
                Title = h.Title.Trim(),
                Description = h.Description?.Trim() ?? string.Empty,
                IsHighlighted = h.IsHighlighted
            })
            .ToList() ?? new List<CompanyHighlight>();

        if (newHighlights.Count > 0)
            await _db.CompanyHighlights.AddRangeAsync(newHighlights);

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

        // Vừa cập nhật xong thông tin công ty — kiểm tra xem hồ sơ (công ty +
        // cá nhân người đại diện) đã đủ để tự động kích hoạt tài khoản chưa.
        var userForActivation = await _db.Users.FindAsync(emp.UserId);
        if (await ProfileCompletionHelper.TryAutoActivateAsync(_db, userForActivation))
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

        // Vừa cập nhật xong thông tin cá nhân người đại diện — kiểm tra xem hồ
        // sơ (cá nhân + công ty) đã đủ để tự động kích hoạt tài khoản chưa.
        if (await ProfileCompletionHelper.TryAutoActivateAsync(_db, user))
            await _db.SaveChangesAsync();

        // Claim "AvatarURL" trong cookie đăng nhập chỉ được set lúc Login, nên sau khi
        // cập nhật ảnh đại diện ở đây, header (layout) vẫn hiển thị ảnh CŨ cho tới khi
        // đăng nhập lại. Re-sign-in ngay với claim mới để avatar ở góc header cập nhật tức thì.
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.FullName ?? user.Email),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role ?? "Employer"),
            new Claim("AvatarURL", user.AvatarUrl ?? "")
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var newPrincipal = new ClaimsPrincipal(identity);

        var authProperties = new AuthenticationProperties
        {
            IsPersistent = User.Identity?.IsAuthenticated == true,
            ExpiresUtc = (await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme))
                            .Properties?.ExpiresUtc
        };

        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, newPrincipal, authProperties);

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
    public async Task<IActionResult> ScheduleInterview(Interview model, string dateStr, string timeStr, string? contactPhone)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var app = await _db.Applications
            .Include(a => a.Job).ThenInclude(j => j!.Employer)
            .Include(a => a.CandidateProfile).ThenInclude(p => p!.User)
            .FirstOrDefaultAsync(a => a.AppID == model.AppID && a.Job!.EmployerId == emp.EmployerId);

        if (app == null) return NotFound();

        // Ghép ngày (dd/MM/yyyy) + giờ (HH:mm) do JS gửi lên thành DateTime thật.
        if (DateTime.TryParseExact($"{dateStr} {timeStr}", "dd/MM/yyyy HH:mm",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None, out var parsedDate))
        {
            model.InterviewDate = parsedDate;
        }
        else
        {
            ModelState.AddModelError("", "Ngày hoặc giờ phỏng vấn không hợp lệ. Vui lòng nhập đúng định dạng (VD: 30/06/2026 và 09:00).");
        }

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

            var companyName = emp.CompanyName ?? app.Job?.Employer?.CompanyName ?? "Công ty";
            var candidateName = app.CandidateProfile?.FullName ?? app.CandidateProfile?.User?.FullName ?? "Ứng viên";
            var candidateEmail = app.CandidateProfile?.User?.Email;
            var phoneToShow = string.IsNullOrWhiteSpace(contactPhone) ? emp.User?.PhoneNumber : contactPhone;

            _db.Notifications.Add(new Notification
            {
                UserId = app.CandidateProfile?.UserId ?? 0,
                Title = $"Thư mời phỏng vấn: {app.Job?.Title}",
                Content = $"Bạn nhận được lời mời phỏng vấn.\nThời gian: {model.InterviewDate:dd/MM/yyyy HH:mm}\nĐịa điểm/Hình thức: {model.Location}\nGhi chú: {model.Notes}" +
                          (string.IsNullOrWhiteSpace(phoneToShow) ? "" : $"\nSố điện thoại liên hệ: {phoneToShow}"),
                Type = "Application",
                RelatedId = app.JobId,
                CreatedAt = DateTime.Now
            });

            await _db.SaveChangesAsync();

            // Gửi email thư mời phỏng vấn thật cho ứng viên (không chặn luồng chính nếu gửi lỗi).
            if (!string.IsNullOrWhiteSpace(candidateEmail))
            {
                try
                {
                    var htmlBody = BuildInterviewEmailHtml(
                        candidateName: candidateName,
                        companyName: companyName,
                        jobTitle: app.Job?.Title ?? "",
                        interviewDate: model.InterviewDate,
                        location: model.Location,
                        notes: model.Notes,
                        contactPhone: phoneToShow,
                        contactEmail: emp.User?.Email);

                    await _emailService.SendAsync(candidateEmail, $"Thư mời phỏng vấn - {app.Job?.Title} tại {companyName}", htmlBody);

                    // Gửi thêm 1 bản sao về email của NTD để làm bằng chứng đã gửi lời mời.
                    if (!string.IsNullOrWhiteSpace(emp.User?.Email))
                    {
                        try
                        {
                            var copyBody = $@"<p style=""font-family:Segoe UI,Arial,sans-serif;color:#1e293b;"">
                                Đây là bản sao thư mời phỏng vấn đã được gửi tới ứng viên <strong>{System.Net.WebUtility.HtmlEncode(candidateName)}</strong>
                                ({System.Net.WebUtility.HtmlEncode(candidateEmail)}) cho vị trí <strong>{System.Net.WebUtility.HtmlEncode(app.Job?.Title)}</strong>.</p>"
                                + htmlBody;

                            await _emailService.SendAsync(emp.User!.Email, $"[Bản sao] Đã gửi thư mời phỏng vấn - {app.Job?.Title}", copyBody);
                        }
                        catch
                        {
                            // Bỏ qua lỗi gửi bản sao cho NTD — không quan trọng bằng việc ứng viên đã nhận được thư mời.
                        }
                    }
                }
                catch (Exception ex)
                {
                    // Không làm gián đoạn quy trình mời phỏng vấn nếu gửi email lỗi (VD: sai SMTP).
                    TempData["Warning"] = "Đã lưu lịch phỏng vấn, nhưng gửi email thất bại: " + ex.Message;
                }
            }

            TempData["Success"] ??= "Đã gửi lời mời phỏng vấn thành công!";
            return RedirectBackOrTo("Interviews");
        }

        ViewBag.Application = app;
        ViewBag.Employer = emp;
        return View(model);
    }

    /// <summary>
    /// Soạn nội dung HTML cho email thư mời phỏng vấn gửi ứng viên.
    /// </summary>
    private static string BuildInterviewEmailHtml(string candidateName, string companyName, string jobTitle,
        DateTime interviewDate, string location, string? notes, string? contactPhone, string? contactEmail)
    {
        return $@"
        <div style=""font-family:Segoe UI,Arial,sans-serif;max-width:600px;margin:0 auto;color:#1e293b;"">
            <div style=""background:linear-gradient(135deg,#4f46e5,#7c3aed);padding:24px;border-radius:12px 12px 0 0;"">
                <h2 style=""color:#fff;margin:0;"">Thư mời phỏng vấn</h2>
                <p style=""color:#e0e7ff;margin:4px 0 0;"">{System.Net.WebUtility.HtmlEncode(companyName)}</p>
            </div>
            <div style=""border:1px solid #e2e8f0;border-top:none;padding:24px;border-radius:0 0 12px 12px;"">
                <p>Kính gửi <strong>{System.Net.WebUtility.HtmlEncode(candidateName)}</strong>,</p>
                <p>Công ty <strong>{System.Net.WebUtility.HtmlEncode(companyName)}</strong> trân trọng mời bạn tham dự buổi phỏng vấn cho vị trí <strong>{System.Net.WebUtility.HtmlEncode(jobTitle)}</strong>.</p>
                <table style=""width:100%;border-collapse:collapse;margin:16px 0;"">
                    <tr><td style=""padding:8px 0;color:#64748b;width:160px;"">Thời gian</td><td style=""padding:8px 0;font-weight:600;"">{interviewDate:HH:mm 'ngày' dd/MM/yyyy}</td></tr>
                    <tr><td style=""padding:8px 0;color:#64748b;"">Địa điểm / Hình thức</td><td style=""padding:8px 0;font-weight:600;"">{System.Net.WebUtility.HtmlEncode(location)}</td></tr>
                    {(string.IsNullOrWhiteSpace(contactPhone) ? "" : $@"<tr><td style=""padding:8px 0;color:#64748b;"">Số điện thoại liên hệ</td><td style=""padding:8px 0;font-weight:600;"">{System.Net.WebUtility.HtmlEncode(contactPhone)}</td></tr>")}
                    {(string.IsNullOrWhiteSpace(contactEmail) ? "" : $@"<tr><td style=""padding:8px 0;color:#64748b;"">Email liên hệ</td><td style=""padding:8px 0;font-weight:600;"">{System.Net.WebUtility.HtmlEncode(contactEmail)}</td></tr>")}
                </table>
                {(string.IsNullOrWhiteSpace(notes) ? "" : $@"<div style=""background:#f1f5f9;border-radius:8px;padding:12px 16px;margin-bottom:16px;""><p style=""margin:0 0 4px;color:#475569;font-weight:600;"">Ghi chú từ nhà tuyển dụng:</p><p style=""margin:0;white-space:pre-line;"">{System.Net.WebUtility.HtmlEncode(notes)}</p></div>")}
                <p>Vui lòng phản hồi lại email này hoặc liên hệ số điện thoại trên nếu bạn cần đổi lịch hoặc có bất kỳ thắc mắc nào.</p>
                <p>Chúc bạn có buổi phỏng vấn thành công!</p>
                <p style=""margin-top:24px;color:#94a3b8;font-size:12px;"">Email này được gửi tự động từ hệ thống JobConnect thay mặt cho {System.Net.WebUtility.HtmlEncode(companyName)}.</p>
            </div>
        </div>";
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
        return RedirectBackOrTo("ManageApplications", new { jobId = app.JobId });
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
            return RedirectBackOrTo("Interviews");
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
        return RedirectBackOrTo("Interviews");
    }
}