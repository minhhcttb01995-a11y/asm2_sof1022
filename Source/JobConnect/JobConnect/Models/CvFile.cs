// [MODEL-HEADER-ADDED]
// Bảng FILE CV mà ứng viên tải lên (PDF/DOCX). 1 CandidateProfile có thể có
// nhiều CV, và có thể chọn 1 CV làm mặc định (IsDefault) khi ứng tuyển nhanh.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class CvFile
{
    public int Cvid { get; set; }

    public int ProfileId { get; set; }

    public string FileName { get; set; } = null!;

    public string FilePath { get; set; } = null!;

    public long? FileSize { get; set; }

    public bool IsDefault { get; set; }

    public DateTime UploadedAt { get; set; }

    public virtual ICollection<Application> Applications { get; set; } = new List<Application>();

    public virtual CandidateProfile Profile { get; set; } = null!;
}
