using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Notification
{
    [Key]
    public int NotifID { get; set; }
    public int UserID { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Content { get; set; }
    public string Type { get; set; } = "System"; // Application | System | Payment
    public bool IsRead { get; set; } = false;
    public int? RelatedID { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public User User { get; set; } = null!;
}