using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    public AuthService(AppDbContext db) => _db = db;

    public async Task<User?> LoginAsync(string email, string password)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email && u.Status == "Active");
        if (user == null) return null;
        return BCrypt.Net.BCrypt.Verify(password, user.PasswordHash) ? user : null;
    }

    public async Task<bool> EmailExistsAsync(string email)
        => await _db.Users.AnyAsync(u => u.Email == email);

    public async Task<User> RegisterCandidateAsync(RegisterViewModel model)
    {
        var user = new User
        {
            Email = model.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
            FullName = model.FullName,
            PhoneNumber = model.PhoneNumber,
            Role = "Candidate",
            Status = "Active"
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        // Tạo profile rỗng cho ứng viên
        _db.CandidateProfiles.Add(new CandidateProfile { UserID = user.UserID });
        await _db.SaveChangesAsync();
        return user;
    }

    public async Task<User> RegisterEmployerAsync(RegisterEmployerViewModel model)
    {
        var user = new User
        {
            Email = model.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
            FullName = model.ContactName,
            PhoneNumber = model.PhoneNumber,
            Role = "Employer",
            Status = "Active"
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        _db.Employers.Add(new Employer
        {
            UserID = user.UserID,
            CompanyName = model.CompanyName,
            TaxCode = model.TaxCode,
            Industry = model.Industry,
            Address = model.Address,
            Website = model.Website
        });
        await _db.SaveChangesAsync();
        return user;
    }
}