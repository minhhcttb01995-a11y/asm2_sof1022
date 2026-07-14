using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace JobConnect.Extensions;

/// <summary>
/// Sinh slug thân thiện URL từ chuỗi tiếng Việt có dấu.
/// VD: "Kinh nghiệm tìm việc 2025" -> "kinh-nghiem-tim-viec-2025"
/// </summary>
public static class SlugHelper
{
    public static string ToSlug(string? input)
    {
        if (string.IsNullOrWhiteSpace(input)) return string.Empty;

        var text = input.Trim().ToLowerInvariant();

        // Xử lý riêng chữ "đ" vì Unicode NFD không tách được ký tự này
        text = text.Replace("đ", "d").Replace("Đ", "d");

        // Tách dấu ra khỏi ký tự gốc (NFD) rồi loại bỏ toàn bộ dấu (Mn = Mark, Nonspacing)
        text = text.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in text)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        text = sb.ToString().Normalize(NormalizationForm.FormC);

        // Thay mọi ký tự không phải chữ/số bằng dấu gạch ngang
        text = Regex.Replace(text, @"[^a-z0-9\s-]", "");
        text = Regex.Replace(text, @"[\s-]+", "-").Trim('-');

        return text;
    }
}
