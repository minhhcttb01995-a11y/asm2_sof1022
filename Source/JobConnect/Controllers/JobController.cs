using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers
{
    public class JobController : Controller
    {
        private readonly IJobService _jobSvc;
        private readonly AppDbContext _db;
        private readonly IStatusCatalogService _statusSvc;
        private readonly IAntiforgery _antiforgery;

        public JobController(IJobService jobSvc, AppDbContext db, IStatusCatalogService statusSvc, IAntiforgery antiforgery)
        {
            _jobSvc = jobSvc;
            _db = db;
            _statusSvc = statusSvc;
            _antiforgery = antiforgery;
        }

        // GET: /Job
        public async Task<IActionResult> Index([FromQuery] JobSearchViewModel filter)
        {
            filter.Page = filter.Page < 1 ? 1 : filter.Page;
            filter.PageSize = 12;

            var (jobs, totalCount) = await _jobSvc.SearchAsync(filter);

            ViewBag.Filter = filter;
            ViewBag.TotalCount = totalCount;
            ViewBag.TotalPages = (int)Math.Ceiling(totalCount / (double)filter.PageSize);

            ViewBag.Industries = await _db.Categories
                .Where(c => c.Type == "Industry")
                .ToListAsync();

            ViewBag.Locations = await _db.Categories
                .Where(c => c.Type == "Location")
                .ToListAsync();

            // Nếu là gọi AJAX (lọc/tìm kiếm/phân trang không tải lại cả trang),
            // chỉ trả về phần danh sách kết quả + phân trang.
            bool isAjax = Request.Headers["X-Requested-With"] == "XMLHttpRequest";
            if (isAjax)
            {
                return PartialView("_JobListResults", jobs);
            }

            return View(jobs);
        }

        // GET: /Job/Detail/5
        public async Task<IActionResult> Detail(int id)
        {
            var job = await _jobSvc.GetByIdAsync(id);
            if (job == null) return NotFound();

            int? profileId = null;
            bool hasApplied = false;
            bool isSaved = false;

            if (User.Identity?.IsAuthenticated == true)
            {
                int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out int userId);

                var profile = await _db.CandidateProfiles
                    .FirstOrDefaultAsync(p => p.UserId == userId);

                if (profile != null)
                {
                    profileId = profile.ProfileId;
                    hasApplied = await _jobSvc.HasAppliedAsync(profile.ProfileId, id);

                    // Load danh sách CV của candidate
                    var cvs = await _db.CvFiles
                        .Where(c => c.ProfileId == profile.ProfileId)
                        .OrderByDescending(c => c.UploadedAt)
                        .ToListAsync();

                    ViewBag.CVs = cvs;
                    ViewBag.DefaultCV = cvs.FirstOrDefault(c => c.IsDefault);
                }

                isSaved = await _db.SavedJobs
                    .AnyAsync(s => s.UserId == userId && s.JobId == id);
            }

            var visibleJobStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.JobPost);
            var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);

            var relatedJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => visibleJobStatuses.Contains(j.Status) && visibleEmployerStatuses.Contains(j.Employer.Status) && j.EmployerId == job.EmployerId && j.JobId != id)
                .Take(4)
                .ToListAsync();

            ViewBag.HasApplied = hasApplied;
            ViewBag.IsSaved = isSaved;
            ViewBag.SimilarJobs = relatedJobs;

            return View(job);
        }

        // POST: Ứng tuyển (Chọn CV + Thư xin việc)
        [HttpPost]
        public async Task<IActionResult> Apply(int jobId, int cvId, string? coverLetter)
        {
            bool isAjax = Request.Headers["X-Requested-With"] == "XMLHttpRequest";

            try
            {
                try
                {
                    await _antiforgery.ValidateRequestAsync(HttpContext);
                }
                catch (AntiforgeryValidationException)
                {
                    const string tokenMsg = "Phiên làm việc đã hết hạn, vui lòng tải lại trang và thử lại.";
                    if (isAjax)
                        return Json(new { success = false, message = tokenMsg });
                    TempData["Error"] = tokenMsg;
                    return RedirectToAction("Detail", new { id = jobId });
                }

                if (User.Identity?.IsAuthenticated != true)
                {
                    if (isAjax)
                        return Json(new { success = false, requireLogin = true, message = "Bạn cần đăng nhập để ứng tuyển." });
                    return RedirectToAction("Login", "Account", new { returnUrl = $"/Job/Detail/{jobId}" });
                }

                int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out int userId);

                var profile = await _db.CandidateProfiles
                    .FirstOrDefaultAsync(p => p.UserId == userId);

                if (profile == null)
                {
                    const string msg = "Bạn cần tạo hồ sơ ứng viên trước khi ứng tuyển.";
                    if (isAjax)
                        return Json(new { success = false, message = msg });
                    TempData["Error"] = msg;
                    return RedirectToAction("Detail", new { id = jobId });
                }

                // Kiểm tra CV hợp lệ
                var cv = await _db.CvFiles
                    .FirstOrDefaultAsync(c => c.Cvid == cvId && c.ProfileId == profile.ProfileId);

                if (cv == null)
                {
                    const string msg = "CV không hợp lệ!";
                    if (isAjax)
                        return Json(new { success = false, message = msg });
                    TempData["Error"] = msg;
                    return RedirectToAction("Detail", new { id = jobId });
                }

                // Chặn ứng tuyển mới nếu tin đã hết hạn nộp hồ sơ (vẫn cho rút đơn nếu đã ứng tuyển trước đó)
                bool alreadyApplied = await _jobSvc.HasAppliedAsync(profile.ProfileId, jobId);
                if (!alreadyApplied)
                {
                    var jobDeadlineCheck = await _db.JobPosts.FindAsync(jobId);
                    if (jobDeadlineCheck?.Deadline != null && jobDeadlineCheck.Deadline.Value < DateTime.Now)
                    {
                        const string msg = "Tin tuyển dụng này đã hết hạn nộp hồ sơ, bạn không thể ứng tuyển.";
                        if (isAjax)
                            return Json(new { success = false, message = msg });
                        TempData["Error"] = msg;
                        return RedirectToAction("Detail", new { id = jobId });
                    }
                }

                // Gọi service để ứng tuyển (hoạt động theo kiểu toggle: ứng tuyển lần 2 = rút đơn)
                var result = await _jobSvc.ToggleApplyAsync(jobId, profile.ProfileId, cvId, coverLetter);

                string? successMsg = result switch
                {
                    ApplyToggleResult.Applied => "Ứng tuyển thành công! Nhà tuyển dụng sẽ xem hồ sơ của bạn sớm nhất.",
                    ApplyToggleResult.Withdrawn => "Bạn đã rút đơn ứng tuyển.",
                    _ => null
                };
                string? errorMsg = result == ApplyToggleResult.Error ? "Có lỗi xảy ra khi gửi đơn ứng tuyển." : null;

                if (isAjax)
                {
                    return Json(new
                    {
                        success = errorMsg == null,
                        message = errorMsg ?? successMsg,
                        applied = result == ApplyToggleResult.Applied
                    });
                }

                TempData["Success"] = successMsg;
                if (errorMsg != null)
                    TempData["Error"] = errorMsg;

                return RedirectToAction("Detail", new { id = jobId });
            }
            catch (Exception ex)
            {
                // Không để exception rơi vào middleware xử lý lỗi chung (trả về trang HTML),
                // vì request AJAX cần nhận JSON để hiển thị đúng thông báo trong popup.
                if (isAjax)
                {
                    var detail = ex.InnerException?.Message ?? ex.Message;
                    return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + detail });
                }
                throw;
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleSave(int jobId)
        {
            if (User.Identity?.IsAuthenticated != true)
                return RedirectToAction("Login", "Account", new { returnUrl = $"/Job/Detail/{jobId}" });

            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out int userId))
                return RedirectToAction("Login", "Account", new { returnUrl = $"/Job/Detail/{jobId}" });
            await _jobSvc.ToggleSaveAsync(userId, jobId);

            return RedirectToAction("Detail", new { id = jobId });
        }
    }
}