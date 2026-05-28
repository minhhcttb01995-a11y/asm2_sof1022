namespace JobConnect.Services;

public interface IFileService
{
    Task<string> SaveCvAsync(IFormFile file, int profileId);
    Task<string> SaveAvatarAsync(IFormFile file, int userId);
    void Delete(string filePath);
}