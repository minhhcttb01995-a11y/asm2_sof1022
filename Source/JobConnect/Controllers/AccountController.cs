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
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Home");

        ViewBag.ReturnUrl = returnUrl;
        return View();
    }

    // POST /Account/Login
    // POST /Account/Login
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var user = await _auth.LoginAsync(model.Email, model.Password);

            if (user == null)
            {
                ModelState.AddModelError("", "Email hoặc mật khẩu không đúng.");
                return View(model);
            }

            // Kiểm tra trạng thái tài khoản (Status: Active | Banned | Pending)
            if (user.Status != "Active")
            {
                var msg = user.Status == "Banned"
                    ? "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên."
                    : "Tài khoản chưa được kích hoạt. Vui lòng kiểm tra email xác thực.";
                ModelState.AddModelError("", msg);
                return View(model);
            }

            var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
            new Claim(ClaimTypes.Name, user.FullName ?? user.Email),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role ?? "Candidate"),
            new Claim("AvatarURL", user.AvatarURL ?? "/img/default-avatar.png")
        };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
                new AuthenticationProperties
                {
                    IsPersistent = model.RememberMe,
                    ExpiresUtc = model.RememberMe ? DateTimeOffset.UtcNow.AddDays(30) : DateTimeOffset.UtcNow.AddHours(8)
                });

            // Chuyển hướng dựa trên role
            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
                return Redirect(returnUrl);

            return user.Role switch
            {
                "Admin" => RedirectToAction("Index", "Admin", new { area = "Admin" }),
                "Employer" => RedirectToAction("Dashboard", "Employer"),
                _ => RedirectToAction("Index", "Home")
            };
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi đăng nhập: {ex.Message}");
            return View(model);
        }
    }
    

    // GET /Account/Register
    [HttpGet]
    public IActionResult Register()
    {
        return View();
    }

    // POST /Account/Register
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        try
        {
            // Kiểm tra email đã tồn tại
            if (await _auth.EmailExistsAsync(model.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
                return View(model);
            }

            // Kiểm tra mật khẩu
            if (model.Password != model.ConfirmPassword)
            {
                ModelState.AddModelError("ConfirmPassword", "Mật khẩu xác nhận không khớp.");
                return View(model);
            }

            // Đăng ký
            var result = await _auth.RegisterCandidateAsync(model);

            if (result)
            {
                // Auto-login after successful registration
                var newUser = await _auth.LoginAsync(model.Email, model.Password);
                if (newUser != null)
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.NameIdentifier, newUser.UserID.ToString()),
                        new Claim(ClaimTypes.Name, newUser.FullName ?? newUser.Email),
                        new Claim(ClaimTypes.Email, newUser.Email),
                        new Claim(ClaimTypes.Role, newUser.Role ?? "Candidate"),
                        new Claim("AvatarURL", newUser.AvatarURL ?? "/img/default-avatar.png")
                    };

                    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                    var principal = new ClaimsPrincipal(identity);

                    await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
                        new AuthenticationProperties
                        {
                            IsPersistent = false,
                            ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8)
                        });

                    TempData["Success"] = "Đăng ký thành công! Bạn đã được đăng nhập.";
                    return RedirectToAction("Index", "Home");
                }

                TempData["Success"] = "Đăng ký thành công! Vui lòng đăng nhập.";
                return RedirectToAction("Login");
            }
            else
            {
                ModelState.AddModelError("", "Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.");
                return View(model);
            }
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi: {ex.Message}");
            return View(model);
        }
    }

    // GET /Account/RegisterEmployer
    [HttpGet]
    public IActionResult RegisterEmployer()
    {
        return View();
    }

    // POST /Account/RegisterEmployer
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RegisterEmployer(RegisterEmployerViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        try
        {
            // Kiểm tra email đã tồn tại
            if (await _auth.EmailExistsAsync(model.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
                return View(model);
            }

            // Kiểm tra mật khẩu
            if (model.Password != model.ConfirmPassword)
            {
                ModelState.AddModelError("ConfirmPassword", "Mật khẩu xác nhận không khớp.");
                return View(model);
            }

            // Đăng ký
            var result = await _auth.RegisterEmployerAsync(model);

            if (result)
            {
                // Auto-login employer after registration
                var newUser = await _auth.LoginAsync(model.Email, model.Password);
                if (newUser != null)
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.NameIdentifier, newUser.UserID.ToString()),
                        new Claim(ClaimTypes.Name, newUser.FullName ?? newUser.Email),
                        new Claim(ClaimTypes.Email, newUser.Email),
                        new Claim(ClaimTypes.Role, newUser.Role ?? "Employer"),
                        new Claim("AvatarURL", newUser.AvatarURL ?? "/img/default-avatar.png")
                    };

                    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                    var principal = new ClaimsPrincipal(identity);

                    await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
                        new AuthenticationProperties
                        {
                            IsPersistent = false,
                            ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8)
                        });

                    TempData["Success"] = "Đăng ký thành công! Bạn đã được đăng nhập.";
                    return RedirectToAction("Dashboard", "Employer");
                }

                TempData["Success"] = "Đăng ký tài khoản nhà tuyển dụng thành công! Vui lòng đăng nhập.";
                return RedirectToAction("Login");
            }
            else
            {
                ModelState.AddModelError("", "Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.");
                return View(model);
            }
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi: {ex.Message}");
            return View(model);
        }
    }

    // POST /Account/Logout
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Index", "Home");
    }

    // GET /Account/Settings
    [Authorize]
    public IActionResult Settings()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
        {
            return RedirectToAction("Login");
        }

        var user = _db.Users.Find(userId);
        if (user == null)
            return RedirectToAction("Login");

        ViewBag.User = user;
        return View();
    }

    // POST /Account/ChangePassword
    [HttpPost]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangePassword(string CurrentPassword, string NewPassword, string ConfirmPassword)
    {
        if (string.IsNullOrEmpty(CurrentPassword) || string.IsNullOrEmpty(NewPassword))
        {
            TempData["Error"] = "Vui lòng nhập đầy đủ thông tin.";
            return RedirectToAction("Settings");
        }

        if (NewPassword != ConfirmPassword)
        {
            TempData["Error"] = "Mật khẩu xác nhận không khớp.";
            return RedirectToAction("Settings");
        }

        if (NewPassword.Length < 6)
        {
            TempData["Error"] = "Mật khẩu mới phải có ít nhất 6 ký tự.";
            return RedirectToAction("Settings");
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int uid))
        {
            TempData["Error"] = "Không tìm thấy thông tin người dùng.";
            return RedirectToAction("Login");
        }

        var user = await _db.Users.FindAsync(uid);
        if (user == null)
        {
            TempData["Error"] = "Người dùng không tồn tại.";
            return RedirectToAction("Login");
        }

        if (!BCrypt.Net.BCrypt.Verify(CurrentPassword, user.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu hiện tại không đúng.";
            return RedirectToAction("Settings");
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(NewPassword);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã đổi mật khẩu thành công.";
        return RedirectToAction("Settings");
    }

    // POST /Account/ChangeEmail
    [HttpPost]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangeEmail(string NewEmail, string Password)
    {
        if (string.IsNullOrEmpty(NewEmail) || string.IsNullOrEmpty(Password))
        {
            TempData["Error"] = "Vui lòng nhập đầy đủ thông tin.";
            return RedirectToAction("Settings");
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int uid))
        {
            TempData["Error"] = "Không tìm thấy thông tin người dùng.";
            return RedirectToAction("Login");
        }

        var user = await _db.Users.FindAsync(uid);
        if (user == null)
        {
            TempData["Error"] = "Người dùng không tồn tại.";
            return RedirectToAction("Login");
        }

        if (!BCrypt.Net.BCrypt.Verify(Password, user.PasswordHash))
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

        // Cập nhật claim email
        var identity = (ClaimsIdentity)User.Identity;
        var emailClaim = identity.FindFirst(ClaimTypes.Email);
        if (emailClaim != null)
            identity.RemoveClaim(emailClaim);
        identity.AddClaim(new Claim(ClaimTypes.Email, NewEmail));
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));

        TempData["Success"] = "Đã cập nhật email thành công.";
        return RedirectToAction("Settings");
    }

    // POST /Account/DeleteAccount
    [HttpPost]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAccount(string Password)
    {
        if (string.IsNullOrEmpty(Password))
        {
            TempData["Error"] = "Vui lòng nhập mật khẩu để xác nhận xóa tài khoản.";
            return RedirectToAction("Settings");
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int uid))
        {
            TempData["Error"] = "Không tìm thấy thông tin người dùng.";
            return RedirectToAction("Login");
        }

        var user = await _db.Users.FindAsync(uid);
        if (user == null)
        {
            TempData["Error"] = "Người dùng không tồn tại.";
            return RedirectToAction("Login");
        }

        if (!BCrypt.Net.BCrypt.Verify(Password, user.PasswordHash))
        {
            TempData["Error"] = "Mật khẩu không đúng.";
            return RedirectToAction("Settings");
        }

        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

        TempData["Success"] = "Tài khoản đã được xóa thành công.";
        return RedirectToAction("Index", "Home");
    }
}