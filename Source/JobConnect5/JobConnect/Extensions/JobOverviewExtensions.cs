// [[FILE-HEADER-ADDED]]
// Extension method (hàm mở rộng) gắn thêm vào JobPost/IQueryable<JobPost> để tính các
// chỉ số tổng quan (đếm số lượng theo trạng thái, thống kê nhanh...) mà không cần viết
// lại logic LINQ ở nhiều Controller.
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using JobConnect.Models;

namespace JobConnect.Extensions;

/// <summary>Kết quả tách "Tổng quan" của 1 tin tuyển dụng, để hiển thị dạng tag/chip.</summary>
public class JobOverview
{
    public List<string> RequirementTags { get; set; } = new();
    public List<string> BenefitTags { get; set; } = new();
    public List<string> ExpertiseTags { get; set; } = new();

    public bool HasAny => RequirementTags.Count > 0 || BenefitTags.Count > 0 || ExpertiseTags.Count > 0;
}

/// <summary>
/// Trích xuất nhanh các tag ngắn gọn (Yêu cầu / Quyền lợi / Chuyên môn) từ nội dung tin tuyển dụng
/// để hiển thị ở khối "Tổng quan" trên trang chi tiết.
///
/// CHỦ ĐÍCH THUẦN RULE-BASED (regex + từ khóa) — KHÔNG gọi AI:
///   - Chạy tức thời mỗi lần tải trang, không có độ trễ mạng.
///   - Không tốn API quota/chi phí dù trang được xem hàng nghìn lượt.
///   - Không phụ thuộc dịch vụ ngoài (AI service sập vẫn không ảnh hưởng trang chi tiết).
/// Đánh đổi: tag sinh ra có thể không "mượt" bằng văn phong AI viết lại, nhưng đủ chính xác và
/// có thể tinh chỉnh dễ dàng bằng cách sửa danh sách từ khóa/regex bên dưới.
/// </summary>
public static class JobOverviewExtensions
{
    private const int MaxTagsPerGroup = 4;

    /// <param name="allSkills">Danh sách Skill đang Active trong hệ thống (dùng để dò "Chuyên môn"). Có thể để null nếu không có sẵn.</param>
    public static JobOverview BuildOverview(this JobPost job, IEnumerable<Skill>? allSkills = null)
    {
        var reqText = StripHtml(job.Requirements);
        var benefitText = StripHtml(job.Benefits);
        var descText = StripHtml(job.Description);
        var combinedForExpertise = $"{job.Title} {descText} {reqText}";

        return new JobOverview
        {
            RequirementTags = ExtractRequirementTags(reqText, job.ExperienceLevel),
            BenefitTags = ExtractBenefitTags(benefitText),
            ExpertiseTags = ExtractExpertiseTags(combinedForExpertise, allSkills, job.Category?.Name)
        };
    }

    /// <summary>Bỏ thẻ HTML (nội dung được lưu từ trình soạn thảo rich-text) để lấy text thuần cho việc so khớp.</summary>
    private static string StripHtml(string? html)
    {
        if (string.IsNullOrWhiteSpace(html)) return "";
        var text = Regex.Replace(html, @"<(br|/li|/p|/div|/h[1-6])\s*/?>", "\n", RegexOptions.IgnoreCase);
        text = Regex.Replace(text, "<[^>]+>", " ");
        text = System.Net.WebUtility.HtmlDecode(text);
        return Regex.Replace(text, @"[ \t]{2,}", " ").Trim();
    }

    // ───────────────────────────── Yêu cầu ─────────────────────────────
    private static List<string> ExtractRequirementTags(string requirementText, string? experienceLevel)
    {
        var tags = new List<string>();
        var lower = requirementText.ToLowerInvariant();
        var normLower = NormalizeForMatch(lower); // bản không dấu, dùng cho mọi so khớp regex bên dưới

        // 1) Số năm kinh nghiệm — ưu tiên số cụ thể nêu trong JD (VD: "2 năm", "3-5 năm kinh nghiệm"),
        // nếu JD không nêu số cụ thể mới suy ra từ Cấp bậc (ExperienceLevel) đã chọn khi đăng tin.
        var expMatch = Regex.Match(lower, @"(\d+)\s*(?:-|đến)?\s*(\d+)?\s*năm(?:\s*kinh nghiệm)?");
        if (expMatch.Success)
        {
            var from = expMatch.Groups[1].Value;
            var to = expMatch.Groups[2].Success ? expMatch.Groups[2].Value : null;
            tags.Add(to != null ? $"{from} - {to} năm kinh nghiệm" : $"{from} năm kinh nghiệm chuyên môn");
        }
        else if (Regex.IsMatch(normLower, "chua co kinh nghiem|khong yeu cau kinh nghiem|moi ra truong|dao tao tu dau"))
        {
            tags.Add("Không yêu cầu kinh nghiệm");
        }
        else if (!string.IsNullOrEmpty(experienceLevel))
        {
            tags.Add(experienceLevel switch
            {
                "Fresher" => "Chưa yêu cầu kinh nghiệm",
                "Junior" => "Dưới 2 năm kinh nghiệm",
                "Middle" => "2 - 5 năm kinh nghiệm",
                "Senior" => "Trên 5 năm kinh nghiệm",
                _ => experienceLevel
            });
        }

        // 2) Bằng cấp
        if (Regex.IsMatch(normLower, "dai hoc|cu nhan")) tags.Add("Đại học trở lên");
        else if (Regex.IsMatch(normLower, "cao dang")) tags.Add("Cao đẳng trở lên");
        else if (Regex.IsMatch(normLower, "trung cap")) tags.Add("Trung cấp trở lên");

        // 3) Ngoại ngữ / kỹ năng mềm hay gặp
        if (Regex.IsMatch(normLower, "tieng anh")) tags.Add("Giao tiếp tiếng Anh");
        if (Regex.IsMatch(normLower, "lam viec nhom|teamwork")) tags.Add("Kỹ năng làm việc nhóm");
        if (Regex.IsMatch(normLower, "doc lap")) tags.Add("Làm việc độc lập");

        return tags.Distinct().Take(MaxTagsPerGroup).ToList();
    }

