// [[CONTROLLER-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// AccountController — TOÀN BỘ luồng XÁC THỰC người dùng, không phân biệt vai trò:
//   • Login/Register/RegisterEmployer: đăng nhập, đăng ký Ứng viên / Nhà tuyển dụng.
//   • Logout, Settings: quản lý phiên đăng nhập (Cookie Authentication).
//   • ChangePassword/ChangeEmail/DeleteAccount: tự quản lý tài khoản (yêu cầu [Authorize]).
//   • ExternalLogin/GoogleResponse: đăng nhập bằng Google OAuth.
//   • ForgotPassword/VerifyOtp/ResetPassword: quên mật khẩu qua email OTP.
//   • VerifyEmailOtp/ResendEmailOtp: xác thực email bằng mã OTP gửi qua IEmailService.
// Phụ thuộc: IAuthService (đăng nhập/đăng ký), IEmailService (gửi OTP), AppDbContext trực tiếp
// cho các thao tác đọc/ghi User cụ thể của luồng xác thực.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using JobConnect.ViewModels;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

public class AccountController : Controller
{
    private readonly IAuthService _auth;
    private readonly AppDbContext _db;
    private readonly IEmailService _emailSvc;
    private readonly ICodeGeneratorService _codeGen;

    public AccountController(IAuthService auth, AppDbContext db, IEmailService emailSvc, ICodeGeneratorService codeGen)
    {
        _auth = auth;
        _db = db;

        _emailSvc = emailSvc;
        _codeGen = codeGen;
    }

    /// <summary>
    /// Request được gọi bằng fetch/AJAX từ modal đăng nhập/đăng ký (không phải điều hướng cả trang).
    /// </summary>
    private bool IsAjaxRequest() => Request.Headers["X-Requested-With"] == "XMLHttpRequest";

    /// <summary>
    /// Kiểm tra trạng thái hiện tại của user (theo StatusCatalog động do Admin quản lý)
    /// có bị đánh dấu "Chặn đăng nhập" (BlocksLogin = true) hay không.
    /// </summary>
    private async Task<bool> IsStatusBlockingLoginAsync(string? role, string? status)
    {
        if (string.IsNullOrEmpty(status)) return false;

        var entityType = role switch
        {
            "Candidate" => StatusEntityTypes.Candidate,
            "Employer" => StatusEntityTypes.Employer,
            "Staff" => StatusEntityTypes.Staff,
            _ => "User"
        };

        return await _db.StatusCatalogs.AnyAsync(s =>
            s.EntityType == entityType && s.Code == status && s.BlocksLogin);
    }

