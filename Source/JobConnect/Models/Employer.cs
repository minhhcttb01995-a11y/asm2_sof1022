using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Employer
{
    public int EmployerId { get; set; }

    /// <summary>Mã công ty - ngẫu nhiên, không trùng (VD: CTY7K2A9F).</summary>
    public string? CompanyCode { get; set; }

    public int UserId { get; set; }

    public string CompanyName { get; set; } = null!;

    public string? TaxCode { get; set; }

    public string? Industry { get; set; }

    public string? CompanySize { get; set; }

    public string? Address { get; set; }

    /// <summary>Giới tính của người đại diện tuyển dụng (Nam / Nữ / Khác).</summary>
    public string? Gender { get; set; }

    /// <summary>Số CCCD của người đại diện tuyển dụng.</summary>
    public string? CCCD { get; set; }

    public string? Website { get; set; }

    public string? LogoUrl { get; set; }

    public string? CoverUrl { get; set; }

    // Compatibility aliases (some views/controllers expect LogoURL / CoverURL)
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? LogoURL
    {
        get => LogoUrl;
        set => LogoUrl = value;
    }

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? CoverURL
    {
        get => CoverUrl;
        set => CoverUrl = value;
    }

    public bool IsVerified { get; set; }

    public bool IsLocked { get; set; }

    /// <summary>Đánh dấu công ty "Hot" để hiển thị nổi bật ở trang chủ.</summary>
    public bool IsFeatured { get; set; }

    public string Status { get; set; } = "Active";

    public string? Description { get; set; }

    public string? WhyWorkHereJson { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();

    public virtual User User { get; set; } = null!;

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public List<CompanyHighlight> WhyWorkHereItems { get; internal set; } = new();
}