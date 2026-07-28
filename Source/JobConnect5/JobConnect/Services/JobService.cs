// [[SERVICE-IMPL-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// JobService — cài đặt IJobService: TOÀN BỘ NGHIỆP VỤ liên quan TIN TUYỂN DỤNG,
// đây là service lớn và quan trọng nhất của hệ thống (dùng bởi JobController,
// EmployerController, HomeController...). Các nhóm chức năng chính:
//   • SearchAsync: tìm kiếm/lọc tin theo từ khóa, danh mục, loại hình, mức lương...
//     CHỈ trả về tin có Status + Employer.Status nằm trong danh sách "hiển thị công
//     khai" (tra qua IStatusCatalogService) — tránh lộ tin của công ty bị khóa/chưa duyệt.
//   • GetByIdAsync: lấy chi tiết 1 tin (kèm Employer, Category) để hiển thị trang chi tiết.
//   • ApplyAsync / ToggleApplyAsync: ứng viên nộp đơn ứng tuyển; Toggle cho phép
//     bấm nút 1 lần nữa để RÚT ĐƠN đã nộp trước đó (xem enum ApplyToggleResult).
//   • ToggleSaveAsync: lưu/bỏ lưu tin yêu thích (SavedJob).
//   • GetByEmployerAsync / CreateAsync / UpdateAsync: nhà tuyển dụng xem danh sách
//     tin đã đăng, đăng tin mới (tự sinh JobCode qua ICodeGeneratorService), sửa tin.
//   • SaveImageFromDataUriAsync: ủy quyền (delegate) qua IFileService để lưu ảnh minh họa tin.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Helpers;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class JobService : IJobService
{
    private readonly AppDbContext _db;
    private readonly IFileService _fileSvc;
    private readonly IStatusCatalogService _statusSvc;
    private readonly ICodeGeneratorService _codeGen;

    public JobService(AppDbContext db, IFileService fileSvc, IStatusCatalogService statusSvc, ICodeGeneratorService codeGen)
    {
        _db = db;
        _fileSvc = fileSvc;
        _statusSvc = statusSvc;
        _codeGen = codeGen;
    }

    public async Task<(List<JobPost> Items, int TotalCount)> SearchAsync(JobSearchViewModel f)
    {
        var visibleJobStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.JobPost);
        var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);

        var q = _db.JobPosts
            .Include(j => j.Employer)
            .Include(j => j.Category)
            // [FIX] Trước đây chỉ kiểm tra Employer.Status có nằm trong danh sách "hiển thị công
            // khai" hay không, nhưng KHÔNG kiểm tra Employer.IsLocked. Vì thao tác "Khóa công ty"
            // (LockCompany) chỉ đổi cờ IsLocked chứ không đổi Status, nên tin tuyển dụng của công
            // ty đã bị khóa vẫn lọt ra trang tìm kiếm công khai. Thêm điều kiện !IsLocked để chặn.
            .Where(j => visibleJobStatuses.Contains(j.Status) && visibleEmployerStatuses.Contains(j.Employer.Status) && !j.Employer.IsLocked)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(f.Keyword))
        {
            var kw = f.Keyword.Trim();
            q = q.Where(j => j.Title.Contains(kw) ||
                              (j.Description != null && j.Description.Contains(kw)) ||
                              (j.Employer.CompanyName != null && j.Employer.CompanyName.Contains(kw)));
        }

        if (!string.IsNullOrWhiteSpace(f.Location))
            q = q.Where(j => j.Location != null && j.Location.Contains(f.Location));

        if (!string.IsNullOrWhiteSpace(f.JobType))
            q = q.Where(j => j.JobType == f.JobType);

        if (!string.IsNullOrWhiteSpace(f.ExperienceLevel))
            q = q.Where(j => j.ExperienceLevel == f.ExperienceLevel);

        if (f.Category != null && f.Category.Count > 0)
        {
            // [FIX-LOGIC] JobPost.CategoryId có thể trỏ tới danh mục CHA (Industry, vd:
            // "Marketing - Truyền thông") hoặc danh mục CON (JobType, vd: "Content Creator")
            // tùy vào tin được tạo qua đường nào — trong khi sidebar "Ngành nghề" chỉ gửi lên
            // ID của danh mục CHA. Nếu chỉ so khớp trực tiếp, tin có CategoryId là JobType
            // (chiếm đa số) sẽ không bao giờ khớp → lọc ra 0 kết quả. Cần mở rộng danh sách ID
            // đã chọn ra luôn cả các danh mục con (JobType) thuộc những ngành đó.
            var childCategoryIds = await _db.Categories
                .Where(c => c.ParentId != null && f.Category.Contains(c.ParentId.Value))
                .Select(c => c.CategoryId)
                .ToListAsync();

            var allCategoryIds = f.Category.Concat(childCategoryIds).ToHashSet();
            q = q.Where(j => j.CategoryId != null && allCategoryIds.Contains(j.CategoryId.Value));
        }

        q = f.SortBy switch
        {
            "salary" => q.OrderByDescending(j => j.SalaryMax),
            "popular" => q.OrderByDescending(j => j.ViewCount),
            _ => q.OrderByDescending(j => j.IsFeatured).ThenByDescending(j => j.CreatedAt)
        };

        // Mức lương lọc theo khoảng (nhiều điều kiện OR) - xử lý sau khi lấy dữ liệu
        // vì logic khoảng lương không thể dịch gọn sang SQL với danh sách khoảng chọn tuỳ ý.
        var all = await q.ToListAsync();

        if (f.Salary != null && f.Salary.Count > 0)
        {
            all = all.Where(j => f.Salary.Any(bucket => MatchesSalaryBucket(j, bucket))).ToList();
        }

        var totalCount = all.Count;
        var pageItems = all.Skip((f.Page - 1) * f.PageSize).Take(f.PageSize).ToList();

        return (pageItems, totalCount);
    }

    private static bool MatchesSalaryBucket(JobPost j, string bucket)
    {
        if (j.SalaryNegotiable) return false;

        decimal? min = j.SalaryMin;
        decimal? max = j.SalaryMax;
        decimal effMin = min ?? max ?? 0;
        decimal effMax = max ?? min ?? 0;

        return bucket switch
        {
            "<10" => effMax < 10_000_000m,
            "10-20" => effMin <= 20_000_000m && effMax >= 10_000_000m,
            "20-50" => effMin <= 50_000_000m && effMax >= 20_000_000m,
            ">50" => effMax > 50_000_000m || effMin > 50_000_000m,
            _ => false
        };
    }

    public async Task<ApplyToggleResult> ToggleApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter)
    {
        var existing = await _db.Applications.FirstOrDefaultAsync(a => a.ProfileId == profileId && a.JobId == jobId && a.Status != "Rejected");
        if (existing != null)
        {
            // Rút đơn thì luôn cho phép, bất kể tin đang ở trạng thái nào (kể cả đã hết
            // hạn/bị ẩn) — ứng viên vẫn có quyền rút đơn đã nộp trước đó.
            _db.Applications.Remove(existing);
            await _db.SaveChangesAsync();
            return ApplyToggleResult.Withdrawn;
        }

        // [FIX-LOGIC] Trước đây KHÔNG kiểm tra tin có đang "Active" và còn hạn hay không
        // trước khi tạo đơn ứng tuyển mới — ứng viên có thể ứng tuyển vào tin Draft/
        // Pending/Rejected/Deleted hoặc đã hết hạn nếu biết/đoán được jobId (vd: link cũ
        // đã lưu từ trước khi tin bị ẩn/hết hạn). Chỉ cho ứng tuyển MỚI khi tin đang thật
        // sự công khai và chưa hết hạn.
        var targetJob = await _db.JobPosts.Include(j => j.Employer).FirstOrDefaultAsync(j => j.JobId == jobId);
        if (targetJob == null || targetJob.Status != "Active"
            || (targetJob.Deadline.HasValue && targetJob.Deadline.Value < DateTime.Now))
        {
            return ApplyToggleResult.Error;
        }

        // Remove any existing rejected application to allow re-applying
        var rejectedApp = await _db.Applications
            .FirstOrDefaultAsync(a => a.ProfileId == profileId && a.JobId == jobId && a.Status == "Rejected");
        if (rejectedApp != null)
        {
            _db.Applications.Remove(rejectedApp);
        }

        _db.Applications.Add(new Application
        {
            JobId = jobId,
            ProfileId = profileId,
            Cvid = cvId,
            CoverLetter = coverLetter,
            Status = "Pending",
            AppliedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();

        _db.Notifications.Add(new Notification
        {
            UserId = targetJob.Employer?.UserId ?? 0,
            Title = $"Có ứng viên mới cho tin \"{targetJob.Title}\"",
            Type = "Application",
            RelatedId = jobId,
            CreatedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();
        return ApplyToggleResult.Applied;
    }

    public async Task<JobPost?> GetByIdAsync(int id)
    {
        var job = await _db.JobPosts
            .Include(j => j.Employer).ThenInclude(e => e.User)
            .Include(j => j.Category).ThenInclude(c => c!.Parent)
            .Include(j => j.Applications)
            .FirstOrDefaultAsync(j => j.JobId == id);

        if (job == null) return null;

        // [FIX] Trước đây trang chi tiết tin tuyển dụng (public) không kiểm tra Status/IsLocked
        // gì cả — ai có link/ID cũng xem được tin dù tin đã bị ẩn, chờ duyệt, hoặc công ty đã bị
        // khóa/xóa. Thêm kiểm tra giống hệt điều kiện đang dùng ở SearchAsync để đồng bộ.
        var visibleJobStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.JobPost);
        var visibleEmployerStatuses = await _statusSvc.GetPublicVisibleCodesAsync(StatusEntityTypes.Employer);

        bool isVisible = visibleJobStatuses.Contains(job.Status)
            && visibleEmployerStatuses.Contains(job.Employer.Status)
            && !job.Employer.IsLocked;

        if (!isVisible) return null;

        job.ViewCount++;
        await _db.SaveChangesAsync();
        return job;
    }

    public async Task<bool> HasAppliedAsync(int profileId, int jobId)
        => await _db.Applications.AnyAsync(a => a.ProfileId == profileId && a.JobId == jobId && a.Status != "Rejected");

    public async Task<bool> ApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter)
    {
        // Check if there's an existing non-rejected application
        if (await HasAppliedAsync(profileId, jobId)) return false;

        // Remove any existing rejected application to allow re-applying
        var rejectedApp = await _db.Applications
            .FirstOrDefaultAsync(a => a.ProfileId == profileId && a.JobId == jobId && a.Status == "Rejected");
        if (rejectedApp != null)
        {
            _db.Applications.Remove(rejectedApp);
        }

        _db.Applications.Add(new Application
        {
            JobId = jobId,
            ProfileId = profileId,
            Cvid = cvId,
            CoverLetter = coverLetter,
            Status = "Pending",
            AppliedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();

        var job = await _db.JobPosts.Include(j => j.Employer).FirstAsync(j => j.JobId == jobId);
        _db.Notifications.Add(new Notification
        {
            UserId = job.Employer?.UserId ?? 0,
            Title = $"Có ứng viên mới cho tin \"{job.Title}\"",
            Type = "Application",
            RelatedId = jobId,
            CreatedAt = DateTime.Now
        });
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ToggleSaveAsync(int userId, int jobId)
    {
        var saved = await _db.SavedJobs.FirstOrDefaultAsync(s => s.UserId == userId && s.JobId == jobId);
        if (saved != null)
        {
            _db.SavedJobs.Remove(saved);
            await _db.SaveChangesAsync();
            return false;
        }
        _db.SavedJobs.Add(new SavedJob { UserId = userId, JobId = jobId });
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<List<JobPost>> GetByEmployerAsync(int employerId)
        => await _db.JobPosts
                    .Include(j => j.Applications)
                    .Where(j => j.EmployerId == employerId && j.Status != "Deleted")
                    .OrderByDescending(j => j.CreatedAt)
                    .ToListAsync();

    public async Task<JobPost> CreateAsync(JobPost job)
    {
        job.Status = "Pending";
        job.CreatedAt = DateTime.Now;
        job.JobCode = await _codeGen.GenerateJobCodeAsync();
        _db.JobPosts.Add(job);
        await _db.SaveChangesAsync();

        // Báo cho TOÀN BỘ Admin biết ngay lập tức có tin tuyển dụng mới cần duyệt.
        var companyName = await _db.Employers
            .Where(e => e.EmployerId == job.EmployerId)
            .Select(e => e.CompanyName)
            .FirstOrDefaultAsync();

        await _db.NotifyAdminsAsync(
            title: "Có tin tuyển dụng mới cần duyệt",
            content: $"\"{job.Title}\" từ công ty {companyName ?? "(không rõ)"}",
            type: "NewJobPost",
            relatedId: job.JobId);
        await _db.SaveChangesAsync();

        return job;
    }

    public async Task UpdateAsync(JobPost job)
    {
        job.UpdatedAt = DateTime.Now;
        _db.JobPosts.Update(job);
        await _db.SaveChangesAsync();
    }

    // Delegate đến FileService
    public async Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder)
    {
        return await _fileSvc.SaveImageFromDataUriAsync(dataUri, relativeFolder);
    }
}