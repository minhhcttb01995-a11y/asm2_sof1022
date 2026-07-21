// [MODEL-HEADER-ADDED]
// Bảng HỒ SƠ ỨNG VIÊN — thông tin chi tiết của 1 User có Role = Candidate:
// họ tên, ngày sinh, địa chỉ, chức danh mong muốn, mức lương mong muốn, có đang
// mở tìm việc hay không (IsOpenToWork). 1 hồ sơ có nhiều CV (CvFiles), nhiều kỹ
// năng (CandidateSkills) và nhiều đơn ứng tuyển (Applications).
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class CandidateProfile
{
    public int ProfileId { get; set; }

    public int UserId { get; set; }

    public string? FullName { get; set; }

    public string? Phone { get; set; }

    public string? Avatar { get; set; }

    public DateTime? DateOfBirth { get; set; }

    public string? Gender { get; set; }

    public string? Address { get; set; }

    public string? JobTitle { get; set; }

    public string? Summary { get; set; }

    public int ExperienceYears { get; set; }

    public decimal? DesiredSalary { get; set; }

    public bool IsOpenToWork { get; set; }

    public virtual ICollection<Application> Applications { get; set; } = new List<Application>();

    public virtual ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();

    public virtual ICollection<CvFile> CvFiles { get; set; } = new List<CvFile>();

    public virtual User User { get; set; } = null!;
}
