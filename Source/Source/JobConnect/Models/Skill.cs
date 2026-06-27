using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

/// <summary>
/// Represents a skill that can be assigned to candidates
/// </summary>
public class Skill
{
    [Key]
    public int SkillID { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; set; }

    [Required]
    [StringLength(50)]
    public SkillCategory Category { get; set; } = SkillCategory.Programming;

    [Required]
    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public virtual ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();
}

/// <summary>
/// Skill categories for classification
/// </summary>
public enum SkillCategory
{
    Programming,
    Design,
    Marketing,
    SoftSkills,
    Language,
    Management,
    Other
}