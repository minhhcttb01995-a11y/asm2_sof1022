using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class StatusCatalogService : IStatusCatalogService
{
    private readonly AppDbContext _db;

    public StatusCatalogService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<StatusCatalog>> GetAllAsync(string? entityType = null, string? keyword = null)
    {
        var query = _db.StatusCatalogs.AsQueryable();

        if (!string.IsNullOrWhiteSpace(entityType))
            query = query.Where(s => s.EntityType == entityType);

        if (!string.IsNullOrWhiteSpace(keyword))
            query = query.Where(s => s.Name.Contains(keyword) || s.Code.Contains(keyword));

        return await query
            .OrderBy(s => s.EntityType)
            .ThenBy(s => s.Name)
            .ToListAsync();
    }

    public async Task<List<StatusCatalog>> GetActiveByEntityTypeAsync(string entityType)
    {
        return await _db.StatusCatalogs
            .Where(s => s.EntityType == entityType && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();
    }

    public async Task<StatusCatalog?> GetByIdAsync(int id)
    {
        return await _db.StatusCatalogs.FindAsync(id);
    }

    public async Task<bool> CreateAsync(StatusCatalog model)
    {
        // Generate Code from Name if not provided
        if (string.IsNullOrEmpty(model.Code))
        {
            model.Code = GenerateCodeFromName(model.Name);
        }

        // Check for duplicate Code within EntityType
        if (await ExistsAsync(model.EntityType, model.Code))
            return false;

        // Check for duplicate Name within EntityType
        if (await NameExistsAsync(model.EntityType, model.Name))
            return false;

        model.CreatedAt = DateTime.Now;
        model.IsSystem = false; // trạng thái do Admin tạo mới không phải mặc định hệ thống
        _db.StatusCatalogs.Add(model);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateAsync(StatusCatalog model)
    {
        var entity = await _db.StatusCatalogs.FindAsync(model.Id);
        if (entity == null) return false;

        // Don't allow changing Code - it's the unique identifier
        // Only update other fields including ColorClass and Description
        entity.EntityType = model.EntityType;
        entity.Name = model.Name;
        entity.ColorClass = model.ColorClass;
        entity.Description = model.Description;
        entity.IsActive = model.IsActive;
        entity.BlocksLogin = model.BlocksLogin;
        entity.ShowPublicly = model.ShowPublicly;
        entity.UpdatedAt = DateTime.Now;

        // Check for duplicate Name within EntityType (excluding current record)
        if (await NameExistsAsync(model.EntityType, model.Name, model.Id))
            return false;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<(bool Success, string? Error, int RecordCount)> DeleteAsync(int id)
    {
        var entity = await _db.StatusCatalogs.FindAsync(id);
        if (entity == null)
            return (false, "Không tìm thấy trạng thái.", 0);

        // Check if status is in use by entity records
        int recordCount = 0;
        switch (entity.EntityType)
        {
            case "Staff":
                recordCount = await _db.Staff.CountAsync(s => s.Status.ToString() == entity.Code);
                break;
            case "Employer":
                recordCount = await _db.Employers.CountAsync(e => e.Status == entity.Code);
                break;
            case "Candidate":
                recordCount = await _db.Users.CountAsync(u => u.Role == "Candidate" && u.Status == entity.Code);
                break;
            case "JobPost":
                recordCount = await _db.JobPosts.CountAsync(j => j.Status == entity.Code);
                break;
            case "Company":
                recordCount = await _db.Employers.CountAsync(e => e.Status == entity.Code);
                break;
            case "BlogPost":
                recordCount = await _db.BlogPosts.CountAsync(b => b.Status == entity.Code);
                break;
        }

        if (recordCount > 0)
            return (false, $"Trạng thái này đang được sử dụng bởi {recordCount} bản ghi. Không thể xóa.", recordCount);

        _db.StatusCatalogs.Remove(entity);
        await _db.SaveChangesAsync();
        return (true, null, 0);
    }

    public async Task<bool> ToggleActiveAsync(int id)
    {
        var entity = await _db.StatusCatalogs.FindAsync(id);
        if (entity == null) return false;

        entity.IsActive = !entity.IsActive;
        entity.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ExistsAsync(string entityType, string code, int? excludeId = null)
    {
        return await _db.StatusCatalogs.AnyAsync(s =>
            s.EntityType == entityType &&
            s.Code == code &&
            (!excludeId.HasValue || s.Id != excludeId.Value));
    }

    public async Task<bool> NameExistsAsync(string entityType, string name, int? excludeId = null)
    {
        return await _db.StatusCatalogs.AnyAsync(s =>
            s.EntityType == entityType &&
            s.Name == name &&
            (!excludeId.HasValue || s.Id != excludeId.Value));
    }

    public async Task<string> GetDisplayNameAsync(string entityType, string code)
    {
        var found = await _db.StatusCatalogs
            .Where(s => s.EntityType == entityType && s.Code == code)
            .Select(s => s.Name)
            .FirstOrDefaultAsync();

        return found ?? code;
    }

    public async Task<List<string>> GetPublicVisibleCodesAsync(string entityType)
    {
        return await _db.StatusCatalogs
            .Where(s => s.EntityType == entityType && s.ShowPublicly)
            .Select(s => s.Code!)
            .ToListAsync();
    }

    private string GenerateCodeFromName(string name)
    {
        if (string.IsNullOrEmpty(name))
            return string.Empty;

        // Remove Vietnamese accents and convert to uppercase
        var vietnameseMap = new Dictionary<char, char>
        {
            {'à', 'a'}, {'á', 'a'}, {'ả', 'a'}, {'ã', 'a'}, {'ạ', 'a'},
            {'ă', 'a'}, {'ằ', 'a'}, {'ắ', 'a'}, {'ẳ', 'a'}, {'ẵ', 'a'}, {'ặ', 'a'},
            {'â', 'a'}, {'ầ', 'a'}, {'ấ', 'a'}, {'ẩ', 'a'}, {'ẫ', 'a'}, {'ậ', 'a'},
            {'è', 'e'}, {'é', 'e'}, {'ẻ', 'e'}, {'ẽ', 'e'}, {'ẹ', 'e'},
            {'ê', 'e'}, {'ề', 'e'}, {'ế', 'e'}, {'ể', 'e'}, {'ễ', 'e'}, {'ệ', 'e'},
            {'ì', 'i'}, {'í', 'i'}, {'ỉ', 'i'}, {'ĩ', 'i'}, {'ị', 'i'},
            {'ò', 'o'}, {'ó', 'o'}, {'ỏ', 'o'}, {'õ', 'o'}, {'ọ', 'o'},
            {'ô', 'o'}, {'ồ', 'o'}, {'ố', 'o'}, {'ổ', 'o'}, {'ỗ', 'o'}, {'ộ', 'o'},
            {'ơ', 'o'}, {'ờ', 'o'}, {'ớ', 'o'}, {'ở', 'o'}, {'ỡ', 'o'}, {'ợ', 'o'},
            {'ù', 'u'}, {'ú', 'u'}, {'ủ', 'u'}, {'ũ', 'u'}, {'ụ', 'u'},
            {'ư', 'u'}, {'ừ', 'u'}, {'ứ', 'u'}, {'ử', 'u'}, {'ữ', 'u'}, {'ự', 'u'},
            {'ỳ', 'y'}, {'ý', 'y'}, {'ỷ', 'y'}, {'ỹ', 'y'}, {'ỵ', 'y'},
            {'đ', 'd'},
            {'À', 'A'}, {'Á', 'A'}, {'Ả', 'A'}, {'Ã', 'A'}, {'Ạ', 'A'},
            {'Ă', 'A'}, {'Ằ', 'A'}, {'Ắ', 'A'}, {'Ẳ', 'A'}, {'Ẵ', 'A'}, {'Ặ', 'A'},
            {'Â', 'A'}, {'Ầ', 'A'}, {'Ấ', 'A'}, {'Ẩ', 'A'}, {'Ẫ', 'A'}, {'Ậ', 'A'},
            {'È', 'E'}, {'É', 'E'}, {'Ẻ', 'E'}, {'Ẽ', 'E'}, {'Ẹ', 'E'},
            {'Ê', 'E'}, {'Ề', 'E'}, {'Ế', 'E'}, {'Ể', 'E'}, {'Ễ', 'E'}, {'Ệ', 'E'},
            {'Ì', 'I'}, {'Í', 'I'}, {'Ỉ', 'I'}, {'Ĩ', 'I'}, {'Ị', 'I'},
            {'Ò', 'O'}, {'Ó', 'O'}, {'Ỏ', 'O'}, {'Õ', 'O'}, {'Ọ', 'O'},
            {'Ô', 'O'}, {'Ồ', 'O'}, {'Ố', 'O'}, {'Ổ', 'O'}, {'Ỗ', 'O'}, {'Ộ', 'O'},
            {'Ơ', 'O'}, {'Ờ', 'O'}, {'Ớ', 'O'}, {'Ở', 'O'}, {'Ỡ', 'O'}, {'Ợ', 'O'},
            {'Ù', 'U'}, {'Ú', 'U'}, {'Ủ', 'U'}, {'Ũ', 'U'}, {'Ụ', 'U'},
            {'Ư', 'U'}, {'Ừ', 'U'}, {'Ứ', 'U'}, {'Ử', 'U'}, {'Ữ', 'U'}, {'Ự', 'U'},
            {'Ỳ', 'Y'}, {'Ý', 'Y'}, {'Ỷ', 'Y'}, {'Ỹ', 'Y'}, {'Ỵ', 'Y'},
            {'Đ', 'D'}
        };

        var result = new System.Text.StringBuilder();
        foreach (char c in name)
        {
            if (vietnameseMap.ContainsKey(c))
            {
                result.Append(vietnameseMap[c]);
            }
            else if (char.IsLetterOrDigit(c))
            {
                result.Append(c);
            }
            else if (char.IsWhiteSpace(c))
            {
                result.Append('_');
            }
        }

        return result.ToString().ToUpper();
    }
}