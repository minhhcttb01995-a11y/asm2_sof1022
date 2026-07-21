// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// JobController — trang CÔNG KHAI TÌM KIẾM & ỨNG TUYỂN việc làm (khác CandidateController
// là trang quản lý cá nhân của ứng viên):
//   • Index: trang tìm kiếm/lọc danh sách tin tuyển dụng (dùng IJobService.SearchAsync).
//   • Detail: trang chi tiết 1 tin tuyển dụng.
//   • Apply: ứng viên nộp đơn ứng tuyển cho 1 tin (yêu cầu đăng nhập).
//   • ToggleSave: lưu/bỏ lưu tin yêu thích.
// ═══════════════════════════════════════════════════════════════════════════
using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Extensions;
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
                // Quan trọng: KHÔNG để trình duyệt cache response này theo URL.
                // Vì URL này (/Job?...) cũng được dùng cho lần tải trang đầy đủ
                // (kèm layout/CSS) khi người dùng bấm nút Back/Forward hoặc F5.
                // Nếu không có Cache-Control: no-store, trình duyệt có thể trả lại
                // đúng bản HTML rút gọn (không CSS) này khi điều hướng lại trang,
                // khiến trang bị mất toàn bộ giao diện.
                Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
                Response.Headers["Vary"] = "X-Requested-With";
                return PartialView("_JobListResults", jobs);
            }

            Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
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

            // Tổng quan (Yêu cầu / Quyền lợi / Chuyên môn) — tính thuần cục bộ (regex + từ khóa),
            // KHÔNG gọi AI nên hiển thị tức thời, không tốn quota dù trang được xem nhiều lần.
            var allSkills = await _db.Skills.Where(s => s.IsActive).ToListAsync();
            ViewBag.Overview = job.BuildOverview(allSkills);

            ViewBag.HasApplied = hasApplied;
            ViewBag.IsSaved = isSaved;
            ViewBag.SimilarJobs = relatedJobs;

            return View(job);
        }

        // POST: Ứng tuyển (Chọn CV + Thư xin việc)
        // Lưu ý: KHÔNG dùng [ValidateAntiForgeryToken] ở đây vì attribute này chạy
        // như một filter TRƯỚC khi vào try/catch bên dưới — nếu token lỗi, exception
        // sẽ rơi thẳng ra Developer Exception Page (trả về HTML) thay vì JSON, khiến
        // popup ứng tuyển hiện lỗi "Server trả về lỗi (mã 500)" và không parse được.
        // Validate token thủ công bên trong try để luôn trả JSON cho request AJAX.
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