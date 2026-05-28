using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class JobService : IJobService
{
    private readonly AppDbContext _db;
    public JobService(AppDbContext db) => _db = db;

    public async Task<List<JobPost>> SearchAsync(JobSearchViewModel f)
    {
        var q = _db.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Category)
            .Where(j => j.Status == "Open")
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(f.Keyword))
            q = q.Where(j => j.Title.Contains(f.Keyword) ||
                              (j.Description != null && j.Description.Contains(f.Keyword)));

        if (!string.IsNullOrWhiteSpace(f.Location))
            q = q.Where(j => j.Location != null && j.Location.Contains(f.Location));

        if (!string.IsNullOrWhiteSpace(f.JobType))
            q = q.Where(j => j.JobType == f.JobType);

        if (!string.IsNullOrWhiteSpace(f.ExperienceLevel))
            q = q.Where(j => j.ExperienceLevel == f.ExperienceLevel);

        if (f.SalaryMin.HasValue)
            q = q.Where(j => j.SalaryMax >= f.SalaryMin || j.SalaryNegotiable);

        q = f.SortBy switch
        {
            "newest" => q.OrderByDescending(j => j.CreatedAt),
            "salary" => q.OrderByDescending(j => j.SalaryMax),
            "popular" => q.OrderByDescending(j => j.ViewCount),
            _ => q.OrderByDescending(j => j.IsFeatured).ThenByDescending(j => j.CreatedAt)
        };

        return await q.Skip((f.Page - 1) * f.PageSize).Take(f.PageSize).ToListAsync();
    }

    public async Task<JobPost?> GetByIdAsync(int id)
    {
        var job = await _db.JobPosts
            .Include(j => j.Employer).ThenInclude(e => e.User)
            .Include(j => j.Category)
            .Include(j => j.Applications)
            .FirstOrDefaultAsync(j => j.JobID == id);

        if (job != null) { job.ViewCount++; await _db.SaveChangesAsync(); }
        return job;
    }

    public async Task<bool> HasAppliedAsync(int profileId, int jobId)
        => await _db.Applications.AnyAsync(a => a.ProfileID == profileId && a.JobID == jobId);

    public async Task<bool> ApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter)
    {
        if (await HasAppliedAsync(profileId, jobId)) return false;

        _db.Applications.Add(new Application
        {
            JobID = jobId,
            ProfileID = profileId,
            CVID = cvId,
            CoverLetter = coverLetter
        });
        await _db.SaveChangesAsync();

        // Thông báo cho nhà tuyển dụng
        var job = await _db.JobPosts.Include(j => j.Employer).FirstAsync(j => j.JobID == jobId);
        _db.Notifications.Add(new Notification
        {
            UserID = job.Employer.UserID,
            Title = $"Có ứng viên mới cho tin \"{job.Title}\"",
            Type = "Application",
            RelatedID = jobId
        });
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ToggleSaveAsync(int userId, int jobId)
    {
        var saved = await _db.SavedJobs.FirstOrDefaultAsync(s => s.UserID == userId && s.JobID == jobId);
        if (saved != null)
        {
            _db.SavedJobs.Remove(saved);
            await _db.SaveChangesAsync();
            return false;
        }
        _db.SavedJobs.Add(new SavedJob { UserID = userId, JobID = jobId });
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<List<JobPost>> GetByEmployerAsync(int employerId)
        => await _db.JobPosts
                    .Include(j => j.Applications)
                    .Where(j => j.EmployerID == employerId)
                    .OrderByDescending(j => j.CreatedAt)
                    .ToListAsync();

    public async Task<JobPost> CreateAsync(JobPost job)
    {
        job.Status = "Pending";
        job.CreatedAt = DateTime.Now;
        _db.JobPosts.Add(job);
        await _db.SaveChangesAsync();
        return job;
    }

    public async Task UpdateAsync(JobPost job)
    {
        job.UpdatedAt = DateTime.Now;
        _db.JobPosts.Update(job);
        await _db.SaveChangesAsync();
    }
}