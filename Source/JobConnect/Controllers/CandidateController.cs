// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// CandidateController — [Authorize(Roles = "Candidate")]: TRANG CÁ NHÂN CỦA ỨNG VIÊN
// sau khi đăng nhập (khác với JobController là trang public tìm việc):
//   • Profile/UpdateProfile: xem/sửa hồ sơ cá nhân.
//   • CvManager/UploadCv/SetDefaultCv/DeleteCv: quản lý các file CV đã tải lên.
//   • Applications: xem danh sách đơn đã ứng tuyển + trạng thái xử lý.
//   • SavedJobs/FollowedCompanies: tin đã lưu + công ty đang theo dõi.
//   • Skills/AddSkill/RemoveSkill: quản lý danh sách kỹ năng trong hồ sơ.
//   • Notifications/MarkRead: thông báo cá nhân.
//   • AiCvBuilder: tính năng AI hỗ trợ sinh nội dung CV (dùng IGeminiService).
// Chú ý: các action đều dùng [Route("Candidate/...")] tường minh thay vì route mặc định.
// ═══════════════════════════════════════════════════════════════════════════
using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

[Authorize(Roles = "Candidate")]
public class CandidateController : Controller
{
    private readonly AppDbContext _db;
    private readonly IFileService _fileService;
    private readonly IGeminiService _aiService;
    private readonly IWebHostEnvironment _env;
    private readonly ICvTextExtractionService _cvTextExtractor;

    public CandidateController(AppDbContext db, IFileService fileService, IGeminiService aiService, IWebHostEnvironment env, ICvTextExtractionService cvTextExtractor)
    {
        _db = db;
        _fileService = fileService;
        _aiService = aiService;
        _env = env;
        _cvTextExtractor = cvTextExtractor;
    }

    private int CurrentUserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    #region Profile & CV Manager

