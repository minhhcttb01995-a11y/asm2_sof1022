using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class ServicePackage
{
    public int PackageId { get; set; }

    public string Name { get; set; } = null!;

    public decimal Price { get; set; }

    public int DurationDays { get; set; }

    public int MaxJobPosts { get; set; }

    public int MaxFeatured { get; set; }

    public string? Description { get; set; }

    public bool IsActive { get; set; }

    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}
