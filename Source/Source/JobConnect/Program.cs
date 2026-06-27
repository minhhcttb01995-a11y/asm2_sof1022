using JobConnect.Data;
using JobConnect.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

var builder = WebApplication.CreateBuilder(args);

// ── Configuration ──────────────────────────────────────────────
var configuration = builder.Configuration;

// ── Database ───────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlServer(
    configuration.GetConnectionString("DefaultConnection"),
    sqlOptions => sqlOptions.EnableRetryOnFailure());
});
// Thêm dòng này vào Program.cs, sau builder.Services.AddDbContext:
builder.Services.AddScoped<IEmailService, EmailService>();
// ── Authentication (Cookie + Google) ──────────────────────────
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
    options.AccessDeniedPath = "/Account/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromDays(7);
    options.SlidingExpiration = true;
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
})
.AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
{
    options.ClientId = configuration["Authentication:Google:ClientId"]!;
    options.ClientSecret = configuration["Authentication:Google:ClientSecret"]!;
    options.CallbackPath = "/signin-google";
});

// ── Authorization ──────────────────────────────────────────────
builder.Services.AddAuthorization();

// ── Services ───────────────────────────────────────────────────
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJobService, JobService>();
builder.Services.AddScoped<IFileService, FileService>();
builder.Services.AddScoped<ISkillService, SkillService>();

// ── MVC ────────────────────────────────────────────────────────
builder.Services.AddControllersWithViews();

// ── Build App ──────────────────────────────────────────────────
var app = builder.Build();

// ── Middleware Pipeline ────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

// ── Routes ─────────────────────────────────────────────────────
app.MapControllerRoute(
name: "default",
pattern: "{controller=Home}/{action=Index}/{id?}");

// ── Database Migration + Seed Data ─────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();

    try
    {
        var dbContext = services.GetRequiredService<AppDbContext>();

        logger.LogInformation("Applying database migrations...");
        dbContext.Database.MigrateAsync().GetAwaiter().GetResult();

        if (app.Environment.IsDevelopment())
        {
            logger.LogInformation("Seeding initial data...");
            SeedData.Initialize(services).GetAwaiter().GetResult();
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex,
            "An error occurred while migrating or seeding the database. Application will continue.");
    }
}

// ── Debug Route ────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.MapGet("/gen",
    () => BCrypt.Net.BCrypt.HashPassword("Admin@123"));
}

app.Run();
