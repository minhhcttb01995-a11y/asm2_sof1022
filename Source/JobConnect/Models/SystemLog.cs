using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class SystemLog
{
    [Key]
    public int LogID { get; set; }
    public int? UserID { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? IPAddress { get; set; }
    public string? Detail { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    public User? User { get; set; }
}