// ═══════════════════════════════════════════════════════════════════════════
// AuthService — cài đặt IAuthService: xử lý ĐĂNG NHẬP và ĐĂNG KÝ tài khoản.
// Mật khẩu KHÔNG BAO GIỜ lưu dạng chữ thường (plain text): dùng thư viện BCrypt
// để "băm" (hash) khi đăng ký và "so khớp" (verify) khi đăng nhập.
// Được AccountController gọi tới thông qua Dependency Injection.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;  // Thêm dòng này

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

        return user;
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

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return false;
        }
    }
}