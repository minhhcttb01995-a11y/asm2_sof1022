// ═══════════════════════════════════════════════════════════════════════════
// Program.cs — ĐIỂM KHỞI ĐỘNG (entry point) của ứng dụng JobConnect.
//
// Đây là ứng dụng ASP.NET Core MVC (mô hình Database First) cho một website
// tuyển dụng/tìm việc. File này làm 2 việc chính, theo đúng thứ tự bắt buộc
// của ASP.NET Core:
//   1) "builder" section: ĐĂNG KÝ (Dependency Injection) tất cả dịch vụ mà
//      ứng dụng cần: kết nối database (EF Core + SQL Server), đăng nhập
//      (Cookie + Google OAuth), phân quyền (Admin/Staff), và các Service
//      nghiệp vụ (JobService, FileService, GeminiService AI, v.v...).
//   2) "app" section: THIẾT LẬP PIPELINE xử lý HTTP request (middleware) theo
//      đúng thứ tự: static files -> routing -> authentication -> authorization
//      -> map route -> chạy app.
//
// Cách chạy dự án: xem hướng dẫn "HUONG_DAN_CHAY_DU_AN.md" ở thư mục gốc.
//
// [FIX 30/07] Google OAuth giờ chỉ được đăng ký (AddGoogle) khi appsettings.json
// thực sự có Authentication:Google:ClientId / ClientSecret. Trước đây luôn gọi
// AddGoogle(...) dù ClientId/Secret rỗng, khiến OAuthOptions.Validate() ném
// ArgumentException("The value cannot be an empty string. (Parameter 'ClientId')")
// ngay khi có request đầu tiên -> app trả về lỗi 500 trên môi trường chưa cấu
// hình Google (ví dụ server hosting chưa có Authentication:Google trong
// appsettings.json). Đăng nhập bằng Cookie (email/password thường) vẫn hoạt
// động bình thường dù không có Google OAuth.
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Hubs;
using JobConnect.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

// Tạo "builder" — đối tượng dùng để cấu hình ứng dụng trước khi nó chạy
// (đọc appsettings.json, đăng ký service, cấu hình logging...).
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, "keys")))
    .SetApplicationName("JobConnect");
// ── Configuration ──────────────────────────────────────────────
var configuration = builder.Configuration;

// ── Database ───────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlServer(
    configuration.GetConnectionString("DefaultConnection"),
    sqlOptions => sqlOptions.EnableRetryOnFailure());
});

builder.Services.AddScoped<IEmailService, EmailService>();

// ── Authentication (Cookie + Google, Google chỉ khi có cấu hình) ─
var googleClientId = configuration["Authentication:Google:ClientId"];
var googleClientSecret = configuration["Authentication:Google:ClientSecret"];
bool hasGoogleAuth = !string.IsNullOrWhiteSpace(googleClientId)
                     && !string.IsNullOrWhiteSpace(googleClientSecret);

var authBuilder = builder.Services.AddAuthentication(options =>
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
    // FIX: Project chỉ chạy HTTP ở localhost (xem launchSettings.json, không có
    // profile HTTPS nào). CookieSecurePolicy.Always khiến trình duyệt KHÔNG lưu
    // cookie đăng nhập trên kết nối HTTP -> mất session ngay sau khi login ->
    // [Authorize(Roles = "Staff,Admin")] trả về 401 ở mọi trang cần đăng nhập.
    // SameAsRequest sẽ tự dùng Secure khi chạy HTTPS (production) và bỏ qua khi
    // chạy HTTP (local dev), nên hoạt động đúng ở cả 2 môi trường.
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});

if (hasGoogleAuth)
{
    authBuilder.AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
    {
        options.ClientId = googleClientId!;
        options.ClientSecret = googleClientSecret!;
        options.CallbackPath = "/signin-google";

        // FIX LỖI 500 ON HOSTING HTTP (RunASP):
        // Cho phép lưu Correlation Cookie khi callback gửi qua kết nối HTTP
        options.CorrelationCookie.SameSite = SameSiteMode.Lax;
        options.CorrelationCookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    });
}

// FIX LỖI 500: Cấu hình Forwarded Headers cho Reverse Proxy của RunASP/SmarterASP
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

// ── Authorization ──────────────────────────────────────────────
builder.Services.AddAuthorization(options =>
{
    // Admin có toàn quyền (bao gồm quản lý Staff)
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));

    // Staff có quyền truy cập các module quản lý
    options.AddPolicy("StaffAccess", policy =>
        policy.RequireRole("Admin", "Staff"));
});

// ── Services ───────────────────────────────────────────────────
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJobService, JobService>();
builder.Services.AddScoped<IFileService, FileService>();
builder.Services.AddScoped<ISkillService, SkillService>();
builder.Services.AddScoped<IStatusCatalogService, StatusCatalogService>();
builder.Services.AddScoped<ICodeGeneratorService, CodeGeneratorService>();
builder.Services.AddHttpClient<IGeminiService, GeminiService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddScoped<ICvTextExtractionService, CvTextExtractionService>();
builder.Services.AddScoped<ILocalCvMatchService, LocalCvMatchService>();
builder.Services.AddScoped<IJobModerationService, JobModerationService>();

