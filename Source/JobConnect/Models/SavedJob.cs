// [MODEL-HEADER-ADDED]
// Bảng TIN ĐÃ LƯU: User bấm "lưu tin" cho 1 JobPost để xem lại sau, không phải là
// ứng tuyển (khác với bảng Application).
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class SavedJob
{
    public int SaveId { get; set; }

    public int UserId { get; set; }

    public int JobId { get; set; }

    public DateTime SavedAt { get; set; }

    public virtual JobPost Job { get; set; } = null!;

    // Compatibility alias for views/controllers expecting JobPost
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public JobPost JobPost
    {
        get => Job;
        set => Job = value;
    }

    public virtual User User { get; set; } = null!;
}
