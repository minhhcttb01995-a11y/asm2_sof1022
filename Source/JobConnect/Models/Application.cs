// [MODEL-HEADER-ADDED]
// Bảng HỒ SƠ ỨNG TUYỂN: đại diện cho việc 1 ứng viên (CandidateProfile) nộp CV
// (CvFile) vào 1 tin tuyển dụng (JobPost). Có Status (đang chờ/đã duyệt/từ chối...)
// và có thể phát sinh nhiều buổi phỏng vấn (Interview). Các property Profile/CvFile
// bên dưới chỉ là "alias" (bí danh, [NotMapped]) để code cũ gọi tên khác vẫn chạy được.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Application
{
    public int AppID { get; set; }

    public int JobId { get; set; }

    public int ProfileId { get; set; }

    public int? Cvid { get; set; }

    public string? CoverLetter { get; set; }

    public string Status { get; set; } = null!;

    public DateTime AppliedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual CvFile? Cv { get; set; }

    public virtual ICollection<Interview> Interviews { get; set; } = new List<Interview>();

    public virtual JobPost Job { get; set; } = null!;

    // Mapped navigation property named CandidateProfile to match view/controller usage
    public virtual CandidateProfile CandidateProfile { get; set; } = null!;

    // Backwards-compatible alias for code referring to Profile
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public CandidateProfile Profile
    {
        get => CandidateProfile;
        set => CandidateProfile = value;
    }

    // Compatibility alias for Cv
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public CvFile? CvFile
    {
        get => Cv;
        set => Cv = value;
    }
}
