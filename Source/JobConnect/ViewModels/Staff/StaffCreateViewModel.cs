using System.ComponentModel.DataAnnotations;

namespace JobConnect.ViewModels.Staff;

public class StaffCreateViewModel
{
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    [StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ tên là bắt buộc")]
    [StringLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "CCCD là bắt buộc")]
    [StringLength(20, MinimumLength = 9, ErrorMessage = "CCCD phải từ 9-20 ký tự")]
    [RegularExpression(@"^\d+$", ErrorMessage = "CCCD chỉ được chứa số")]
    public string CCCD { get; set; } = string.Empty;

    [StringLength(20)]
    [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
    public string? Phone { get; set; }

    [StringLength(20)]
    public string? Gender { get; set; }


    [StringLength(100)]
    public string Position { get; set; } = string.Empty;

    [StringLength(100)]
    public string Department { get; set; } = string.Empty;

    public string? Role { get; set; }
}