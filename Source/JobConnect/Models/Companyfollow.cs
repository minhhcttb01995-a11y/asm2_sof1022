// [MODEL-HEADER-ADDED]
// Bảng lưu việc 1 User (ứng viên) BẤM THEO DÕI (follow) 1 công ty (Employer) —
// dùng để gợi ý/thông báo khi công ty đó đăng tin tuyển dụng mới.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class CompanyFollow
{
    public int FollowId { get; set; }

    public int UserId { get; set; }

    public int EmployerId { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual Employer Employer { get; set; } = null!;
}
