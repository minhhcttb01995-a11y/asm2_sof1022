using JobConnect.Models;

namespace JobConnect.Services;

/// <summary>
/// Service quản lý danh mục Trạng thái do Admin tùy chỉnh
/// (Ứng viên, Nhà tuyển dụng, Nhân viên, Công ty, Tin tuyển dụng).
/// </summary>
public interface IStatusCatalogService
{
    Task<List<StatusCatalog>> GetAllAsync(string? entityType = null, string? keyword = null);
    Task<List<StatusCatalog>> GetActiveByEntityTypeAsync(string entityType);
    Task<StatusCatalog?> GetByIdAsync(int id);
    Task<bool> CreateAsync(StatusCatalog model);
    Task<bool> UpdateAsync(StatusCatalog model);
    Task<(bool Success, string? Error, int RecordCount)> DeleteAsync(int id);
    Task<bool> ToggleActiveAsync(int id);
    Task<bool> ExistsAsync(string entityType, string code, int? excludeId = null);

    /// <summary>Lấy tên hiển thị (Name) theo EntityType + Code, dùng để in badge trạng thái ở các trang khác.</summary>
    Task<string> GetDisplayNameAsync(string entityType, string code);

    /// <summary>
    /// Lấy danh sách Code của các trạng thái được đánh dấu ShowPublicly = true cho một EntityType.
    /// Dùng để lọc dữ liệu hiển thị công khai (trang chủ, danh sách công ty, tin tuyển dụng, blog...).
    /// </summary>
    Task<List<string>> GetPublicVisibleCodesAsync(string entityType);
}