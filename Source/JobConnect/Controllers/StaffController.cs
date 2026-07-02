using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels.Staff;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Admin")]
public class StaffController : Controller
{
    private readonly AppDbContext _context;
    private readonly ILogger<StaffController> _logger;

    public StaffController(AppDbContext context, ILogger<StaffController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: Staff
    public async Task<IActionResult> Index(
        string? searchTerm,
        StaffStatus? statusFilter,
        string? departmentFilter,
        string? sortBy = "CreatedAt",
        bool sortDescending = true,
        int page = 1,
        int pageSize = 10)
    {
        var query = _context.Staff
            .Include(s => s.User)
            .Where(s => s.Status != StaffStatus.Deleted) // Ẩn nhân viên đã xóa mềm
            .AsQueryable();

        // Search
        if (!string.IsNullOrEmpty(searchTerm))
        {
            query = query.Where(s =>
                s.FullName.Contains(searchTerm) ||
                s.Email.Contains(searchTerm) ||
                s.EmployeeCode.Contains(searchTerm) ||
                s.Phone != null && s.Phone.Contains(searchTerm));
        }

        // Filter by status
        if (statusFilter.HasValue)
        {
            query = query.Where(s => s.Status == statusFilter.Value);
        }

        // Filter by department
        if (!string.IsNullOrEmpty(departmentFilter))
        {
            query = query.Where(s => s.Department == departmentFilter);
        }

        // Sorting
        query = sortBy switch
        {
            "EmployeeCode" => sortDescending ? query.OrderByDescending(s => s.EmployeeCode) : query.OrderBy(s => s.EmployeeCode),
            "FullName" => sortDescending ? query.OrderByDescending(s => s.FullName) : query.OrderBy(s => s.FullName),
            "Email" => sortDescending ? query.OrderByDescending(s => s.Email) : query.OrderBy(s => s.Email),
            "Position" => sortDescending ? query.OrderByDescending(s => s.Position) : query.OrderBy(s => s.Position),
            "Department" => sortDescending ? query.OrderByDescending(s => s.Department) : query.OrderBy(s => s.Department),
            "Status" => sortDescending ? query.OrderByDescending(s => s.Status) : query.OrderBy(s => s.Status),
            _ => sortDescending ? query.OrderByDescending(s => s.CreatedAt) : query.OrderBy(s => s.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var staffList = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new StaffListItemViewModel
            {
                Id = s.Id,
                ApplicationUserId = s.ApplicationUserId,
                EmployeeCode = s.EmployeeCode,
                FullName = s.FullName,
                Email = s.Email,
                Avatar = s.Avatar,
                Position = s.Position,
                Department = s.Department,
                Role = "Staff", // TODO: Get from ASP.NET Identity roles
                Status = s.Status,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            })
            .ToListAsync();

        var viewModel = new StaffIndexViewModel
        {
            StaffList = staffList,
            CurrentPage = page,
            TotalPages = totalPages,
            PageSize = pageSize,
            TotalCount = totalCount,
            SearchTerm = searchTerm,
            StatusFilter = statusFilter,
            DepartmentFilter = departmentFilter,
            SortBy = sortBy,
            SortDescending = sortDescending
        };

        // Get departments for filter dropdown
        ViewBag.Departments = await _context.Staff
            .Where(s => !string.IsNullOrEmpty(s.Department))
            .Select(s => s.Department)
            .Distinct()
            .ToListAsync();

        return View(viewModel);
    }

    // GET: Staff/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .Include(s => s.ActivityLogs.OrderByDescending(al => al.CreatedAt).Take(10))
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        var viewModel = new StaffDetailsViewModel
        {
            Id = staff.Id,
            EmployeeCode = staff.EmployeeCode,
            FullName = staff.FullName,
            Email = staff.Email,
            Phone = staff.Phone,
            Avatar = staff.Avatar,
            Position = staff.Position,
            Department = staff.Department,
            Role = "Staff", // TODO: Get from ASP.NET Identity roles
            Status = staff.Status,
            CreatedAt = staff.CreatedAt,
            UpdatedAt = staff.UpdatedAt,
            LastLoginAt = staff.User?.LastLoginAt,
            RecentActivities = staff.ActivityLogs.Select(al => new ActivityLogViewModel
            {
                Id = al.Id,
                Action = al.Action,
                Description = al.Description,
                IpAddress = al.IpAddress,
                CreatedAt = al.CreatedAt
            }).ToList()
        };

        return View(viewModel);
    }

    // GET: Staff/Create
    public IActionResult Create()
    {
        return View();
    }

    // POST: Staff/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(StaffCreateViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        // Check if email already exists
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == model.Email);

        if (existingUser != null)
        {
            ModelState.AddModelError("Email", "Email đã tồn tại trong hệ thống");
            return View(model);
        }

        // Generate employee code
        var employeeCode = await GenerateEmployeeCodeAsync();

