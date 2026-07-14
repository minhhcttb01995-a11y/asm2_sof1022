using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Interview
{
    public int InterviewId { get; set; }

    public int AppID { get; set; }

    public DateTime InterviewDate { get; set; }

    public string Location { get; set; } = null!;

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Application Application { get; set; } = null!;

    // Compatibility alias for InterviewID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int InterviewID
    {
        get => InterviewId;
        set => InterviewId = value;
    }

    // Backwards-compatible alias (some views/controllers use AppId)
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int AppId
    {
        get => AppID;
        set => AppID = value;
    }
}
