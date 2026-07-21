// [[FILE-HEADER-ADDED]]
// ViewModel cho trang "AI CV Builder" (CandidateController.AiCvBuilder):
// gom toàn bộ dữ liệu người dùng nhập (họ tên, kỹ năng, kinh nghiệm...) để gửi
// cho GeminiService sinh CV, cùng với Result (kết quả AI trả về) để hiển thị lại view.
using JobConnect.Services;
using Microsoft.AspNetCore.Http;

namespace JobConnect.ViewModels;

public class AiCvBuilderViewModel
{
    public string FullName { get; set; } = "";
    public string JobTitle { get; set; } = "";
    public int ExperienceYears { get; set; }
    public string Skills { get; set; } = "";
    public string Education { get; set; } = "";
    public string WorkHistory { get; set; } = "";
    public string Achievements { get; set; } = "";

    // Thông tin liên hệ hiển thị trên CV (không qua AI, lấy trực tiếp từ hồ sơ / người dùng nhập)
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }

    // Ngôn ngữ: raw text người dùng nhập, AI sẽ chuẩn hoá thành danh sách gọn
    public string Languages { get; set; } = "";

    // Người tham chiếu: KHÔNG qua AI (tránh AI bịa thông tin liên hệ của người thật).
    // Mỗi dòng dạng: "Họ tên - Chức vụ - Công ty - SĐT - Email"
    public string References { get; set; } = "";

    // Ảnh đại diện
    public IFormFile? PhotoFile { get; set; }
    public string? PhotoUrl { get; set; }

    public AiCvResult? Result { get; set; }
    public List<string>? ReferenceLines { get; set; }
    public string? ErrorMessage { get; set; }
}
