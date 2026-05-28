using JobConnect.Data;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

public class AccountController : Controller
{
    private readonly IAuthService _auth;
    private readonly AppDbContext _db;

    public AccountController(IAuthService auth, AppDbContext db)
    {
        _auth = auth;
        _db = db;
    }

    // GET /Account/Login
    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        ViewBag.ReturnUrl = returnUrl;
        return View();
    }

    // POST /Account/Login
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
    {
        if (!ModelState.IsValid) return View(model);

        var user = await _auth.LoginAsync(model.Email, model.Password);
        if (user == null)
        {
            ModelState.AddModelError("", "Email hoặc mật khẩu không đúng.");
            return View(model);
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserID.ToString()),
            new(ClaimTypes.Name,           user.FullName),
            new(ClaimTypes.Email,          user.Email),
            new(ClaimTypes.Role,           user.Role),
            new("AvatarURL",               user.AvatarURL ?? "/img/default-avatar.png")
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
            new AuthenticationProperties { IsPersistent = model.RememberMe });

        return Redirect(returnUrl ?? user.Role switch
        {
            "Admin" => "/Admin/Dashboard",
            "Employer" => "/Employer/Dashboard",
            _ => "/"
        });
    }

    // GET /Account/Register
    public IActionResult Register() => View();

    // POST /Account/Register
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        if (await _auth.EmailExistsAsync(model.Email))
        {
            ModelState.AddModelError("Email", "Email này đã được sử dụng.");
            return View(model);
        }

        await _auth.RegisterCandidateAsync(model);
        TempData["Success"] = "Đăng ký thành công! Vui lòng đăng nhập.";
        return RedirectToAction("Login");
    }

    // GET /Account/RegisterEmployer
    public IActionResult RegisterEmployer() => View();

    // POST /Account/RegisterEmployer
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> RegisterEmployer(RegisterEmployerViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        if (await _auth.EmailExistsAsync(model.Email))
        {
            ModelState.AddModelError("Email", "Email này đã được sử dụng.");
            return View(model);
        }

        await _auth.RegisterEmployerAsync(model);
        TempData["Success"] = "Đăng ký tài khoản nhà tuyển dụng thành công!";
        return RedirectToAction("Login");
    }

    // POST /Account/Logout
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Index", "Home");
    }

    [Authorize]
    public IActionResult Settings() => View();

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangePassword(string CurrentPassword, string NewPassword, string ConfirmPassword)
    {
        if (NewPassword != ConfirmPassword)
        {
            TempData["Error"] = "Mật khẩu xác nhận không khớp.";
            return RedirectToAction("Settings");
        }
        var uid = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(uid);
        if (user == null || !BCrypt.Net.BCrypt.Verify(CurrentPassword, user.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu hiện tại không đúng.";
            return RedirectToAction("Settings");
        }
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(NewPassword);
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã đổi mật khẩu thành công.";
        return RedirectToAction("Settings");
    }

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangeEmail(string NewEmail, string Password)
    {
        var uid = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(uid);
        if (user == null || !BCrypt.Net.BCrypt.Verify(Password, user.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu không đúng.";
            return RedirectToAction("Settings");
        }
        if (await _db.Users.AnyAsync(u => u.Email == NewEmail && u.UserID != uid))
        {
            TempData["Error"] = "Email này đã được sử dụng.";
            return RedirectToAction("Settings");
        }
        user.Email = NewEmail;
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã cập nhật email.";
        return RedirectToAction("Settings");
    }

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAccount(string Password)
    {
        var uid = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(uid);
        if (user == null || !BCrypt.Net.BCrypt.Verify(Password, user.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu không đúng.";
            return RedirectToAction("Settings");
        }
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Index", "Home");
    }
}