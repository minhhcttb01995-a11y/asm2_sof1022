using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Transaction
{
    [Key]
    public int TransID { get; set; }
    public int EmployerID { get; set; }
    public int PackageID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMethod { get; set; } = "BankTransfer";
    public string Status { get; set; } = "Pending";
    public DateTime? ExpiredAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    public Employer Employer { get; set; } = null!;
    public ServicePackage ServicePackage { get; set; } = null!;
}