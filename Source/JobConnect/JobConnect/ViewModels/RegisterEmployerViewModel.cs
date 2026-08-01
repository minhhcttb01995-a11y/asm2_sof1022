// [[FILE-HEADER-ADDED]]
// ViewModel cho form đăng ký tài khoản NHÀ TUYỂN DỤNG (AccountController.RegisterEmployer) —
// gồm cả thông tin tài khoản (email/mật khẩu) và thông tin công ty ban đầu.
using System.ComponentModel.DataAnnotations;

namespace JobConnect.ViewModels;

public class RegisterEmployerViewModel
{
    [Required] public string ContactName { get; set; } = string.Empty;
    [Required][EmailAddress] public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    [Required][MinLength(8)][DataType(DataType.Password)] public string Password { get; set; } = string.Empty;
    [Compare("Password")][DataType(DataType.Password)] public string ConfirmPassword { get; set; } = string.Empty;
    [Required] public string CompanyName { get; set; } = string.Empty;
    public string? TaxCode { get; set; }
    public string? Industry { get; set; }
    public string? Address { get; set; }
    public string? Website { get; set; }
    public bool AgreeTerms { get; set; }
}