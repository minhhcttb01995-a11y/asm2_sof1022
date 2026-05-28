using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Skill
{
    [Key]
    public int SkillID { get; set; }
    public int? CategoryID { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    public Category? Category { get; set; }
    public ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();
}