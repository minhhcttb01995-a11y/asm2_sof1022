// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// StatusCatalogController — [Authorize(Roles = "Admin")]: trang Admin quản lý DANH MỤC
// TRẠNG THÁI tùy chỉnh (xem Models/StatusCatalog.cs + Services/StatusCatalogService.cs):
//   • Index/Create/Edit/Delete/ToggleActive: CRUD danh mục trạng thái.
//   • ByEntityType: API nhỏ trả về danh sách trạng thái theo loại đối tượng (dùng AJAX
//     để đổ vào dropdown khi tạo/sửa 1 trạng thái mới, tránh trùng Code).
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Admin")]
public class StatusCatalogController : Controller
{
    private readonly AppDbContext _db;
    private readonly IStatusCatalogService _statusSvc;

    public StatusCatalogController(AppDbContext db, IStatusCatalogService statusSvc)
    {
        _db = db;
        _statusSvc = statusSvc;
    }

    private int? GetCurrentStaffId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
        {
            var staff = _db.Staff.FirstOrDefault(s => s.ApplicationUserId == userId);
            return staff?.Id;
        }
        return null;
    }

    private async Task LogActivityAsync(string action, string description)
    {
        var staffId = GetCurrentStaffId();
        if (staffId.HasValue)
        {
            var log = new ActivityLog
            {
                StaffId = staffId.Value,
                Action = action,
                Description = description,
                CreatedAt = DateTime.Now,
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                UserAgent = Request.Headers["User-Agent"].ToString()
            };
            _db.ActivityLogs.Add(log);
            await _db.SaveChangesAsync();
        }
    }

    // GET /StatusCatalog
    public async Task<IActionResult> Index(string? entityType = null, string? keyword = null)
    {
        var statuses = await _statusSvc.GetAllAsync(entityType, keyword);

        ViewBag.EntityTypes = StatusEntityTypes.All;
        ViewBag.SelectedEntityType = entityType;
        ViewBag.Keyword = keyword;

        return View(statuses);
    }

    // GET /StatusCatalog/Create
    public IActionResult Create()
    {
        ViewBag.EntityTypes = StatusEntityTypes.All;
        return View(new StatusCatalog());
    }

    // POST /StatusCatalog/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(StatusCatalog model)
    {
        // Auto-generate Code from Name if empty
        if (string.IsNullOrEmpty(model.Code))
        {
            model.Code = GenerateCodeFromName(model.Name);
        }

        if (!ModelState.IsValid)
        {
            ViewBag.EntityTypes = StatusEntityTypes.All;
            return View(model);
        }

        var success = await _statusSvc.CreateAsync(model);
        if (!success)
        {
            ModelState.AddModelError("", "Tên trạng thái này đã tồn tại cho loại đối tượng này.");
            ViewBag.EntityTypes = StatusEntityTypes.All;
            return View(model);
        }

        await LogActivityAsync("CreateStatus", $"Đã tạo trạng thái mới: {model.Code} ({model.Name}) cho {model.EntityType}");
        TempData["Success"] = "Đã thêm trạng thái thành công!";
        return RedirectToAction("Index", new { entityType = model.EntityType });
    }

    // GET /StatusCatalog/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var status = await _statusSvc.GetByIdAsync(id);
        if (status == null)
            return NotFound();

        ViewBag.EntityTypes = StatusEntityTypes.All;
        return View(status);
    }

    // POST /StatusCatalog/Edit
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(StatusCatalog model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.EntityTypes = StatusEntityTypes.All;
            return View(model);
        }

        var success = await _statusSvc.UpdateAsync(model);
        if (!success)
        {
            ModelState.AddModelError("", "Tên trạng thái này đã tồn tại cho loại đối tượng này.");
            ViewBag.EntityTypes = StatusEntityTypes.All;
            return View(model);
        }

        await LogActivityAsync("UpdateStatus", $"Đã cập nhật trạng thái: {model.Code} ({model.Name}) cho {model.EntityType}");
        TempData["Success"] = "Đã cập nhật trạng thái thành công!";
        return RedirectToAction("Index", new { entityType = model.EntityType });
    }

    // POST /StatusCatalog/Delete/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        var status = await _statusSvc.GetByIdAsync(id);
        var (success, error, recordCount) = await _statusSvc.DeleteAsync(id);
        if (!success)
        {
            TempData["Error"] = error ?? "Không thể xóa trạng thái này.";
            return RedirectToAction("Index");
        }

        if (status != null)
        {
            await LogActivityAsync("DeleteStatus", $"Đã xóa trạng thái: {status.Code} ({status.Name}) cho {status.EntityType}");
        }
        TempData["Success"] = "Đã xóa trạng thái thành công!";
        return RedirectToAction("Index");
    }

    // POST /StatusCatalog/ToggleActive/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleActive(int id)
    {
        var status = await _db.StatusCatalogs.FindAsync(id);
        if (status == null)
        {
            TempData["Error"] = "Không tìm thấy trạng thái.";
            return RedirectToAction("Index");
        }

        var oldStatus = status.IsActive ? "Đang hoạt động" : "Không hoạt động";
        status.IsActive = !status.IsActive;
        var newStatus = status.IsActive ? "Đang hoạt động" : "Không hoạt động";
        await _db.SaveChangesAsync();

        await LogActivityAsync("ToggleStatusActive", $"Đã thay đổi trạng thái hoạt động: {status.Code} ({status.Name}) từ {oldStatus} sang {newStatus}");
        TempData["Success"] = $"Đã cập nhật trạng thái hoạt động.";
        return RedirectToAction("Index");
    }

    // GET /StatusCatalog/ByEntityType/Candidate
    [AllowAnonymous]
    public async Task<IActionResult> ByEntityType(string entityType)
    {
        var statuses = await _statusSvc.GetActiveByEntityTypeAsync(entityType);
        return Json(statuses);
    }

    private string GenerateCodeFromName(string name)
    {
        if (string.IsNullOrEmpty(name))
            return string.Empty;

        // Remove Vietnamese accents and convert to uppercase
        var vietnameseMap = new Dictionary<char, char>
        {
            {'à', 'a'}, {'á', 'a'}, {'ả', 'a'}, {'ã', 'a'}, {'ạ', 'a'},
            {'ă', 'a'}, {'ằ', 'a'}, {'ắ', 'a'}, {'ẳ', 'a'}, {'ẵ', 'a'}, {'ặ', 'a'},
            {'â', 'a'}, {'ầ', 'a'}, {'ấ', 'a'}, {'ẩ', 'a'}, {'ẫ', 'a'}, {'ậ', 'a'},
            {'è', 'e'}, {'é', 'e'}, {'ẻ', 'e'}, {'ẽ', 'e'}, {'ẹ', 'e'},
            {'ê', 'e'}, {'ề', 'e'}, {'ế', 'e'}, {'ể', 'e'}, {'ễ', 'e'}, {'ệ', 'e'},
            {'ì', 'i'}, {'í', 'i'}, {'ỉ', 'i'}, {'ĩ', 'i'}, {'ị', 'i'},
            {'ò', 'o'}, {'ó', 'o'}, {'ỏ', 'o'}, {'õ', 'o'}, {'ọ', 'o'},
            {'ô', 'o'}, {'ồ', 'o'}, {'ố', 'o'}, {'ổ', 'o'}, {'ỗ', 'o'}, {'ộ', 'o'},
            {'ơ', 'o'}, {'ờ', 'o'}, {'ớ', 'o'}, {'ở', 'o'}, {'ỡ', 'o'}, {'ợ', 'o'},
            {'ù', 'u'}, {'ú', 'u'}, {'ủ', 'u'}, {'ũ', 'u'}, {'ụ', 'u'},
            {'ư', 'u'}, {'ừ', 'u'}, {'ứ', 'u'}, {'ử', 'u'}, {'ữ', 'u'}, {'ự', 'u'},
            {'ỳ', 'y'}, {'ý', 'y'}, {'ỷ', 'y'}, {'ỹ', 'y'}, {'ỵ', 'y'},
            {'đ', 'd'},
            {'À', 'A'}, {'Á', 'A'}, {'Ả', 'A'}, {'Ã', 'A'}, {'Ạ', 'A'},
            {'Ă', 'A'}, {'Ằ', 'A'}, {'Ắ', 'A'}, {'Ẳ', 'A'}, {'Ẵ', 'A'}, {'Ặ', 'A'},
            {'Â', 'A'}, {'Ầ', 'A'}, {'Ấ', 'A'}, {'Ẩ', 'A'}, {'Ẫ', 'A'}, {'Ậ', 'A'},
            {'È', 'E'}, {'É', 'E'}, {'Ẻ', 'E'}, {'Ẽ', 'E'}, {'Ẹ', 'E'},
            {'Ê', 'E'}, {'Ề', 'E'}, {'Ế', 'E'}, {'Ể', 'E'}, {'Ễ', 'E'}, {'Ệ', 'E'},
            {'Ì', 'I'}, {'Í', 'I'}, {'Ỉ', 'I'}, {'Ĩ', 'I'}, {'Ị', 'I'},
            {'Ò', 'O'}, {'Ó', 'O'}, {'Ỏ', 'O'}, {'Õ', 'O'}, {'Ọ', 'O'},
            {'Ô', 'O'}, {'Ồ', 'O'}, {'Ố', 'O'}, {'Ổ', 'O'}, {'Ỗ', 'O'}, {'Ộ', 'O'},
            {'Ơ', 'O'}, {'Ờ', 'O'}, {'Ớ', 'O'}, {'Ở', 'O'}, {'Ỡ', 'O'}, {'Ợ', 'O'},
            {'Ù', 'U'}, {'Ú', 'U'}, {'Ủ', 'U'}, {'Ũ', 'U'}, {'Ụ', 'U'},
            {'Ư', 'U'}, {'Ừ', 'U'}, {'Ứ', 'U'}, {'Ử', 'U'}, {'Ữ', 'U'}, {'Ự', 'U'},
            {'Ỳ', 'Y'}, {'Ý', 'Y'}, {'Ỷ', 'Y'}, {'Ỹ', 'Y'}, {'Ỵ', 'Y'},
            {'Đ', 'D'}
        };

        var result = new System.Text.StringBuilder();
        foreach (char c in name)
        {
            if (vietnameseMap.ContainsKey(c))
            {
                result.Append(vietnameseMap[c]);
            }
            else if (char.IsLetterOrDigit(c))
            {
                result.Append(c);
            }
            else if (char.IsWhiteSpace(c))
            {
                result.Append('_');
            }
        }

        return result.ToString().ToUpper();
    }
}