using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class CandidateProfile
{
    [Key]
    public int ProfileID { get; set; }

    [Required]
    public int UserID { get; set; }

    [MaxLength(100)]
    public string? FullName { get; set; }

    [MaxLength(15)]
    public string? Phone { get; set; }

    [MaxLength(500)]
    public string? Avatar { get; set; }

    public DateTime? DateOfBirth { get; set; }

    [MaxLength(20)]
    public string? Gender { get; set; }

    [MaxLength(200)]
    public string? Address { get; set; }

    [MaxLength(1000)]
    public string? Summary { get; set; }

    public int ExperienceYears { get; set; } = 0;

    [Column(TypeName = "decimal(18,2)")]
    public decimal? DesiredSalary { get; set; }

    public bool IsOpenToWork { get; set; } = true;

    // ==================== NAVIGATION PROPERTIES ====================

    [ForeignKey(nameof(UserID))]
    public virtual User? User { get; set; }

    public virtual ICollection<CvFile> CvFiles { get; set; } = new List<CvFile>();

    public virtual ICollection<CandidateSkill> CandidateSkills { get; set; } = new List<CandidateSkill>();

    public virtual ICollection<Application> Applications { get; set; } = new List<Application>();
}