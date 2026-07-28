// [MODEL-HEADER-ADDED]
// Bảng BÁO CÁO VI PHẠM: User báo cáo 1 JobPost hoặc 1 Company (Employer) vi phạm
// (spam, lừa đảo, nội dung không phù hợp...). Report được Staff xử lý (ProcessedByStaff),
// có ghi chú xử lý (ProcessNote) và trạng thái (Status: Pending/InProgress/Resolved/Rejected).
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Report
{
    public int Id { get; set; }

    public int ReporterId { get; set; }

    public int ReporterType { get; set; }

    public ReportType ReportType { get; set; }

    public int? JobPostId { get; set; }

    public int? CompanyId { get; set; }

    public string? ReportedEntityName { get; set; }

    public string Reason { get; set; } = null!;

    public string? Description { get; set; }

    public ReportStatus Status { get; set; }

    public int? ProcessedByStaffId { get; set; }

    public string? ProcessNote { get; set; }

    public DateTime? ProcessedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Employer? Company { get; set; }

    public virtual JobPost? JobPost { get; set; }

    public virtual Staff? ProcessedByStaff { get; set; }

    public virtual User Reporter { get; set; } = null!;

    // Keep ReporterType wrapper for compatibility
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public ReporterType ReporterTypeEnum
    {
        get => (ReporterType)ReporterType;
        set => ReporterType = (int)value;
    }
}