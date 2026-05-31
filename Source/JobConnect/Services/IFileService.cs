    namespace JobConnect.Services;

    public interface IFileService
    {
        Task<string> SaveCvAsync(IFormFile file, int profileId);
        Task<string> SaveAvatarAsync(IFormFile file, int userId);
        Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder);
        void Delete(string filePath);
    }