// [[FILE-HEADER-ADDED]]
// Bảng tra tên hiển thị (tiếng Việt) cho các loại Category (Type = "Industry", "Location"...),
// tránh phải viết if/switch lặp lại ở nhiều View khác nhau.
namespace JobConnect.Helpers;

/// <summary>
/// Ánh xạ giá trị Type của Category (lưu trong DB, giữ nguyên tiếng Anh để tương thích code cũ)
/// sang nhãn hiển thị tiếng Việt trên giao diện Admin/Staff.
/// </summary>
public static class CategoryTypeLabels
{
    private static readonly Dictionary<string, string> Labels = new()
    {
        ["Industry"] = "Ngành nghề",
        ["Location"] = "Địa điểm",
        ["Level"] = "Cấp độ",
        ["JobType"] = "Loại công việc"
    };

    public static string GetLabel(string? type)
    {
        if (string.IsNullOrEmpty(type)) return string.Empty;
        return Labels.TryGetValue(type, out var label) ? label : type;
    }
}