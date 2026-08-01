// [[FILE-HEADER-ADDED]]
// Bảng tra tên hiển thị (tiếng Việt) cho enum SkillCategory,
// tránh phải viết if/switch lặp lại ở nhiều View khác nhau.
using JobConnect.Models;

namespace JobConnect.Helpers;

/// <summary>
/// Ánh xạ giá trị SkillCategory (giữ nguyên tiếng Anh trong enum/DB để tương thích code cũ)
/// sang nhãn hiển thị tiếng Việt trên giao diện Admin.
/// </summary>
public static class SkillCategoryLabels
{
    private static readonly Dictionary<SkillCategory, string> Labels = new()
    {
        [SkillCategory.Programming] = "Lập trình",
        [SkillCategory.Design] = "Thiết kế",
        [SkillCategory.Marketing] = "Marketing",
        [SkillCategory.Language] = "Ngoại ngữ",
        [SkillCategory.SoftSkills] = "Kỹ năng mềm"
    };

    public static string GetLabel(SkillCategory category)
    {
        return Labels.TryGetValue(category, out var label) ? label : category.ToString();
    }

    public static string GetLabel(string? category)
    {
        if (string.IsNullOrEmpty(category)) return string.Empty;
        return Enum.TryParse<SkillCategory>(category, out var parsed) ? GetLabel(parsed) : category;
    }
}
