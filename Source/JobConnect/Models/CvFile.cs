using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class CvFile
{
    [Key]
    [Column("CVID")]
    public int CvFileID { get; set; }  // map to existing DB column CVID if present

    // Compatibility alias used in views/controllers expecting 'Id'
    [NotMapped]
    public int Id { get => CvFileID; set => CvFileID = value; }

    public int ProfileID { get; set; }

    public string FileName { get; set; } = string.Empty;
    public string FilePath { get; set; } = string.Empty;
    public int? FileSize { get; set; }

    public bool IsDefault { get; set; } = false;

    public DateTime UploadedAt { get; set; } = DateTime.Now;

    // Navigation property
    [ForeignKey("ProfileID")]
    public virtual CandidateProfile? Profile { get; set; }
}