// [SERVICE-IFACE-HEADER-ADDED]
// Interface cho dịch vụ nghiệp vụ TIN TUYỂN DỤNG: tìm kiếm/lọc tin, xem chi tiết,
// ứng tuyển (Apply)/rút đơn (ToggleApplyAsync), lưu tin (ToggleSaveAsync), nhà
// tuyển dụng tạo/sửa tin. ApplyToggleResult mô tả 3 trạng thái có thể xảy ra khi
// người dùng bấm nút ứng tuyển. Cài đặt bởi JobService.cs.
using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Services;

public enum ApplyToggleResult
{
    Applied,    // Nộp đơn thành công (lần đầu)
    Withdrawn,  // Rút đơn đã nộp trước đó (bấm ứng tuyển lần 2)
    Error       // Có lỗi xảy ra
}

public interface IJobService
{
    Task<(List<JobPost> Items, int TotalCount)> SearchAsync(JobSearchViewModel filter);
    Task<JobPost?> GetByIdAsync(int id);
    Task<bool> ApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter);
    Task<ApplyToggleResult> ToggleApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter);
    Task<bool> ToggleSaveAsync(int userId, int jobId);
    Task<List<JobPost>> GetByEmployerAsync(int employerId);
    Task<JobPost> CreateAsync(JobPost job);
    Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder);
    Task UpdateAsync(JobPost job);
    Task<bool> HasAppliedAsync(int profileId, int jobId);
}