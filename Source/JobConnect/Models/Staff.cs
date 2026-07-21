// [MODEL-HEADER-ADDED]
// Bảng HỒ SƠ NHÂN VIÊN nội bộ (Admin/Staff quản trị hệ thống) — gắn với 1 User
// (ApplicationUser) qua ApplicationUserId. Lưu mã nhân viên, chức vụ, phòng ban,
// trạng thái làm việc. Staff có thể xử lý Report, SupportTicket và có ActivityLog riêng.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Staff
{
    public int Id { get; set; }

    public int ApplicationUserId { get; set; }

    public string EmployeeCode { get; set; } = null!;

    public string? CCCD { get; set; }

    public string FullName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Avatar { get; set; }

    public string Position { get; set; } = null!;

    public string? Gender { get; set; }

    public string Department { get; set; } = null!;

    public string Status { get; set; } = "Active";

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<ActivityLog> ActivityLogs { get; set; } = new List<ActivityLog>();

    public virtual User ApplicationUser { get; set; } = null!;

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<SupportTicket> SupportTickets { get; set; } = new List<SupportTicket>();

    // Alias để tương thích với code gọi staff.User
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public User User => ApplicationUser;
}