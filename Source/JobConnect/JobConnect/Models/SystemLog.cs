// [MODEL-HEADER-ADDED]
// Bảng LOG HỆ THỐNG chung (khác với ActivityLog chỉ dành cho Staff): ghi lại hành
// động của BẤT KỲ User nào (đăng nhập, đăng ký...) kèm IP và chi tiết, phục vụ audit/debug.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class SystemLog
{
    public int LogId { get; set; }

    public int? UserId { get; set; }

    public string Action { get; set; } = null!;

    public string? Ipaddress { get; set; }

    public string? Detail { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User? User { get; set; }
}
