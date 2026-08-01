// ═══════════════════════════════════════════════════════════════════════════
// RuleBasedContentModeration — chấm 5 module Spam/Scam/Violence/Hate/Adult
// 100% BẰNG C# (không gọi AI), theo đúng pattern ComputeFakeSalaryModule /
// ComputeMissingInformationModule đã có trong Jobmoderationservice.cs.
//
// CÁCH DÙNG: gọi RuleBasedContentModeration.ComputeAll(job) thay cho
// _gemini.AnalyzeJobModerationAsync(request) trong BuildAiRequestAndCallAsync.
//
// GIỚI HẠN THẬT SỰ (đọc kỹ trước khi coi đây là "xong"):
//   - Bắt được: từ khóa lộ liễu, số điện thoại/link lạ, "việc nhẹ lương cao",
//     yêu cầu chuyển khoản trước, chửi thề/miệt thị trực tiếp, nội dung 18+ rõ ràng.
//   - KHÔNG bắt được: lừa đảo tinh vi không dùng từ khóa đặc trưng, mỉa mai/ẩn ý,
//     nội dung phân biệt gián tiếp không có từ nhạy cảm, kẻ gian cố tình viết
//     "l.ừa đ.ảo", "chuyển khoản" -> "chuyển khoảng", chèn khoảng trắng/ký tự lạ
//     giữa các chữ để né keyword (đã xử lý 1 phần bằng NormalizeForMatching, nhưng
//     không thể chống 100%).
//   - Vì vậy nên dùng theo mô hình HYBRID (khuyến nghị ở cuối file) chứ không nên
//     cắt AI hoàn toàn 100% ngay từ đầu.
// ═══════════════════════════════════════════════════════════════════════════
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using JobConnect.Models;

namespace JobConnect.Services;

