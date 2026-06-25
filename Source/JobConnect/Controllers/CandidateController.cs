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

    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    #region Profile & CV Manager

    [Route("Candidate/Profile")]
    public async Task<IActionResult> Profile()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserID == CurrentUserId);

        return View(profile ?? new CandidateProfile());
    }

    [Route("Candidate/CvManager")]
    public async Task<IActionResult> CvManager()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserID == CurrentUserId);

        if (profile == null)
        {
            // Tạo profile trống nếu chưa có
            profile = new CandidateProfile
            {
                UserID = CurrentUserId
            };
        }

        return View(profile);
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/UpdateProfile")]
    public async Task<IActionResult> UpdateProfile(string? summary, string? address,
        int? experienceYears, decimal? desiredSalary, bool isOpenToWork, IFormFile? avatarFile)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.UserID == CurrentUserId);

        if (profile == null)
        {
            profile = new CandidateProfile { UserID = CurrentUserId };
            _db.CandidateProfiles.Add(profile);
        }

        profile.Summary = summary;
        profile.Address = address;
        profile.ExperienceYears = experienceYears ?? 0;
        profile.DesiredSalary = desiredSalary;
        profile.IsOpenToWork = isOpenToWork;

        if (avatarFile != null && avatarFile.Length > 0)
        {
            // TODO: Implement SaveAvatarAsync in FileService if needed
            // profile.User.AvatarURL = await _fileService.SaveAvatarAsync(avatarFile, CurrentUserId);
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
                .FirstOrDefaultAsync(p => p.UserID == CurrentUserId);

            if (profile == null)
            {
                profile = new CandidateProfile { UserID = CurrentUserId };
                _db.CandidateProfiles.Add(profile);
                await _db.SaveChangesAsync();
            }

            var uploadedCv = await _fileService.UploadCvAsync(cvFile, profile.ProfileID);

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
            .FirstOrDefaultAsync(p => p.UserID == CurrentUserId);

        if (profile == null)
            return View(new List<Application>());

        var applications = await _db.Applications
            .Include(a => a.Job).ThenInclude(j => j.Employer)
            .Where(a => a.ProfileID == profile.ProfileID)
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        return View(applications);
    }

    [Route("Candidate/SavedJobs")]
    public async Task<IActionResult> SavedJobs()
    {
        var saved = await _db.SavedJobs
            .Include(s => s.JobPost).ThenInclude(j => j.Employer)
            .Where(s => s.UserID == CurrentUserId)
            .OrderByDescending(s => s.SavedAt)
            .ToListAsync();

        return View(saved);
    }

    #endregion
}