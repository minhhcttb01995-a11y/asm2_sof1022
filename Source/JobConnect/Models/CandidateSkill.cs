using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

/// <summary>
/// Junction table representing a candidate's skill with proficiency details
/// </summary>
public class CandidateSkill
{
    [Key]
    [Column(Order = 1)]
    public int ProfileID { get; set; }

    [Key]
    [Column(Order = 2)]
    public int SkillID { get; set; }

    [Required]
    [StringLength(50)]
    public ProficiencyLevel ProficiencyLevel { get; set; } = ProficiencyLevel.Intermediate;

    [Range(0, 50)]
    public decimal YearsOfExperience { get; set; } = 0;

    public DateTime? LastUsedDate { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(ProfileID))]
    public virtual CandidateProfile CandidateProfile { get; set; } = null!;

    [ForeignKey(nameof(SkillID))]
    public virtual Skill Skill { get; set; } = null!;
}

/// <summary>
/// Proficiency levels for candidate skills
/// </summary>
public enum ProficiencyLevel
{
    Beginner,
    Elementary,
    Intermediate,
    Advanced,
    Expert
}