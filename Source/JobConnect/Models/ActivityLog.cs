using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class ActivityLog
{
    public int Id { get; set; }

    public int StaffId { get; set; }

    public string Action { get; set; } = null!;

    public string? Description { get; set; }

    public string? IpAddress { get; set; }

    public string? UserAgent { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Staff Staff { get; set; } = null!;
}
