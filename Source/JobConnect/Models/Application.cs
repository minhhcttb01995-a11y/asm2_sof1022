using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class Application
{
    [Key]
    public int AppID { get; set; }

    public int JobID { get; set; }
    public int ProfileID { get; set; }
    public int? CVID { get; set; }

    public string? CoverLetter { get; set; }

    [Required]
    public string Status { get; set; } = "Pending"; // Pending, Reviewed, Interview, Offered, Rejected

    // Temporarily not mapped to DB to avoid runtime errors when the database lacks these columns.
    [NotMapped]
    public int? Rating { get; set; }  // Đánh giá hồ sơ (1-5 sao)

    // THÊM DÒNG NÀY - property Note
    [NotMapped]
    public string? Note { get; set; }  // Ghi chú của nhà tuyển dụng

    public DateTime AppliedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey("JobID")]
    [InverseProperty("Applications")]
    public virtual JobPost? JobPost { get; set; }

    [ForeignKey("ProfileID")]
    [InverseProperty("Applications")]
    public virtual CandidateProfile? CandidateProfile { get; set; }

    [ForeignKey("CVID")]
    public virtual CvFile? CvFile { get; set; }
}