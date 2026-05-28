using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class CandidateSkill
{
    [Key]
    public int ProfileID { get; set; }
    public int SkillID { get; set; }
    public string Level { get; set; } = "Intermediate";
    public decimal? YearsOfExp { get; set; }

    public CandidateProfile CandidateProfile { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}