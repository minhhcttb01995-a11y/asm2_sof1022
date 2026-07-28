// [MODEL-HEADER-ADDED]
// Bảng THÔNG BÁO trong hệ thống gửi cho 1 User cụ thể (VD: "Đơn ứng tuyển của bạn
// đã được duyệt"), có Type để phân loại và IsRead để biết đã đọc hay chưa.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Notification
{
    public int NotifId { get; set; }

    public int UserId { get; set; }

    public string Title { get; set; } = null!;

    public string? Content { get; set; }

    public string Type { get; set; } = null!;

    public bool IsRead { get; set; }

    public int? RelatedId { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;
}