        // Create user
        var user = new User
        {
            Email = model.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
            Role = "Staff",
            Status = "Active",
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // Create staff
        var staff = new Staff
        {
            ApplicationUserId = user.UserID,
            EmployeeCode = employeeCode,
            FullName = model.FullName,
            Email = model.Email,
            Phone = model.Phone,
            Position = model.Position,
            Department = model.Department,
            Status = StaffStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        _context.Staff.Add(staff);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Created Staff", $"Created staff {staff.FullName} with code {employeeCode}");

        TempData["Success"] = "Đã tạo nhân viên thành công";
        return RedirectToAction(nameof(Index));
    }

    // GET: Staff/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        var viewModel = new StaffEditViewModel
        {
            Id = staff.Id,
            ApplicationUserId = staff.ApplicationUserId.ToString(),
            EmployeeCode = staff.EmployeeCode,
            FullName = staff.FullName,
            Email = staff.Email,
            Phone = staff.Phone,
            Avatar = staff.Avatar,
            Position = staff.Position,
            Department = staff.Department,
            Status = staff.Status,
            Role = "Staff" // TODO: Get from ASP.NET Identity roles
        };

        return View(viewModel);
    }

    // POST: Staff/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, StaffEditViewModel model)
    {
        if (id != model.Id)
        {
            return NotFound();
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        // Update staff
        staff.FullName = model.FullName;
        staff.Phone = model.Phone;
        staff.Position = model.Position;
        staff.Department = model.Department;
        staff.Status = model.Status;
        staff.UpdatedAt = DateTime.UtcNow;

        // Update user email if changed
        if (staff.User != null && staff.User.Email != model.Email)
        {
            var emailExists = await _context.Users
                .AnyAsync(u => u.Email == model.Email && u.UserID != staff.ApplicationUserId);

            if (emailExists)
            {
                ModelState.AddModelError("Email", "Email đã tồn tại trong hệ thống");
                return View(model);
            }

            staff.User.Email = model.Email;
        }

        staff.Email = model.Email;

        _context.Update(staff);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Updated Staff", $"Updated staff {staff.FullName}");

        TempData["Success"] = "Đã cập nhật nhân viên thành công";
        return RedirectToAction(nameof(Index));
    }

    // GET: Staff/Delete/5
    public async Task<IActionResult> Delete(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        return View(staff);
    }

    // POST: Staff/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .Include(s => s.ActivityLogs)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        // Cannot delete self
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(currentUserId, out var userId) && staff.ApplicationUserId == userId)
        {
            TempData["Error"] = "Bạn không thể xóa chính mình";
            return RedirectToAction(nameof(Index));
        }

        var staffName = staff.FullName;

        // Soft delete: chuyển trạng thái thành Deleted, không xóa khỏi DB
        staff.Status = StaffStatus.Deleted;
        staff.UpdatedAt = DateTime.UtcNow;

        // Khóa tài khoản user liên kết
        if (staff.User != null)
        {
            staff.User.Status = "Banned";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Deleted Staff", $"Soft-deleted staff {staffName}");

        TempData["Success"] = "Đã xóa nhân viên thành công";
        return RedirectToAction(nameof(Index));
    }

