// [MODEL-HEADER-ADDED]
// Bảng nối (many-to-many) giữa CandidateProfile và Skill: lưu ứng viên nào có
// kỹ năng gì, mức độ thành thạo (ProficiencyLevel: Beginner..Expert) và số năm
// kinh nghiệm với kỹ năng đó.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class CandidateSkill
{
    public int ProfileId { get; set; }

    public int SkillId { get; set; }

    // Store as enum for clearer usage across controllers/views
    public ProficiencyLevel ProficiencyLevel { get; set; }

    public decimal YearsOfExperience { get; set; }

    public DateTime? LastUsedDate { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual CandidateProfile Profile { get; set; } = null!;

    public virtual Skill Skill { get; set; } = null!;

    // Compatibility alias for skill id
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int SkillID
    {
        get => SkillId;
        set => SkillId = value;
    }
}
