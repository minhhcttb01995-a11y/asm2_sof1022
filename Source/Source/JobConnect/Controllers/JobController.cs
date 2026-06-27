using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers
{
    public class JobController : Controller
    {
        private readonly IJobService _jobSvc;
        private readonly AppDbContext _db;

        public JobController(IJobService jobSvc, AppDbContext db)
        {
            _jobSvc = jobSvc;
            _db = db;
        }

        // GET: /Job
        public async Task<IActionResult> Index([FromQuery] JobSearchViewModel filter)
        {
            filter.Page = filter.Page < 1 ? 1 : filter.Page;
            filter.PageSize = 12;

            var jobs = await _jobSvc.SearchAsync(filter);

            // Get total count of ALL filtered results (not just this page)
            var totalCount = await _jobSvc.GetFilteredCountAsync(filter);

            ViewBag.Filter = filter;
            ViewBag.TotalCount = totalCount;
            ViewBag.TotalPages = (int)Math.Ceiling(totalCount / (double)filter.PageSize);

            ViewBag.Industries = await _db.Categories
                .Where(c => c.Type == "Industry")
                .ToListAsync();

            ViewBag.Locations = await _db.Categories
                .Where(c => c.Type == "Location")
                .ToListAsync();

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
                int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

                var profile = await _db.CandidateProfiles
                    .FirstOrDefaultAsync(p => p.UserID == userId);

                if (profile != null)
                {
                    profileId = profile.ProfileID;
                    hasApplied = await _jobSvc.HasAppliedAsync(profile.ProfileID, id);

                    // Load danh sách CV của candidate
                    var cvs = await _db.CvFiles
                        .Where(c => c.ProfileID == profile.ProfileID)
                        .OrderByDescending(c => c.UploadedAt)
                        .ToListAsync();

                    ViewBag.CVs = cvs;
                    ViewBag.DefaultCV = cvs.FirstOrDefault(c => c.IsDefault);
                }

                isSaved = await _db.SavedJobs
                    .AnyAsync(s => s.UserID == userId && s.JobID == id);
            }

            var relatedJobs = await _db.JobPosts
                .Include(j => j.Employer)
                .Where(j => j.Status == "Open" && j.EmployerID == job.EmployerID && j.JobID != id)
                .Take(4)
                .ToListAsync();

            ViewBag.HasApplied = hasApplied;
            ViewBag.IsSaved = isSaved;
            ViewBag.SimilarJobs = relatedJobs;

            return View(job);
        }

        // POST: Ứng tuyển (Chọn CV + Thư xin việc)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Apply(int jobId, int cvId, string? coverLetter)
        {
            if (User.Identity?.IsAuthenticated != true)
                return RedirectToAction("Login", "Account", new { returnUrl = $"/Job/Detail/{jobId}" });

            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var profile = await _db.CandidateProfiles
                .FirstOrDefaultAsync(p => p.UserID == userId);

            if (profile == null)
            {
                TempData["Error"] = "Bạn cần tạo hồ sơ ứng viên trước khi ứng tuyển.";
                return RedirectToAction("Detail", new { id = jobId });
            }

            // Kiểm tra CV hợp lệ
            var cv = await _db.CvFiles
                .FirstOrDefaultAsync(c => c.CvID == cvId && c.ProfileID == profile.ProfileID);

            if (cv == null)
            {
                TempData["Error"] = "CV không hợp lệ!";
                return RedirectToAction("Detail", new { id = jobId });
            }

            // Gọi service để ứng tuyển
            bool result = await _jobSvc.ToggleApplyAsync(jobId, profile.ProfileID, cvId, coverLetter);

            if (result)
                TempData["Success"] = "Ứng tuyển thành công! Nhà tuyển dụng sẽ xem hồ sơ của bạn sớm nhất.";
            else
                TempData["Error"] = "Có lỗi xảy ra khi gửi đơn ứng tuyển.";

            return RedirectToAction("Detail", new { id = jobId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleSave(int jobId)
        {
            if (User.Identity?.IsAuthenticated != true)
                return RedirectToAction("Login", "Account", new { returnUrl = $"/Job/Detail/{jobId}" });

            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            await _jobSvc.ToggleSaveAsync(userId, jobId);

            return RedirectToAction("Detail", new { id = jobId });
        }
    }
}