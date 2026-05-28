using System.Security.Claims;
using JobConnect.Data;
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

    // GET /Candidate/Profile
    public async Task<IActionResult> Profile()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CvFiles)
            .Include(p => p.CandidateSkills).ThenInclude(cs => cs.Skill)
            .FirstOrDefaultAsync(p => p.UserID == UserId);
        return View(profile);
    }

    // POST /Candidate/UpdateProfile
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProfile(string? summary, string? address,
        int? experienceYears, decimal? desiredSalary, bool isOpenToWork, IFormFile? avatarFile)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.UserID == UserId);

        if (profile == null) return NotFound();

        profile.Summary = summary;
        profile.Address = address;
        profile.ExperienceYears = experienceYears ?? 0;
        profile.DesiredSalary = desiredSalary;
        profile.IsOpenToWork = isOpenToWork;

        if (avatarFile != null && avatarFile.Length > 0)
        {
            profile.User.AvatarURL = await _fileSvc.SaveAvatarAsync(avatarFile, UserId);
            profile.User.UpdatedAt = DateTime.Now;
        }

        await _db.SaveChangesAsync();
        TempData["Success"] = "Cập nhật hồ sơ thành công!";
        return RedirectToAction("Profile");
    }

    // GET /Candidate/CvManager
    public async Task<IActionResult> CvManager()
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.CvFiles)
            .FirstOrDefaultAsync(p => p.UserID == UserId);
        return View(profile);
    }

    // POST /Candidate/UploadCv
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UploadCv(IFormFile cvFile)
    {
        if (cvFile == null || cvFile.Length == 0)
        { TempData["Error"] = "Vui lòng chọn file CV."; return RedirectToAction("CvManager"); }

        var ext = Path.GetExtension(cvFile.FileName).ToLower();
        if (ext != ".pdf" && ext != ".docx")
        { TempData["Error"] = "Chỉ chấp nhận file PDF hoặc DOCX."; return RedirectToAction("CvManager"); }

        if (cvFile.Length > 5 * 1024 * 1024)
        { TempData["Error"] = "File quá 5MB."; return RedirectToAction("CvManager"); }

        var profile = await _db.CandidateProfiles.FirstOrDefaultAsync(p => p.UserID == UserId);
        if (profile == null) return NotFound();

        var path = await _fileSvc.SaveCvAsync(cvFile, profile.ProfileID);
        _db.CvFiles.Add(new Models.CvFile
        {
            ProfileID = profile.ProfileID,
            FileName = cvFile.FileName,
            FilePath = path,
            FileSize = (int)cvFile.Length,
            IsDefault = !(await _db.CvFiles.AnyAsync(c => c.ProfileID == profile.ProfileID))
        });
        await _db.SaveChangesAsync();
        TempData["Success"] = "Upload CV thành công!";
        return RedirectToAction("CvManager");
    }

    // GET /Candidate/SavedJobs
    public async Task<IActionResult> SavedJobs()
    {
        var saved = await _db.SavedJobs
            .Include(s => s.JobPost).ThenInclude(j => j.Employer)
            .Where(s => s.UserID == UserId)
            .OrderByDescending(s => s.SavedAt)
            .ToListAsync();
        return View(saved);
    }

    // GET /Candidate/Applications
    public async Task<IActionResult> Applications()
    {
        var profile = await _db.CandidateProfiles.FirstOrDefaultAsync(p => p.UserID == UserId);
        if (profile == null) return View(new List<Models.Application>());

        var apps = await _db.Applications
            .Include(a => a.JobPost).ThenInclude(j => j.Employer)
            .Where(a => a.ProfileID == profile.ProfileID)
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();
        return View(apps);
    }
}