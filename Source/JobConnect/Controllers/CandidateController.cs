using System.Security.Claims;
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers;

[Authorize(Roles = "Candidate")]
public class CandidateController : Controller
{
    private readonly AppDbContext _db;
    private readonly IFileService _fileService;

    public CandidateController(AppDbContext db, IFileService fileService)
    {
        _db = db;
        _fileService = fileService;
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
        var success = await _fileService.DeleteCvAsync(cvId, CurrentUserId);

        if (success)
            TempData["Success"] = "Xóa CV thành công!";
        else
            TempData["Error"] = "Không thể xóa CV.";

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
}