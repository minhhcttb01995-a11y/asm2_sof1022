// [SERVICE-IFACE-HEADER-ADDED]
// Interface cho dịch vụ TÍCH HỢP AI (Google Gemini) — 2 tính năng: (1) tự động
// SINH NỘI DUNG CV (GenerateCvAsync) từ thông tin thô người dùng nhập, và (2)
// PHÂN TÍCH ĐỘ PHÙ HỢP giữa CV ứng viên và mô tả công việc (AnalyzeMatchAsync),
// trả về % phù hợp + điểm mạnh/điểm thiếu. Các class AiCvRequest/AiCvResult/
// AiMatchResult là DTO (gói dữ liệu) truyền vào/nhận về từ AI. Cài đặt bởi GeminiService.cs.
namespace JobConnect.Services;

public class AiCvRequest
{
    public string FullName { get; set; } = "";
    public string JobTitle { get; set; } = "";
    public int ExperienceYears { get; set; }
    public string Skills { get; set; } = ""; // free text, comma separated
    public string Education { get; set; } = "";
    public string WorkHistory { get; set; } = ""; // free text describing past jobs
    public string Achievements { get; set; } = "";
    public string Languages { get; set; } = ""; // free text, e.g. "tiếng Anh khá, tiếng Nhật N3"
    public string? Language { get; set; } = "vi";

    // ── Thông tin tin tuyển dụng cần "may đo" CV theo (tùy chọn) ──
    // Khi TargetJobTitle/TargetJobDescription/TargetJobRequirements có giá trị,
    // GeminiService sẽ chèn thêm hướng dẫn "ưu tiên nhấn mạnh phần nào khớp job"
    // vào prompt. KHÔNG dùng để yêu cầu AI bịa thêm kỹ năng/kinh nghiệm mới.
    public string? TargetJobTitle { get; set; }
    public string? TargetJobDescription { get; set; }
    public string? TargetJobRequirements { get; set; }
    public string? TargetCompanyName { get; set; }
}

public class AiCvResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string Summary { get; set; } = "";
    public List<string> Skills { get; set; } = new();
    public List<string> Experience { get; set; } = new();
    public List<string> Education { get; set; } = new();
    public List<string> Achievements { get; set; } = new();
    public List<string> Languages { get; set; } = new();
}

public class AiMatchResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public int MatchPercent { get; set; }
    public List<string> Strengths { get; set; } = new();
    public List<string> Gaps { get; set; } = new();
    public string Summary { get; set; } = "";
}

public interface IGeminiService
{
    Task<AiCvResult> GenerateCvAsync(AiCvRequest request);
    Task<AiMatchResult> AnalyzeMatchAsync(string candidateText, string jobText);

    /// <summary>
    /// Gọi AI phân tích 1 bài đăng tuyển dụng theo bộ tiêu chí kiểm duyệt (spam, scam,
    /// bạo lực, thù ghét, nội dung người lớn, lương ảo, trùng lặp, thiếu thông tin, uy tín
    /// công ty). Trả về điểm thô từng module do AI chấm; việc tính OverallRisk/Recommendation
    /// cuối cùng do JobModerationService đảm nhiệm (không dùng trực tiếp số AI trả về).
    /// </summary>
    Task<JobModerationResult> AnalyzeJobModerationAsync(JobModerationRequest request);
}