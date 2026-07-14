using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class SupportTicket
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int Type { get; set; }

    public string Subject { get; set; } = null!;

    public string Message { get; set; } = null!;

    public int Status { get; set; }

    public int? AssignedToStaffId { get; set; }

    public int Priority { get; set; }

    public string? StaffResponse { get; set; }

    public DateTime? AssignedAt { get; set; }

    public DateTime? ResolvedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Staff? AssignedToStaff { get; set; }

    public virtual User User { get; set; } = null!;

    // Typed enum wrappers for compatibility with views
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public TicketStatus StatusEnum
    {
        get => (TicketStatus)Status;
        set => Status = (int)value;
    }

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public TicketType TypeEnum
    {
        get => (TicketType)Type;
        set => Type = (int)value;
    }
}