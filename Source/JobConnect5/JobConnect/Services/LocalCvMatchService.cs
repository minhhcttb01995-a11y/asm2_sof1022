// [[SERVICE-IMPL-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// LocalCvMatchService — thuật toán so khớp CV ứng viên với tin tuyển dụng MÀ
// KHÔNG CẦN GỌI AI (chạy nội bộ, nhanh, miễn phí) — dùng làm phương án chính
// hoặc dự phòng khi không dùng GeminiService.
// Cách hoạt động (CalculateMatch):
//   1) Ưu tiên so khớp theo danh sách Skill có sẵn trong hệ thống: kiểm tra tên
//      kỹ năng nào xuất hiện cả trong CV lẫn trong tin tuyển dụng (title+description
//      +requirements) -> tính tỉ lệ trùng khớp = độ phù hợp.
//   2) Nếu tin tuyển dụng không nhắc tới kỹ năng nào có trong danh mục Skill, dùng
//      phương án dự phòng: so khớp TẦN SUẤT TỪ KHÓA sau khi loại bỏ StopWords (từ
//      chung chung như "và", "của", "công ty"... không mang tính phân biệt ngành nghề).
//   3) LooksLikeCv: kiểm tra sơ bộ văn bản có "giống CV" hay không (đủ độ dài, có
//      cấu trúc...) để tránh chấm điểm phù hợp cho 1 file không phải CV.
// ═══════════════════════════════════════════════════════════════════════════
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace JobConnect.Services;

public class LocalCvMatchResult
{
    public bool LooksLikeCv { get; set; }
    public int? MatchPercent { get; set; }
    /// <summary>Lý do khi không tính được % (VD: file không giống CV, không đủ dữ liệu...).</summary>
    public string? Reason { get; set; }
}

public interface ILocalCvMatchService
{
    /// <summary>
    /// Tính % phù hợp giữa nội dung CV và tin tuyển dụng — ưu tiên so khớp theo danh sách kỹ năng (Skill)
    /// đã có sẵn trong hệ thống (tránh bị đánh lừa bởi các từ chung chung như "kinh nghiệm", "quản lý"
    /// xuất hiện ở mọi ngành nghề). Chỉ dùng so khớp từ khóa tần suất làm phương án dự phòng khi
    /// tin tuyển dụng không chứa kỹ năng nào nằm trong danh mục Skill.
    /// </summary>
    LocalCvMatchResult CalculateMatch(string cvText, string jobTitle, string jobDescription, string jobRequirements, IEnumerable<string> knownSkillNames);
}

public class LocalCvMatchService : ILocalCvMatchService
{
    // Từ chung chung / mang tính "văn bản kinh doanh - tuyển dụng" — loại khỏi tập từ khóa dự phòng
    // vì chúng xuất hiện ở hầu như MỌI ngành nghề (không riêng CV hay JD của 1 lĩnh vực cụ thể),
    // nên nếu không loại sẽ khiến CV ngành A vẫn "phù hợp" giả tạo với job ngành B hoàn toàn khác.
    private static readonly HashSet<string> StopWords = new(new[]
    {
        "va","cua","cho","voi","cac","la","co","duoc","trong","nay","den","tai","theo",
        "nhu","de","khi","hoac","nhung","mot","hay","tu","ve","neu","ban","chung","toi",
        "the","and","for","with","to","of","in","a","an","on","at","or","is","are",
        "will","be","as","by","this","that","we","you","your","our",
        "phat","trien","phattrien","san","pham","sanpham","kinh","doanh","kinhdoanh","gia","tri",
        "giatri","du","an","duan","muc","tieu","muctieu","chien","luoc","chienluoc","khach","hang",
        "khachhang","thi","truong","thitruong","cong","ty","congty","doi","ngu","doingu","nhom",
        "thanh","vien","thanhvien","vai","tro","vaitro","chuyen","mon","chuyenmon","gioi","thieu",
        "gioithieu","noi","dung","noidung","thong","tin","thongtin","hoat","dong","hoatdong",
        "quan","ly","quanly","ke","hoach","kehoach","xay","dung","xaydung","phuong","an","phuongan",
        "co","hoi","cohoi","thach","thuc","thachthuc","giai","phap","giaiphap","dinh","huong",
        "dinhhuong","tang","truong","tangtruong","loi","ich","loiich","hieu","qua","hieuqua",
        // Từ ngữ tuyển dụng / hồ sơ chung chung — xuất hiện ở CV/JD của MỌI ngành nghề, không đặc thù kỹ năng
        "kinh","nghiem","kinhnghiem","lam","viec","lamviec","cong","viec","congviec","yeu","cau",
        "yeucau","ung","vien","ungvien","tuyen","ungtuyen","vi","tri","vitri","nhan",
        "nhanvien","doanh","nghiep","doanhnghiep","moi","truong","moitruong","dam","bao",
        "dambao","chinh","xac","chinhxac","thuc","hien","thuchien","kiem","tra","kiemtra","dao",
        "tao","daotao","nghiepvu","linh","vuc","linhvuc","nganh","ky","dinhky",
        "an","toan","antoan","chat","luong","chatluong","phoi","hop","phoihop","ho","tro","hotro",
        "he","thong","hethong","dich","vu","dichvu","cham","soc","chamsoc","khoe","suc","suckhoe",
        "nang","luc","nangluc","kien","thuc","kienthuc","trach","nhiem","trachnhiem","cap","nhat",
        "capnhat","xu","xuly","van","phong","vanphong","uu","toiuu","hoc","tap","hoctap",
        "chuong","trinh","chuongtrinh","dai","hoc","daihoc","tot","nghiep","totnghiep","diem"
    });

