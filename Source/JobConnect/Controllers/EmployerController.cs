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

    public EmployerController(AppDbContext db, IJobService jobSvc)
    {
        _db = db;
        _jobSvc = jobSvc;
    }

    private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private async Task<Employer?> GetEmployerAsync()
        => await _db.Employers.FirstOrDefaultAsync(e => e.UserID == UserId);

    // GET /Employer/Dashboard
    public async Task<IActionResult> Dashboard()
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return RedirectToAction("RegisterEmployer", "Account");

        var jobs = await _jobSvc.GetByEmployerAsync(emp.EmployerID);

        ViewBag.Employer = emp;
        ViewBag.JobCount = jobs.Count;
        ViewBag.AppCount = jobs.Sum(j => j.Applications.Count);
        ViewBag.OpenCount = jobs.Count(j => j.Status == "Open");
        return View(jobs);
    }

    // GET /Employer/PostJob
    public async Task<IActionResult> PostJob()
    {
        ViewBag.Categories = await _db.Categories.Where(c => c.Type == "Industry").ToListAsync();
        return View(new JobPost());
    }

    // POST /Employer/PostJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PostJob(JobPost model)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return NotFound();

        model.EmployerID = emp.EmployerID;
        await _jobSvc.CreateAsync(model);
        TempData["Success"] = "Tin tuyển dụng đã được gửi duyệt!";
        return RedirectToAction("Dashboard");
    }

    // GET /Employer/ManageApplications?jobId=5
    public async Task<IActionResult> ManageApplications(int jobId = 0)
    {
        if (jobId == 0) return RedirectToAction("Dashboard");

        var emp = await GetEmployerAsync();
        var job = await _db.JobPosts
            .Include(j => j.Employer)
            .FirstOrDefaultAsync(j => j.JobID == jobId && j.EmployerID == emp!.EmployerID);

        if (job == null) return NotFound();

        var apps = await _db.Applications
            .Include(a => a.CandidateProfile).ThenInclude(p => p.User)
            .Include(a => a.CvFile)
            .Where(a => a.JobID == jobId)
            .OrderByDescending(a => a.AppliedAt)
            .ToListAsync();

        ViewBag.Job = job;
        return View(apps);
    }

    // POST /Employer/UpdateApplicationStatus
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateApplicationStatus(int appId, string status, int jobId)
    {
        var app = await _db.Applications
            .Include(a => a.CandidateProfile)
            .FirstOrDefaultAsync(a => a.AppID == appId);

        if (app == null) return NotFound();

        app.Status = status;
        app.UpdatedAt = DateTime.Now;

        var job = await _db.JobPosts.FindAsync(app.JobID);
        _db.Notifications.Add(new Notification
        {
            UserID = app.CandidateProfile.UserID,
            Title = $"Đơn ứng tuyển \"{job?.Title}\" đã được cập nhật: {status}",
            Type = "Application",
            RelatedID = app.JobID
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
            JobID = job.JobID,
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
            .Where(c => c.Type == "Industry").ToListAsync(), "CategoryID", "Name", vm.CategoryID);
        return View(vm);
    }

    // POST /Employer/EditJob
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> EditJob(PostJobViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = new SelectList(await _db.Categories
                .Where(c => c.Type == "Industry").ToListAsync(), "CategoryID", "Name", model.CategoryID);
            return View(model);
        }
        var job = await _db.JobPosts.FindAsync(model.JobID);
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
    public async Task<IActionResult> CompanyProfile(Employer model)
    {
        var emp = await GetEmployerAsync();
        if (emp == null) return NotFound();

        emp.CompanyName = model.CompanyName;
        emp.TaxCode = model.TaxCode;
        emp.Industry = model.Industry;
        emp.CompanySize = model.CompanySize;
        emp.Address = model.Address;
        emp.Website = model.Website;
        emp.LogoURL = model.LogoURL;
        emp.CoverURL = model.CoverURL;
        emp.Description = model.Description;

        await _db.SaveChangesAsync();
        TempData["Success"] = "Cập nhật hồ sơ công ty thành công!";
        return RedirectToAction("CompanyProfile");
    }
}