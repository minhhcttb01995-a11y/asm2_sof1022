// [MODEL-HEADER-ADDED]
// Bảng ghi log hoạt động của NHÂN VIÊN (Staff) trong hệ thống quản trị:
// mỗi khi Staff thực hiện 1 hành động quan trọng (khóa tài khoản, duyệt tin...),
// hệ thống lưu lại Action + mô tả + IP + trình duyệt vào bảng này để tra soát sau này.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class ActivityLog
{
    public int Id { get; set; }

    public int StaffId { get; set; }

    public string Action { get; set; } = null!;

    public string? Description { get; set; }

    public string? IpAddress { get; set; }

    public string? UserAgent { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Staff Staff { get; set; } = null!;
}
