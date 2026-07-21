// [[FILE-HEADER-ADDED]]
// Hàm tiện ích tính TOÁN ĐƯỜNG DẪN/NỘI DUNG ảnh đại diện mặc định — khi User chưa
// upload avatar, hiển thị chữ cái đầu tên (kiểu "avatar chữ") thay vì ảnh trống.
namespace JobConnect.Helpers;

public static class AvatarHelper
{
    // Bảng màu nền cố định, đẹp trên nền tối lẫn nền sáng
    private static readonly string[] Colors =
    {
        "#6366F1", "#8B5CF6", "#EC4899", "#F43F5E", "#F97316",
        "#F59E0B", "#10B981", "#14B8A6", "#06B6D4", "#3B82F6"
    };

    /// <summary>Lấy chữ cái đầu tiên (viết hoa) của tên để hiển thị trong avatar mặc định.</summary>
    public static string GetInitial(string? fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            return "?";

        // Lấy chữ cái đầu của TỪ CUỐI CÙNG trong tên (thường là tên gọi ở VN, VD: "Nguyễn Văn An" -> "A")
        var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var word = parts.Length > 0 ? parts[^1] : fullName.Trim();

        return word.Substring(0, 1).ToUpperInvariant();
    }

    /// <summary>Sinh màu nền cố định dựa theo tên (cùng 1 tên luôn ra cùng 1 màu).</summary>
    public static string GetColor(string? fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            return Colors[0];

        int hash = 0;
        foreach (var c in fullName)
            hash = (hash * 31 + c) & 0x7FFFFFFF;

        return Colors[hash % Colors.Length];
    }
}