// ── MVC ────────────────────────────────────────────────────────
builder.Services.AddControllersWithViews();

// ── SignalR (Thông báo thời gian thực - real-time notifications) ─
// Cho phép server chủ động "đẩy" (push) thông báo mới xuống trình duyệt của
// đúng người dùng đang đăng nhập (Admin/Staff/Employer/Candidate), thay vì
// người dùng phải tự bấm F5 hoặc chờ polling mới thấy thông báo mới.
builder.Services.AddSignalR();

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

app.UseForwardedHeaders(); // FIX LỖI 500: Đọc Forwarded Headers từ Proxy

// FIX: Không có cổng HTTPS nào cấu hình cho local dev (launchSettings.json chỉ
// có profile "http"), nên UseHttpsRedirection() ở dev chỉ sinh warning vô ích
// và không redirect được. Chỉ bật khi chạy production (đã có HTTPS thật).
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

// ── Routes ─────────────────────────────────────────────────────
app.MapControllerRoute(
name: "default",
pattern: "{controller=Home}/{action=Index}/{id?}");

// Endpoint SignalR cho thông báo thời gian thực — trình duyệt sẽ kết nối tới
// đường dẫn này (xem wwwroot/js/notifications-realtime.js).
app.MapHub<NotificationHub>("/hubs/notifications");

// ── Database First: KHÔNG migrate, chỉ kiểm tra kết nối + seed (nếu cần) ──
// Database đã được tạo sẵn bằng script SQL (JobConnectDB_Create.sql) chạy
// trực tiếp trong SSMS. Model C# được sinh ra từ database đó bằng lệnh:
//    dotnet ef dbcontext scaffold ...
// Vì vậy KHÔNG được gọi dbContext.Database.MigrateAsync() nữa — Migrations
// thuộc về Code First, đi ngược lại yêu cầu Database First.
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();

    try
    {
        var dbContext = services.GetRequiredService<AppDbContext>();

        // Chỉ kiểm tra là kết nối được tới database đã tạo sẵn,
        // KHÔNG tạo/sửa schema từ code nữa.
        logger.LogInformation("Checking database connection...");
        bool canConnect = await dbContext.Database.CanConnectAsync();

        if (!canConnect)
        {
            logger.LogError(
                "Không kết nối được tới database. Hãy chắc chắn bạn đã chạy " +
                "script JobConnectDB_Create.sql trong SSMS và connection string " +
                "trong appsettings.json đúng với server của bạn.");
        }
        else
        {
            // [FIX] Gộp dữ liệu cũ: trước đây bảng StatusCatalogs có 2 EntityType khác nhau
            // ("Employer" và "Company") cùng dùng để lưu trạng thái cho MỘT bảng Employer,
            // khiến trạng thái tạo dưới nhãn "Công ty" không hiện ra ở trang /Admin/Companies
            // (chỉ đọc EntityType = "Employer"). Đoạn dưới đây tự động chạy 1 lần khi khởi
            // động app để chuyển toàn bộ StatusCatalog có EntityType = "Company" sang "Employer":
            //    - Nếu Code đó đã tồn tại sẵn bên "Employer" → xoá bản ghi "Company" trùng lặp.
            //    - Nếu chưa có → đổi EntityType của nó thành "Employer" để giữ lại cấu hình cũ.
            try
            {
                var companyTyped = await dbContext.StatusCatalogs
                    .Where(s => s.EntityType == "Company")
                    .ToListAsync();

                if (companyTyped.Count > 0)
                {
                    var employerCodes = await dbContext.StatusCatalogs
                        .Where(s => s.EntityType == "Employer")
                        .Select(s => s.Code)
                        .ToListAsync();

                    foreach (var s in companyTyped)
                    {
                        if (employerCodes.Contains(s.Code))
                        {
                            dbContext.StatusCatalogs.Remove(s); // trùng, đã có bên Employer rồi
                        }
                        else
                        {
                            s.EntityType = "Employer";
                            s.UpdatedAt = DateTime.Now;
                            employerCodes.Add(s.Code);
                        }
                    }

                    await dbContext.SaveChangesAsync();
                    logger.LogInformation(
                        "Đã gộp {Count} trạng thái từ EntityType 'Company' sang 'Employer'.",
                        companyTyped.Count);
                }
            }
            catch (Exception mergeEx)
            {
                logger.LogError(mergeEx, "Lỗi khi gộp StatusCatalog 'Company' -> 'Employer'.");
            }
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex,
            "An error occurred while connecting to or seeding the database.");
    }

}

// ── Debug Route ────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.MapGet("/gen",
    () => BCrypt.Net.BCrypt.HashPassword("Admin@123"));
}

app.Run();