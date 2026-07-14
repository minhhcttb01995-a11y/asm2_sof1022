using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class CompanyFollow
{
    public int FollowId { get; set; }

    public int UserId { get; set; }

    public int EmployerId { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual Employer Employer { get; set; } = null!;
}
