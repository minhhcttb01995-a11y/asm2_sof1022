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