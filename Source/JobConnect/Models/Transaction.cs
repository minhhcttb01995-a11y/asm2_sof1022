using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Transaction
{
    public int TransId { get; set; }

    public int EmployerId { get; set; }

    public int PackageId { get; set; }

    public decimal Amount { get; set; }

    public string PaymentMethod { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime? ExpiredAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Employer Employer { get; set; } = null!;

    public virtual ServicePackage Package { get; set; } = null!;
}
