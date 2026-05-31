using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models;

public class SavedJob
{
    [Key]
    public int SaveID { get; set; }
    public int UserID { get; set; }
    public int JobID { get; set; }
    public DateTime SavedAt { get; set; } = DateTime.Now;

    public User User { get; set; } = null!;
    [ForeignKey(nameof(JobID))]
    public JobPost JobPost { get; set; } = null!;
}