public static class RuleBasedContentModeration
{
    // Chấm cả 5 module cùng lúc, trả về đúng dạng JobModerationResult như Gemini trả về,
    // để JobModerationService.RecalculateRisk dùng lại được nguyên xi, không cần sửa gì thêm.
    public static JobModerationResult ComputeAll(JobPost job)
    {
        var rawText = $"{job.Title}\n{job.Description}\n{job.Requirements}\n{job.Benefits}";
        var norm = NormalizeForMatching(rawText);

        var modules = new List<JobModerationModule>
        {
            ComputeSpam(job, rawText, norm),
            ComputeScam(rawText, norm),
            ComputeViolence(norm),
            ComputeHate(norm),
            ComputeAdult(norm)
        };

        return new JobModerationResult
        {
            Success = true,
            Summary = "Chấm bằng luật/từ khóa (rule-based), không qua AI.",
            Modules = modules,
            OverallRisk = 0,              // JobModerationService.RecalculateRisk sẽ tính lại
            Recommendation = "ManualReview",
            RiskRecalculatedByServer = false
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // CHUẨN HÓA TEXT — bước quan trọng nhất để rule-based đỡ bị "né" bằng
    // cách chèn khoảng trắng/dấu chấm/số thay chữ (l.ừa đ.ảo, ch4t zalo...).
    // ─────────────────────────────────────────────────────────────────────
    private static string NormalizeForMatching(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";

        var lower = text.ToLowerInvariant();

        // Bỏ dấu tiếng Việt để bắt được cả biến thể không dấu ("lua dao", "viec nhe luong cao")
        var noAccent = RemoveVietnameseDiacritics(lower);

        // Thay số hay bị dùng thay chữ cái (leetspeak nhẹ, phổ biến trong tin rác VN)
        noAccent = noAccent
            .Replace("4", "a").Replace("3", "e").Replace("1", "i")
            .Replace("0", "o").Replace("5", "s").Replace("@", "a");

        // Gộp các ký tự chèn giữa để né keyword: "l.ừ.a đ ả o" -> "lua dao"
        noAccent = Regex.Replace(noAccent, @"[\.\-_\*]+", "");
        noAccent = Regex.Replace(noAccent, @"\s{2,}", " ");

        return noAccent;
    }

    private static string RemoveVietnameseDiacritics(string text)
    {
        var normalized = text.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(c);
            if (category != UnicodeCategory.NonSpacingMark) sb.Append(c);
        }
        return sb.ToString().Replace('đ', 'd').Replace('Đ', 'D').Normalize(NormalizationForm.FormC);
    }

    // Helper: cộng điểm nếu khớp 1 trong danh sách cụm từ (đã chuẩn hóa), ghi issue kèm bằng chứng.
    private static void ScanPhrases(string normText, string rawTextForEvidence, IEnumerable<(string phrase, int weight, string label)> rules,
        List<JobModerationIssue> issues, ref int score)
    {
        foreach (var (phrase, weight, label) in rules)
        {
            if (normText.Contains(phrase))
            {
                issues.Add(new JobModerationIssue { Issue = label, Evidence = phrase });
                score += weight;
            }
        }
    }

    // Bỏ thẻ HTML (Quill editor lưu content dạng "<p>...</p>") để lấy text thật, tính độ dài
    // nội dung có nghĩa chính xác hơn là đếm luôn cả ký tự "<p>", "</p>".
    private static string StripHtml(string? html)
    {
        if (string.IsNullOrWhiteSpace(html)) return "";
        var noTags = Regex.Replace(html, "<[^>]+>", " ");
        // Bỏ HTML entity phổ biến (&nbsp;...) để không tính nhầm là "có nội dung".
        noTags = Regex.Replace(noTags, "&[a-zA-Z]+;", " ");
        return Regex.Replace(noTags, @"\s+", " ").Trim();
    }

    // ═════════════════════════ 1. SPAM ═════════════════════════
    private static JobModerationModule ComputeSpam(JobPost job, string rawText, string normText)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;

        // ─── Kiểm tra RÁC THEO TỪNG FIELD (quan trọng nhất — bắt đúng case: Title bình
        // thường nhưng Description/Requirements/Benefits là chữ gõ bậy như "<p>CăDwad</p>").
        // Nếu gộp chung tất cả field lại để tính độ dài thì Title hợp lệ sẽ "che" mất field
        // rác, nên phải kiểm tra riêng từng field quan trọng.
        void CheckFieldGibberish(string? fieldValue, string fieldLabel)
        {
            var stripped = StripHtml(fieldValue);
            var len = stripped.Replace(" ", "").Length;
            if (len == 0) return; // rỗng đã có MissingInformationDetection xử lý riêng, không tính trùng ở đây

            if (len < 10)
            {
                issues.Add(new JobModerationIssue
                {
                    Issue = $"Trường \"{fieldLabel}\" gần như trống/vô nghĩa (dưới 10 ký tự thật)",
                    Evidence = stripped
                });
                score += 55;
            }
            else if (len < 25)
            {
                issues.Add(new JobModerationIssue
                {
                    Issue = $"Trường \"{fieldLabel}\" quá ngắn so với nội dung tin tuyển dụng bình thường",
                    Evidence = stripped
                });
                score += 25;
            }
        }

        CheckFieldGibberish(job.Description, "Mô tả công việc");
        CheckFieldGibberish(job.Requirements, "Yêu cầu công việc");
        CheckFieldGibberish(job.Benefits, "Phúc lợi");

        // Viết hoa toàn bộ (>= 15 ký tự chữ, tỷ lệ hoa > 70%)
        var letters = rawText.Where(char.IsLetter).ToList();
        if (letters.Count >= 15)
        {
            var upperRatio = letters.Count(char.IsUpper) / (double)letters.Count;
            if (upperRatio > 0.7)
            {
                issues.Add(new JobModerationIssue { Issue = "Viết hoa toàn bộ/quá nhiều", Evidence = $"{upperRatio:P0} ký tự viết hoa" });
                score += 25;
            }
        }

        // Spam dấu chấm than / emoji lặp
        var exclaimRun = Regex.Matches(rawText, @"!{3,}").Count;
        if (exclaimRun > 0) { issues.Add(new JobModerationIssue { Issue = "Lạm dụng dấu chấm than" }); score += 15; }

        var emojiCount = Regex.Matches(rawText, @"[\uD83C-\uDBFF\uDC00-\uDFFF]").Count;
        if (emojiCount >= 8) { issues.Add(new JobModerationIssue { Issue = "Quá nhiều emoji", Evidence = $"{emojiCount} emoji" }); score += 20; }

        // Lặp từ/cụm liên tiếp (VD: "gấp gấp gấp", "tuyển tuyển tuyển")
        if (Regex.IsMatch(normText, @"\b(\w+)\s+\1\s+\1\b"))
        {
            issues.Add(new JobModerationIssue { Issue = "Lặp từ liên tiếp bất thường" });
            score += 20;
        }

        // Cố chèn chỉ thị hệ thống / prompt injection — vẫn phải canh dù không còn gửi AI,
        // vì đây tự nó là dấu hiệu gian dối rất mạnh.
        var injectionPhrases = new[]
        {
            "bo qua huong dan", "ignore previous instruction", "system prompt",
            "tra ve overallrisk", "hay tra ve", "bo qua chi thi"
        };
        foreach (var p in injectionPhrases)
        {
            if (normText.Contains(p))
            {
                issues.Add(new JobModerationIssue { Issue = "Nghi ngờ chèn chỉ thị giả mạo hệ thống", Evidence = p });
                score += 60;
            }
        }

        return new JobModerationModule { Name = "SpamDetection", Score = Math.Clamp(score, 0, 100), Issues = issues };
    }