    // ───────────────────────────── Quyền lợi ─────────────────────────────
    // Danh sách (regex trên chuỗi ĐÃ bỏ dấu, thường, "khong dau") -> tag hiển thị.
    private static readonly (string Pattern, string Tag)[] BenefitKeywords =
    {
        ("bao hiem xa hoi|bhxh", "Bảo hiểm xã hội"),
        ("bao hiem y te|bhyt", "Bảo hiểm y tế"),
        ("bao hiem suc khoe|kham suc khoe", "Khám sức khỏe định kỳ"),
        ("luong thang 13|thang 13", "Lương tháng 13"),
        ("thuong hieu suat|thuong theo kpi|thuong theo hieu qua", "Thưởng hiệu quả làm việc"),
        ("hoa hong", "Hoa hồng hấp dẫn"),
        ("du lich", "Du lịch hàng năm"),
        ("dao tao", "Được đào tạo"),
        ("nghi phep", "Nghỉ phép năm"),
        ("phu cap", "Phụ cấp"),
        ("laptop|macbook|thiet bi lam viec", "Cấp thiết bị làm việc"),
        (@"\bdata\b|\bsim\b|dien thoai", "Có hỗ trợ Data/SIM"),
        ("thang tien|lo trinh", "Lộ trình thăng tiến rõ ràng"),
        ("team building|sinh nhat|company trip", "Hoạt động Team Building"),
    };

    private static List<string> ExtractBenefitTags(string benefitText)
    {
        var norm = NormalizeForMatch(benefitText.ToLowerInvariant());
        var tags = new List<string>();
        foreach (var (pattern, tag) in BenefitKeywords)
        {
            if (Regex.IsMatch(norm, pattern))
                tags.Add(tag);
            if (tags.Count >= MaxTagsPerGroup) break;
        }
        return tags;
    }

    // ───────────────────────────── Chuyên môn ─────────────────────────────
    private static List<string> ExtractExpertiseTags(string text, IEnumerable<Skill>? allSkills, string? categoryName)
    {
        var tags = new List<string>();
        var normalized = NormalizeForMatch(text);

        if (allSkills != null)
        {
            foreach (var skill in allSkills)
            {
                if (string.IsNullOrWhiteSpace(skill.Name)) continue;
                var normSkill = NormalizeForMatch(skill.Name);
                if (normSkill.Length >= 2 && normalized.Contains(normSkill))
                {
                    tags.Add(skill.Name);
                    if (tags.Count >= MaxTagsPerGroup) break;
                }
            }
        }

        // Bổ sung các cụm viết tắt trong ngoặc (VD: "(B2B)", "(SEO)", "(KPI)") — thường là thuật ngữ
        // chuyên môn đặc thù mà danh mục Skill chưa có sẵn.
        if (tags.Count < MaxTagsPerGroup)
        {
            var acronyms = Regex.Matches(text, @"\(([A-Z][A-Z0-9]{1,5})\)")
                .Select(m => m.Groups[1].Value)
                .Where(a => !tags.Contains(a))
                .Distinct();
            foreach (var a in acronyms)
            {
                tags.Add(a);
                if (tags.Count >= MaxTagsPerGroup) break;
            }
        }

        if (tags.Count == 0 && !string.IsNullOrWhiteSpace(categoryName))
        {
            tags.Add(categoryName);
        }

        return tags.Take(MaxTagsPerGroup).ToList();
    }

    /// <summary>Bỏ dấu tiếng Việt + hạ chữ thường, GIỮ khoảng trắng (khác SlugHelper — không nối liền thành slug).</summary>
    private static string NormalizeForMatch(string input)
    {
        if (string.IsNullOrEmpty(input)) return "";
        var lower = input.ToLowerInvariant().Replace('đ', 'd');
        var formD = lower.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in formD)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        return Regex.Replace(sb.ToString().Normalize(NormalizationForm.FormC), @"\s+", " ").Trim();
    }
}