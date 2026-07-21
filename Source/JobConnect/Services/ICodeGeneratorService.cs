// [SERVICE-IFACE-HEADER-ADDED]
// Interface cho dịch vụ sinh MÃ ĐỊNH DANH (UserCode, CompanyCode, JobCode, BlogCode,
// StaffCode) hiển thị cho người dùng dễ nhớ hơn là ID số. Cài đặt bởi CodeGeneratorService.cs.
namespace JobConnect.Services;

/// <summary>
/// Sinh mã định danh cho các loại đối tượng trong hệ thống.
/// - Người dùng (Ứng viên/Nhà tuyển dụng): mã TỰ TĂNG dựa theo UserId (không cần kiểm tra trùng).
/// - Công ty / Tin tuyển dụng / Blog / Nhân viên: mã NGẪU NHIÊN, có kiểm tra trùng trong CSDL.
/// </summary>
public interface ICodeGeneratorService
{
    /// <summary>Mã người dùng - tự tăng theo UserId. VD: Candidate -> UV000042, Employer -> NTD000022.</summary>
    string GenerateUserCode(string role, int userId);

    /// <summary>Mã công ty ngẫu nhiên, đảm bảo không trùng. VD: CTY7K2A9F.</summary>
    Task<string> GenerateCompanyCodeAsync();

    /// <summary>Mã tin tuyển dụng ngẫu nhiên, đảm bảo không trùng. VD: TD4B8X1C.</summary>
    Task<string> GenerateJobCodeAsync();

    /// <summary>Mã bài blog ngẫu nhiên, đảm bảo không trùng. VD: BL9Q3M7Z.</summary>
    Task<string> GenerateBlogCodeAsync();

    /// <summary>Mã nhân viên ngẫu nhiên (không dấu gạch ngang), đảm bảo không trùng. VD: NV5H2K8P.</summary>
    Task<string> GenerateStaffCodeAsync();
}
