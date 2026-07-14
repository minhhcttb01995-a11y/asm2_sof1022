using System.ComponentModel.DataAnnotations;
using JobConnect.Models;

namespace JobConnect.ViewModels.Staff;

public class StaffEditViewModel
{
    public int Id { get; set; }

    [Required]
    [StringLength(20)]
    public string ApplicationUserId { get; set; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string EmployeeCode { get; set; } = string.Empty;

    [Required(ErrorMessage = "CCCD là bắt buộc")]
    [StringLength(20, MinimumLength = 9, ErrorMessage = "CCCD phải từ 9-20 ký tự")]
    [RegularExpression(@"^\d+$", ErrorMessage = "CCCD chỉ được chứa số")]
    public string CCCD { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [StringLength(20)]
    [Phone]
    public string? Phone { get; set; }

    [StringLength(20)]
    public string? Gender { get; set; }

    [StringLength(500)]
    public string? Avatar { get; set; }

    [Required]
    [StringLength(100)]
    public string Position { get; set; } = string.Empty;

    [StringLength(100)]
    public string Department { get; set; } = string.Empty;

    [Required]
    public string Status { get; set; } = "Active";

    public string? Role { get; set; }
}