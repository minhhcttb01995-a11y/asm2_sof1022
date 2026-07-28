// ═══════════════════════════════════════════════════════════════════════════
// AuthService — cài đặt IAuthService: xử lý ĐĂNG NHẬP và ĐĂNG KÝ tài khoản.
// Mật khẩu KHÔNG BAO GIỜ lưu dạng chữ thường (plain text): dùng thư viện BCrypt
// để "băm" (hash) khi đăng ký và "so khớp" (verify) khi đăng nhập.
// Được AccountController gọi tới thông qua Dependency Injection.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Helpers;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;  // Thêm dòng này
using System.Linq;

namespace JobConnect.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;              // EF Core DbContext để truy vấn/ghi database
    private readonly ICodeGeneratorService _codeGen; // Sinh UserCode/CompanyCode khi đăng ký

    public AuthService(AppDbContext db, ICodeGeneratorService codeGen)
    {
        _db = db;
        _codeGen = codeGen;
    }

    // Kiểm tra đăng nhập: tìm User theo email (không phân biệt hoa/thường),
    // sau đó so khớp mật khẩu nhập vào với PasswordHash đã lưu bằng BCrypt.Verify.
    // Trả về null nếu sai email hoặc sai mật khẩu (không tiết lộ lý do cụ thể vì lý do bảo mật).
    public async Task<User?> LoginAsync(string email, string password)
    {
        var normalizedEmail = email?.Trim().ToLowerInvariant();
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        if (user == null)
            return null;

        // Sửa: BCrypt.Net.BCrypt.Verify
        if (!BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            return null;

        // Chặn đăng nhập nếu tài khoản đã bị xóa mềm hoặc bị khóa/cấm.
        // Lưu ý: tùy nơi thực hiện "xóa đệm" mà Status có thể là "Deleted"
        // (AdminController xóa User/Employer/BlogPost) hoặc "Banned"
        // (StaffController xóa nhân viên chỉ set Status="Banned", không set "Deleted").
        // Nên chặn theo DeletedAt (đáng tin cậy nhất) VÀ theo các Status không cho phép đăng nhập.
        if (!CanLogin(user))
            return null;

        return user;
    }

    // Danh sách các trạng thái KHÔNG được phép đăng nhập.
    // Nếu sau này có thêm trạng thái mới (vd: "Suspended"), chỉ cần thêm vào đây.
    private static readonly string[] BlockedStatuses = { "Deleted", "Banned" };

    private static bool CanLogin(User user)
    {
        if (user.DeletedAt != null)
            return false;

        if (!string.IsNullOrEmpty(user.Status) &&
            BlockedStatuses.Any(s => string.Equals(s, user.Status, StringComparison.OrdinalIgnoreCase)))
            return false;

        return true;
    }

    // Kiểm tra email đã có tài khoản trong hệ thống chưa (dùng khi đăng ký để báo lỗi trùng email).
    public async Task<bool> EmailExistsAsync(string email)
    {
        var normalized = email?.Trim().ToLowerInvariant();
        return await _db.Users.AnyAsync(u => u.Email.ToLower() == normalized);
    }

    // Đăng ký tài khoản ỨNG VIÊN (Role = "Candidate"):
    // 1) Tạo User mới với mật khẩu đã hash.
    // 2) Lưu vào DB lần 1 để EF Core sinh ra UserId (auto-increment).
    // 3) Dùng UserId đó sinh UserCode (VD: UV000042) rồi lưu lại lần 2.
    public async Task<bool> RegisterCandidateAsync(RegisterViewModel model)
    {
        try
        {
            var user = new User
            {
                Email = model.Email,
                FullName = model.FullName,
                PhoneNumber = model.PhoneNumber,
                // Sửa: BCrypt.Net.BCrypt.HashPassword
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
                Role = "Candidate",
                CreatedAt = DateTime.Now,
                AvatarURL = null
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            // Mã người dùng: tự tăng theo UserId (vd: UV000042)
            user.UserCode = _codeGen.GenerateUserCode("Candidate", user.UserId);
            await _db.SaveChangesAsync();

            // Thông báo chào mừng + nhắc hoàn thiện hồ sơ: tài khoản vừa tạo CHƯA có
            // CandidateProfile (hồ sơ ứng viên), nên nếu cố ứng tuyển ngay sẽ bị chặn
            // (xem JobController.Apply). Gửi thông báo NGAY để họ biết cần bổ sung
            // thông tin trước khi có thể ứng tuyển.
            _db.Notifications.Add(new Notification
            {
                UserId = user.UserId,
                Title = "Chào mừng bạn đến với JobConnect!",
                Content = "Hãy hoàn thiện hồ sơ ứng viên (thông tin cá nhân, kỹ năng, CV) để có thể ứng tuyển vào các vị trí bạn quan tâm.",
                Type = "System",
                IsRead = false,
                CreatedAt = DateTime.Now
            });
            await _db.SaveChangesAsync();

            // Báo cho TOÀN BỘ Admin + Staff biết ngay lập tức có ứng viên mới
            // đăng ký (giống cơ chế đã dùng cho nhà tuyển dụng mới ở dưới).
            await _db.NotifyAdminsAsync(
                title: "Có ứng viên mới đăng ký",
                content: $"Ứng viên \"{user.FullName}\" ({user.Email}) vừa đăng ký tài khoản.",
                type: "NewCandidate",
                relatedId: user.UserId);
            await _db.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return false;
        }
    }

    // Đăng ký tài khoản NHÀ TUYỂN DỤNG (Role = "Employer"):
    // Khác với Candidate, ngoài User còn phải tạo thêm bản ghi Employer (hồ sơ công ty),
    // với Status = "Pending" (chờ Admin/Staff duyệt) và IsVerified = false ban đầu.
    public async Task<bool> RegisterEmployerAsync(RegisterEmployerViewModel model)
    {
        try
        {
            var user = new User
            {
                Email = model.Email,
                FullName = model.ContactName,
                PhoneNumber = model.PhoneNumber,
                // Sửa: BCrypt.Net.BCrypt.HashPassword
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
                Role = "Employer",
                CreatedAt = DateTime.Now,
                AvatarURL = null
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            // Mã người dùng: tự tăng theo UserId (vd: NTD000022)
            user.UserCode = _codeGen.GenerateUserCode("Employer", user.UserId);

            // Tạo employer profile
            var employer = new Employer
            {
                UserId = user.UserId,
                CompanyCode = await _codeGen.GenerateCompanyCodeAsync(),
                CompanyName = model.CompanyName,
                TaxCode = model.TaxCode,
                Industry = model.Industry,
                Address = model.Address,
                Website = model.Website,
                IsVerified = false,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _db.Employers.Add(employer);
            await _db.SaveChangesAsync();

            // Nhắc nhà tuyển dụng bổ sung đầy đủ thông tin cá nhân + công ty
            // trước khi được phép sử dụng đầy đủ hệ thống (đăng tin, v.v...) —
            // tương tự thông báo chào mừng đã gửi cho Candidate ở trên.
            _db.Notifications.Add(new Notification
            {
                UserId = user.UserId,
                Title = "Chào mừng bạn đến với JobConnect!",
                Content = "Hãy bổ sung đầy đủ thông tin cá nhân (giới tính, CCCD) và thông tin công ty (mã số thuế, lĩnh vực, địa chỉ) để tài khoản được kích hoạt và có thể sử dụng đầy đủ các chức năng, bao gồm đăng tin tuyển dụng.",
                Type = "System",
                IsRead = false,
                CreatedAt = DateTime.Now
            });
            await _db.SaveChangesAsync();

            // Báo cho TOÀN BỘ Admin + Staff biết ngay lập tức có nhà tuyển dụng/công ty
            // mới đăng ký, cần xem xét duyệt (giống cơ chế NotifyAdminsAsync đã dùng cho
            // tin tuyển dụng mới ở JobService.CreateAsync).
            await _db.NotifyAdminsAsync(
                title: "Có nhà tuyển dụng mới đăng ký",
                content: $"Công ty \"{employer.CompanyName}\" ({model.Email}) vừa đăng ký tài khoản nhà tuyển dụng, đang chờ duyệt.",
                type: "NewEmployer",
                relatedId: employer.EmployerId);
            await _db.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return false;
        }
    }
}