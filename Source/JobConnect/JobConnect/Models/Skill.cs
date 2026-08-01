// [MODEL-HEADER-ADDED]
// Bảng danh mục KỸ NĂNG (VD: "C#", "Thiết kế đồ họa"...), thuộc 1 Category, dùng
// để gắn vào hồ sơ ứng viên (CandidateSkill) và lọc/tìm kiếm ứng viên phù hợp.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Skill
{
    public int SkillId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public int? CategoryId { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();

    public virtual Category? Category { get; set; }

    // Compatibility alias for views/controllers expecting SkillID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int SkillID
    {
        get => SkillId;
        set => SkillId = value;
    }
}
