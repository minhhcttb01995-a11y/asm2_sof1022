using JobConnect.Data;
using JobConnect.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

// ── 1. Cấu hình Database ──────────────────────────────────────
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// Sửa lỗi: Đảm bảo AddEntityFrameworkStores sử dụng đúng AppDbContext
builder.Services.AddDefaultIdentity<ApplicationUser>(options =>
{
    options.SignIn.RequireConfirmedAccount = false; // Để false cho dễ test lúc đầu
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
    .AddEntityFrameworkStores<AppDbContext>();

// ── 2. Authentication (Cookie + Google) ───────────────────────
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = IdentityConstants.ApplicationScheme;
    options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
})
.AddCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
    options.AccessDeniedPath = "/Account/AccessDenied";
})
.AddGoogle(googleOptions =>
{
    // Đọc từ appsettings.json
    googleOptions.ClientId = builder.Configuration["GoogleKeys:ClientId"] ?? "dummy-id";
    googleOptions.ClientSecret = builder.Configuration["GoogleKeys:ClientSecret"] ?? "dummy-secret";
});

// ── 3. Services (Dependency Injection) ──────────────────────
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJobService, JobService>();
builder.Services.AddScoped<IFileService, FileService>();

// ── 4. MVC ──────────────────────────────────────────────────
builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages(); // Cần thiết nếu dùng Identity Default UI

var app = builder.Build();

// ── 5. Middleware Pipeline ───────────────────────────────────
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

// ── 6. Routes ────────────────────────────────────────────────
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapRazorPages();

// ── 7. Auto migrate & Seed Data ──────────────────────────────
// Bọc trong try-catch để nếu lỗi DB thì App vẫn chạy được (tránh lỗi 'Unable to connect')
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var db = services.GetRequiredService<AppDbContext>();
        db.Database.Migrate();
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Một lỗi đã xảy ra khi Migration Database.");
    }
}

// Route phụ trợ
app.MapGet("/gen", () => BCrypt.Net.BCrypt.HashPassword("Admin@123"));

app.Run();