    // GET /Account/Login
    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            if (IsAjaxRequest())
                return Json(new { success = true, redirectUrl = Url.Action("Index", "Home") });
            return RedirectToAction("Index", "Home");
        }

        ViewBag.ReturnUrl = returnUrl;

        if (IsAjaxRequest())
            return PartialView("_LoginModalPartial", new LoginViewModel());

        return View();
    }

    // POST /Account/Login
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
    {
        ViewBag.ReturnUrl = returnUrl;

        if (!ModelState.IsValid)
        {
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_LoginModalPartial", model);
            }
            return View(model);
        }

        try
        {
            var user = await _auth.LoginAsync(model.Email, model.Password);

            if (user == null)
            {
                ModelState.AddModelError("", "Email hoặc mật khẩu không đúng.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_LoginModalPartial", model);
                }
                return View(model);
            }

            // Kiểm tra trạng thái tài khoản - chặn đăng nhập nếu trạng thái hiện tại
            // được Admin đánh dấu BlocksLogin = true trong danh mục Trạng thái (StatusCatalog)
            if (await IsStatusBlockingLoginAsync(user.Role, user.Status))
            {
                ModelState.AddModelError("", "Tài khoản của bạn đang ở trạng thái không được phép đăng nhập. Vui lòng liên hệ quản trị viên.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_LoginModalPartial", model);
                }
                return View(model);
            }

            // Cập nhật LastLoginAt
            user.LastLoginAt = DateTime.Now;
            await _db.SaveChangesAsync();

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Name, user.FullName ?? user.Email),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role ?? "Candidate"),
                new Claim("AvatarURL", user.AvatarUrl ?? "")
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
                new AuthenticationProperties
                {
                    IsPersistent = model.RememberMe,
                    ExpiresUtc = model.RememberMe ? DateTimeOffset.UtcNow.AddDays(30) : DateTimeOffset.UtcNow.AddHours(8)
                });

            string redirectUrl;
            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                redirectUrl = returnUrl;
            }
            else
            {
                redirectUrl = user.Role switch
                {
                    "Admin" => Url.Action("Index", "Admin")!,
                    "Staff" => Url.Action("Index", "StaffDashboard")!,
                    "Employer" => Url.Action("Dashboard", "Employer")!,
                    _ => Url.Action("Index", "Home")!
                };
            }

            if (IsAjaxRequest())
                return Json(new { success = true, redirectUrl });

            return Redirect(redirectUrl);
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi đăng nhập: {ex.Message}");
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_LoginModalPartial", model);
            }
            return View(model);
        }
    }

    // GET /Account/Register
    [HttpGet]
    public IActionResult Register()
    {
        if (IsAjaxRequest())
            return PartialView("_RegisterModalPartial", new RegisterViewModel());
        return View();
    }

    // POST /Account/Register
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_RegisterModalPartial", model);
            }
            return View(model);
        }

        try
        {
            if (await _auth.EmailExistsAsync(model.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterModalPartial", model);
                }
                return View(model);
            }

            if (model.Password != model.ConfirmPassword)
            {
                ModelState.AddModelError("ConfirmPassword", "Mật khẩu xác nhận không khớp.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterModalPartial", model);
                }
                return View(model);
            }

            var result = await _auth.RegisterCandidateAsync(model);

            if (result)
            {
                var newUser = await _db.Users.FirstOrDefaultAsync(u => u.Email == model.Email);
                if (newUser != null)
                {
                    // Set Pending + sinh OTP 6 số
                    newUser.Status = "Pending";
                    var otp = new Random().Next(100000, 999999).ToString();
                    newUser.OtpCode = otp;
                    newUser.OtpExpiry = DateTime.Now.AddMinutes(10);
                    await _db.SaveChangesAsync();

                    // Gửi email xác thực
                    var html = BuildOtpEmail(newUser.FullName ?? newUser.Email, otp, "xác thực tài khoản", 10);
                    try { await _emailSvc.SendAsync(newUser.Email, "✉️ Xác thực tài khoản JobConnect", html); }
                    catch { /* log */ }

                    TempData["OtpEmail"] = newUser.Email;
                    TempData["OtpPurpose"] = "register";
                    TempData["Success"] = "Đăng ký thành công! Kiểm tra email để lấy mã xác thực.";

                    if (IsAjaxRequest())
                        return Json(new { success = true, redirectUrl = Url.Action("VerifyEmailOtp") });

                    return RedirectToAction("VerifyEmailOtp");
                }

                ModelState.AddModelError("", "Có lỗi khi tạo tài khoản. Vui lòng thử lại.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterModalPartial", model);
                }
                return View(model);
            }
            else
            {
                ModelState.AddModelError("", "Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterModalPartial", model);
                }
                return View(model);
            }
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi: {ex.Message}");
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_RegisterModalPartial", model);
            }
            return View(model);
        }
    }

    // GET /Account/RegisterEmployer
    [HttpGet]
    public IActionResult RegisterEmployer()
    {
        if (IsAjaxRequest())
            return PartialView("_RegisterEmployerModalPartial", new RegisterEmployerViewModel());
        return View();
    }

    // POST /Account/RegisterEmployer
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RegisterEmployer(RegisterEmployerViewModel model)
    {
        if (!ModelState.IsValid)
        {
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_RegisterEmployerModalPartial", model);
            }
            return View(model);
        }

        try
        {
            if (await _auth.EmailExistsAsync(model.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterEmployerModalPartial", model);
                }
                return View(model);
            }

            if (model.Password != model.ConfirmPassword)
            {
                ModelState.AddModelError("ConfirmPassword", "Mật khẩu xác nhận không khớp.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterEmployerModalPartial", model);
                }
                return View(model);
            }

            var result = await _auth.RegisterEmployerAsync(model);

            if (result)
            {
                var newUser = await _db.Users.FirstOrDefaultAsync(u => u.Email == model.Email);
                if (newUser != null)
                {
                    newUser.Status = "Pending";
                    var otp = new Random().Next(100000, 999999).ToString();
                    newUser.OtpCode = otp;
                    newUser.OtpExpiry = DateTime.Now.AddMinutes(10);
                    await _db.SaveChangesAsync();

                    var html = BuildOtpEmail(newUser.FullName ?? newUser.Email, otp, "xác thực tài khoản nhà tuyển dụng", 10);
                    try { await _emailSvc.SendAsync(newUser.Email, "✉️ Xác thực tài khoản JobConnect", html); }
                    catch { /* log */ }

                    TempData["OtpEmail"] = newUser.Email;
                    TempData["OtpPurpose"] = "register";
                    TempData["Success"] = "Đăng ký thành công! Kiểm tra email để lấy mã xác thực.";

                    if (IsAjaxRequest())
                        return Json(new { success = true, redirectUrl = Url.Action("VerifyEmailOtp") });

                    return RedirectToAction("VerifyEmailOtp");
                }

                ModelState.AddModelError("", "Có lỗi khi tạo tài khoản. Vui lòng thử lại.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterEmployerModalPartial", model);
                }
                return View(model);
            }
            else
            {
                ModelState.AddModelError("", "Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.");
                if (IsAjaxRequest())
                {
                    Response.StatusCode = 400;
                    return PartialView("_RegisterEmployerModalPartial", model);
                }
                return View(model);
            }
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", $"Lỗi: {ex.Message}");
            if (IsAjaxRequest())
            {
                Response.StatusCode = 400;
                return PartialView("_RegisterEmployerModalPartial", model);
            }
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

        // Không đổi ngay — yêu cầu xác thực OTP gửi tới email trước khi áp dụng
        var otp = new Random().Next(100000, 999999).ToString();
        user.OtpCode = otp;
        user.OtpExpiry = DateTime.Now.AddMinutes(10);
        await _db.SaveChangesAsync();

        var html = BuildOtpEmail(user.FullName ?? user.Email, otp, "đổi mật khẩu", 10);
        try { await _emailSvc.SendAsync(user.Email, "🔐 Xác thực đổi mật khẩu - JobConnect", html); }
        catch { /* log nếu cần */ }

        TempData["OtpEmail"] = user.Email;
        TempData["OtpPurpose"] = "change_password";
        TempData["PendingNewPasswordHash"] = BCrypt.Net.BCrypt.HashPassword(NewPassword);
        TempData["OtpReturnController"] = "Account";
        TempData["OtpReturnAction"] = "Settings";
        TempData["Success"] = "Đã gửi mã OTP xác thực đến email của bạn. Vui lòng nhập mã để hoàn tất đổi mật khẩu.";
        return RedirectToAction("VerifyEmailOtp");
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

        if (await _db.Users.AnyAsync(u => u.Email == NewEmail && u.UserId != uid))
        {
            TempData["Error"] = "Email này đã được sử dụng.";
            return RedirectToAction("Settings");
        }

        // Không đổi ngay — gửi OTP tới EMAIL MỚI để xác nhận quyền sở hữu trước khi áp dụng
        var otp = new Random().Next(100000, 999999).ToString();
        user.OtpCode = otp;
        user.OtpExpiry = DateTime.Now.AddMinutes(10);
        await _db.SaveChangesAsync();

        var html = BuildOtpEmail(user.FullName ?? user.Email, otp, "đổi email", 10);
        try { await _emailSvc.SendAsync(NewEmail, "🔐 Xác thực đổi email - JobConnect", html); }
        catch { /* log nếu cần */ }

        TempData["OtpEmail"] = user.Email; // dùng email hiện tại để tra cứu user
        TempData["OtpPurpose"] = "change_email";
        TempData["PendingNewEmail"] = NewEmail;
        TempData["OtpReturnController"] = "Account";
        TempData["OtpReturnAction"] = "Settings";
        TempData["Success"] = $"Đã gửi mã OTP xác thực đến {NewEmail}. Vui lòng nhập mã để hoàn tất đổi email.";
        return RedirectToAction("VerifyEmailOtp");
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

        // Không xóa ngay — yêu cầu xác thực OTP gửi tới email trước khi xóa vĩnh viễn
        var otp = new Random().Next(100000, 999999).ToString();
        user.OtpCode = otp;
        user.OtpExpiry = DateTime.Now.AddMinutes(10);
        await _db.SaveChangesAsync();

        var html = BuildOtpEmail(user.FullName ?? user.Email, otp, "xóa tài khoản", 10);
        try { await _emailSvc.SendAsync(user.Email, "🔐 Xác thực xóa tài khoản - JobConnect", html); }
        catch { /* log nếu cần */ }

        TempData["OtpEmail"] = user.Email;
        TempData["OtpPurpose"] = "delete_account";
        TempData["OtpReturnController"] = "Account";
        TempData["OtpReturnAction"] = "Settings";
        TempData["Success"] = "Đã gửi mã OTP xác thực đến email của bạn. Vui lòng nhập mã để xác nhận xóa tài khoản.";
        return RedirectToAction("VerifyEmailOtp");
    }

    // ================= GOOGLE LOGIN =================

    // Đồng bộ tên Action xử lý từ View (View gọi ExternalLogin với provider="Google")
    [HttpGet]
    public IActionResult ExternalLogin(string provider, string? returnUrl = null)
    {
        var properties = new AuthenticationProperties
        {
            RedirectUri = Url.Action(nameof(GoogleResponse), new { returnUrl })
        };

        return Challenge(properties, provider ?? GoogleDefaults.AuthenticationScheme);
    }

    [HttpGet]
    public async Task<IActionResult> GoogleResponse(string? returnUrl = null)
    {
        // 1. Xác thực và lấy thông tin từ External Login (Google Scheme)
        var result = await HttpContext.AuthenticateAsync(GoogleDefaults.AuthenticationScheme);

        if (!result.Succeeded || result.Principal == null)
        {
            TempData["Error"] = "Không lấy được thông tin xác thực từ Google.";
            return RedirectToAction("Login");
        }

        // 2. Đọc chính xác các Claim từ Google Principal trả về
        var email = result.Principal.FindFirstValue(ClaimTypes.Email);
        var name = result.Principal.FindFirstValue(ClaimTypes.Name);

        if (string.IsNullOrEmpty(email))
        {
            TempData["Error"] = "Tài khoản Google của bạn không cung cấp Email công khai.";
            return RedirectToAction("Login");
        }

        // 3. Kiểm tra User trong DB hệ thống
        var user = await _db.Users.FirstOrDefaultAsync(x => x.Email == email);

        if (user == null)
        {
            // Tạo tài khoản Candidate mới nếu chưa tồn tại
            user = new User
            {
                Email = email,
                FullName = name ?? email,
                Role = "Candidate",
                Status = "Active",
                AvatarUrl = null,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()),
                CreatedAt = DateTime.Now
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            // Mã người dùng: tự tăng theo UserId
            user.UserCode = _codeGen.GenerateUserCode("Candidate", user.UserId);
            await _db.SaveChangesAsync();

            // Khởi tạo Profile đi kèm
            // [ĐÃ SỬA] Trước đây chỉ gán UserId mà không gán FullName, khiến các trang
            // hiển thị (VD: Lịch phỏng vấn, Danh sách ứng viên...) đọc từ CandidateProfile.FullName
            // bị trống dù User.FullName đã có tên lấy từ Google.
            var profile = new CandidateProfile
            {
                UserId = user.UserId,
                FullName = name ?? email
            };

            _db.CandidateProfiles.Add(profile);
            await _db.SaveChangesAsync();
        }
        else
        {
            // [ĐÃ SỬA] Vá lại các tài khoản Google đã tạo TRƯỚC khi sửa lỗi ở trên,
            // đang có CandidateProfile.FullName bị trống (hiển thị "U" không tên trong
            // danh sách ứng viên/lịch phỏng vấn bên nhà tuyển dụng).
            var existingProfile = await _db.CandidateProfiles.FirstOrDefaultAsync(p => p.UserId == user.UserId);
            if (existingProfile != null && string.IsNullOrWhiteSpace(existingProfile.FullName))
            {
                existingProfile.FullName = name ?? user.FullName ?? email;
                await _db.SaveChangesAsync();
            }
        }

        // Kiểm tra nếu tài khoản đang ở trạng thái bị chặn đăng nhập
        if (await IsStatusBlockingLoginAsync(user.Role, user.Status))
        {
            TempData["Error"] = "Tài khoản liên kết với Google này đang ở trạng thái không được phép đăng nhập.";
            return RedirectToAction("Login");
        }

        // 4. Thiết lập Session Cookie chính thức cho ứng dụng (Cookie Scheme)
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.FullName ?? user.Email),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role ?? "Candidate"),
            new Claim("AvatarURL", user.AvatarUrl ?? "")
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
            new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7)
            });

        TempData["Success"] = "Đăng nhập bằng Google thành công.";

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            return Redirect(returnUrl);

        return RedirectToAction("Index", "Home");
    }

    // ====================== QUÊN MẬT KHẨU ======================

    [HttpGet]
    public IActionResult ForgotPassword() => View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ForgotPassword(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            ModelState.AddModelError("", "Vui lòng nhập email.");
            return View();
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email.Trim().ToLower());

        if (user != null)
        {
            // Hủy token cũ
            var old = _db.PasswordResetTokens.Where(t => t.Email == email.ToLower() && !t.IsUsed);
            _db.PasswordResetTokens.RemoveRange(old);

            // Tạo OTP 6 số
            var code = new Random().Next(100000, 999999).ToString();
            _db.PasswordResetTokens.Add(new PasswordResetToken
            {
                Email = email.Trim().ToLower(),
                Code = code,
                ExpiresAt = DateTime.Now.AddMinutes(10),
                IsUsed = false
            });
            await _db.SaveChangesAsync();

            var html = $"<div style='font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f8fafc;border-radius:16px;'>"
                     + $"<h2 style='color:#003d9b;text-align:center'>JobConnect</h2>"
                     + $"<div style='background:#fff;border-radius:12px;padding:24px;border:1px solid #e2e8f0;'>"
                     + $"<p>Xin chào <strong>{user.FullName ?? user.Email}</strong>,</p>"
                     + $"<p>Mã OTP đặt lại mật khẩu của bạn là:</p>"
                     + $"<div style='text-align:center;margin:24px 0;'>"
                     + $"<span style='font-size:40px;font-weight:900;letter-spacing:12px;color:#003d9b;background:#eff6ff;padding:16px 24px;border-radius:12px;display:inline-block;'>{code}</span>"
                     + $"</div>"
                     + $"<p style='color:#94a3b8;font-size:13px;text-align:center'>Mã có hiệu lực trong <strong>10 phút</strong>. Không chia sẻ mã này với bất kỳ ai.</p>"
                     + $"</div></div>";

            try { await _emailSvc.SendAsync(email, "Mã OTP đặt lại mật khẩu - JobConnect", html); }
            catch { /* log nếu cần */ }
        }

        TempData["Info"] = "Nếu email tồn tại, mã OTP đã được gửi. Vui lòng kiểm tra hộp thư.";
        return RedirectToAction("VerifyOtp", new { email });
    }

    [HttpGet]
    public IActionResult VerifyOtp(string email)
    {
        ViewBag.Email = email;
        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> VerifyOtp(string email, string code)
    {
        ViewBag.Email = email;
        if (string.IsNullOrWhiteSpace(code))
        {
            ModelState.AddModelError("", "Vui lòng nhập mã OTP.");
            return View();
        }

        var token = await _db.PasswordResetTokens
            .Where(t => t.Email == email.ToLower() && t.Code == code.Trim()
                     && !t.IsUsed && t.ExpiresAt > DateTime.Now)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (token == null)
        {
            ModelState.AddModelError("", "Mã OTP không đúng hoặc đã hết hạn.");
            return View();
        }

        TempData["ResetEmail"] = email;
        TempData["ResetTokenId"] = token.Id.ToString();
        return RedirectToAction("ResetPassword");
    }

    [HttpGet]
    public IActionResult ResetPassword()
    {
        if (TempData["ResetEmail"] == null) return RedirectToAction("ForgotPassword");
        ViewBag.Email = TempData["ResetEmail"];
        ViewBag.TokenId = TempData["ResetTokenId"];
        TempData.Keep("ResetEmail"); TempData.Keep("ResetTokenId");
        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(string email, int tokenId, string newPassword, string confirmPassword)
    {
        if (newPassword != confirmPassword)
        {
            ModelState.AddModelError("", "Mật khẩu xác nhận không khớp.");
            ViewBag.Email = email; ViewBag.TokenId = tokenId;
            return View();
        }
        if (newPassword.Length < 6)
        {
            ModelState.AddModelError("", "Mật khẩu phải có ít nhất 6 ký tự.");
            ViewBag.Email = email; ViewBag.TokenId = tokenId;
            return View();
        }

        var token = await _db.PasswordResetTokens
            .FirstOrDefaultAsync(t => t.Id == tokenId && t.Email == email && !t.IsUsed && t.ExpiresAt > DateTime.Now);

        if (token == null)
        {
            TempData["Error"] = "Phiên đặt lại đã hết hạn. Vui lòng thực hiện lại.";
            return RedirectToAction("ForgotPassword");
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null) return RedirectToAction("ForgotPassword");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        user.UpdatedAt = DateTime.Now;
        token.IsUsed = true;
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đặt lại mật khẩu thành công! Vui lòng đăng nhập.";
        return RedirectToAction("Login");
    }


    // ====================== XÁC THỰC EMAIL OTP ======================

    // Helper tạo email đẹp
    private static string BuildOtpEmail(string name, string otp, string purpose, int minutes) => $@"
<!DOCTYPE html><html><head><meta charset='UTF-8'></head>
<body style='margin:0;padding:0;background:#0a0a0a;font-family:Arial,sans-serif;'>
<table width='100%' cellpadding='0' cellspacing='0' style='padding:40px 0;'>
<tr><td align='center'>
<table width='520' cellpadding='0' cellspacing='0' style='background:#111827;border-radius:16px;border:1px solid #1e293b;overflow:hidden;'>
  <tr><td style='background:linear-gradient(135deg,#1d4ed8,#4f46e5);padding:28px 40px;text-align:center;'>
    <div style='font-size:26px;font-weight:900;color:#fff;'>📋 JobConnect</div>
    <div style='color:#bfdbfe;font-size:12px;margin-top:4px;'>Mã xác thực {purpose}</div>
  </td></tr>
  <tr><td style='padding:32px 40px;'>
    <p style='color:#94a3b8;font-size:14px;margin:0 0 6px;'>Xin chào <strong style='color:#f1f5f9;'>{name}</strong>,</p>
    <p style='color:#94a3b8;font-size:14px;margin:0 0 24px;'>Mã OTP để {purpose} của bạn là:</p>
    <div style='background:#0f172a;border:2px dashed #3b82f6;border-radius:12px;padding:24px;text-align:center;margin-bottom:24px;'>
      <div style='color:#94a3b8;font-size:11px;letter-spacing:2px;margin-bottom:10px;text-transform:uppercase;'>Mã xác thực OTP</div>
      <div style='font-size:42px;font-weight:900;letter-spacing:12px;color:#60a5fa;font-family:monospace;'>{otp}</div>
      <div style='color:#64748b;font-size:12px;margin-top:10px;'>⏱ Hiệu lực trong <strong style='color:#f59e0b;'>{minutes} phút</strong></div>
    </div>
    <p style='color:#64748b;font-size:12px;'>Không chia sẻ mã này với bất kỳ ai. Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email.</p>
  </td></tr>
  <tr><td style='background:#0f172a;padding:16px 40px;border-top:1px solid #1e293b;text-align:center;'>
    <p style='color:#475569;font-size:11px;margin:0;'>© 2025 JobConnect – Nhóm Star Arrow</p>
  </td></tr>
</table></td></tr></table></body></html>";

    // GET /Account/VerifyEmailOtp
    [HttpGet]
    public IActionResult VerifyEmailOtp()
    {
        var email = TempData["OtpEmail"]?.ToString();
        if (string.IsNullOrEmpty(email)) return RedirectToAction("Login");
        TempData.Keep("OtpEmail");
        TempData.Keep("OtpPurpose");
        TempData.Keep("RememberMe");
        TempData.Keep("ReturnUrl");
        TempData.Keep("PendingNewPasswordHash");
        TempData.Keep("PendingNewEmail");
        TempData.Keep("OtpReturnController");
        TempData.Keep("OtpReturnAction");
        ViewBag.Email = email;
        ViewBag.Purpose = TempData.Peek("OtpPurpose")?.ToString() ?? "register";
        return View();
    }

    // POST /Account/VerifyEmailOtp
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> VerifyEmailOtp(string email, string otp, string purpose)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null) return RedirectToAction("Login");

        ViewBag.Email = email;
        ViewBag.Purpose = purpose;

        if (user.OtpExpiry == null || user.OtpExpiry < DateTime.Now)
        {
            ViewBag.OtpError = "Mã OTP đã hết hạn. Vui lòng gửi lại.";
            TempData.Keep("OtpEmail"); TempData.Keep("OtpPurpose");
            TempData.Keep("PendingNewPasswordHash"); TempData.Keep("PendingNewEmail");
            TempData.Keep("OtpReturnController"); TempData.Keep("OtpReturnAction");
            return View();
        }

        if (user.OtpCode?.Trim() != otp.Trim())
        {
            ViewBag.OtpError = "Mã OTP không đúng. Vui lòng kiểm tra lại.";
            TempData.Keep("OtpEmail"); TempData.Keep("OtpPurpose");
            TempData.Keep("PendingNewPasswordHash"); TempData.Keep("PendingNewEmail");
            TempData.Keep("OtpReturnController"); TempData.Keep("OtpReturnAction");
            return View();
        }

        // Xác thực thành công → clear OTP
        user.OtpCode = null;
        user.OtpExpiry = null;

        // ===== Các hành động bảo mật tài khoản: đổi mật khẩu / đổi email / xóa tài khoản =====
        if (purpose is "change_password" or "change_email" or "delete_account")
        {
            var retController = TempData["OtpReturnController"]?.ToString() ?? "Account";
            var retAction = TempData["OtpReturnAction"]?.ToString() ?? "Settings";

            if (purpose == "change_password")
            {
                var pendingHash = TempData["PendingNewPasswordHash"]?.ToString();
                if (!string.IsNullOrEmpty(pendingHash))
                {
                    user.PasswordHash = pendingHash;
                    user.UpdatedAt = DateTime.Now;
                }
                await _db.SaveChangesAsync();
                TempData["Success"] = "✅ Đổi mật khẩu thành công.";
            }
            else if (purpose == "change_email")
            {
                var pendingEmail = TempData["PendingNewEmail"]?.ToString();
                if (!string.IsNullOrEmpty(pendingEmail))
                {
                    user.Email = pendingEmail;
                    user.UpdatedAt = DateTime.Now;
                    await _db.SaveChangesAsync();

                    if (User.Identity?.IsAuthenticated == true &&
                        User.FindFirstValue(ClaimTypes.NameIdentifier) == user.UserId.ToString())
                    {
                        var identity = (ClaimsIdentity)User.Identity!;
                        var emailClaim = identity.FindFirst(ClaimTypes.Email);
                        if (emailClaim != null) identity.RemoveClaim(emailClaim);
                        identity.AddClaim(new Claim(ClaimTypes.Email, pendingEmail));
                        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));
                    }
                }
                else
                {
                    await _db.SaveChangesAsync();
                }
                TempData["Success"] = "✅ Đổi email thành công.";
            }
            else // delete_account
            {
                await _db.SaveChangesAsync();
                _db.Users.Remove(user);
                await _db.SaveChangesAsync();
                if (User.Identity?.IsAuthenticated == true)
                    await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                TempData["Success"] = "Tài khoản đã được xóa thành công.";
                return RedirectToAction("Index", "Home");
            }

            return RedirectToAction(retAction, retController);
        }

        if (purpose == "register")
            user.Status = "Active";

        user.LastLoginAt = DateTime.Now;
        await _db.SaveChangesAsync();

        // Đọc RememberMe & ReturnUrl từ TempData
        var rememberMe = TempData["RememberMe"]?.ToString() == "True";
        var returnUrl = TempData["ReturnUrl"]?.ToString();

        // Đăng nhập luôn
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name,           user.FullName ?? user.Email),
            new Claim(ClaimTypes.Email,          user.Email),
            new Claim(ClaimTypes.Role,           user.Role ?? "Candidate"),
            new Claim("AvatarURL",               user.AvatarUrl ?? "")
        };
        var loginIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(loginIdentity),
            new AuthenticationProperties
            {
                IsPersistent = rememberMe,
                ExpiresUtc = rememberMe ? DateTimeOffset.UtcNow.AddDays(30) : DateTimeOffset.UtcNow.AddHours(8)
            });

        TempData["Success"] = purpose == "register"
            ? "🎉 Xác thực email thành công! Chào mừng đến với JobConnect."
            : "✅ Xác thực đăng nhập thành công!";

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            return Redirect(returnUrl);

        return user.Role switch
        {
            "Admin" => RedirectToAction("Index", "Admin"),
            "Staff" => RedirectToAction("Index", "StaffDashboard"),
            "Employer" => RedirectToAction("Dashboard", "Employer"),
            _ => RedirectToAction("Index", "Home")
        };
    }

    // POST /Account/ResendEmailOtp
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResendEmailOtp(string email, string purpose)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null) return RedirectToAction("Login");

        var otp = new Random().Next(100000, 999999).ToString();
        user.OtpCode = otp;
        user.OtpExpiry = DateTime.Now.AddMinutes(10);
        await _db.SaveChangesAsync();

        var purposeLabel = purpose switch
        {
            "login" => "xác thực đăng nhập",
            "change_password" => "đổi mật khẩu",
            "change_email" => "đổi email",
            "delete_account" => "xóa tài khoản",
            _ => "xác thực tài khoản"
        };

        // Với đổi email, OTP phải gửi tới email MỚI (đang chờ xác nhận), không phải email hiện tại
        var pendingEmail = TempData.Peek("PendingNewEmail")?.ToString();
        var sendTo = (purpose == "change_email" && !string.IsNullOrEmpty(pendingEmail)) ? pendingEmail : user.Email;

        var html = BuildOtpEmail(user.FullName ?? user.Email, otp, purposeLabel, 10);
        try { await _emailSvc.SendAsync(sendTo, "🔐 Gửi lại mã OTP - JobConnect", html); }
        catch { /* log */ }

        TempData["OtpEmail"] = email;
        TempData["OtpPurpose"] = purpose;
        TempData.Keep("PendingNewPasswordHash");
        TempData.Keep("PendingNewEmail");
        TempData.Keep("OtpReturnController");
        TempData.Keep("OtpReturnAction");
        TempData["Success"] = $"Đã gửi lại mã OTP mới về {sendTo}.";
        return RedirectToAction("VerifyEmailOtp");
    }


}