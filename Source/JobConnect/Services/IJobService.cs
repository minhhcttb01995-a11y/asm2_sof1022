using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Services;

public interface IJobService
{
    Task<List<JobPost>> SearchAsync(JobSearchViewModel filter);
    Task<JobPost?> GetByIdAsync(int id);
    Task<bool> ApplyAsync(int jobId, int profileId, int? cvId, string? coverLetter);
    Task<bool> ToggleSaveAsync(int userId, int jobId);
    Task<List<JobPost>> GetByEmployerAsync(int employerId);
    Task<JobPost> CreateAsync(JobPost job);
    Task UpdateAsync(JobPost job);
    Task<bool> HasAppliedAsync(int profileId, int jobId);
}