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
    public string Status { get; set; } = "Pending"; // Pending | Reviewed | Accepted | Rejected | Interview
    public DateTime AppliedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("JobID")]
    public JobPost JobPost { get; set; } = null!;

    [ForeignKey("ProfileID")]
    public CandidateProfile CandidateProfile { get; set; } = null!;

    [ForeignKey("CVID")]
    public CvFile? CvFile { get; set; }
}