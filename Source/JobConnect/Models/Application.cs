using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class Application
{
    [Key]
    public int AppID { get; set; }

    [Required]
    public int JobID { get; set; }

    [Required]
    public int ProfileID { get; set; }

    public int? CVID { get; set; }

    [StringLength(1000)]
    public string? CoverLetter { get; set; }

    [Required]
    [StringLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, Reviewing, Interview, Offered, Rejected

    public DateTime AppliedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    // Các trường hỗ trợ cho nhà tuyển dụng (không lưu vào DB)
    [NotMapped]
    public int? Rating { get; set; }           // Đánh giá 1-5

    [NotMapped]
    public string? Note { get; set; }          // Ghi chú của nhà tuyển dụng

    // ==================== NAVIGATION PROPERTIES ====================
    [ForeignKey("JobID")]
    public virtual JobPost? Job { get; set; }   // Đổi từ JobPost thành Job cho nhất quán

    [ForeignKey("ProfileID")]
    public virtual CandidateProfile? CandidateProfile { get; set; }

    [ForeignKey("CVID")]
    public virtual CvFile? CvFile { get; set; }

    // Optional: Thêm collection nếu cần
    // public virtual ICollection<Interview>? Interviews { get; set; }
}