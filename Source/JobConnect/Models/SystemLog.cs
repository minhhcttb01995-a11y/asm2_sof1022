using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class SystemLog
{
    public int LogId { get; set; }

    public int? UserId { get; set; }

    public string Action { get; set; } = null!;

    public string? Ipaddress { get; set; }

    public string? Detail { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User? User { get; set; }
}
