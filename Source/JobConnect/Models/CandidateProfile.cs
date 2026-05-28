using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class CandidateProfile
{
    [Key]
    public int ProfileID { get; set; }
    public int UserID { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? Address { get; set; }
    public string? Summary { get; set; }
    public int ExperienceYears { get; set; } = 0;
    public decimal? DesiredSalary { get; set; }
    public bool IsOpenToWork { get; set; } = true;

    // Navigation
    public User User { get; set; } = null!;
    public ICollection<CvFile> CvFiles { get; set; } = new List<CvFile>();
    public ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}