    // POST: Staff/Lock/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Lock(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        // Cannot lock self
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(currentUserId, out var userId) && staff.ApplicationUserId == userId)
        {
            TempData["Error"] = "Bạn không thể khóa chính mình";
            return RedirectToAction(nameof(Index));
        }

        staff.Status = StaffStatus.Locked;
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.User != null)
        {
            staff.User.Status = "Banned";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Locked Staff", $"Locked staff {staff.FullName}");

        TempData["Success"] = "Đã khóa tài khoản nhân viên";
        return RedirectToAction(nameof(Index));
    }

    // POST: Staff/Unlock/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Unlock(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        staff.Status = StaffStatus.Active;
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.User != null)
        {
            staff.User.Status = "Active";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Unlocked Staff", $"Unlocked staff {staff.FullName}");

        TempData["Success"] = "Đã mở khóa tài khoản nhân viên";
        return RedirectToAction(nameof(Index));
    }

    // GET: Staff/Deleted — Danh sách nhân viên đã xóa mềm
    public async Task<IActionResult> Deleted(
        string? searchTerm,
        string? departmentFilter,
        int page = 1,
        int pageSize = 10)
    {
        var query = _context.Staff
            .Include(s => s.User)
            .Where(s => s.Status == StaffStatus.Deleted)
            .AsQueryable();

        if (!string.IsNullOrEmpty(searchTerm))
        {
            query = query.Where(s =>
                s.FullName.Contains(searchTerm) ||
                s.Email.Contains(searchTerm) ||
                s.EmployeeCode.Contains(searchTerm));
        }

        if (!string.IsNullOrEmpty(departmentFilter))
        {
            query = query.Where(s => s.Department == departmentFilter);
        }

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var staffList = await query
            .OrderByDescending(s => s.UpdatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new StaffListItemViewModel
            {
                Id = s.Id,
                ApplicationUserId = s.ApplicationUserId,
                EmployeeCode = s.EmployeeCode,
                FullName = s.FullName,
                Email = s.Email,
                Avatar = s.Avatar,
                Position = s.Position,
                Department = s.Department,
                Role = "Staff",
                Status = s.Status,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            })
            .ToListAsync();

        var viewModel = new StaffIndexViewModel
        {
            StaffList = staffList,
            CurrentPage = page,
            TotalPages = totalPages,
            PageSize = pageSize,
            TotalCount = totalCount,
            SearchTerm = searchTerm,
            DepartmentFilter = departmentFilter
        };

        ViewBag.Departments = await _context.Staff
            .Where(s => s.Status == StaffStatus.Deleted && !string.IsNullOrEmpty(s.Department))
            .Select(s => s.Department)
            .Distinct()
            .ToListAsync();

        return View(viewModel);
    }

    // POST: Staff/Restore/5 — Khôi phục nhân viên đã xóa mềm
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Restore(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id && s.Status == StaffStatus.Deleted);

        if (staff == null)
        {
            TempData["Error"] = "Không tìm thấy nhân viên cần khôi phục.";
            return RedirectToAction(nameof(Deleted));
        }

        staff.Status = StaffStatus.Active;
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.User != null)
        {
            staff.User.Status = "Active";
        }

        await _context.SaveChangesAsync();
        await LogActivityAsync("Restored Staff", $"Khôi phục nhân viên {staff.FullName}");

        TempData["Success"] = $"Đã khôi phục nhân viên {staff.FullName} thành công.";
        return RedirectToAction(nameof(Deleted));
    }

    // GET: Staff/ResetPassword/5
    public async Task<IActionResult> ResetPassword(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        ViewBag.StaffName = staff.FullName;
        ViewBag.StaffId = id;

        return View();
    }

    // POST: Staff/ResetPassword/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(int id, string newPassword)
    {
        if (string.IsNullOrEmpty(newPassword) || newPassword.Length < 6)
        {
            ModelState.AddModelError("newPassword", "Mật khẩu phải có ít nhất 6 ký tự");
            ViewBag.StaffId = id;
            return View();
        }

        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null || staff.User == null)
        {
            return NotFound();
        }

        staff.User.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Reset Password", $"Reset password for staff {staff.FullName}");

        TempData["Success"] = "Đã reset mật khẩu thành công";
        return RedirectToAction(nameof(Index));
    }

    // GET: Staff/ActivityLog/5
    public async Task<IActionResult> ActivityLog(int id, int page = 1)
    {
        var staff = await _context.Staff
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        var activities = await _context.ActivityLogs
            .Where(al => al.StaffId == id)
            .OrderByDescending(al => al.CreatedAt)
            .Skip((page - 1) * 20)
            .Take(20)
            .ToListAsync();

        var totalCount = await _context.ActivityLogs
            .Where(al => al.StaffId == id)
            .CountAsync();

        var totalPages = (int)Math.Ceiling(totalCount / 20.0);

        ViewBag.Staff = staff;
        ViewBag.Activities = activities;
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;

        return View();
    }

    private async Task<string> GenerateEmployeeCodeAsync()
    {
        var prefix = "STF";
        var year = DateTime.Now.Year;
        var count = await _context.Staff.CountAsync() + 1;
        return $"{prefix}{year}{count:D4}";
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
    // =====================================================================
    // THÊM VÀO StaffController.cs — dán trước dòng cuối cùng (dòng 557)
    // tức là trước dấu } đóng của class
    // =====================================================================

    // GET: Staff/SetRole/5
    public async Task<IActionResult> SetRole(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null) return NotFound();

        // Các vai trò có thể phân quyền cho Staff
        var availableRoles = new List<string> { "Staff", "Admin" };

        ViewBag.StaffId = id;
        ViewBag.StaffName = staff.FullName;
        ViewBag.CurrentRole = staff.User?.Role ?? "Staff";
        ViewBag.AvailableRoles = availableRoles;

        return View();
    }

    // POST: Staff/SetRole/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetRole(int id, string role)
    {
        var allowedRoles = new[] { "Staff", "Admin" };
        if (!allowedRoles.Contains(role))
        {
            TempData["Error"] = "Vai trò không hợp lệ.";
            return RedirectToAction(nameof(Details), new { id });
        }

        var staff = await _context.Staff
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null) return NotFound();

        // Không cho đổi vai trò của chính mình
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(currentUserId, out var uid) && staff.ApplicationUserId == uid)
        {
            TempData["Error"] = "Bạn không thể thay đổi vai trò của chính mình.";
            return RedirectToAction(nameof(Details), new { id });
        }

        if (staff.User != null)
        {
            var oldRole = staff.User.Role;
            staff.User.Role = role;
            staff.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await LogActivityAsync("Set Role",
                $"Đổi vai trò của {staff.FullName} từ {oldRole} → {role}");

            TempData["Success"] = $"Đã phân quyền {staff.FullName} thành {role}.";
        }

        return RedirectToAction(nameof(Details), new { id });
    }
}