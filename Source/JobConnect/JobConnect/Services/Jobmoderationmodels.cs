// [SERVICE-DTO-ADDED]
// DTO cho tính năng KIỂM DUYỆT AI bài đăng tuyển dụng (JobModerationRequest = dữ liệu
// đầu vào ghép vào prompt; JobModerationResult/JobModerationModule = kết quả trả về).
// CompanyTrustScore và SimilarityPercent được HỆ THỐNG (JobModerationService) tính toán
// khách quan từ DB trước khi gửi cho AI — không để AI tự đoán 2 giá trị này.
namespace JobConnect.Services;

public class JobModerationRequest
{
    public string JobTitle { get; set; } = "";
    public string JobDescription { get; set; } = "";
    public string Salary { get; set; } = "";
    public string CompanyName { get; set; } = "";
    public string? Website { get; set; }
    public string? Email { get; set; }
    public string? Location { get; set; }
    public string? Requirements { get; set; }
    public string? Benefits { get; set; }
    public string? Skills { get; set; }

    /// <summary>0-100, do hệ thống tính sẵn (xem JobModerationService.CalculateCompanyTrustScore). Null = chưa có dữ liệu.</summary>
    public int? CompanyTrustScore { get; set; }

    /// <summary>0-100, do hệ thống tính sẵn (so khớp với các JobPost khác). Null = chưa có dữ liệu.</summary>
    public int? SimilarityPercent { get; set; }
}

public class JobModerationIssue
{
    public string Issue { get; set; } = "";
    public string Evidence { get; set; } = "";
}

public class JobModerationModule
{
    public string Name { get; set; } = "";
    public int Score { get; set; }
    public List<JobModerationIssue> Issues { get; set; } = new();
}

public class JobModerationResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }

    public int OverallRisk { get; set; }
    public string Recommendation { get; set; } = "ManualReview"; // Approve | ManualReview | Reject
    public string Summary { get; set; } = "";
    public List<JobModerationModule> Modules { get; set; } = new();

    /// <summary>
    /// True nếu OverallRisk/Recommendation ở trên là kết quả ĐÃ ĐƯỢC HỆ THỐNG (C#) tính lại/áp
    /// override — không phải nguyên văn số AI trả về. Luôn true khi Success = true, vì
    /// JobModerationService không bao giờ tin trực tiếp phép tính risk của model (đề phòng
    /// model tính sai hoặc bị prompt injection thao túng con số cuối).
    /// </summary>
    public bool RiskRecalculatedByServer { get; set; }

    /// <summary>True nếu kết quả này lấy từ cache (bảng JobModerationLog) do nội dung tin
    /// chưa đổi từ lần chấm AI trước — không tốn thêm lượt gọi AI nào cho lần này.</summary>
    public bool FromCache { get; set; }
}