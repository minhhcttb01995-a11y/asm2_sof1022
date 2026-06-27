namespace JobConnect.Services;

public interface IFileService
{
    Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder);
    Task<bool> DeleteFileAsync(string filePath);
    string GetContentType(string extension);

    Task<JobConnect.Models.CvFile> UploadCvAsync(IFormFile file, int profileId);
    Task<bool> SetDefaultCvAsync(int cvId, int userId);
    Task<bool> DeleteCvAsync(int cvId, int userId);
    Task<string> SaveAvatarAsync(IFormFile avatarFile, int userId);
}
