// [MODEL-HEADER-ADDED]
// Bảng TIN TUYỂN DỤNG — cốt lõi của cả hệ thống: tiêu đề, mô tả, yêu cầu, quyền lợi,
// khoảng lương, loại hình công việc, địa điểm, hạn nộp hồ sơ, trạng thái duyệt
// (Status), lượt xem (ViewCount), có phải tin nổi bật hay không (IsFeatured).
// 1 tin thuộc 1 Employer và 1 Category, có nhiều Application/SavedJob/Report.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class JobPost
{
    public int JobId { get; set; }

    /// <summary>Mã tin tuyển dụng - ngẫu nhiên, không trùng (VD: TD4B8X1C).</summary>
    public string? JobCode { get; set; }

    public int EmployerId { get; set; }

    public int? CategoryId { get; set; }

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public string? Requirements { get; set; }

    public string? Benefits { get; set; }

    public decimal? SalaryMin { get; set; }

    public decimal? SalaryMax { get; set; }

    public bool SalaryNegotiable { get; set; }

    public string JobType { get; set; } = null!;

    public string? Location { get; set; }

    public string? ExperienceLevel { get; set; }

    public DateTime? Deadline { get; set; }

    public string Status { get; set; } = null!;

    public int ViewCount { get; set; }

    public bool IsFeatured { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Application> Applications { get; set; } = new List<Application>();

    public virtual Category? Category { get; set; }

    // Compatibility alias for CategoryID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int? CategoryID
    {
        get => CategoryId;
        set => CategoryId = value;
    }

    public virtual Employer Employer { get; set; } = null!;

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<SavedJob> SavedJobs { get; set; } = new List<SavedJob>();
}