    [Route("Candidate/Profile")]
    public async Task<IActionResult> Profile()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        return View(profile ?? new CandidateProfile());
    }

    [Route("Candidate/CvManager")]
    public async Task<IActionResult> CvManager()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        if (profile == null)
        {
            // Tạo profile trống nếu chưa có
            profile = new CandidateProfile
            {
                UserId = CurrentUserId
            };
        }

        return View(profile);
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/UpdateProfile")]
    public async Task<IActionResult> UpdateProfile(
        string? fullName,
        string? jobTitle,
        string? phone,
        string? gender,
        DateTime? dateOfBirth,
        string? summary,
        string? address,
        int? experienceYears,
        decimal? desiredSalary,
        bool isOpenToWork,
        IFormFile? avatarFile)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        if (profile == null)
        {
            profile = new CandidateProfile { UserId = CurrentUserId };
            _db.CandidateProfiles.Add(profile);
        }

        // ── Thông tin cá nhân ──
        if (!string.IsNullOrWhiteSpace(fullName))
        {
            profile.FullName = fullName.Trim();
            if (profile.User != null)
                profile.User.FullName = fullName.Trim();   // đồng bộ lên bảng Users
        }

        if (!string.IsNullOrWhiteSpace(phone))
        {
            profile.Phone = phone.Trim();
            if (profile.User != null)
                profile.User.PhoneNumber = phone.Trim();   // đồng bộ lên bảng Users
        }

        profile.Gender = gender;
        profile.DateOfBirth = dateOfBirth;
        profile.Address = address;
        profile.JobTitle = jobTitle?.Trim();

        // ── Thông tin nghề nghiệp ──
        profile.Summary = summary;
        profile.ExperienceYears = experienceYears ?? 0;
        profile.DesiredSalary = desiredSalary;
        profile.IsOpenToWork = isOpenToWork;

        if (avatarFile != null && avatarFile.Length > 0)
        {
            await _fileService.SaveAvatarAsync(avatarFile, CurrentUserId);
        }

        await _db.SaveChangesAsync();

        // [ĐÃ SỬA] Sau khi cập nhật hồ sơ (đặc biệt là ảnh đại diện), claim "AvatarURL"
        // trong cookie đăng nhập vẫn đang giữ giá trị CŨ (được set từ lúc Login), nên
        // header (Layout) không tự nhận ảnh mới cho tới khi đăng nhập lại. Ở đây ta
        // đọc lại User mới nhất từ DB rồi re-sign-in để làm mới claim ngay lập tức.
        var currentUser = profile.User ?? await _db.Users.FindAsync(CurrentUserId);
        if (currentUser != null)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, currentUser.UserId.ToString()),
                new Claim(ClaimTypes.Name, currentUser.FullName ?? currentUser.Email),
                new Claim(ClaimTypes.Email, currentUser.Email),
                new Claim(ClaimTypes.Role, currentUser.Role ?? "Candidate"),
                new Claim("AvatarURL", currentUser.AvatarUrl ?? "")
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
        }

        TempData["Success"] = "Cập nhật hồ sơ thành công!";
        return RedirectToAction("Profile");
    }

    #endregion

    #region CV Management

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/UploadCv")]
    public async Task<IActionResult> UploadCv(IFormFile cvFile)
    {
        if (cvFile == null || cvFile.Length == 0)
        {
            TempData["Error"] = "Vui lòng chọn file CV.";
            return RedirectToAction("CvManager");
        }

        var ext = Path.GetExtension(cvFile.FileName).ToLowerInvariant();
        if (ext != ".pdf" && ext != ".docx")
        {
            TempData["Error"] = "Chỉ chấp nhận file PDF hoặc DOCX.";
            return RedirectToAction("CvManager");
        }

        if (cvFile.Length > 5 * 1024 * 1024) // 5MB
        {
            TempData["Error"] = "File CV tối đa 5MB.";
            return RedirectToAction("CvManager");
        }

        try
        {
            var profile = await _db.CandidateProfiles
                .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

            if (profile == null)
            {
                profile = new CandidateProfile { UserId = CurrentUserId };
                _db.CandidateProfiles.Add(profile);
                await _db.SaveChangesAsync();
            }

            var uploadedCv = await _fileService.UploadCvAsync(cvFile, profile.ProfileId);

            TempData["Success"] = "Upload CV thành công!";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Lỗi upload CV: {ex.Message}";
        }

        return RedirectToAction("CvManager");
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/SetDefaultCv")]
    public async Task<IActionResult> SetDefaultCv(int cvId)
    {
        var success = await _fileService.SetDefaultCvAsync(cvId, CurrentUserId);

        if (success)
            TempData["Success"] = "Đặt CV mặc định thành công!";
        else
            TempData["Error"] = "Không thể đặt CV mặc định.";

        return RedirectToAction("CvManager");
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/DeleteCv")]
    public async Task<IActionResult> DeleteCv(int cvId)
    {
        var result = await _fileService.DeleteCvAsync(cvId, CurrentUserId);

        TempData[result == JobConnect.Services.CvDeleteResult.Success ? "Success" : "Error"] = result switch
        {
            JobConnect.Services.CvDeleteResult.Success => "Xóa CV thành công!",
            JobConnect.Services.CvDeleteResult.InUse => "Bạn đã dùng CV này để ứng tuyển nên không thể xóa. Hãy đặt CV khác làm mặc định nếu muốn dùng CV khác cho các đơn ứng tuyển mới.",
            _ => "Không thể xóa CV."
        };

        return RedirectToAction("CvManager");
    }

    #endregion

    #region Applications & Saved Jobs

    [Route("Candidate/Applications")]
    public async Task<IActionResult> Applications()
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        if (profile == null)
            return View(new List<Application>());

        var applications = await _db.Applications
            .Include(a => a.Job!).ThenInclude(j => j.Employer)
            .Where(a => a.ProfileId == profile.ProfileId)
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        return View(applications);
    }

    [Route("Candidate/SavedJobs")]
    public async Task<IActionResult> SavedJobs()
    {
        var saved = await _db.SavedJobs
            .Include(s => s.Job).ThenInclude(j => j.Employer)
            .Where(s => s.UserId == CurrentUserId)
            .OrderByDescending(s => s.SavedAt)
            .ToListAsync();

        return View(saved);
    }

    [Route("Candidate/FollowedCompanies")]
    public async Task<IActionResult> FollowedCompanies()
    {
        var followed = await _db.CompanyFollows
            .Include(f => f.Employer)
            .Where(f => f.UserId == CurrentUserId)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return View(followed);
    }

    #endregion

    #region Skills

    [Route("Candidate/Skills")]
    public async Task<IActionResult> Skills()
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        List<CandidateSkill> candidateSkills = new();
        if (profile != null)
        {
            candidateSkills = await _db.CandidateSkills
                .Include(cs => cs.Skill)
                .Where(cs => cs.ProfileId == profile.ProfileId)
                .OrderBy(cs => cs.Skill.Name)
                .ToListAsync();
        }

        var allSkills = await _db.Skills
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

        int completion = candidateSkills.Count >= 5 ? 100
            : (int)Math.Round(candidateSkills.Count / 5.0 * 100);

        ViewBag.CandidateSkills = candidateSkills;
        ViewBag.AvailableSkills = allSkills;
        ViewBag.ProfileCompletion = completion;

        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/AddSkill")]
    public async Task<IActionResult> AddSkill(int skillId, string proficiency, decimal yearsOfExp, DateTime? lastUsed)
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        if (profile == null)
        {
            TempData["Error"] = "Vui lòng tạo hồ sơ trước.";
            return RedirectToAction("Skills");
        }

        var exists = await _db.CandidateSkills
            .AnyAsync(cs => cs.ProfileId == profile.ProfileId && cs.SkillId == skillId);

        if (exists)
        {
            TempData["Error"] = "Bạn đã thêm kỹ năng này rồi.";
            return RedirectToAction("Skills");
        }

        if (!Enum.TryParse<ProficiencyLevel>(proficiency, out var level))
            level = ProficiencyLevel.Intermediate;

        _db.CandidateSkills.Add(new CandidateSkill
        {
            ProfileId = profile.ProfileId,
            SkillId = skillId,
            ProficiencyLevel = level,
            YearsOfExperience = yearsOfExp,
            LastUsedDate = lastUsed,
            CreatedAt = DateTime.Now
        });

        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã thêm kỹ năng thành công!";
        return RedirectToAction("Skills");
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/RemoveSkill")]
    public async Task<IActionResult> RemoveSkill(int skillId)
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        if (profile != null)
        {
            var cs = await _db.CandidateSkills
                .FirstOrDefaultAsync(x => x.ProfileId == profile.ProfileId && x.SkillId == skillId);

            if (cs != null)
            {
                _db.CandidateSkills.Remove(cs);
                await _db.SaveChangesAsync();
                TempData["Success"] = "Đã xóa kỹ năng.";
            }
        }

        return RedirectToAction("Skills");
    }

    #endregion

    #region Notifications

    [Route("Candidate/Notifications")]
    public async Task<IActionResult> Notifications()
    {
        var notifications = await _db.Notifications
            .Where(n => n.UserId == CurrentUserId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();

        // Mark all as read
        var unread = notifications.Where(n => !n.IsRead).ToList();
        if (unread.Any())
        {
            unread.ForEach(n => n.IsRead = true);
            await _db.SaveChangesAsync();
        }

        return View(notifications);
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/MarkRead")]
    public async Task<IActionResult> MarkRead(int notifId)
    {
        var notif = await _db.Notifications
            .FirstOrDefaultAsync(n => n.NotifId == notifId && n.UserId == CurrentUserId);

        if (notif != null)
        {
            notif.IsRead = true;
            await _db.SaveChangesAsync();
        }

        return RedirectToAction("Notifications");
    }

    #endregion

    #region AI - Tạo CV & Kiểm tra độ phù hợp

    [Route("Candidate/AiCvBuilder")]
    public async Task<IActionResult> AiCvBuilder()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.UserId == CurrentUserId);

        var model = new JobConnect.ViewModels.AiCvBuilderViewModel
        {
            FullName = profile?.FullName ?? profile?.User?.FullName ?? "",
            JobTitle = profile?.JobTitle ?? "",
            ExperienceYears = profile?.ExperienceYears ?? 0,
            Email = profile?.User?.Email,
            Phone = profile?.Phone ?? profile?.User?.PhoneNumber,
            Address = profile?.Address,
            PhotoUrl = profile?.Avatar
        };

        return View(model);
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/AiCvBuilder")]
    public async Task<IActionResult> AiCvBuilder(JobConnect.ViewModels.AiCvBuilderViewModel model)
    {
        // Lưu ảnh đại diện (nếu người dùng chọn ảnh mới) — chỉ dùng để hiển thị trên CV,
        // không ghi đè avatar chính của tài khoản.
        if (model.PhotoFile != null && model.PhotoFile.Length > 0)
        {
            var ext = Path.GetExtension(model.PhotoFile.FileName).ToLowerInvariant();
            var allowedExts = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (allowedExts.Contains(ext) && model.PhotoFile.Length <= 3 * 1024 * 1024)
            {
                var fileName = $"cv_{CurrentUserId}_{Guid.NewGuid()}{ext}";
                var relativePath = Path.Combine("uploads/cv-photos", fileName).Replace("\\", "/");
                var fullPath = Path.Combine(_env.WebRootPath, relativePath);
                Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);
                using (var stream = new FileStream(fullPath, FileMode.Create))
                {
                    await model.PhotoFile.CopyToAsync(stream);
                }
                model.PhotoUrl = "/" + relativePath;
            }
        }

        var request = new AiCvRequest
        {
            FullName = model.FullName,
            JobTitle = model.JobTitle,
            ExperienceYears = model.ExperienceYears,
            Skills = model.Skills,
            Education = model.Education,
            WorkHistory = model.WorkHistory,
            Achievements = model.Achievements,
            Languages = model.Languages
        };

        var result = await _aiService.GenerateCvAsync(request);

        // References KHÔNG qua AI (tránh AI bịa thông tin người tham chiếu thật) — chỉ tách dòng người dùng nhập.
        model.ReferenceLines = (model.References ?? "")
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();

        if (!result.Success)
        {
            model.ErrorMessage = result.Error;
        }
        else
        {
            model.Result = result;
        }

        return View(model);
    }

    #endregion
}