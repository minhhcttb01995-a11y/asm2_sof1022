using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using JobConnect.Data;
using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Controllers
{
    public class AccountController : Controller
    {
        private readonly AppDbContext _context;

        public AccountController(AppDbContext context) => _context = context;

        [HttpGet]
        public IActionResult Login(string returnUrl = "/") { ViewBag.ReturnUrl = returnUrl; return View(); }

        [HttpGet]
        public IActionResult Register() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            // Kiểm tra email tồn tại
            if (await _context.Users.AnyAsync(u => u.Email == model.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
                return View(model);
            }

            var user = new User
            {
                Email = model.Email,
                FullName = model.FullName,
                Role = model.Role,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password), // Dùng BCrypt
                Status = "Active",
                CreatedAt = DateTime.Now
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return RedirectToAction("Login");
        }

        [HttpGet]
        public IActionResult ExternalLogin(string returnUrl = "/")
        {
            var props = new AuthenticationProperties { RedirectUri = Url.Action("GoogleCallback", new { returnUrl }) };
            return Challenge(props, GoogleDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public async Task<IActionResult> GoogleCallback(string returnUrl = "/")
        {
            var res = await HttpContext.AuthenticateAsync(GoogleDefaults.AuthenticationScheme);
            if (!res.Succeeded) return RedirectToAction("Login");

            var email = res.Principal.FindFirstValue(ClaimTypes.Email);
            var name = res.Principal.FindFirstValue(ClaimTypes.Name);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                user = new User { Email = email!, FullName = name, Role = "Candidate", PasswordHash = "Google", Status = "Active" };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var claims = new List<Claim> {
                new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme)));

            return LocalRedirect(returnUrl);
        }

        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Index", "Home");
        }
    }
}