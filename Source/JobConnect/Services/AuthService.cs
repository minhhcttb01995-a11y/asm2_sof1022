using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;  // Thêm dòng này

namespace JobConnect.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly ICodeGeneratorService _codeGen;

    public AuthService(AppDbContext db, ICodeGeneratorService codeGen)
    {
        _db = db;
        _codeGen = codeGen;
    }

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

    public async Task<bool> EmailExistsAsync(string email)
    {
        var normalized = email?.Trim().ToLowerInvariant();
        return await _db.Users.AnyAsync(u => u.Email.ToLower() == normalized);
    }

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