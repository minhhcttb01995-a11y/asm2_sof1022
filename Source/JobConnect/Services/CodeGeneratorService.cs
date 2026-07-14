using JobConnect.Data;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

public class CodeGeneratorService : ICodeGeneratorService
{
    private const string RandomChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // bỏ ký tự dễ nhầm (0,O,1,I)
    private static readonly Random _random = new();

    private readonly AppDbContext _db;

    public CodeGeneratorService(AppDbContext db)
    {
        _db = db;
    }

    public string GenerateUserCode(string role, int userId)
    {
        var prefix = role switch
        {
            "Candidate" => "UV",   // Ứng Viên
            "Employer" => "NTD",   // Nhà Tuyển Dụng
            "Admin" => "AD",
            "Staff" => "NV",
            _ => "ND"              // Người Dùng (fallback)
        };
        return $"{prefix}{userId:D6}";
    }

    public async Task<string> GenerateCompanyCodeAsync()
        => await GenerateUniqueRandomCodeAsync("CTY", 6,
            code => _db.Employers.AnyAsync(e => e.CompanyCode == code));

    public async Task<string> GenerateJobCodeAsync()
        => await GenerateUniqueRandomCodeAsync("TD", 6,
            code => _db.JobPosts.AnyAsync(j => j.JobCode == code));

    public async Task<string> GenerateBlogCodeAsync()
        => await GenerateUniqueRandomCodeAsync("BL", 6,
            code => _db.BlogPosts.AnyAsync(b => b.BlogCode == code));

    public async Task<string> GenerateStaffCodeAsync()
        => await GenerateUniqueRandomCodeAsync("NV", 6,
            code => _db.Staff.AnyAsync(s => s.EmployeeCode == code));

    private static string RandomSegment(int length)
    {
        var chars = new char[length];
        for (int i = 0; i < length; i++)
        {
            chars[i] = RandomChars[_random.Next(RandomChars.Length)];
        }
        return new string(chars);
    }

    private async Task<string> GenerateUniqueRandomCodeAsync(string prefix, int randomLength, Func<string, Task<bool>> existsCheck)
    {
        string code;
        var attempts = 0;
        do
        {
            code = $"{prefix}{RandomSegment(randomLength)}";
            attempts++;
            // Sau nhiều lần đụng hàng hiếm gặp, tăng độ dài để chắc chắn thoát vòng lặp
            if (attempts > 10) randomLength++;
        }
        while (await existsCheck(code));

        return code;
    }
}
