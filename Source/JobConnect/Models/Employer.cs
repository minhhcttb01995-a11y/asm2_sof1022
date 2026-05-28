using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Employer
{
    [Key]
    public int EmployerID { get; set; }
    public int UserID { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? TaxCode { get; set; }
    public string? Industry { get; set; }
    public string? CompanySize { get; set; } // 1-10 | 11-50 | 51-200 | 200+
    public string? Address { get; set; }
    public string? Website { get; set; }
    public string? LogoURL { get; set; }
    public string? CoverURL { get; set; }
    public bool IsVerified { get; set; } = false;
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public User User { get; set; } = null!;
    public ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}