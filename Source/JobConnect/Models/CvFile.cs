using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class CvFile
{
    [Key]
    public int CvID { get; set; }                    // ← Quan trọng: khớp với CVID trong Application

    [Required]
    public int ProfileID { get; set; }               // ← Khớp với ProfileID trong Application

    [Required]
    [MaxLength(200)]
    public string FileName { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string FilePath { get; set; } = string.Empty;

    public long? FileSize { get; set; }

    public bool IsDefault { get; set; } = false;

    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey(nameof(ProfileID))]
    public virtual CandidateProfile? Profile { get; set; }

    public virtual ICollection<Application> Applications { get; set; } = new List<Application>();
}