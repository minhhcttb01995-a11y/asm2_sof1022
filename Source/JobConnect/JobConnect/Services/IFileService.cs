// [SERVICE-IFACE-HEADER-ADDED]
// Interface cho dịch vụ XỬ LÝ FILE: lưu ảnh (avatar, logo công ty) từ base64 data-URI,
// upload/xóa/đặt CV mặc định, xác định Content-Type theo phần mở rộng file.
// CvDeleteResult là kết quả trả về khi xóa CV (không cho xóa nếu CV đang được
// dùng để nộp đơn ứng tuyển). Cài đặt bởi FileService.cs.
namespace JobConnect.Services;

public enum CvDeleteResult
{
    Success,
    NotFound,
    /// <summary>CV đã được dùng để nộp cho 1 đơn ứng tuyển nên không thể xóa.</summary>
    InUse
}

public interface IFileService
{
    Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder);
    Task<bool> DeleteFileAsync(string filePath);
    string GetContentType(string extension);

    Task<JobConnect.Models.CvFile> UploadCvAsync(IFormFile file, int profileId);
    Task<bool> SetDefaultCvAsync(int cvId, int userId);
    Task<CvDeleteResult> DeleteCvAsync(int cvId, int userId);
    Task<string> SaveAvatarAsync(IFormFile avatarFile, int userId);
}
