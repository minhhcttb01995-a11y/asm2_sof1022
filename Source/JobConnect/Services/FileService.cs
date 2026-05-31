namespace JobConnect.Services;

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _env;

    public FileService(IWebHostEnvironment env) => _env = env;

    public async Task<string> SaveCvAsync(IFormFile file, int profileId)
    {
        if (profileId <= 0)
            throw new ArgumentException("Profile ID không hợp lệ");

        var folder = Path.Combine(_env.WebRootPath, "uploads", "cv", profileId.ToString());
        Directory.CreateDirectory(folder);

        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName).ToLower()}";
        var fullPath = Path.Combine(folder, fileName);

        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/uploads/cv/{profileId}/{fileName}";
    }

    public async Task<string> SaveAvatarAsync(IFormFile file, int userId)
    {
        var folder = Path.Combine(_env.WebRootPath, "uploads", "avatar");
        Directory.CreateDirectory(folder);

        var fileName = $"user_{userId}_{Guid.NewGuid()}{Path.GetExtension(file.FileName).ToLower()}";
        var fullPath = Path.Combine(folder, fileName);

        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/uploads/avatar/{fileName}";
    }

    public void Delete(string filePath)
    {
        if (string.IsNullOrEmpty(filePath)) return;

        try
        {
            var fullPath = Path.Combine(_env.WebRootPath, filePath.TrimStart('/'));
            if (File.Exists(fullPath))
                File.Delete(fullPath);
        }
        catch { }
    }

    public async Task<string> SaveImageFromDataUriAsync(string dataUri, string relativeFolder)
    {
        // data:[<mediatype>][;base64],<data>
        if (string.IsNullOrEmpty(dataUri) || !dataUri.Contains(","))
            throw new ArgumentException("Invalid data URI");

        var parts = dataUri.Split(',', 2);
        var meta = parts[0];
        var base64 = parts[1];

        string ext = ".png";
        if (meta.Contains("image/jpeg") || meta.Contains("image/jpg")) ext = ".jpg";
        else if (meta.Contains("image/webp")) ext = ".webp";
        else if (meta.Contains("image/gif")) ext = ".gif";

        var folder = Path.Combine(_env.WebRootPath, relativeFolder.TrimStart('/'));
        Directory.CreateDirectory(folder);

        var fileName = $"img_{Guid.NewGuid()}{ext}";
        var fullPath = Path.Combine(folder, fileName);

        var bytes = Convert.FromBase64String(base64);
        await File.WriteAllBytesAsync(fullPath, bytes);

        return $"/{relativeFolder.TrimStart('/')}/{fileName}";
    }
}