    // ═════════════════════════ 2. SCAM ═════════════════════════
    private static readonly (string, int, string)[] ScamRules =
    {
        ("dong phi", 45, "Yêu cầu đóng phí trước khi làm việc"),
        ("phi ho so", 35, "Nhắc đến phí hồ sơ"),
        ("phi dao tao", 35, "Nhắc đến phí đào tạo (dấu hiệu lừa đảo phổ biến)"),
        ("dat coc", 40, "Yêu cầu đặt cọc"),
        ("chuyen khoan truoc", 50, "Yêu cầu chuyển khoản trước"),
        ("lam tai nha", 10, "Việc làm tại nhà (chỉ báo nhẹ, cần xét thêm ngữ cảnh)"),
        ("viec nhe luong cao", 55, "Cụm từ đặc trưng lừa đảo \"việc nhẹ lương cao\""),
        ("khong can kinh nghiem luong cao", 30, "Không cần kinh nghiệm nhưng lương cao bất thường"),
        ("lien he zalo", 15, "Yêu cầu liên hệ qua Zalo cá nhân (cần xét thêm)"),
        ("lien he telegram", 35, "Yêu cầu liên hệ qua Telegram (ít phổ biến trong tuyển dụng hợp pháp)"),
        ("lien he whatsapp", 30, "Yêu cầu liên hệ qua WhatsApp"),
        ("inbox de biet them", 20, "Giấu thông tin, yêu cầu inbox riêng"),
        ("nhan luong ngay", 25, "Cam kết nhận lương ngay bất thường"),
        ("khong phong van", 20, "Không phỏng vấn vẫn nhận (bất thường với vị trí có yêu cầu)"),
        ("thu nhap khung", 20, "Cụm từ phóng đại thu nhập"),
    };

    private static JobModerationModule ComputeScam(string rawText, string normText)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;

        ScanPhrases(normText, rawText, ScamRules, issues, ref score);

        // Có số điện thoại cá nhân nhưng KHÔNG có email/website công ty nào trong text
        // (đã có field email/website riêng ở CompanyTrust, ở đây chỉ xét trong nội dung mô tả).
        var hasPhone = Regex.IsMatch(rawText, @"(0|\+84)(\d[\s\.\-]?){8,9}\d");
        var hasLink = Regex.IsMatch(normText, @"(bit\.ly|tinyurl|shorten|t\.me/)");
        if (hasLink)
        {
            issues.Add(new JobModerationIssue { Issue = "Chứa link rút gọn/link lạ đáng ngờ" });
            score += 35;
        }
        if (hasPhone && normText.Contains("zalo"))
        {
            issues.Add(new JobModerationIssue { Issue = "Combo SĐT cá nhân + Zalo (mẫu hình thường gặp ở tin rác/lừa đảo)" });
            score += 10;
        }