    // Các cụm "tiêu đề mục" đặc trưng RIÊNG của CV — gần như không xuất hiện trong pitch deck,
    // hợp đồng, hay tài liệu kinh doanh khác. Yêu cầu khớp >= 2 cụm khác nhau mới coi là CV thật.
    private static readonly string[] CvSignals =
    {
        "kinh nghiem lam viec", "kinh nghiem", "qua trinh cong tac", "qua trinh lam viec",
        "hoc van", "trinh do hoc van", "trinh do chuyen mon",
        "ky nang", "ky nang chuyen mon", "ky nang mem",
        "muc tieu nghe nghiep", "dinh huong nghe nghiep",
        "thong tin ca nhan", "thong tin lien he ca nhan",
        "chung chi", "van bang", "tot nghiep loai",
        "curriculum vitae", "resume", "so yeu ly lich"
    };

    public LocalCvMatchResult CalculateMatch(string cvText, string jobTitle, string jobDescription, string jobRequirements, IEnumerable<string> knownSkillNames)
    {
        if (string.IsNullOrWhiteSpace(cvText))
            return new LocalCvMatchResult { LooksLikeCv = false, Reason = "Không đọc được nội dung file." };

        var cvNormalized = Normalize(cvText);

        // Bước 1: Kiểm tra văn bản có giống CV thật không.
        int signalCount = CvSignals.Count(sig => cvNormalized.Contains(sig));
        if (signalCount < 2)
        {
            return new LocalCvMatchResult
            {
                LooksLikeCv = false,
                Reason = "File này không giống định dạng CV (thiếu các mục như kinh nghiệm, kỹ năng, học vấn...). Có thể ứng viên nhầm file đính kèm."
            };
        }

        var jobRequirementsNormalized = Normalize($"{jobTitle} {jobRequirements}");

        // Bước 2 (CHÍNH): So khớp theo danh mục Skill có sẵn trong hệ thống — tín hiệu đáng tin cậy nhất
        // vì tên kỹ năng (VD: "Docker", "Kubernetes", "Dược lâm sàng") mang tính đặc thù ngành,
        // không dùng chung cho mọi lĩnh vực như các từ "kinh nghiệm", "quản lý"...
        var normalizedSkills = knownSkillNames
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(Normalize)
            .Where(s => s.Length >= 2)
            .Distinct()
            .ToList();

        var requiredSkills = normalizedSkills.Where(sk => jobRequirementsNormalized.Contains(sk)).ToList();

        if (requiredSkills.Count >= 2)
        {
            int matchedSkillCount = requiredSkills.Count(sk => cvNormalized.Contains(sk));
            var skillPercent = (int)Math.Round(matchedSkillCount * 100.0 / requiredSkills.Count);
            return new LocalCvMatchResult { LooksLikeCv = true, MatchPercent = Math.Clamp(skillPercent, 0, 100) };
        }

        // Bước 3 (DỰ PHÒNG): Job không khai báo đủ kỹ năng cụ thể -> tạm dùng so khớp từ khóa tần suất
        // (đã lọc rất kỹ các từ chung chung), CHỈ lấy từ Tiêu đề + Yêu cầu (bỏ Mô tả vì quá chung chung).
        var reqKeywords = ExtractKeywords($"{jobTitle} {jobRequirements}", maxKeywords: 20, minLength: 4);
        if (reqKeywords.Count == 0)
        {
            return new LocalCvMatchResult
            {
                LooksLikeCv = true,
                MatchPercent = null,
                Reason = "Tin tuyển dụng chưa mô tả đủ chi tiết (thiếu kỹ năng/yêu cầu cụ thể) để so khớp chính xác."
            };
        }

        int matched = reqKeywords.Count(kw => cvNormalized.Contains(kw));
        var percent = (int)Math.Round(matched * 100.0 / reqKeywords.Count);
        return new LocalCvMatchResult { LooksLikeCv = true, MatchPercent = Math.Clamp(percent, 0, 100) };
    }

    /// <summary>Bỏ dấu tiếng Việt + chuyển thường + gộp khoảng trắng, để so khớp ổn định khi trích từ PDF.</summary>
    private static string Normalize(string input)
    {
        var lower = input.ToLowerInvariant();
        var formD = lower.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in formD)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(c);
            if (category != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        var withDiacriticsRemoved = sb.ToString().Replace('đ', 'd').Normalize(NormalizationForm.FormC);
        return Regex.Replace(withDiacriticsRemoved, @"\s+", " ").Trim();
    }

    private static List<string> ExtractKeywords(string text, int maxKeywords, int minLength = 3)
    {
        if (string.IsNullOrWhiteSpace(text)) return new List<string>();

        var normalized = Normalize(text);
        var words = Regex.Matches(normalized, $@"[a-z0-9]{{{minLength},}}")
            .Select(m => m.Value)
            .Where(w => !StopWords.Contains(w))
            .ToList();

        return words
            .GroupBy(w => w)
            .OrderByDescending(g => g.Count())
            .Take(maxKeywords)
            .Select(g => g.Key)
            .ToList();
    }
}