using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class ServicePackage
{
    [Key]
    public int PackageID { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationDays { get; set; }
    public int MaxJobPosts { get; set; }
    public int MaxFeatured { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}