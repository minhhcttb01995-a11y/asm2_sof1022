using Microsoft.AspNetCore.Hosting;
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _env;
    private readonly AppDbContext _db;

    public FileService(IWebHostEnvironment env, AppDbContext db)
    {
        _env = env;
        _db = db;
    }

    public async Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder)
    {
        if (string.IsNullOrEmpty(dataUri) || !dataUri.StartsWith("data:"))
            return dataUri;

        try
        {
            var base64Data = dataUri.Split(',')[1];
            var bytes = Convert.FromBase64String(base64Data);

            var fileName = $"{Guid.NewGuid()}.jpg";
            var relativePath = Path.Combine(relativeFolder, fileName).Replace("\\", "/");
            var fullPath = Path.Combine(_env.WebRootPath, relativePath);

            Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);
            await File.WriteAllBytesAsync(fullPath, bytes);

            return "/" + relativePath;
        }
        catch
        {
            return string.Empty;
        }
    }

    public async Task<bool> DeleteFileAsync(string filePath)
    {
        try
        {
            var fullPath = Path.Combine(_env.WebRootPath, filePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                return true;
            }
            return false;
        }
        catch
        {
            return false;
        }
    }

    public string GetContentType(string extension)
    {
        return extension.ToLower() switch
        {
            ".pdf" => "application/pdf",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            _ => "application/octet-stream"
        };
    }

    // ─── CV Methods ───────────────────────────────────────────────────────────

    public async Task<CvFile> UploadCvAsync(IFormFile file, int profileId)
    {
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();

        // Chặn ở tầng service (không chỉ dựa vào validate ở controller) để tránh
        // upload file thực thi (.exe/.php/.aspx/...) nếu có chỗ khác gọi thẳng hàm này.
        var allowedExt = new[] { ".pdf", ".docx", ".doc" };
        if (!allowedExt.Contains(ext))
            throw new InvalidOperationException("Chỉ chấp nhận file PDF hoặc DOCX/DOC.");

        const long maxSize = 5 * 1024 * 1024; // 5MB
        if (file.Length <= 0 || file.Length > maxSize)
            throw new InvalidOperationException("File CV không hợp lệ hoặc vượt quá 5MB.");

        var folder = Path.Combine(_env.WebRootPath, "uploads", "cvs");
        Directory.CreateDirectory(folder);

        var savedName = $"{Guid.NewGuid()}{ext}";
        var fullPath = Path.Combine(folder, savedName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
            await file.CopyToAsync(stream);

        var relativePath = $"/uploads/cvs/{savedName}";

        // Nếu chưa có CV nào, tự đặt mặc định
        var hasExisting = await _db.CvFiles.AnyAsync(c => c.ProfileId == profileId);

        var cvFile = new CvFile
        {
            ProfileId = profileId,
            FileName = file.FileName,
            FilePath = relativePath,
            FileSize = file.Length,
            IsDefault = !hasExisting,
            UploadedAt = DateTime.UtcNow
        };

        _db.CvFiles.Add(cvFile);
        await _db.SaveChangesAsync();

        return cvFile;
    }

    public async Task<bool> SetDefaultCvAsync(int cvId, int userId)
    {
        // Xác minh CV thuộc về user này
        var target = await _db.CvFiles
            .Include(c => c.Profile)
            .FirstOrDefaultAsync(c => c.Cvid == cvId && c.Profile != null && c.Profile.UserId == userId);

        if (target == null) return false;

        // Bỏ mặc định tất cả CV cũ của profile
        var others = await _db.CvFiles
            .Where(c => c.ProfileId == target.ProfileId && c.Cvid != cvId)
            .ToListAsync();

        foreach (var cv in others)
            cv.IsDefault = false;

        target.IsDefault = true;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteCvAsync(int cvId, int userId)
    {
        var cv = await _db.CvFiles
            .Include(c => c.Profile)
            .FirstOrDefaultAsync(c => c.Cvid == cvId && c.Profile != null && c.Profile.UserId == userId);

        if (cv == null) return false;

        // Xóa file vật lý
        var fullPath = Path.Combine(_env.WebRootPath,
            cv.FilePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));

        if (File.Exists(fullPath))
            File.Delete(fullPath);

        _db.CvFiles.Remove(cv);
        await _db.SaveChangesAsync();

        // Nếu vừa xóa CV mặc định, tự chọn CV mới nhất làm mặc định
        if (cv.IsDefault)
        {
            var next = await _db.CvFiles
                .Where(c => c.ProfileId == cv.ProfileId)
                .OrderByDescending(c => c.UploadedAt)
                .FirstOrDefaultAsync();

            if (next != null)
            {
                next.IsDefault = true;
                await _db.SaveChangesAsync();
            }
        }

        return true;
    }

    public async Task<string> SaveAvatarAsync(IFormFile avatarFile, int userId)
    {
        try
        {
            var ext = Path.GetExtension(avatarFile.FileName).ToLowerInvariant();
            var allowedExts = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            if (!allowedExts.Contains(ext)) return string.Empty;

            const long maxAvatarSize = 3 * 1024 * 1024; // 3MB
            if (avatarFile.Length > maxAvatarSize) return string.Empty;

            var fileName = $"user_{userId}_{Guid.NewGuid()}{ext}";
            var relativeFolder = "uploads/avatar";
            var relativePath = Path.Combine(relativeFolder, fileName).Replace("\\", "/");
            var fullPath = Path.Combine(_env.WebRootPath, relativePath);

            Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

            using var stream = new FileStream(fullPath, FileMode.Create);
            await avatarFile.CopyToAsync(stream);

            // Update User record
            var user = await _db.Users.FindAsync(userId);
            if (user != null)
            {
                user.AvatarUrl = "/" + relativePath;
                await _db.SaveChangesAsync();
            }

            return "/" + relativePath;
        }
        catch
        {
            return string.Empty;
        }
    }
}