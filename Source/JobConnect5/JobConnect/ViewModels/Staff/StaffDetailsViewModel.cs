// [[FILE-HEADER-ADDED]]
// ViewModel cho trang xem chi tiết 1 nhân viên (StaffController.Details).
using JobConnect.Models;

namespace JobConnect.ViewModels.Staff;

public class StaffDetailsViewModel
{
    public int Id { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public string CCCD { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Gender { get; set; }
    public string? Avatar { get; set; }
    public string Position { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = "Active";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public List<ActivityLogViewModel> RecentActivities { get; set; } = new();
}

public class ActivityLogViewModel
{
    public int Id { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IpAddress { get; set; }
    public DateTime CreatedAt { get; set; }
}