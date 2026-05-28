namespace JobConnect.Services;

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _env;
    public FileService(IWebHostEnvironment env) => _env = env;

    public async Task<string> SaveCvAsync(IFormFile file, int profileId)
    {
        var folder = Path.Combine(_env.WebRootPath, "uploads", "cv", profileId.ToString());
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var fullPath = Path.Combine(folder, fileName);
        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);
        return $"/uploads/cv/{profileId}/{fileName}";
    }

    public async Task<string> SaveAvatarAsync(IFormFile file, int userId)
    {
        var folder = Path.Combine(_env.WebRootPath, "uploads", "avatar");
        Directory.CreateDirectory(folder);
        var fileName = $"user_{userId}{Path.GetExtension(file.FileName)}";
        var fullPath = Path.Combine(folder, fileName);
        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);
        return $"/uploads/avatar/{fileName}";
    }

    public void Delete(string filePath)
    {
        var full = Path.Combine(_env.WebRootPath, filePath.TrimStart('/'));
        if (File.Exists(full)) File.Delete(full);
    }
}