        return new JobModerationModule { Name = "ScamDetection", Score = Math.Clamp(score, 0, 100), Issues = issues };
    }

    // ═════════════════════════ 3. VIOLENCE ═════════════════════════
    private static readonly (string, int, string)[] ViolenceRules =
    {
        ("danh nhau", 60, "Nhắc đến đánh nhau"),
        ("bao luc", 55, "Từ khóa bạo lực"),
        ("de doa", 65, "Từ khóa đe dọa"),
        ("thanh toan doi thu", 70, "Kêu gọi \"thanh toán\" đối thủ (ẩn ý bạo lực)"),
        ("giet", 80, "Từ khóa cực đoan nghiêm trọng"),
        ("khung bo", 90, "Từ khóa khủng bố"),
        ("vu khi", 40, "Nhắc đến vũ khí (cần xét ngữ cảnh, có thể hợp lệ với ngành bảo vệ/an ninh)"),
    };

    private static JobModerationModule ComputeViolence(string normText)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;
        ScanPhrases(normText, normText, ViolenceRules, issues, ref score);
        return new JobModerationModule { Name = "ViolenceDetection", Score = Math.Clamp(score, 0, 100), Issues = issues };
    }

    // ═════════════════════════ 4. HATE SPEECH ═════════════════════════
    // LƯU Ý: yêu cầu tuyển dụng đặc thù hợp pháp (VD: "chỉ tuyển nam do tính chất công việc
    // bảo vệ/bốc vác") KHÔNG được tính là vi phạm — vì vậy KHÔNG chấm điểm chỉ vì có
    // "chỉ tuyển nam"/"chỉ tuyển nữ" đơn thuần, CHỈ chấm khi đi kèm ngôn từ miệt thị/xúc phạm.
    private static readonly (string, int, string)[] HateRules =
    {
        ("ngu nhu", 60, "Ngôn từ miệt thị trí tuệ theo nhóm người"),
        ("bo doi", 0, ""), // placeholder tránh false-positive, không dùng
        ("man rợ", 50, "Ngôn từ miệt thị"),
        ("phan biet chung toc", 70, "Nhắc trực tiếp đến phân biệt chủng tộc"),
        ("ky thi vung mien", 65, "Kỳ thị vùng miền"),
        ("khong tuyen nguoi mien", 55, "Từ chối tuyển theo vùng miền (kỳ thị vùng miền)"),
        ("khong nhan nguoi dan toc", 70, "Từ chối tuyển theo dân tộc (kỳ thị)"),
    };

    private static JobModerationModule ComputeHate(string normText)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;
        ScanPhrases(normText, normText, HateRules.Where(r => r.Item2 > 0), issues, ref score);
        return new JobModerationModule { Name = "HateSpeechDetection", Score = Math.Clamp(score, 0, 100), Issues = issues };
    }

    // ═════════════════════════ 5. ADULT CONTENT ═════════════════════════
    private static readonly (string, int, string)[] AdultRules =
    {
        ("massage kin", 70, "Dịch vụ massage kín (dấu hiệu nội dung người lớn)"),
        ("massage nhay cam", 75, "Massage nhạy cảm"),
        ("khieu dam", 90, "Từ khóa khiêu dâm trực tiếp"),
        ("gai goi", 90, "Từ khóa mại dâm"),
        ("18+", 40, "Ghi rõ 18+ (cần xét thêm ngữ cảnh, có thể là ngành giải trí hợp pháp)"),
        ("ngoai hinh nong bong", 30, "Yêu cầu ngoại hình gợi cảm bất thường so với công việc"),
        ("tiep khach nam", 45, "Cụm từ thường gắn với dịch vụ nhạy cảm"),
        ("phuc vu nhu cau", 40, "Cụm từ mơ hồ thường gắn với dịch vụ người lớn"),
    };

    private static JobModerationModule ComputeAdult(string normText)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;
        ScanPhrases(normText, normText, AdultRules, issues, ref score);
        return new JobModerationModule { Name = "AdultContentDetection", Score = Math.Clamp(score, 0, 100), Issues = issues };
    }
}