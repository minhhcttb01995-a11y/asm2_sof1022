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
    private readonly IFileService _fileSvc;

    public CandidateController(AppDbContext db, IFileService fileSvc)
    {
        _db = db;
        _fileSvc = fileSvc;
    }

    private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    #region Profile
    [Route("Candidate/Profile")]
    public async Task<IActionResult> Profile()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        if (profile != null)
        {
            profile.CvFiles = await _db.CvFiles
                .Where(c => c.ProfileID == profile.ProfileID)
                .ToListAsync();
        }

        return View(profile ?? new Models.CandidateProfile());
    }

    [Route("Candidate/CvManager")]
    public async Task<IActionResult> CvManager()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        // Nếu lỗi vẫn xảy ra, thử load riêng
        if (profile != null)
        {
            profile.CvFiles = await _db.CvFiles
                .Where(c => c.ProfileID == profile.ProfileID)
                .ToListAsync();
        }

        return View(profile ?? new Models.CandidateProfile());
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/UpdateProfile")]
    public async Task<IActionResult> UpdateProfile(string? summary, string? address,
        int? experienceYears, decimal? desiredSalary, bool isOpenToWork, IFormFile? avatarFile)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        // If profile does not exist, create it so user can save profile and then upload CV
        if (profile == null)
        {
            profile = new Models.CandidateProfile
            {
                UserID = UserId,
                Summary = summary,
                Address = address,
                ExperienceYears = experienceYears ?? 0,
                DesiredSalary = desiredSalary,
                IsOpenToWork = isOpenToWork
            };
            _db.CandidateProfiles.Add(profile);
            // Ensure user navigation is loaded/created
            var user = await _db.Users.FindAsync(UserId);
            if (user != null)
            {
                profile.User = user;
            }
        }
        else
        {
            profile.Summary = summary;
            profile.Address = address;
            profile.ExperienceYears = experienceYears ?? 0;
            profile.DesiredSalary = desiredSalary;
            profile.IsOpenToWork = isOpenToWork;
        }

        if (avatarFile != null && avatarFile.Length > 0)
        {
            // make sure user exists
            if (profile.User == null)
            {
                profile.User = await _db.Users.FindAsync(UserId) ?? new User { UserID = UserId };
            }
            profile.User.AvatarURL = await _fileSvc.SaveAvatarAsync(avatarFile, UserId);
            profile.User.UpdatedAt = DateTime.Now;
        }

        await _db.SaveChangesAsync();
        TempData["Success"] = "Cập nhật hồ sơ thành công!";
        return RedirectToAction("Profile");
    }

    [HttpPost, ValidateAntiForgeryToken]
    [Route("Candidate/UploadCv")]
    public async Task<IActionResult> UploadCv(IFormFile cvFile)
    {
        if (cvFile == null || cvFile.Length == 0)
        {
            TempData["Error"] = "Vui lòng chọn file CV.";
            return RedirectToAction("Profile");
        }

        var ext = Path.GetExtension(cvFile.FileName).ToLower();
        if (ext != ".pdf" && ext != ".docx")
        {
            TempData["Error"] = "Chỉ chấp nhận file PDF hoặc DOCX.";
            return RedirectToAction("CvManager");
        }

        if (cvFile.Length > 5 * 1024 * 1024)
        {
            TempData["Error"] = "File tối đa 5MB.";
            return RedirectToAction("CvManager");
        }

        try
        {
            var profile = await _db.CandidateProfiles
                .FirstOrDefaultAsync(p => p.UserID == UserId);

            // If profile does not exist, create an empty one to attach CV
            if (profile == null)
            {
                profile = new Models.CandidateProfile
                {
                    UserID = UserId,
                    Summary = string.Empty,
                    Address = string.Empty,
                    ExperienceYears = 0,
                    IsOpenToWork = true
                };
                _db.CandidateProfiles.Add(profile);
                await _db.SaveChangesAsync(); // need ProfileID
            }

            var filePath = await _fileSvc.SaveCvAsync(cvFile, profile.ProfileID);

            var isFirstCv = !await _db.CvFiles.AnyAsync(c => c.ProfileID == profile.ProfileID);

            var newCv = new Models.CvFile
            {
                ProfileID = profile.ProfileID,
                FileName = cvFile.FileName,
                FilePath = filePath,
                FileSize = (int)cvFile.Length,
                IsDefault = isFirstCv,
                UploadedAt = DateTime.Now
            };

            _db.CvFiles.Add(newCv);
            await _db.SaveChangesAsync();
            TempData["Success"] = "Upload CV thành công!";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Lỗi upload CV: {ex.Message}";
        }

        return RedirectToAction("CvManager");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Route("Candidate/DeleteCv")]
    public async Task<IActionResult> DeleteCv(int cvId)
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        if (profile == null)
        {
            TempData["Error"] = "Không tìm thấy hồ sơ.";
            return RedirectToAction("CvManager");
        }

        var selectedCv = await _db.CvFiles.FindAsync(cvId);
        if (selectedCv == null || selectedCv.ProfileID != profile.ProfileID)
        {
            TempData["Error"] = "CV không tồn tại hoặc không thuộc về bạn.";
            return RedirectToAction("CvManager");
        }

        try
        {
            // Delete physical file
            _fileSvc.Delete(selectedCv.FilePath);

            // Remove DB record
            _db.CvFiles.Remove(selectedCv);

            // If deleted CV was default, pick another as default (if any)
            if (selectedCv.IsDefault)
            {
                var another = await _db.CvFiles
                    .Where(c => c.ProfileID == profile.ProfileID && c.CvFileID != cvId)
                    .OrderByDescending(c => c.UploadedAt)
                    .FirstOrDefaultAsync();

                if (another != null)
                    another.IsDefault = true;
            }

            await _db.SaveChangesAsync();
            TempData["Success"] = "Xóa CV thành công.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Lỗi khi xóa CV: {ex.Message}";
        }

        return RedirectToAction("CvManager");
    }
    #endregion

    #region Applications
    [Route("Candidate/Applications")]
    public async Task<IActionResult> Applications()
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        if (profile == null)
            return View(new List<Models.Application>());

        var applications = await _db.Applications
            .Include(a => a.JobPost).ThenInclude(j => j.Employer)
            .Where(a => a.ProfileID == profile.ProfileID)
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        return View(applications);
    }
    #endregion

    #region Saved Jobs
    [Route("Candidate/SavedJobs")]
    public async Task<IActionResult> SavedJobs()
    {
        var saved = await _db.SavedJobs
            .Include(s => s.JobPost).ThenInclude(j => j.Employer)
            .Where(s => s.UserID == UserId)
            .OrderByDescending(s => s.SavedAt)
            .ToListAsync();

        return View(saved);
    }
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Route("Candidate/SetDefaultCv")]
    public async Task<IActionResult> SetDefaultCv(int cvId)
    {
        var profile = await _db.CandidateProfiles
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        if (profile == null)
        {
            TempData["Error"] = "Không tìm thấy hồ sơ.";
            return RedirectToAction("CvManager");
        }

        // Reset all CVs to not default
        var allCvs = await _db.CvFiles.Where(c => c.ProfileID == profile.ProfileID).ToListAsync();
        foreach (var cv in allCvs)
        {
            cv.IsDefault = false;
        }

        // Set selected CV as default
        var selectedCv = await _db.CvFiles.FindAsync(cvId);
        if (selectedCv != null && selectedCv.ProfileID == profile.ProfileID)
        {
            selectedCv.IsDefault = true;
            await _db.SaveChangesAsync();
            TempData["Success"] = "Đã đặt CV mặc định thành công!";
        }
        else
        {
            TempData["Error"] = "CV không tồn tại.";
        }

        return RedirectToAction("CvManager");
    }
    #endregion
}