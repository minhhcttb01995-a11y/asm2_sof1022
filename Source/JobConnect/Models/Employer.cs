using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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
    [Column(TypeName = "nvarchar(max)")]
    public string? LogoURL { get; set; }
    [Column(TypeName = "nvarchar(max)")]
    public string? CoverURL { get; set; }
    public bool IsVerified { get; set; } = false;
    public bool IsLocked { get; set; } = false;   // ← THÊM MỚI: Admin có thể khoá công ty
    [Column(TypeName = "nvarchar(max)")]
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public User User { get; set; } = null!;
    public ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}