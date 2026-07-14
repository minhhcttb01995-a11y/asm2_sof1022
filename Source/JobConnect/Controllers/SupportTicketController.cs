using JobConnect.Data;
using JobConnect.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Staff,Admin")]
public class SupportTicketController : Controller
{
    private readonly AppDbContext _context;
    private readonly ILogger<SupportTicketController> _logger;

    public SupportTicketController(AppDbContext context, ILogger<SupportTicketController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: SupportTicket
    public async Task<IActionResult> Index(TicketStatus? status = null, int page = 1, int pageSize = 10)
    {
        var query = _context.SupportTickets
            .Include(st => st.User)
            .Include(st => st.AssignedToStaff)
            .AsQueryable();

        if (status.HasValue)
        {
            query = query.Where(st => st.Status == (int)status.Value);
        }

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var tickets = await query
            .OrderByDescending(st => st.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;
        ViewBag.StatusFilter = status;

        return View(tickets);
    }

    // GET: SupportTicket/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var ticket = await _context.SupportTickets
            .Include(st => st.User)
            .Include(st => st.AssignedToStaff)
            .FirstOrDefaultAsync(st => st.Id == id);

        if (ticket == null)
        {
            return NotFound();
        }

        return View(ticket);
    }

    // POST: SupportTicket/Assign/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Assign(int id)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId))
        {
            return RedirectToAction(nameof(Index));
        }

        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.ApplicationUserId == userId);

        if (staff == null)
        {
            return RedirectToAction(nameof(Index));
        }

        var ticket = await _context.SupportTickets.FindAsync(id);
        if (ticket == null)
        {
            return NotFound();
        }

        ticket.AssignedToStaffId = staff.Id;
        ticket.Status = (int)TicketStatus.InProgress;
        ticket.AssignedAt = DateTime.UtcNow;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await LogActivityAsync("Assigned Ticket", $"Assigned ticket {id} to self");

        TempData["Success"] = "Đã gán ticket cho bạn";
        return RedirectToAction(nameof(Index));
    }

    // POST: SupportTicket/Respond/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Respond(int id, string response)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId))
        {
            return RedirectToAction(nameof(Index));
        }

        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.ApplicationUserId == userId);

        if (staff == null)
        {
            return RedirectToAction(nameof(Index));
        }

        var ticket = await _context.SupportTickets.FindAsync(id);
        if (ticket == null)
        {
            return NotFound();
        }

        ticket.StaffResponse = response;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await LogActivityAsync("Responded to Ticket", $"Responded to ticket {id}");

        TempData["Success"] = "Đã gửi phản hồi";
        return RedirectToAction(nameof(Details), new { id });
    }

    // POST: SupportTicket/Resolve/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Resolve(int id)
    {
        var ticket = await _context.SupportTickets.FindAsync(id);
        if (ticket == null)
        {
            return NotFound();
        }

        ticket.Status = (int)TicketStatus.Resolved;
        ticket.ResolvedAt = DateTime.UtcNow;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await LogActivityAsync("Resolved Ticket", $"Resolved ticket {id}");

        TempData["Success"] = "Đã giải quyết ticket";
        return RedirectToAction(nameof(Index));
    }

    // POST: SupportTicket/Close/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Close(int id)
    {
        var ticket = await _context.SupportTickets.FindAsync(id);
        if (ticket == null)
        {
            return NotFound();
        }

        ticket.Status = (int)TicketStatus.Closed;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await LogActivityAsync("Closed Ticket", $"Closed ticket {id}");

        TempData["Success"] = "Đã đóng ticket";
        return RedirectToAction(nameof(Index));
    }

    private async Task LogActivityAsync(string action, string? description = null)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userId)) return;

        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.ApplicationUserId == userId);

        if (staff == null) return;

        var activityLog = new ActivityLog
        {
            StaffId = staff.Id,
            Action = action,
            Description = description,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
            UserAgent = Request.Headers["User-Agent"].ToString(),
            CreatedAt = DateTime.UtcNow
        };

        _context.ActivityLogs.Add(activityLog);
        await _context.SaveChangesAsync();
    }
}