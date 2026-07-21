// [MODEL-HEADER-ADDED]
// Bảng TIN NHẮN riêng giữa 2 User (VD: nhà tuyển dụng nhắn ứng viên), có thể gắn
// với 1 JobPost cụ thể (JobId) để biết tin nhắn liên quan tới tin tuyển dụng nào.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Message
{
    public int MessageId { get; set; }

    public int SenderId { get; set; }

    public int ReceiverId { get; set; }

    public string Content { get; set; } = null!;

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? JobId { get; set; }

    public virtual JobPost? Job { get; set; }

    public virtual User Receiver { get; set; } = null!;

    public virtual User Sender { get; set; } = null!;
}
