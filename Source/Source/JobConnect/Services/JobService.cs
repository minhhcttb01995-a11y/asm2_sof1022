using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class JobService : IJobService
{
    private readonly AppDbContext _db;
    private readonly IFileService _fileSvc;

    public JobService(AppDbContext db, IFileService fileSvc)
    {
        _db = db;
        _fileSvc = fileSvc;
    }

    public async Task<List<JobPost>> SearchAsync(JobSearchViewModel f)
    {
        var q = _db.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Category)
            .Where(j => j.Status == "Open")
            .AsQueryable();

        // Xử lý thanh tìm kiếm chung (Keyword)
        if (!string.IsNullOrWhiteSpace(f.Keyword))
        {
            var keyword = f.Keyword.Trim();

            // Danh sách từ khóa địa điểm để tách biệt logic quét dữ liệu
            var locationKeywords = new[] { "hà nội", "ha noi", "hồ chí minh", "ho chi minh", "hcm", "đà nẵng", "da nang", "hải phòng", "hai phong", "cần thơ", "can tho" };

            if (locationKeywords.Any(loc => keyword.Equals(loc, StringComparison.OrdinalIgnoreCase)))
            {
                // Nếu gõ địa điểm -> CHỈ tìm kiếm đích danh trong cột Location của JobPost
                q = q.Where(j => j.Location != null && j.Location.Contains(keyword));
            }
            else
            {
                // Nếu gõ từ khóa khác -> Tìm theo Tiêu đề, Mô tả, Tên công ty
                q = q.Where(j => j.Title.Contains(keyword) ||
                                 (j.Description != null && j.Description.Contains(keyword)) ||
                                 (j.Employer != null && j.Employer.CompanyName.Contains(keyword)));
            }
        }

        // Bộ lọc Địa điểm độc lập (Dành cho Combobox ở Sidebar bên trái)
        if (!string.IsNullOrWhiteSpace(f.Location))
        {
            var location = f.Location.Trim();
            q = q.Where(j => j.Location != null && j.Location.Contains(location));
        }

        // Handle multiple job types
        if (f.JobType != null && f.JobType.Length > 0)
            q = q.Where(j => f.JobType.Contains(j.JobType));

        if (!string.IsNullOrWhiteSpace(f.ExperienceLevel))
            q = q.Where(j => j.ExperienceLevel == f.ExperienceLevel);

        // Handle multiple salary ranges using OR conditions
        if (f.Salary != null && f.Salary.Length > 0)
        {
            bool hasSalary10 = f.Salary.Contains("<10");
            bool hasSalary1020 = f.Salary.Contains("10-20");
            bool hasSalary2050 = f.Salary.Contains("20-50");
            bool hasSalary50 = f.Salary.Contains(">50");

            q = q.Where(j => 
                (hasSalary10 && (j.SalaryMax < 10000000 || j.SalaryNegotiable == true)) ||
                (hasSalary1020 && ((j.SalaryMin >= 10000000 && j.SalaryMax <= 20000000) || j.SalaryNegotiable == true)) ||
                (hasSalary2050 && ((j.SalaryMin >= 20000000 && j.SalaryMax <= 50000000) || j.SalaryNegotiable == true)) ||
                (hasSalary50 && (j.SalaryMin >= 50000000 || j.SalaryNegotiable == true))
            );
        }

        // Handle multiple categories
        if (f.Category != null && f.Category.Length > 0)
        {
            var categoryIds = f.Category.ToList();
            q = q.Where(j => j.CategoryID.HasValue && categoryIds.Contains(j.CategoryID.Value));
        }

        q = f.SortBy switch
        {
            "newest" => q.OrderByDescending(j => j.CreatedAt),
            "salary" => q.OrderByDescending(j => j.SalaryMax),
            "popular" => q.OrderByDescending(j => j.ViewCount),
            _ => q.OrderByDescending(j => j.IsFeatured).ThenByDescending(j => j.CreatedAt)
        };

        return await q.Skip((f.Page - 1) * f.PageSize).Take(f.PageSize).ToListAsync();
    }

    public async Task<int> GetFilteredCountAsync(JobSearchViewModel f)
    {
        var q = _db.JobPosts
            .Include(j => j.Employer)
            .Where(j => j.Status == "Open")
            .AsQueryable();

        // Đồng bộ logic đếm số lượng với hàm SearchAsync ở trên
        if (!string.IsNullOrWhiteSpace(f.Keyword))
        {
            var keyword = f.Keyword.Trim();
            var locationKeywords = new[] { "hà nội", "ha noi", "hồ chí minh", "ho chi minh", "hcm", "đà nẵng", "da nang", "hải phòng", "hai phong", "cần thơ", "can tho" };

            if (locationKeywords.Any(loc => keyword.Equals(loc, StringComparison.OrdinalIgnoreCase)))
            {
                q = q.Where(j => j.Location != null && j.Location.Contains(keyword));
            }
            else
            {
                q = q.Where(j => j.Title.Contains(keyword) ||
                                 (j.Description != null && j.Description.Contains(keyword)) ||
                                 (j.Employer != null && j.Employer.CompanyName.Contains(keyword)));
            }
        }

        if (!string.IsNullOrWhiteSpace(f.Location))
        {
            var location = f.Location.Trim();
            q = q.Where(j => j.Location != null && j.Location.Contains(location));
        }

        // Handle multiple job types
        if (f.JobType != null && f.JobType.Length > 0)
            q = q.Where(j => f.JobType.Contains(j.JobType));

        if (!string.IsNullOrWhiteSpace(f.ExperienceLevel))
            q = q.Where(j => j.ExperienceLevel == f.ExperienceLevel);

        // Handle multiple salary ranges using OR conditions
        if (f.Salary != null && f.Salary.Length > 0)
        {
            bool hasSalary10 = f.Salary.Contains("<10");
            bool hasSalary1020 = f.Salary.Contains("10-20");
            bool hasSalary2050 = f.Salary.Contains("20-50");
            bool hasSalary50 = f.Salary.Contains(">50");

            q = q.Where(j => 
                (hasSalary10 && (j.SalaryMax < 10000000 || j.SalaryNegotiable == true)) ||
                (hasSalary1020 && ((j.SalaryMin >= 10000000 && j.SalaryMax <= 20000000) || j.SalaryNegotiable == true)) ||
                (hasSalary2050 && ((j.SalaryMin >= 20000000 && j.SalaryMax <= 50000000) || j.SalaryNegotiable == true)) ||
                (hasSalary50 && (j.SalaryMin >= 50000000 || j.SalaryNegotiable == true))
            );
        }

        // Handle multiple categories
        if (f.Category != null && f.Category.Length > 0)
        {
            var categoryIds = f.Category.ToList();
            q = q.Where(j => j.CategoryID.HasValue && categoryIds.Contains(j.CategoryID.Value));
        }

        return await q.CountAsync();
    }

    public async Task<bool> ToggleApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter)
    {
        var existing = await _db.Applications.FirstOrDefaultAsync(a => a.ProfileID == profileId && a.JobID == jobId && a.Status != "Rejected");
        if (existing != null)
        {
            _db.Applications.Remove(existing);
            await _db.SaveChangesAsync();
            return false;
        }

        var rejectedApp = await _db.Applications
            .FirstOrDefaultAsync(a => a.ProfileID == profileId && a.JobID == jobId && a.Status == "Rejected");
        if (rejectedApp != null)
        {
            _db.Applications.Remove(rejectedApp);
        }

        _db.Applications.Add(new Application
        {
            JobID = jobId,
            ProfileID = profileId,
            CVID = cvId,
            CoverLetter = coverLetter,
            AppliedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();

        var job = await _db.JobPosts.Include(j => j.Employer).FirstAsync(j => j.JobID == jobId);
        _db.Notifications.Add(new Notification
        {
            UserID = job.Employer?.UserID ?? 0,
            Title = $"Có ứng viên mới cho tin \"{job.Title}\"",
            Type = "Application",
            RelatedID = jobId,
            CreatedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<JobPost?> GetByIdAsync(int id)
    {
        var job = await _db.JobPosts
            .Include(j => j.Employer).ThenInclude(e => e.User)
            .Include(j => j.Category)
            .Include(j => j.Applications)
            .FirstOrDefaultAsync(j => j.JobID == id);

        if (job != null)
        {
            job.ViewCount++;
            await _db.SaveChangesAsync();
        }
        return job;
    }

    public async Task<bool> HasAppliedAsync(int profileId, int jobId)
        => await _db.Applications.AnyAsync(a => a.ProfileID == profileId && a.JobID == jobId && a.Status != "Rejected");

    public async Task<bool> ApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter)
    {
        if (await HasAppliedAsync(profileId, jobId)) return false;

        var rejectedApp = await _db.Applications
            .FirstOrDefaultAsync(a => a.ProfileID == profileId && a.JobID == jobId && a.Status == "Rejected");
        if (rejectedApp != null)
        {
            _db.Applications.Remove(rejectedApp);
        }

        _db.Applications.Add(new Application
        {
            JobID = jobId,
            ProfileID = profileId,
            CVID = cvId,
            CoverLetter = coverLetter,
            AppliedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();

        var job = await _db.JobPosts.Include(j => j.Employer).FirstAsync(j => j.JobID == jobId);
        _db.Notifications.Add(new Notification
        {
            UserID = job.Employer?.UserID ?? 0,
            Title = $"Có ứng viên mới cho tin \"{job.Title}\"",
            Type = "Application",
            RelatedID = jobId,
            CreatedAt = DateTime.Now
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

    public async Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder)
    {
        return await _fileSvc.SaveImageFromDataUriAsync(dataUri, relativeFolder);
    }
}