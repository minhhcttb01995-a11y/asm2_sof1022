// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// StaffController — [Authorize(Roles = "Admin")]: CHỈ ADMIN mới được QUẢN LÝ NHÂN VIÊN
// (Staff) — khác StaffDashboardController là nơi Staff tự làm việc hàng ngày:
//   • Index/Details: danh sách & xem chi tiết 1 nhân viên.
//   • Create/Edit/Delete/DeleteConfirmed: CRUD hồ sơ nhân viên.
//   • Lock/Unlock/ChangeStatus: khóa/mở khóa tài khoản nhân viên.
//   • Delete/Restore/PermanentDelete: xóa mềm (đẩy xuống cuối danh sách), khôi phục, xóa vĩnh viễn — ngay tại Index.
//   • ResetPassword: Admin đặt lại mật khẩu cho 1 nhân viên.
//   • ActivityLog: xem lịch sử hoạt động (ActivityLog) của 1 nhân viên.
//   • SetRole: đổi vai trò tài khoản (VD: nâng lên Admin).
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels.Staff;
using Microsoft.AspNetCore.Antiforgery;
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
    private readonly ICodeGeneratorService _codeGen;
    private readonly IAntiforgery _antiforgery;

    public StaffController(AppDbContext context, ILogger<StaffController> logger, ICodeGeneratorService codeGen, IAntiforgery antiforgery)
    {
        _context = context;
        _logger = logger;
        _codeGen = codeGen;
        _antiforgery = antiforgery;
    }

    /// <summary>
    /// Quay lại đúng trang (kèm nguyên trang số, từ khóa tìm kiếm, bộ lọc...) mà người dùng
    /// vừa đứng khi bấm nút (Xóa/Khôi phục/Khóa...), thay vì luôn nhảy về trang 1 mặc định.
    /// Dùng header "Referer" (chính là URL đang mở khi submit form).
    /// </summary>
    private IActionResult RedirectBackOrTo(string fallbackAction)
    {
        var referer = Request.Headers["Referer"].ToString();
        if (!string.IsNullOrEmpty(referer))
        {
            return Redirect(referer);
        }
        return RedirectToAction(fallbackAction);
    }

    private IActionResult RedirectBackOrTo(string fallbackAction, object routeValues)
    {
        var referer = Request.Headers["Referer"].ToString();
        if (!string.IsNullOrEmpty(referer))
        {
            return Redirect(referer);
        }
        return RedirectToAction(fallbackAction, routeValues);
    }

    // GET: Staff
    public async Task<IActionResult> Index(
        string? searchTerm,
        string? statusFilter,
        string? departmentFilter,
        string? sortBy = "CreatedAt",
        bool sortDescending = true,
        int page = 1,
        int pageSize = 10)
    {
        var query = _context.Staff
            .Include(s => s.ApplicationUser)
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
        if (!string.IsNullOrEmpty(statusFilter))
        {
            query = query.Where(s => s.Status == statusFilter);
        }

        // Filter by department
        if (!string.IsNullOrEmpty(departmentFilter))
        {
            query = query.Where(s => s.Department == departmentFilter);
        }

        // Sorting - nhân viên đã xóa mềm luôn bị đẩy xuống cuối danh sách/trang cuối
        query = query.OrderBy(s => s.Status == "Deleted" ? 1 : 0);
        query = sortBy switch
        {
            "EmployeeCode" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.EmployeeCode) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.EmployeeCode),
            "FullName" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.FullName) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.FullName),
            "Email" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.Email) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.Email),
            "Position" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.Position) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.Position),
            "Department" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.Department) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.Department),
            "Status" => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.Status) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.Status),
            _ => sortDescending ? ((IOrderedQueryable<Staff>)query).ThenByDescending(s => s.CreatedAt) : ((IOrderedQueryable<Staff>)query).ThenBy(s => s.CreatedAt)
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
                CCCD = s.CCCD,
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

        // Danh sách trạng thái do Admin quản lý (StatusCatalog) để hiển thị dropdown như trang Người dùng
        ViewBag.StaffStatuses = await _context.StatusCatalogs
            .Where(s => s.EntityType == StatusEntityTypes.Staff && s.IsActive)
            .OrderBy(s => s.Id)
            .ToListAsync();

        return View(viewModel);
    }

    // POST: Staff/ChangeStatus — Đổi trạng thái nhân viên theo StatusCatalog (AJAX, giống trang Người dùng)
    // Lưu ý: validate token thủ công trong try/catch (không dùng [ValidateAntiForgeryToken]
    // trực tiếp) để luôn trả JSON, tránh JS phía client bị crash khi parse HTML lỗi.
    [HttpPost]
    public async Task<IActionResult> ChangeStatus(int id, string newStatus)
    {
        try
        {
            try { await _antiforgery.ValidateRequestAsync(HttpContext); }
            catch (AntiforgeryValidationException) { return Json(new { success = false, message = "Phiên làm việc đã hết hạn, vui lòng tải lại trang." }); }

            var staff = await _context.Staff
                .Include(s => s.ApplicationUser)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (staff == null)
            {
                return Json(new { success = false, message = "Không tìm thấy nhân viên" });
            }

            // Không cho tự đổi trạng thái của chính mình
            var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(currentUserId, out var uid) && staff.ApplicationUserId == uid)
            {
                return Json(new { success = false, message = "Bạn không thể tự đổi trạng thái của chính mình" });
            }

            // Kiểm tra trạng thái có tồn tại trong danh mục StatusCatalog không
            var status = await _context.StatusCatalogs
                .FirstOrDefaultAsync(s => s.EntityType == StatusEntityTypes.Staff && s.Code == newStatus && s.IsActive);

            if (status == null)
            {
                return Json(new { success = false, message = "Trạng thái không hợp lệ!" });
            }

            staff.Status = newStatus;
            staff.UpdatedAt = DateTime.UtcNow;

            // Đồng bộ trạng thái đăng nhập của tài khoản liên kết
            if (staff.ApplicationUser != null)
            {
                staff.ApplicationUser.Status = status.BlocksLogin ? "Banned" : "Active";
            }

            await _context.SaveChangesAsync();

            await LogActivityAsync("Changed Staff Status", $"Đổi trạng thái của {staff.FullName} thành {status.Name}");

            return Json(new { success = true, message = $"Đã cập nhật trạng thái thành: {status.Name}" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Có lỗi xảy ra ở server: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    // GET: Staff/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
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
            CCCD = staff.CCCD ?? string.Empty,
            FullName = staff.FullName,
            Email = staff.Email,
            Phone = staff.Phone,
            Gender = staff.Gender,
            Avatar = staff.Avatar,
            Position = staff.Position,
            Department = staff.Department,
            Role = "Staff", // TODO: Get from ASP.NET Identity roles
            Status = staff.Status,
            CreatedAt = staff.CreatedAt,
            UpdatedAt = staff.UpdatedAt,
            LastLoginAt = staff.ApplicationUser?.LastLoginAt,
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
            TempData["Error"] = "Vui lòng kiểm tra lại thông tin đã nhập.";
            TempData["OpenCreateModal"] = true;
            return RedirectBackOrTo(nameof(Index));
        }

        // Check if email already exists
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == model.Email);

        if (existingUser != null)
        {
            TempData["Error"] = "Email đã tồn tại trong hệ thống";
            TempData["OpenCreateModal"] = true;
            return RedirectBackOrTo(nameof(Index));
        }

        // Check if CCCD already exists
        var existingCccd = await _context.Staff
            .FirstOrDefaultAsync(s => s.CCCD == model.CCCD);

        if (existingCccd != null)
        {
            TempData["Error"] = "Số CCCD đã tồn tại trong hệ thống";
            TempData["OpenCreateModal"] = true;
            return RedirectBackOrTo(nameof(Index));
        }

        // Generate employee code (ngẫu nhiên, không dấu gạch - vd: NV5H2K8P)
        var employeeCode = await _codeGen.GenerateStaffCodeAsync();

        // Create user
        var user = new User
        {
            Email = model.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
            Role = "Staff",
            FullName = model.FullName,
            PhoneNumber = model.Phone,
            Status = "Active",
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // Mã người dùng: tự tăng theo UserId
        user.UserCode = _codeGen.GenerateUserCode("Staff", user.UserId);
        await _context.SaveChangesAsync();

        // Create staff
        var staff = new Staff
        {
            ApplicationUserId = user.UserId,
            EmployeeCode = employeeCode,
            CCCD = model.CCCD,
            FullName = model.FullName,
            Email = model.Email,
            Phone = model.Phone,
            Gender = model.Gender,
            Position = model.Position,
            Department = model.Department,

            Status = "Active",
            CreatedAt = DateTime.UtcNow
        };

        _context.Staff.Add(staff);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Created Staff", $"Created staff {staff.FullName} with code {employeeCode}");

        TempData["Success"] = "Đã tạo nhân viên thành công";
        return RedirectBackOrTo(nameof(Index));
    }

    // GET: Staff/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
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
            CCCD = staff.CCCD ?? string.Empty,
            FullName = staff.FullName,
            Email = staff.Email,
            Phone = staff.Phone,
            Gender = staff.Gender,
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
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        // Check if CCCD already exists on another staff
        if (staff.CCCD != model.CCCD)
        {
            var cccdExists = await _context.Staff
                .AnyAsync(s => s.CCCD == model.CCCD && s.Id != staff.Id);

            if (cccdExists)
            {
                ModelState.AddModelError("CCCD", "Số CCCD đã tồn tại trong hệ thống");
                return View(model);
            }
        }

        // Update staff
        staff.FullName = model.FullName;
        staff.CCCD = model.CCCD;
        staff.Phone = model.Phone;
        staff.Gender = model.Gender;
        staff.Position = model.Position;
        staff.Department = model.Department;

        staff.Status = model.Status;
        staff.UpdatedAt = DateTime.UtcNow;

        // Update user email if changed
        if (staff.ApplicationUser != null && staff.ApplicationUser.Email != model.Email)
        {
            var emailExists = await _context.Users
                .AnyAsync(u => u.Email == model.Email && u.UserId != staff.ApplicationUserId);

            if (emailExists)
            {
                ModelState.AddModelError("Email", "Email đã tồn tại trong hệ thống");
                return View(model);
            }

            staff.ApplicationUser.Email = model.Email;
        }

        staff.Email = model.Email;

        _context.Update(staff);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Updated Staff", $"Updated staff {staff.FullName}");

        TempData["Success"] = "Đã cập nhật nhân viên thành công";
        return RedirectBackOrTo(nameof(Index));
    }

    // GET: Staff/Delete/5
    public async Task<IActionResult> Delete(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
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
            .Include(s => s.ApplicationUser)
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
            return RedirectBackOrTo(nameof(Index));
        }

        var staffName = staff.FullName;

        // Soft delete: chuyển trạng thái thành Deleted, không xóa khỏi DB
        staff.Status = "Deleted";
        staff.UpdatedAt = DateTime.UtcNow;

        // Khóa tài khoản user liên kết
        if (staff.ApplicationUser != null)
        {
            staff.ApplicationUser.Status = "Banned";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Deleted Staff", $"Soft-deleted staff {staffName}");

        TempData["Success"] = "Đã xóa nhân viên thành công";
        return RedirectBackOrTo(nameof(Index));
    }

    // POST: Staff/Lock/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Lock(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
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
            return RedirectBackOrTo(nameof(Index));
        }

        staff.Status = "Locked";
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.ApplicationUser != null)
        {
            staff.ApplicationUser.Status = "Banned";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Locked Staff", $"Locked staff {staff.FullName}");

        TempData["Success"] = "Đã khóa tài khoản nhân viên";
        return RedirectBackOrTo(nameof(Index));
    }

    // POST: Staff/Unlock/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Unlock(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            return NotFound();
        }

        staff.Status = "Active";
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.ApplicationUser != null)
        {
            staff.ApplicationUser.Status = "Active";
        }

        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Unlocked Staff", $"Unlocked staff {staff.FullName}");

        TempData["Success"] = "Đã mở khóa tài khoản nhân viên";
        return RedirectBackOrTo(nameof(Index));
    }

    // POST: Staff/Restore/5 — Khôi phục nhân viên đã xóa mềm (thao tác ngay tại trang Index)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Restore(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id && s.Status == "Deleted");

        if (staff == null)
        {
            TempData["Error"] = "Không tìm thấy nhân viên cần khôi phục.";
            return RedirectBackOrTo(nameof(Index));
        }

        staff.Status = "Active";
        staff.UpdatedAt = DateTime.UtcNow;

        if (staff.ApplicationUser != null)
        {
            staff.ApplicationUser.Status = "Active";
        }

        await _context.SaveChangesAsync();
        await LogActivityAsync("Restored Staff", $"Khôi phục nhân viên {staff.FullName}");

        TempData["Success"] = $"Đã khôi phục nhân viên {staff.FullName} thành công.";
        return RedirectBackOrTo(nameof(Index));
    }

    // POST: Staff/PermanentDelete/5 — Xóa vĩnh viễn (chỉ áp dụng cho nhân viên đã ở trạng thái Deleted)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> PermanentDelete(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
            .Include(s => s.ActivityLogs)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null)
        {
            TempData["Error"] = "Không tìm thấy nhân viên này.";
            return RedirectBackOrTo(nameof(Index));
        }

        if (staff.Status != "Deleted")
        {
            TempData["Error"] = "Chỉ có thể xóa vĩnh viễn nhân viên đang ở trạng thái đã xóa.";
            return RedirectBackOrTo(nameof(Index));
        }

        var staffName = staff.FullName;
        var appUser = staff.ApplicationUser;

        if (staff.ActivityLogs != null && staff.ActivityLogs.Count > 0)
            _context.RemoveRange(staff.ActivityLogs);

        _context.Staff.Remove(staff);
        if (appUser != null)
            _context.Users.Remove(appUser);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            TempData["Error"] = $"Không thể xóa vĩnh viễn nhân viên {staffName} vì vẫn còn dữ liệu liên quan. Hãy xử lý dữ liệu đó trước.";
            return RedirectBackOrTo(nameof(Index));
        }

        TempData["Success"] = $"Đã xóa vĩnh viễn nhân viên {staffName} khỏi hệ thống.";
        return RedirectBackOrTo(nameof(Index));
    }

    // GET: Staff/ResetPassword/5
    public async Task<IActionResult> ResetPassword(int id)
    {
        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
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
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null || staff.ApplicationUser == null)
        {
            return NotFound();
        }

        staff.ApplicationUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        await _context.SaveChangesAsync();

        // Log activity
        await LogActivityAsync("Reset Password", $"Reset password for staff {staff.FullName}");

        TempData["Success"] = "Đã reset mật khẩu thành công";
        return RedirectBackOrTo(nameof(Index));
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
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null) return NotFound();

        // Các vai trò có thể phân quyền cho Staff
        var availableRoles = new List<string> { "Staff", "Admin" };

        ViewBag.StaffId = id;
        ViewBag.StaffName = staff.FullName;
        ViewBag.CurrentRole = staff.ApplicationUser?.Role ?? "Staff";
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
            return RedirectBackOrTo(nameof(Details), new { id });
        }

        var staff = await _context.Staff
            .Include(s => s.ApplicationUser)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (staff == null) return NotFound();

        // Không cho đổi vai trò của chính mình
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(currentUserId, out var uid) && staff.ApplicationUserId == uid)
        {
            TempData["Error"] = "Bạn không thể thay đổi vai trò của chính mình.";
            return RedirectBackOrTo(nameof(Details), new { id });
        }

        if (staff.ApplicationUser != null)
        {
            var oldRole = staff.ApplicationUser.Role;
            staff.ApplicationUser.Role = role;
            staff.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await LogActivityAsync("Set Role",
                $"Đổi vai trò của {staff.FullName} từ {oldRole} → {role}");

            TempData["Success"] = $"Đã phân quyền {staff.FullName} thành {role}.";
        }

        return RedirectBackOrTo(nameof(Details), new { id });
    }
}