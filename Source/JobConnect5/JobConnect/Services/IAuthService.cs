// [SERVICE-IFACE-HEADER-ADDED]
// Interface (hợp đồng) cho dịch vụ XÁC THỰC người dùng: đăng nhập, kiểm tra email
// đã tồn tại chưa, đăng ký tài khoản Ứng viên / Nhà tuyển dụng. Được cài đặt bởi
// AuthService.cs và đăng ký DI trong Program.cs (AddScoped<IAuthService, AuthService>).
// Controllers (AccountController) chỉ biết tới interface này, không phụ thuộc trực
// tiếp vào AuthService -> dễ thay thế/test.
using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Services;

public interface IAuthService
{
    Task<User?> LoginAsync(string email, string password);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> RegisterCandidateAsync(RegisterViewModel model);
    Task<bool> RegisterEmployerAsync(RegisterEmployerViewModel model);
}