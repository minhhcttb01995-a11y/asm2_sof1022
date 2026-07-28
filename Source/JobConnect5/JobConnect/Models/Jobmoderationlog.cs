// [MODEL-HEADER-ADDED]
// Bảng LƯU KẾT QUẢ KIỂM DUYỆT AI cho từng JobPost — mục đích CHÍNH là cache để
// tránh gọi lại Gemini API (tốn token) mỗi lần Staff mở lại trang duyệt tin.
// ContentHash = mã băm SHA-256 của các trường nội dung ảnh hưởng tới kiểm duyệt
// (Title, Description, Requirements, Benefits, Salary...). Nếu Employer sửa tin
// -> ContentHash đổi -> JobModerationService biết cần gọi lại AI; nếu không đổi
// -> trả thẳng kết quả cũ trong bảng này, không gọi AI.
namespace JobConnect.Models;

public class JobModerationLog
{
    public int Id { get; set; }

    public int JobId { get; set; }
    public virtual JobPost? Job { get; set; }

    /// <summary>SHA-256 hex của nội dung tin tại thời điểm chấm — dùng để biết khi nào cần chấm lại.</summary>
    public string ContentHash { get; set; } = "";

    public int OverallRisk { get; set; }
    public string Recommendation { get; set; } = "";
    public string? Summary { get; set; }

    /// <summary>Toàn bộ danh sách modules (score + issues) serialize dạng JSON để xem lại chi tiết.</summary>
    public string ModulesJson { get; set; } = "[]";

    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
}