using JobConnect.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace JobConnect.Data
{
    /// <summary>
    /// SeedData – Khởi tạo dữ liệu mẫu cho toàn bộ hệ thống JobConnect.
    ///
    /// THỨ TỰ SEED (quan trọng – phải theo thứ tự do phụ thuộc FK):
    ///   1.  Users            – 20 bản ghi (1 Admin, 2 SuperAdmin/Staff user, 2 Staff user, 6 Employer, 9 Candidate)
    ///   2.  Staff            – 3 bản ghi  (SuperAdmin + 2 Staff, liên kết với User ở bước 1)
    ///   3.  Categories       – 20 bản ghi (8 Industry, 6 Location, 4 Level, 2 JobType)
    ///   4.  Skills           – 20 bản ghi (đủ các SkillCategory)
    ///   5.  ServicePackages  – 20 bản ghi (các gói dịch vụ cho nhà tuyển dụng)
    ///   6.  Employers        – 6 bản ghi  (liên kết User Employer)
    ///   7.  CandidateProfiles– 9 bản ghi  (liên kết User Candidate)
    ///   8.  CvFiles          – 20 bản ghi (2 CV / candidate – tổng 9 candidate × 2 = 18, thêm 2 của candidate 1)
    ///   9.  CandidateSkills  – 20 bản ghi (composite PK: ProfileID + SkillID, mỗi profile 2 skill)
    ///   10. JobPosts         – 20 bản ghi (liên kết Employer + Category)
    ///   11. Applications     – 20 bản ghi (liên kết JobPost + CandidateProfile + CvFile)
    ///   12. SavedJobs        – 20 bản ghi (liên kết User Candidate + JobPost, unique index)
    ///   13. Notifications    – 20 bản ghi (liên kết User)
    ///   14. Transactions     – 20 bản ghi (liên kết Employer + ServicePackage)
    ///   15. BlogPosts        – 20 bản ghi (liên kết User Admin)
    ///   16. SystemLogs       – 20 bản ghi (liên kết User, nullable)
    ///   17. Interviews       – 20 bản ghi (liên kết Application)
    ///   18. Reports          – 20 bản ghi (liên kết User + JobPost/Employer)
    ///   19. SupportTickets   – 20 bản ghi (liên kết User + Staff)
    ///   20. ActivityLogs     – 20 bản ghi (liên kết Staff)
    ///
    /// MẬT KHẨU SEED:
    ///   - Tất cả user thường : Test@123  (hash BCrypt rounds=12)
    ///   - Admin / Staff      : Admin@123 (hash BCrypt rounds=12)
    /// </summary>
    public static class SeedData
    {
        // ─────────────────────────────────────────────────────────────
        // BCrypt hash sẵn (tránh phụ thuộc thư viện lúc seed)
        // ─────────────────────────────────────────────────────────────
        // Test@123
        private const string UserHash = "$2a$12$C1IOdpqSw3kMkdN7U7Rb0ObOuj3ru6HJG3QzP1Sk8EG/OCZxz5m5O";
        // Admin@123
        private const string AdminHash = "$2a$12$ymY/qtoRN48u6qAp4OjdFu1bECLm3mVLDPr0j3T6IMAS8mKsjvf6i";

        // ─────────────────────────────────────────────────────────────
        // ENTRY POINT
        // ─────────────────────────────────────────────────────────────
        public static async Task Initialize(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Bỏ qua nếu đã có dữ liệu (chạy lại app không bị lỗi duplicate)
            if (await context.Users.AnyAsync()) return;

            // ── Seed theo đúng thứ tự FK dependency ──
            await SeedUsers(context);               // Bước 1
            await SeedStaff(context);               // Bước 2  (cần Users)
            await SeedCategories(context);          // Bước 3
            await SeedSkills(context);              // Bước 4
            await SeedServicePackages(context);     // Bước 5
            await SeedEmployers(context);           // Bước 6  (cần Users)
            await SeedCandidateProfiles(context);   // Bước 7  (cần Users)
            await SeedCvFiles(context);             // Bước 8  (cần CandidateProfiles)
            await SeedCandidateSkills(context);     // Bước 9  (cần Profiles + Skills)
            await SeedJobPosts(context);            // Bước 10 (cần Employers + Categories)
            await SeedApplications(context);        // Bước 11 (cần JobPosts + Profiles + CvFiles)
            await SeedSavedJobs(context);           // Bước 12 (cần Users + JobPosts)
            await SeedNotifications(context);       // Bước 13 (cần Users + JobPosts)
            await SeedTransactions(context);        // Bước 14 (cần Employers + ServicePackages)
            await SeedBlogPosts(context);           // Bước 15 (cần Users Admin)
            await SeedSystemLogs(context);          // Bước 16 (cần Users)
            await SeedInterviews(context);          // Bước 17 (cần Applications)
            await SeedReports(context);             // Bước 18 (cần Users + JobPosts + Employers)
            await SeedSupportTickets(context);      // Bước 19 (cần Users + Staff)
            await SeedActivityLogs(context);        // Bước 20 (cần Staff)

            Console.WriteLine("✅ SeedData hoàn tất – tất cả bảng đã có 20 bản ghi mẫu!");
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 1 – USERS (20 bản ghi)
        //   Phân bổ role:
        //     [0]       admin@jobconnect.vn     → Admin
        //     [1-2]     superadmin, staff1-2    → SuperAdmin / Staff  (tạo cùng lúc để dùng ngay ở Bước 2)
        //     [3-8]     hr@..., recruit@...     → Employer  (6 người)
        //     [9-19]    an.nguyen@..., ...      → Candidate (10 người)
        //
        //   Lưu ý model User:
        //     - UserID   : int PK, tự sinh
        //     - Role     : "Admin" | "SuperAdmin" | "Staff" | "Employer" | "Candidate"
        //     - Status   : "Active" | "Banned" | "Pending"
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedUsers(AppDbContext context)
        {
            var users = new[]
            {
                // ── [0] Admin hệ thống ──
                new User { Email = "admin@jobconnect.vn",      PasswordHash = AdminHash, Role = "Admin",      FullName = "Quản trị viên",           PhoneNumber = "0987654321", Status = "Active", CreatedAt = DateTime.UtcNow },
 
                // ── [1-2] Staff thường – sẽ gắn vào Staff ở Bước 2 ──
                new User { Email = "staff1@jobconnect.vn",     PasswordHash = AdminHash, Role = "Staff",      FullName = "Nguyễn Văn Staff 1",       PhoneNumber = "0912345678", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "staff2@jobconnect.vn",     PasswordHash = AdminHash, Role = "Staff",      FullName = "Trần Thị Staff 2",         PhoneNumber = "0923456789", Status = "Active", CreatedAt = DateTime.UtcNow },
 
                // ── [4-9] Employer (6 công ty) ──
                new User { Email = "hr@fptsoft.com",           PasswordHash = UserHash,  Role = "Employer",   FullName = "Nguyễn Thị HR – FPT",      PhoneNumber = "0909123456", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "recruit@vng.com.vn",       PasswordHash = UserHash,  Role = "Employer",   FullName = "Lê Minh Tuyển – VNG",      PhoneNumber = "0908234567", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "talent@tiki.vn",           PasswordHash = UserHash,  Role = "Employer",   FullName = "Phạm Thị Lan – Tiki",      PhoneNumber = "0907345678", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "hr@momo.vn",               PasswordHash = UserHash,  Role = "Employer",   FullName = "Trần Hoàng Nam – MoMo",    PhoneNumber = "0906456789", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "hr@shopee.vn",             PasswordHash = UserHash,  Role = "Employer",   FullName = "Bùi Thanh Tùng – Shopee",  PhoneNumber = "0904678901", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "talent@zalo.me",           PasswordHash = UserHash,  Role = "Employer",   FullName = "Đặng Quốc Huy – Zalo",    PhoneNumber = "0903789012", Status = "Active", CreatedAt = DateTime.UtcNow },
 
                // ── [10-19] Candidate (10 người) ──
                new User { Email = "an.nguyen@gmail.com",      PasswordHash = UserHash,  Role = "Candidate",  FullName = "Nguyễn Văn An",            PhoneNumber = "0912111222", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "binh.le@gmail.com",        PasswordHash = UserHash,  Role = "Candidate",  FullName = "Lê Thị Bình",              PhoneNumber = "0923222333", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "cuong.pham@gmail.com",     PasswordHash = UserHash,  Role = "Candidate",  FullName = "Phạm Mạnh Cường",          PhoneNumber = "0934333444", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "duyen.vo@gmail.com",       PasswordHash = UserHash,  Role = "Candidate",  FullName = "Võ Thị Duyên",             PhoneNumber = "0945444555", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "em.tran@gmail.com",        PasswordHash = UserHash,  Role = "Candidate",  FullName = "Trần Minh Em",             PhoneNumber = "0956555666", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "giang.hoang@gmail.com",    PasswordHash = UserHash,  Role = "Candidate",  FullName = "Hoàng Thị Giang",          PhoneNumber = "0967666777", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "hung.bui@gmail.com",       PasswordHash = UserHash,  Role = "Candidate",  FullName = "Bùi Văn Hùng",             PhoneNumber = "0978777888", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "ky.do@gmail.com",          PasswordHash = UserHash,  Role = "Candidate",  FullName = "Đỗ Hải Kỳ",               PhoneNumber = "0989888999", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "lan.dang@gmail.com",       PasswordHash = UserHash,  Role = "Candidate",  FullName = "Đặng Thị Lan",             PhoneNumber = "0990999000", Status = "Active", CreatedAt = DateTime.UtcNow },
                new User { Email = "minh.cao@gmail.com",       PasswordHash = UserHash,  Role = "Candidate",  FullName = "Cao Xuân Minh",            PhoneNumber = "0911000111", Status = "Active", CreatedAt = DateTime.UtcNow },
            };
            // Tổng: 19 bản ghi (1 Admin + 2 Staff + 6 Employer + 10 Candidate)

            await context.Users.AddRangeAsync(users);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 2 – STAFF (2 bản ghi liên kết vào bảng Staff)
        //   Model Staff:
        //     - Id                : int PK, tự sinh
        //     - ApplicationUserId : FK → User.UserID  (NOT NULL)
        //     - EmployeeCode      : string UNIQUE, NOT NULL
        //     - FullName, Email, Phone, Position, Department : string NOT NULL
        //     - Status            : enum StaffStatus { Active=1, Locked=2 }
        //
        //   Lấy UserID từ email đã seed ở Bước 1
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedStaff(AppDbContext context)
        {
            // Lấy đúng user theo email để lấy UserID đã được EF sinh ra
            var uStaff1 = await context.Users.FirstAsync(u => u.Email == "staff1@jobconnect.vn");
            var uStaff2 = await context.Users.FirstAsync(u => u.Email == "staff2@jobconnect.vn");

            var staffList = new[]
            {
                // ── Staff 1 – Content Moderator ──
                new Staff
                {
                    ApplicationUserId = uStaff1.UserID,
                    EmployeeCode      = "STF20260001",
                    FullName          = uStaff1.FullName,
                    Email             = uStaff1.Email,
                    Phone             = uStaff1.PhoneNumber,
                    Position          = "Content Moderator",
                    Department        = "Content Management",
                    Status            = StaffStatus.Active,
                    CreatedAt         = DateTime.UtcNow
                },
                // ── Staff 2 – Customer Support ──
                new Staff
                {
                    ApplicationUserId = uStaff2.UserID,
                    EmployeeCode      = "STF20260002",
                    FullName          = uStaff2.FullName,
                    Email             = uStaff2.Email,
                    Phone             = uStaff2.PhoneNumber,
                    Position          = "Customer Support",
                    Department        = "Support",
                    Status            = StaffStatus.Active,
                    CreatedAt         = DateTime.UtcNow
                },
            };
            // Tổng: 2 bản ghi Staff (dùng lại ở Bước 19 SupportTickets, Bước 20 ActivityLogs)

            await context.Staff.AddRangeAsync(staffList);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 3 – CATEGORIES (20 bản ghi)
        //   Model Category:
        //     - CategoryID : int PK, tự sinh
        //     - ParentID   : int? (self-reference – để null vì đây là root)
        //     - Name       : string NOT NULL
        //     - Type       : "Industry" | "Location" | "Level" | "JobType"
        //     - Slug       : string NOT NULL (dùng để query JobPosts ở Bước 6)
        //
        //   Phân bổ: 8 Industry + 6 Location + 4 Level + 2 JobType = 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedCategories(AppDbContext context)
        {
            var cats = new[]
            {
                // ── Industry (8) – ngành nghề ──
                new Category { Name = "Công nghệ thông tin",      Type = "Industry", Slug = "cong-nghe-thong-tin" },
                new Category { Name = "Marketing & Truyền thông", Type = "Industry", Slug = "marketing"           },
                new Category { Name = "Tài chính – Kế toán",      Type = "Industry", Slug = "tai-chinh-ke-toan"   },
                new Category { Name = "Kỹ thuật – Cơ khí",        Type = "Industry", Slug = "ky-thuat-co-khi"     },
                new Category { Name = "Y tế – Dược phẩm",         Type = "Industry", Slug = "y-te-duoc-pham"      },
                new Category { Name = "Thiết kế – Mỹ thuật",      Type = "Industry", Slug = "thiet-ke"            },
                new Category { Name = "Giáo dục – Đào tạo",       Type = "Industry", Slug = "giao-duc-dao-tao"    },
                new Category { Name = "Bán hàng – Kinh doanh",    Type = "Industry", Slug = "ban-hang-kinh-doanh" },
 
                // ── Location (6) – địa điểm ──
                new Category { Name = "Hà Nội",          Type = "Location", Slug = "ha-noi"      },
                new Category { Name = "TP. Hồ Chí Minh", Type = "Location", Slug = "ho-chi-minh" },
                new Category { Name = "Đà Nẵng",         Type = "Location", Slug = "da-nang"     },
                new Category { Name = "Cần Thơ",         Type = "Location", Slug = "can-tho"     },
                new Category { Name = "Hải Phòng",       Type = "Location", Slug = "hai-phong"   },
                new Category { Name = "Bình Dương",      Type = "Location", Slug = "binh-duong"  },
 
                // ── Level (4) – cấp độ kinh nghiệm ──
                new Category { Name = "Fresher", Type = "Level",   Slug = "fresher" },
                new Category { Name = "Junior",  Type = "Level",   Slug = "junior"  },
                new Category { Name = "Middle",  Type = "Level",   Slug = "middle"  },
                new Category { Name = "Senior",  Type = "Level",   Slug = "senior"  },
 
                // ── JobType (2) – hình thức việc làm ──
                new Category { Name = "FullTime",   Type = "JobType", Slug = "full-time"   },
                new Category { Name = "Internship", Type = "JobType", Slug = "internship"  },
            };
            // Tổng: 20 bản ghi

            await context.Categories.AddRangeAsync(cats);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 4 – SKILLS (20 bản ghi)
        //   Model Skill:
        //     - SkillID     : int PK, tự sinh
        //     - Name        : string UNIQUE, NOT NULL
        //     - Description : string?
        //     - Category    : enum SkillCategory { Programming, Design, Marketing, SoftSkills, Language, Management, Other }
        //     - IsActive    : bool (true = đang hiển thị trên UI)
        //
        //   Phân bổ: 10 Programming + 3 Design + 3 Marketing + 2 SoftSkills + 2 Language = 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedSkills(AppDbContext context)
        {
            var skills = new[]
            {
                // ── Programming (10) ──
                new Skill { Name = "C#",          Description = "Ngôn ngữ .NET của Microsoft",            Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = ".NET Core",   Description = "Framework cross-platform của Microsoft",  Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "JavaScript",  Description = "Ngôn ngữ lập trình web client/server",   Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "React.js",    Description = "Thư viện UI của Facebook",               Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "Python",      Description = "Ngôn ngữ đa dụng, phổ biến AI/Data",    Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "Java",        Description = "Ngôn ngữ hướng đối tượng enterprise",    Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "Node.js",     Description = "Runtime JavaScript phía server",         Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "SQL Server",  Description = "Hệ quản trị CSDL của Microsoft",         Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "Docker",      Description = "Containerization platform",              Category = SkillCategory.Programming, IsActive = true },
                new Skill { Name = "Flutter",     Description = "Framework mobile cross-platform",        Category = SkillCategory.Programming, IsActive = true },
 
                // ── Design (3) ──
                new Skill { Name = "Figma",       Description = "Công cụ thiết kế UI/UX",                Category = SkillCategory.Design,      IsActive = true },
                new Skill { Name = "Adobe XD",    Description = "Công cụ thiết kế UI/UX của Adobe",      Category = SkillCategory.Design,      IsActive = true },
                new Skill { Name = "Photoshop",   Description = "Phần mềm chỉnh sửa ảnh chuyên nghiệp",  Category = SkillCategory.Design,      IsActive = true },
 
                // ── Marketing (3) ──
                new Skill { Name = "SEO",         Description = "Tối ưu hóa công cụ tìm kiếm",           Category = SkillCategory.Marketing,   IsActive = true },
                new Skill { Name = "Google Ads",  Description = "Quảng cáo trên Google",                 Category = SkillCategory.Marketing,   IsActive = true },
                new Skill { Name = "Facebook Ads",Description = "Quảng cáo trên Facebook",               Category = SkillCategory.Marketing,   IsActive = true },
 
                // ── SoftSkills (2) ──
                new Skill { Name = "Communication",   Description = "Kỹ năng giao tiếp hiệu quả",        Category = SkillCategory.SoftSkills,  IsActive = true },
                new Skill { Name = "Problem Solving", Description = "Kỹ năng giải quyết vấn đề",         Category = SkillCategory.SoftSkills,  IsActive = true },
 
                // ── Language (2) ──
                new Skill { Name = "English",     Description = "Kỹ năng tiếng Anh chuyên ngành",        Category = SkillCategory.Language,    IsActive = true },
                new Skill { Name = "Japanese",    Description = "Kỹ năng tiếng Nhật",                    Category = SkillCategory.Language,    IsActive = true },
            };
            // Tổng: 20 bản ghi (Name UNIQUE – không được trùng)

            await context.Skills.AddRangeAsync(skills);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 5 – SERVICE PACKAGES (20 bản ghi)
        //   Model ServicePackage:
        //     - PackageID    : int PK, tự sinh
        //     - Name         : string NOT NULL
        //     - Price        : decimal (decimal(15,0) – đơn vị VNĐ)
        //     - DurationDays : int (số ngày hiệu lực)
        //     - MaxJobPosts  : int (số tin đăng tối đa; 999 = không giới hạn)
        //     - MaxFeatured  : int (số tin nổi bật tối đa)
        //     - Description  : string?
        //     - IsActive     : bool (false = ẩn khỏi trang mua gói)
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedServicePackages(AppDbContext context)
        {
            var pkgs = new[]
            {
                // ── Gói miễn phí & thử nghiệm ──
                new ServicePackage { Name = "Miễn phí",          Price = 0,          DurationDays = 30,  MaxJobPosts = 3,   MaxFeatured = 0,  Description = "Đăng tối đa 3 tin/tháng, không nổi bật.",                     IsActive = true  },
                new ServicePackage { Name = "Trial 7 ngày",      Price = 99_000,     DurationDays = 7,   MaxJobPosts = 2,   MaxFeatured = 1,  Description = "Dùng thử 7 ngày với đầy đủ tính năng cơ bản.",                IsActive = true  },
 
                // ── Gói tháng phổ thông ──
                new ServicePackage { Name = "Starter",           Price = 299_000,    DurationDays = 30,  MaxJobPosts = 5,   MaxFeatured = 1,  Description = "5 tin/tháng, 1 tin nổi bật – phù hợp startup nhỏ.",          IsActive = true  },
                new ServicePackage { Name = "Basic",             Price = 599_000,    DurationDays = 30,  MaxJobPosts = 8,   MaxFeatured = 2,  Description = "8 tin/tháng, 2 tin nổi bật.",                                  IsActive = true  },
                new ServicePackage { Name = "Pro",               Price = 990_000,    DurationDays = 30,  MaxJobPosts = 15,  MaxFeatured = 3,  Description = "15 tin/tháng, 3 tin nổi bật, hỗ trợ ưu tiên.",               IsActive = true  },
                new ServicePackage { Name = "Pro Plus",          Price = 1_490_000,  DurationDays = 30,  MaxJobPosts = 25,  MaxFeatured = 5,  Description = "25 tin/tháng, 5 tin nổi bật, badge xác thực.",                IsActive = true  },
                new ServicePackage { Name = "Business",          Price = 1_990_000,  DurationDays = 30,  MaxJobPosts = 50,  MaxFeatured = 8,  Description = "50 tin/tháng, 8 tin nổi bật, hiển thị logo.",                 IsActive = true  },
                new ServicePackage { Name = "Enterprise",        Price = 2_490_000,  DurationDays = 30,  MaxJobPosts = 999, MaxFeatured = 10, Description = "Không giới hạn tin, 10 tin nổi bật, logo premium.",           IsActive = true  },
 
                // ── Gói năm – tiết kiệm ──
                new ServicePackage { Name = "Enterprise Annual", Price = 19_900_000, DurationDays = 365, MaxJobPosts = 999, MaxFeatured = 15, Description = "Gói năm Enterprise – tiết kiệm 33%.",                         IsActive = true  },
                new ServicePackage { Name = "Platinum Annual",   Price = 39_900_000, DurationDays = 365, MaxJobPosts = 999, MaxFeatured = 50, Description = "Gói năm cao cấp nhất – đối tác chiến lược.",                  IsActive = true  },
 
                // ── Gói theo ngành / đặc thù ──
                new ServicePackage { Name = "Campus Recruit",    Price = 799_000,    DurationDays = 30,  MaxJobPosts = 10,  MaxFeatured = 2,  Description = "Tuyển dụng sinh viên, hiển thị trang Campus.",                IsActive = true  },
                new ServicePackage { Name = "Tech Talent",       Price = 1_290_000,  DurationDays = 30,  MaxJobPosts = 20,  MaxFeatured = 4,  Description = "Dành riêng cho nhà tuyển dụng ngành IT.",                     IsActive = true  },
                new ServicePackage { Name = "Remote Hire",       Price = 890_000,    DurationDays = 30,  MaxJobPosts = 12,  MaxFeatured = 3,  Description = "Tập trung tin Remote cho ứng viên toàn quốc.",                IsActive = true  },
                new ServicePackage { Name = "Internship Pack",   Price = 390_000,    DurationDays = 30,  MaxJobPosts = 6,   MaxFeatured = 1,  Description = "Đăng tin thực tập sinh với chi phí thấp.",                    IsActive = true  },
                new ServicePackage { Name = "SME Pack",          Price = 690_000,    DurationDays = 30,  MaxJobPosts = 10,  MaxFeatured = 2,  Description = "Gói dành cho doanh nghiệp vừa và nhỏ.",                       IsActive = true  },
 
                // ── Gói theo mùa / 3 tháng ──
                new ServicePackage { Name = "Seasonal 3 tháng", Price = 2_500_000,  DurationDays = 90,  MaxJobPosts = 30,  MaxFeatured = 6,  Description = "Gói 3 tháng linh hoạt cho doanh nghiệp theo mùa.",           IsActive = true  },
                new ServicePackage { Name = "Headhunter",        Price = 3_490_000,  DurationDays = 30,  MaxJobPosts = 999, MaxFeatured = 20, Description = "Dành cho công ty headhunting – không giới hạn tin.",          IsActive = true  },
                new ServicePackage { Name = "Agency Pro",        Price = 4_990_000,  DurationDays = 30,  MaxJobPosts = 999, MaxFeatured = 30, Description = "Dành cho agency tuyển dụng lớn – tối đa hiển thị.",          IsActive = true  },
 
                // ── Gói khuyến mãi (IsActive=false – đã hết hạn) ──
                new ServicePackage { Name = "Flash Sale Q1",    Price = 499_000,    DurationDays = 30,  MaxJobPosts = 10,  MaxFeatured = 3,  Description = "Gói khuyến mãi đầu năm – giá ưu đãi.",                       IsActive = false },
                new ServicePackage { Name = "Flash Sale Q3",    Price = 499_000,    DurationDays = 30,  MaxJobPosts = 10,  MaxFeatured = 3,  Description = "Gói khuyến mãi quý 3.",                                       IsActive = false },
            };
            // Tổng: 20 bản ghi

            await context.ServicePackages.AddRangeAsync(pkgs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 6 – EMPLOYERS (6 bản ghi – đủ cho 20 JobPosts ở Bước 10)
        //   Model Employer:
        //     - EmployerID     : int PK, tự sinh
        //     - UserID         : FK → User.UserID (NOT NULL)
        //     - CompanyName    : string NOT NULL
        //     - Industry       : string?
        //     - CompanySize    : string? ("1-10" | "11-50" | "51-200" | "500-999" | "1000+")
        //     - Address        : string?
        //     - Website        : string?
        //     - LogoURL        : string?  (để null – upload sau)
        //     - IsVerified     : bool
        //     - IsLocked       : bool     (Admin khoá tài khoản)
        //     - Description    : string?
        //     - WhyWorkHereJson: string?  (JSON serialize của List<CompanyHighlight>)
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedEmployers(AppDbContext context)
        {
            // Helper tạo JSON WhyWorkHere cho FPT Software (mẫu điền đầy đủ)
            var fptHighlights = JsonSerializer.Serialize(new List<CompanyHighlight>
            {
                new() { Icon = "diversity_3",   Title = "Môi trường đa văn hóa",  Description = "Hợp tác cùng đội ngũ đa dạng trong môi trường năng động.", IsHighlighted = false },
                new() { Icon = "rocket_launch", Title = "Cơ hội thăng tiến",      Description = "Lộ trình phát triển sự nghiệp rõ ràng với đào tạo chuyên sâu.", IsHighlighted = false },
                new() { Icon = "redeem",        Title = "Phúc lợi hấp dẫn",       Description = "Bảo hiểm sức khoẻ cao cấp, hỗ trợ ăn trưa, phòng gym hiện đại.", IsHighlighted = true  },
            });

            // Dữ liệu tuple: (email, companyName, industry, size, address, website, desc, isVerified, isLocked, whyWorkHereJson)
            var data = new[]
            {
                ("hr@fptsoft.com",       "FPT Software",   "Công nghệ thông tin", "1000+",   "17 Duy Tân, Cầu Giấy, Hà Nội",          "https://fpt-software.com",   "FPT Software – công ty phần mềm hàng đầu VN, 27.000+ nhân viên.",       true,  false, fptHighlights),
                ("recruit@vng.com.vn",   "VNG Corporation","Công nghệ thông tin", "1000+",   "182 Lê Đại Hành, Q.11, TP.HCM",          "https://vng.com.vn",         "VNG sở hữu Zalo, ZaloPay và nhiều sản phẩm internet hàng đầu VN.",      true,  false, (string?)null),
                ("talent@tiki.vn",       "Tiki",           "Thương mại điện tử",  "1000+",   "52 Út Tịch, Tân Bình, TP.HCM",           "https://tiki.vn",            "Tiki – sàn TMĐT hàng đầu với cam kết giao hàng 2H.",                    true,  false, (string?)null),
                ("hr@momo.vn",           "MoMo",           "Fintech",             "500-999", "181 Cao Thắng, Q.10, TP.HCM",            "https://momo.vn",            "MoMo – ví điện tử số 1 Việt Nam, 31+ triệu người dùng.",               true,  false, (string?)null),
                ("hr@shopee.vn",         "Shopee Vietnam", "Thương mại điện tử",  "1000+",   "18 Nguyễn Hữu Thọ, Q.7, TP.HCM",        "https://shopee.vn",          "Shopee – nền tảng TMĐT hàng đầu Đông Nam Á.",                          true,  false, (string?)null),
                ("talent@zalo.me",       "Zalo",           "Công nghệ thông tin", "500-999", "182 Lê Đại Hành, Q.11, TP.HCM",          "https://zalo.me",            "Zalo – ứng dụng nhắn tin và mạng xã hội số 1 Việt Nam.",               true,  false, (string?)null),
            };
            // Tổng: 6 Employer (đủ để phân bổ 20 JobPost theo vòng lặp % 6)

            foreach (var (email, name, industry, size, address, website, desc, verified, locked, why) in data)
            {
                var u = await context.Users.FirstAsync(x => x.Email == email);
                await context.Employers.AddAsync(new Employer
                {
                    UserID = u.UserID,
                    CompanyName = name,
                    Industry = industry,
                    CompanySize = size,
                    Address = address,
                    Website = website,
                    Description = desc,
                    WhyWorkHereJson = why,
                    IsVerified = verified,
                    IsLocked = locked,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 7 – CANDIDATE PROFILES (10 bản ghi)
        //   Model CandidateProfile:
        //     - ProfileID      : int PK, tự sinh
        //     - UserID         : FK → User.UserID (NOT NULL)
        //     - FullName       : string? (copy từ User)
        //     - Phone          : string? (copy từ User.PhoneNumber)
        //     - Avatar         : string? (để null – upload sau)
        //     - DateOfBirth    : DateTime?
        //     - Gender         : string?  ("Nam" | "Nữ")
        //     - Address        : string?
        //     - JobTitle       : string?  (vị trí mong muốn)
        //     - Summary        : string?  (giới thiệu bản thân – max 1000 ký tự)
        //     - ExperienceYears: int
        //     - DesiredSalary  : decimal? (decimal(15,0))
        //     - IsOpenToWork   : bool
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedCandidateProfiles(AppDbContext context)
        {
            // (email, gender, address, dob, jobTitle, summary, expYears, desiredSalary, isOpen)
            var data = new[]
            {
                ("an.nguyen@gmail.com",   "Nam", "Hà Nội",          new DateTime(1998,3,15),  ".NET Developer",        "Lập trình viên .NET 3 năm kinh nghiệm, thành thạo EF Core và SQL Server.",    3,  15_000_000m, true ),
                ("binh.le@gmail.com",     "Nữ",  "TP. Hồ Chí Minh", new DateTime(2000,7,20),  "Frontend Developer",    "Frontend Developer React.js, yêu thích thiết kế UI/UX sáng tạo.",              2,  12_000_000m, true ),
                ("cuong.pham@gmail.com",  "Nam", "Đà Nẵng",         new DateTime(1997,11,5),  "Full-stack Developer",  "Full-stack Developer Node.js + Vue.js, 4 năm kinh nghiệm.",                    4,  20_000_000m, true ),
                ("duyen.vo@gmail.com",    "Nữ",  "TP. Hồ Chí Minh", new DateTime(1999,5,12),  "Data Analyst",          "Data Analyst, thành thạo Python Pandas, SQL và Power BI.",                     3,  18_000_000m, false),
                ("em.tran@gmail.com",     "Nam", "Hà Nội",          new DateTime(1996,9,25),  "DevOps Engineer",       "DevOps Engineer, kinh nghiệm CI/CD với Docker và Kubernetes.",                 5,  30_000_000m, true ),
                ("giang.hoang@gmail.com", "Nữ",  "Cần Thơ",         new DateTime(2001,2,8),   "QA Tester",             "Tester (Manual + Automation) với Selenium và Postman.",                        2,  10_000_000m, true ),
                ("hung.bui@gmail.com",    "Nam", "Hải Phòng",       new DateTime(1998,6,18),  "Mobile Developer",      "Mobile Developer Flutter, đã publish 3 app lên Store.",                        3,  15_000_000m, true ),
                ("ky.do@gmail.com",       "Nam", "Bình Dương",      new DateTime(2002,4,30),  "Junior .NET Developer", "Fresher IT mới tốt nghiệp, biết C# .NET và SQL cơ bản.",                      0,  8_000_000m,  true ),
                ("lan.dang@gmail.com",    "Nữ",  "Hà Nội",          new DateTime(1997,12,3),  "UI/UX Designer",        "UI/UX Designer với 3 năm kinh nghiệm Figma và Adobe XD.",                      3,  18_000_000m, false),
                ("minh.cao@gmail.com",    "Nam", "TP. Hồ Chí Minh", new DateTime(1995,8,22),  "Java Backend Developer","Java Backend Developer 5 năm, thành thạo Spring Boot và microservices.",       5,  35_000_000m, true ),
            };
            // Tổng: 10 bản ghi CandidateProfile

            foreach (var (email, gender, address, dob, jobTitle, summary, expYears, salary, isOpen) in data)
            {
                var u = await context.Users.FirstAsync(x => x.Email == email);
                await context.CandidateProfiles.AddAsync(new CandidateProfile
                {
                    UserID = u.UserID,
                    FullName = u.FullName,
                    Phone = u.PhoneNumber,
                    DateOfBirth = dob,
                    Gender = gender,
                    Address = address,
                    JobTitle = jobTitle,
                    Summary = summary,
                    ExperienceYears = expYears,
                    DesiredSalary = salary,
                    IsOpenToWork = isOpen
                });
            }

            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 8 – CV FILES (20 bản ghi = 2 CV × 10 candidate)
        //   Model CvFile:
        //     - CvID      : int PK, tự sinh
        //     - ProfileID : FK → CandidateProfile.ProfileID (NOT NULL, Cascade Delete)
        //     - FileName  : string NOT NULL (tên file hiển thị)
        //     - FilePath  : string NOT NULL (đường dẫn vật lý trong wwwroot/uploads/cvs)
        //     - FileSize  : long? (bytes)
        //     - IsDefault : bool  (CV mặc định dùng khi apply)
        //     - UploadedAt: DateTime
        //
        //   Mỗi candidate có 2 CV: 1 tiếng Việt (IsDefault=true) + 1 tiếng Anh (IsDefault=false)
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedCvFiles(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles
                                        .OrderBy(p => p.ProfileID)
                                        .ToListAsync();

            // Tên viết tắt theo thứ tự profile để đặt tên file
            var nicknames = new[] { "An", "Binh", "Cuong", "Duyen", "Em", "Giang", "Hung", "Ky", "Lan", "Minh" };

            var cvs = new List<CvFile>();
            for (int i = 0; i < profiles.Count; i++)
            {
                var nick = nicknames[i % nicknames.Length];

                // CV chính (tiếng Việt) – IsDefault = true
                cvs.Add(new CvFile
                {
                    ProfileID = profiles[i].ProfileID,
                    FileName = $"CV_{nick}_Main.pdf",
                    FilePath = $"/uploads/cvs/cv_{nick.ToLower()}_main.pdf",
                    FileSize = 512_000 + i * 10_000,   // khoảng 500KB – 600KB
                    IsDefault = true,
                    UploadedAt = DateTime.UtcNow.AddDays(-30 + i)
                });

                // CV phụ (tiếng Anh) – IsDefault = false
                cvs.Add(new CvFile
                {
                    ProfileID = profiles[i].ProfileID,
                    FileName = $"CV_{nick}_EN.pdf",
                    FilePath = $"/uploads/cvs/cv_{nick.ToLower()}_en.pdf",
                    FileSize = 480_000 + i * 8_000,
                    IsDefault = false,
                    UploadedAt = DateTime.UtcNow.AddDays(-15 + i)
                });
            }
            // Tổng: 10 × 2 = 20 bản ghi

            await context.CvFiles.AddRangeAsync(cvs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 9 – CANDIDATE SKILLS (20 bản ghi = 2 skill × 10 candidate)
        //   Model CandidateSkill (composite PK):
        //     - ProfileID        : FK → CandidateProfile.ProfileID  (PK part 1)
        //     - SkillID          : FK → Skill.SkillID               (PK part 2)
        //     - ProficiencyLevel : enum { Beginner, Elementary, Intermediate, Advanced, Expert }
        //     - YearsOfExperience: decimal(5,2)
        //     - LastUsedDate     : DateTime?
        //
        //   Lưu ý: Composite PK nên mỗi cặp (ProfileID, SkillID) PHẢI DUY NHẤT
        //   → Dùng i và i+1 để lấy skill khác nhau cho mỗi profile
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedCandidateSkills(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles.OrderBy(p => p.ProfileID).ToListAsync();
            var skills = await context.Skills.OrderBy(s => s.SkillID).ToListAsync();

            // Vòng xoay cấp độ kỹ năng
            ProficiencyLevel[] levels = { ProficiencyLevel.Beginner, ProficiencyLevel.Intermediate, ProficiencyLevel.Advanced, ProficiencyLevel.Expert };

            var candidateSkills = new List<CandidateSkill>();
            for (int i = 0; i < profiles.Count; i++)
            {
                // Skill 1: index i % skills.Count
                var skill1 = skills[i % skills.Count];
                // Skill 2: index (i + 5) % skills.Count – cách xa để tránh trùng với skill1
                var skill2 = skills[(i + 5) % skills.Count];

                candidateSkills.Add(new CandidateSkill
                {
                    ProfileID = profiles[i].ProfileID,
                    SkillID = skill1.SkillID,
                    ProficiencyLevel = levels[i % 4],
                    YearsOfExperience = (decimal)(i % 5 + 1),
                    LastUsedDate = DateTime.Now.AddMonths(-(i % 12))
                });

                candidateSkills.Add(new CandidateSkill
                {
                    ProfileID = profiles[i].ProfileID,
                    SkillID = skill2.SkillID,
                    ProficiencyLevel = levels[(i + 2) % 4],
                    YearsOfExperience = (decimal)(i % 3 + 1),
                    LastUsedDate = DateTime.Now.AddMonths(-((i + 3) % 12))
                });
            }
            // Tổng: 10 × 2 = 20 bản ghi (mỗi cặp ProfileID+SkillID duy nhất)

            await context.CandidateSkills.AddRangeAsync(candidateSkills);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 10 – JOB POSTS (20 bản ghi)
        //   Model JobPost:
        //     - JobID          : int PK, tự sinh
        //     - EmployerID     : FK → Employer.EmployerID (NOT NULL)
        //     - CategoryID     : FK → Category.CategoryID (nullable)
        //     - Title          : string NOT NULL
        //     - Description    : string?
        //     - Requirements   : string?
        //     - Benefits       : string?
        //     - SalaryMin/Max  : decimal? (decimal(15,0))
        //     - SalaryNegotiable: bool
        //     - JobType        : "FullTime" | "PartTime" | "Contract" | "Internship" | "Remote"
        //     - Location       : string?
        //     - ExperienceLevel: "Fresher" | "Junior" | "Middle" | "Senior" | "Manager"
        //     - Deadline       : DateTime?
        //     - Status         : "Draft" | "Pending" | "Open" | "Closed" | "Rejected"
        //     - ViewCount      : int
        //     - IsFeatured     : bool
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedJobPosts(AppDbContext context)
        {
            var employers = await context.Employers.OrderBy(e => e.EmployerID).ToListAsync();

            // Lấy CategoryID theo Slug đã seed ở Bước 3
            int CatId(string slug) => context.Categories.First(c => c.Slug == slug).CategoryID;
            int itCat = CatId("cong-nghe-thong-tin");
            int mktCat = CatId("marketing");
            int finCat = CatId("tai-chinh-ke-toan");
            int desCat = CatId("thiet-ke");

            // Helper lấy EmployerID theo vị trí (vòng lặp)
            int E(int i) => employers[i % employers.Count].EmployerID;

            var jobs = new[]
            {
                // ─── FPT Software (E0) ───
                new JobPost { EmployerID=E(0), CategoryID=itCat,  Title=".NET Developer (C# / ASP.NET Core)",
                    Description  ="Phát triển và bảo trì ứng dụng web ASP.NET Core MVC, API RESTful.",
                    Requirements ="- 1+ năm C#/.NET\n- SQL Server, EF Core\n- HTML/CSS cơ bản",
                    Benefits     ="- Lương cạnh tranh\n- Thưởng quý\n- Bảo hiểm cao cấp",
                    SalaryMin=15_000_000, SalaryMax=30_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="Hà Nội",          ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true,  ViewCount=320 },

                new JobPost { EmployerID=E(0), CategoryID=itCat,  Title="Frontend Developer – React.js",
                    Description  ="Xây dựng giao diện web hiện đại với React.js và TailwindCSS.",
                    Requirements ="- 1+ năm React.js\n- HTML/CSS/JS\n- Git, REST API",
                    Benefits     ="- Remote 2 ngày/tuần\n- Môi trường năng động",
                    SalaryMin=12_000_000, SalaryMax=25_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(45), Status="Open", IsFeatured=true,  ViewCount=210 },

                new JobPost { EmployerID=E(0), CategoryID=itCat,  Title="Thực tập sinh Backend Python",
                    Description  ="Hỗ trợ team backend phát triển tính năng mới bằng Python/Django.",
                    Requirements ="- Sinh viên năm 3-4 CNTT\n- Python cơ bản\n- Chăm chỉ, ham học",
                    Benefits     ="- Phụ cấp 3-5 triệu/tháng\n- Xét tuyển chính thức sau thực tập",
                    SalaryMin=3_000_000,  SalaryMax=5_000_000,  SalaryNegotiable=false,
                    JobType="Internship",  Location="Hà Nội",          ExperienceLevel="Fresher",
                    Deadline=DateTime.UtcNow.AddDays(60), Status="Open", IsFeatured=false, ViewCount=95  },
 
                // ─── VNG Corporation (E1) ───
                new JobPost { EmployerID=E(1), CategoryID=itCat,  Title="Backend Engineer – Java Spring Boot",
                    Description  ="Thiết kế và phát triển microservices hiệu suất cao cho nền tảng game.",
                    Requirements ="- 2+ năm Java Spring Boot\n- Kafka, Redis\n- Kinh nghiệm scale hệ thống",
                    Benefits     ="- Stock option\n- 13+ tháng lương\n- Laptop MacBook Pro",
                    SalaryMin=25_000_000, SalaryMax=50_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true,  ViewCount=450 },

                new JobPost { EmployerID=E(1), CategoryID=itCat,  Title="Senior DevOps Engineer",
                    Description  ="Xây dựng hạ tầng cloud, CI/CD pipeline cho hệ thống triệu người dùng.",
                    Requirements ="- 3+ năm DevOps\n- Docker, K8s, Terraform\n- AWS hoặc GCP",
                    Benefits     ="- 40-70 triệu\n- Remote 100%\n- Ngân sách học tập 20tr/năm",
                    SalaryMin=40_000_000, SalaryMax=70_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="Hà Nội",          ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(25), Status="Open", IsFeatured=true,  ViewCount=380 },
 
                // ─── Tiki (E2) ───
                new JobPost { EmployerID=E(2), CategoryID=itCat,  Title="Data Engineer – Python / Spark",
                    Description  ="Xây dựng data pipeline xử lý hàng triệu đơn hàng/ngày.",
                    Requirements ="- Python, SQL\n- Apache Spark, Airflow\n- Data warehouse",
                    Benefits     ="- Thưởng dự án\n- Đội ngũ Data mạnh\n- Free lunch",
                    SalaryMin=20_000_000, SalaryMax=40_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(35), Status="Open", IsFeatured=false, ViewCount=170 },

                new JobPost { EmployerID=E(2), CategoryID=itCat,  Title="iOS Developer – Swift",
                    Description  ="Phát triển tính năng mới và tối ưu hiệu năng ứng dụng iOS Tiki.",
                    Requirements ="- 2+ năm Swift\n- UIKit, SwiftUI\n- App Store submission",
                    Benefits     ="- MacBook + iPhone mới nhất\n- Flexible hours\n- Thưởng cuối năm",
                    SalaryMin=22_000_000, SalaryMax=45_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(40), Status="Open", IsFeatured=true,  ViewCount=260 },
 
                // ─── MoMo (E3) ───
                new JobPost { EmployerID=E(3), CategoryID=itCat,  Title="Android Developer – Kotlin",
                    Description  ="Xây dựng tính năng thanh toán và ví điện tử trên Android.",
                    Requirements ="- 2+ năm Kotlin/Android\n- Bảo mật tài chính\n- Payment SDK",
                    Benefits     ="- Bảo hiểm gia đình\n- WFH thứ 6",
                    SalaryMin=20_000_000, SalaryMax=38_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=140 },

                new JobPost { EmployerID=E(3), CategoryID=finCat, Title="Risk Analyst – Fintech",
                    Description  ="Phân tích rủi ro tín dụng và gian lận trong hệ thống thanh toán.",
                    Requirements ="- Tốt nghiệp Tài chính/Kinh tế\n- SQL, Python cơ bản\n- Risk model",
                    Benefits     ="- Lương + thưởng KPI\n- Đào tạo fintech chuyên sâu",
                    SalaryMin=18_000_000, SalaryMax=30_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(20), Status="Open", IsFeatured=false, ViewCount=88  },
 
                // ─── Shopee (E4) ───
                new JobPost { EmployerID=E(4), CategoryID=itCat,  Title="Machine Learning Engineer",
                    Description  ="Xây dựng mô hình gợi ý sản phẩm và xếp hạng tìm kiếm cho Shopee.",
                    Requirements ="- Python, TensorFlow/PyTorch\n- Recommendation system\n- MLOps",
                    Benefits     ="- Dữ liệu lớn\n- Công bố paper\n- Lương cao cấp",
                    SalaryMin=35_000_000, SalaryMax=65_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true,  ViewCount=610 },

                new JobPost { EmployerID=E(4), CategoryID=desCat, Title="Senior UI/UX Designer",
                    Description  ="Thiết kế trải nghiệm người dùng cho app Shopee iOS và Android.",
                    Requirements ="- 3+ năm UI/UX\n- Figma thành thạo\n- Portfolio mạnh",
                    Benefits     ="- Apple devices mới nhất\n- Design system riêng",
                    SalaryMin=25_000_000, SalaryMax=45_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(35), Status="Open", IsFeatured=true,  ViewCount=290 },

                new JobPost { EmployerID=E(4), CategoryID=mktCat, Title="Performance Marketing Manager",
                    Description  ="Lên kế hoạch và triển khai chiến dịch Google/Facebook Ads quy mô lớn.",
                    Requirements ="- 3+ năm performance marketing\n- Google Ads, Meta Ads\n- Phân tích số liệu",
                    Benefits     ="- Ngân sách marketing lớn\n- Thưởng KPI",
                    SalaryMin=20_000_000, SalaryMax=40_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(28), Status="Open", IsFeatured=false, ViewCount=105 },
 
                // ─── Zalo (E5) ───
                new JobPost { EmployerID=E(5), CategoryID=itCat,  Title="Node.js Backend Developer",
                    Description  ="Phát triển API cho hệ thống chat real-time Zalo – triệu concurrent users.",
                    Requirements ="- 2+ năm Node.js\n- WebSocket, Redis Pub/Sub\n- High-load system",
                    Benefits     ="- Hệ thống triệu user\n- Sản phẩm made-in-VN\n- Thưởng KPI",
                    SalaryMin=20_000_000, SalaryMax=38_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(25), Status="Open", IsFeatured=false, ViewCount=195 },

                new JobPost { EmployerID=E(5), CategoryID=itCat,  Title="QA Automation Engineer",
                    Description  ="Viết automation test cho web và mobile, tích hợp vào CI/CD pipeline.",
                    Requirements ="- 1+ năm Selenium/Appium\n- Java hoặc Python\n- Agile/Scrum",
                    Benefits     ="- Cấp chứng chỉ ISTQB\n- Giờ giấc linh hoạt",
                    SalaryMin=13_000_000, SalaryMax=22_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=78  },
 
                // ─── FPT Software tiếp (E0) – thêm vị trí senior ───
                new JobPost { EmployerID=E(0), CategoryID=itCat,  Title="Scrum Master / Agile Coach",
                    Description  ="Hướng dẫn team Agile, tổ chức ceremonies, loại bỏ impediment.",
                    Requirements ="- Chứng chỉ CSM/PSM\n- 3+ năm Scrum Master\n- Kỹ năng coaching",
                    Benefits     ="- Ngân sách coaching 30tr/năm\n- Hội thảo quốc tế",
                    SalaryMin=25_000_000, SalaryMax=45_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="Hà Nội",          ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=87  },
 
                // ─── VNG – thêm 2 vị trí ───
                new JobPost { EmployerID=E(1), CategoryID=itCat,  Title="Full-stack Developer – Vue.js + .NET",
                    Description  ="Phát triển sản phẩm SaaS nội bộ dùng Vue.js phía front và .NET Core phía back.",
                    Requirements ="- 2+ năm Vue.js\n- 1+ năm .NET Core\n- SQL Server",
                    Benefits     ="- Laptop cấp sẵn\n- Thưởng dự án\n- Team nhỏ năng động",
                    SalaryMin=18_000_000, SalaryMax=35_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="Hà Nội",          ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(20), Status="Open", IsFeatured=false, ViewCount=130 },
 
                // ─── Tiki – 2 vị trí thêm ───
                new JobPost { EmployerID=E(2), CategoryID=itCat,  Title="Flutter Developer",
                    Description  ="Phát triển app Tiki mobile trên Flutter.",
                    Requirements ="- 1+ năm Flutter/Dart\n- State management\n- REST API",
                    Benefits     ="- Smartphone mới nhất\n- Flexible hours",
                    SalaryMin=18_000_000, SalaryMax=35_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=148 },

                new JobPost { EmployerID=E(2), CategoryID=mktCat, Title="Content Marketing Executive",
                    Description  ="Sản xuất nội dung blog, social media và email marketing cho Tiki.",
                    Requirements ="- 1+ năm content marketing\n- Viết tốt TV/TA\n- SEO cơ bản",
                    Benefits     ="- Môi trường sáng tạo\n- Trợ cấp ăn trưa",
                    SalaryMin=10_000_000, SalaryMax=18_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(15), Status="Open", IsFeatured=false, ViewCount=63  },
 
                // ─── MoMo – 1 vị trí thêm ───
                new JobPost { EmployerID=E(3), CategoryID=finCat, Title="Business Analyst – Fintech",
                    Description  ="Phân tích nghiệp vụ ví điện tử, viết tài liệu yêu cầu cho team Dev.",
                    Requirements ="- 2+ năm BA\n- Sản phẩm thanh toán\n- Tiếng Anh tốt",
                    Benefits     ="- Môi trường fintech\n- Cổ phiếu ESOP",
                    SalaryMin=18_000_000, SalaryMax=32_000_000, SalaryNegotiable=false,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(20), Status="Open", IsFeatured=false, ViewCount=112 },
 
                // ─── Zalo – thêm 1 vị trí ───
                new JobPost { EmployerID=E(5), CategoryID=itCat,  Title="Security Engineer – AppSec",
                    Description  ="Đảm bảo an toàn bảo mật ứng dụng Zalo trên cả web và mobile.",
                    Requirements ="- 2+ năm AppSec\n- OWASP Top 10\n- Penetration testing",
                    Benefits     ="- Hệ thống scale lớn\n- Đào tạo bảo mật chuyên sâu",
                    SalaryMin=25_000_000, SalaryMax=50_000_000, SalaryNegotiable=true,
                    JobType="FullTime",    Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true,  ViewCount=220 },
            };
            // Tổng: 20 bản ghi JobPost – CreatedAt gán mặc định theo model = DateTime.Now

            await context.JobPosts.AddRangeAsync(jobs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 11 – APPLICATIONS (20 bản ghi)
        //   Model Application:
        //     - AppID      : int PK, tự sinh
        //     - JobID      : FK → JobPost.JobID      (NOT NULL, Restrict Delete)
        //     - ProfileID  : FK → CandidateProfile.ProfileID (NOT NULL, Restrict Delete)
        //     - CVID       : FK → CvFile.CvID         (nullable)
        //     - CoverLetter: string?  (thư ứng tuyển)
        //     - Status     : "Pending" | "Reviewing" | "Interview" | "Offered" | "Rejected"
        //     - AppliedAt  : DateTime
        //     - UpdatedAt  : DateTime?
        //
        //   Ràng buộc UNIQUE(JobID, ProfileID) → không được seed 2 đơn cùng 1 cặp
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedApplications(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles.OrderBy(p => p.ProfileID).ToListAsync();
            var jobs = await context.JobPosts.OrderBy(j => j.JobID).ToListAsync();
            // Chỉ lấy CV mặc định để gắn vào đơn ứng tuyển
            var defaultCvs = await context.CvFiles.Where(c => c.IsDefault).ToListAsync();

            string[] statuses = { "Pending", "Reviewing", "Interview", "Offered", "Rejected" };
            string[] letters =
            {
                "Kính gửi, tôi rất quan tâm đến vị trí này và tin rằng kinh nghiệm của tôi phù hợp.",
                "Tôi có 3 năm kinh nghiệm trong lĩnh vực này và mong được đóng góp cho công ty.",
                "Với kỹ năng và đam mê, tôi tự tin có thể hoàn thành tốt các yêu cầu công việc.",
                "Đây là cơ hội tôi đang tìm kiếm để phát triển sự nghiệp.",
                "Tôi đã theo dõi công ty từ lâu và muốn trở thành một phần của đội ngũ.",
                "Kỹ năng lập trình và tư duy phân tích của tôi sẽ là tài sản quý giá cho team.",
                "Tôi đã tham khảo kỹ JD và tự tin đáp ứng được trên 90% yêu cầu.",
                "Mong muốn đóng góp vào sự phát triển của công ty với nhiệt huyết và chuyên môn.",
                "Tôi đang tìm kiếm môi trường thách thức để phát triển sự nghiệp.",
                "Portfolio của tôi bao gồm các dự án thực tế liên quan trực tiếp đến JD.",
                "Tôi có kinh nghiệm Agile và hiểu quy trình phát triển phần mềm.",
                "Sản phẩm của công ty luôn là nguồn cảm hứng của tôi.",
                "Thành tích: giảm 30% thời gian deploy nhờ cải thiện CI/CD pipeline.",
                "Tôi vừa hoàn thành khóa học chuyên sâu và sẵn sàng áp dụng ngay.",
                "Mong được thảo luận thêm về vị trí này trong buổi phỏng vấn.",
                "Tôi sẵn sàng bắt đầu ngay lập tức nếu được chấp nhận.",
                "Tiếng Anh thành thạo, có thể làm việc với đối tác nước ngoài.",
                "Rất mong được gặp gỡ team và tìm hiểu thêm về văn hóa công ty.",
                "Tôi đã nghiên cứu kỹ sản phẩm và có nhiều ý tưởng muốn đóng góp.",
                "Khả năng tự học và thích nghi nhanh là điểm mạnh lớn nhất của tôi.",
            };

            var apps = new List<Application>();
            var usedPairs = new HashSet<(int JobID, int ProfileID)>(); // đảm bảo UNIQUE
            int count = 0;

            // Duyệt profile × job cho đến khi đủ 20 bản ghi
            for (int i = 0; i < profiles.Count && count < 20; i++)
            {
                for (int j = 0; j < jobs.Count && count < 20; j++)
                {
                    var pair = (jobs[j].JobID, profiles[i].ProfileID);
                    if (usedPairs.Contains(pair)) continue;
                    usedPairs.Add(pair);

                    var cv = defaultCvs.FirstOrDefault(c => c.ProfileID == profiles[i].ProfileID);
                    apps.Add(new Application
                    {
                        JobID = jobs[j].JobID,
                        ProfileID = profiles[i].ProfileID,
                        CVID = cv?.CvID,              // nullable – có thể null nếu chưa upload
                        CoverLetter = letters[count % letters.Length],
                        Status = statuses[count % statuses.Length],
                        AppliedAt = DateTime.UtcNow.AddDays(-count),
                        UpdatedAt = count % 2 == 0 ? DateTime.UtcNow.AddDays(-count + 1) : null
                    });
                    count++;
                }
            }
            // Tổng: 20 bản ghi (UNIQUE JobID+ProfileID được kiểm soát bằng HashSet)

            await context.Applications.AddRangeAsync(apps);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 12 – SAVED JOBS (20 bản ghi)
        //   Model SavedJob:
        //     - SaveID  : int PK, tự sinh
        //     - UserID  : FK → User.UserID   (NOT NULL)
        //     - JobID   : FK → JobPost.JobID (NOT NULL, Restrict Delete)
        //     - SavedAt : DateTime
        //
        //   Ràng buộc UNIQUE(UserID, JobID) → không được lưu 1 job 2 lần cho cùng user
        //   Chỉ Candidate mới lưu job (không lưu cho Admin/Employer)
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedSavedJobs(AppDbContext context)
        {
            var candidates = await context.Users
                                          .Where(u => u.Role == "Candidate")
                                          .OrderBy(u => u.UserID)
                                          .ToListAsync();
            var jobs = await context.JobPosts.OrderBy(j => j.JobID).ToListAsync();

            var saved = new List<SavedJob>();
            var usedPairs = new HashSet<(int UserID, int JobID)>();
            int count = 0;

            for (int i = 0; i < candidates.Count && count < 20; i++)
            {
                // Mỗi candidate lưu 2 job (10 × 2 = 20)
                for (int j = 0; j < 2 && count < 20; j++)
                {
                    int jobIndex = (i * 2 + j) % jobs.Count;
                    var pair = (candidates[i].UserID, jobs[jobIndex].JobID);
                    if (usedPairs.Contains(pair))
                    {
                        jobIndex = (jobIndex + 1) % jobs.Count; // thử job kế tiếp
                        pair = (candidates[i].UserID, jobs[jobIndex].JobID);
                    }
                    usedPairs.Add(pair);

                    saved.Add(new SavedJob
                    {
                        UserID = candidates[i].UserID,
                        JobID = jobs[jobIndex].JobID,
                        SavedAt = DateTime.UtcNow.AddDays(-count)
                    });
                    count++;
                }
            }
            // Tổng: 20 bản ghi

            await context.SavedJobs.AddRangeAsync(saved);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 13 – NOTIFICATIONS (20 bản ghi)
        //   Model Notification:
        //     - NotifID  : int PK, tự sinh
        //     - UserID   : FK → User.UserID (NOT NULL, Restrict Delete)
        //     - Title    : string NOT NULL
        //     - Content  : string?
        //     - Type     : "Application" | "System" | "Payment"
        //     - IsRead   : bool
        //     - RelatedID: int?  (có thể là JobID, TransID, v.v.)
        //     - CreatedAt: DateTime
        //
        //   Phân bổ: 8 Application + 7 System + 5 Payment = 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedNotifications(AppDbContext context)
        {
            var users = await context.Users.OrderBy(u => u.UserID).ToListAsync();
            var jobs = await context.JobPosts.OrderBy(j => j.JobID).ToListAsync();

            // Helper lấy user và job theo vị trí (tránh IndexOutOfRange)
            User U(int i) => users[i % users.Count];
            int? J(int i) => jobs.Count > i ? jobs[i].JobID : (int?)null;

            var notifs = new[]
            {
                // ── Application notifications (8) ──
                new Notification { UserID=U(10).UserID, Title="Hồ sơ được xét duyệt",          Content="Hồ sơ ứng tuyển .NET Developer của bạn đang được xem xét.",            Type="Application", IsRead=false, RelatedID=J(0),  CreatedAt=DateTime.UtcNow.AddHours(-1)  },
                new Notification { UserID=U(11).UserID, Title="Mời phỏng vấn",                  Content="Chúc mừng! Bạn được mời phỏng vấn vị trí Frontend Developer.",           Type="Application", IsRead=false, RelatedID=J(1),  CreatedAt=DateTime.UtcNow.AddHours(-2)  },
                new Notification { UserID=U(12).UserID, Title="Hồ sơ bị từ chối",               Content="Rất tiếc, hồ sơ của bạn không phù hợp với vị trí hiện tại.",            Type="Application", IsRead=true,  RelatedID=J(2),  CreatedAt=DateTime.UtcNow.AddHours(-5)  },
                new Notification { UserID=U(13).UserID, Title="Nhận được offer",                 Content="Chúc mừng! Bạn đã nhận được offer từ VNG Corporation.",                  Type="Application", IsRead=false, RelatedID=J(3),  CreatedAt=DateTime.UtcNow.AddHours(-3)  },
                new Notification { UserID=U(14).UserID, Title="CV của bạn được tải về",          Content="Nhà tuyển dụng FPT Software đã tải CV của bạn.",                         Type="Application", IsRead=false, RelatedID=J(0),  CreatedAt=DateTime.UtcNow.AddHours(-7)  },
                new Notification { UserID=U(15).UserID, Title="Lịch phỏng vấn được xác nhận",   Content="Phỏng vấn với Shopee lúc 9:00 ngày 05/07/2026 đã được xác nhận.",        Type="Application", IsRead=true,  RelatedID=J(9),  CreatedAt=DateTime.UtcNow.AddHours(-9)  },
                new Notification { UserID=U(16).UserID, Title="Nhà tuyển dụng theo dõi bạn",    Content="Zalo đã thêm bạn vào danh sách ứng viên tiềm năng.",                    Type="Application", IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-11) },
                new Notification { UserID=U(4).UserID,  Title="Ứng viên mới ứng tuyển",         Content="Có 5 ứng viên mới ứng tuyển vào vị trí .NET Developer.",                Type="Application", IsRead=true,  RelatedID=J(0),  CreatedAt=DateTime.UtcNow.AddHours(-14) },
 
                // ── System notifications (7) ──
                new Notification { UserID=U(17).UserID, Title="Tin tuyển dụng mới phù hợp",     Content="Có 3 tin tuyển dụng mới phù hợp với kỹ năng của bạn.",                  Type="System",      IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-6)  },
                new Notification { UserID=U(18).UserID, Title="Nhắc nhở deadline ứng tuyển",    Content="Tin tuyển dụng 'iOS Developer' sẽ hết hạn trong 2 ngày.",               Type="System",      IsRead=true,  RelatedID=J(6),  CreatedAt=DateTime.UtcNow.AddHours(-8)  },
                new Notification { UserID=U(19).UserID, Title="Tài khoản xác thực thành công",  Content="Công ty MoMo đã được xác thực. Bạn có thể đăng tin tuyển dụng.",         Type="System",      IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-12) },
                new Notification { UserID=U(0).UserID,  Title="Báo cáo hệ thống tuần",          Content="Tuần này: 150 ứng viên mới, 45 tin tuyển dụng, 320 đơn ứng tuyển.",     Type="System",      IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddDays(-1)   },
                new Notification { UserID=U(13).UserID, Title="Hệ thống bảo trì",               Content="Hệ thống sẽ bảo trì từ 01:00-03:00 ngày 30/06/2026.",                   Type="System",      IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-15) },
                new Notification { UserID=U(14).UserID, Title="Hồ sơ nổi bật trong tuần",       Content="Hồ sơ của bạn nằm trong top 10% được xem nhiều nhất tuần này.",          Type="System",      IsRead=true,  RelatedID=null,  CreatedAt=DateTime.UtcNow.AddDays(-2)   },
                new Notification { UserID=U(19).UserID, Title="Chào mừng đến JobConnect!",      Content="Cảm ơn bạn đã đăng ký. Hãy hoàn thiện hồ sơ để tìm việc hiệu quả hơn.", Type="System",      IsRead=true,  RelatedID=null,  CreatedAt=DateTime.UtcNow.AddDays(-5)   },
 
                // ── Payment notifications (5) ──
                new Notification { UserID=U(5).UserID,  Title="Thanh toán thành công",           Content="Gói Pro đã được kích hoạt. Hiệu lực đến 30/07/2026.",                   Type="Payment",     IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-4)  },
                new Notification { UserID=U(6).UserID,  Title="Gói dịch vụ sắp hết hạn",        Content="Gói Enterprise của bạn sẽ hết hạn sau 7 ngày. Hãy gia hạn ngay.",        Type="Payment",     IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddDays(-1)   },
                new Notification { UserID=U(7).UserID,  Title="Thanh toán thất bại",             Content="Giao dịch thanh toán gói Pro Plus thất bại. Vui lòng thử lại.",          Type="Payment",     IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-13) },
                new Notification { UserID=U(8).UserID,  Title="Hoá đơn tháng 6/2026",           Content="Hoá đơn 990.000 VNĐ gói Pro đã được gửi về email của bạn.",             Type="Payment",     IsRead=true,  RelatedID=null,  CreatedAt=DateTime.UtcNow.AddDays(-3)   },
                new Notification { UserID=U(9).UserID,  Title="Nâng cấp gói thành công",        Content="Bạn đã nâng cấp từ Basic lên Pro Plus thành công.",                      Type="Payment",     IsRead=false, RelatedID=null,  CreatedAt=DateTime.UtcNow.AddHours(-20) },
            };
            // Tổng: 20 bản ghi

            await context.Notifications.AddRangeAsync(notifs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 14 – TRANSACTIONS (20 bản ghi)
        //   Model Transaction:
        //     - TransID      : int PK, tự sinh
        //     - EmployerID   : FK → Employer.EmployerID (NOT NULL, Restrict Delete)
        //     - PackageID    : FK → ServicePackage.PackageID (NOT NULL)
        //     - Amount       : decimal(15,0) – đơn vị VNĐ
        //     - PaymentMethod: "BankTransfer" | "VNPay" | "Momo" | "ZaloPay" | "Cash"
        //     - Status       : "Pending" | "Completed" | "Failed"
        //     - ExpiredAt    : DateTime? (ngày hết hạn gói)
        //     - CreatedAt    : DateTime
        //
        //   Phân bổ: 12 Completed + 4 Pending + 4 Failed = 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedTransactions(AppDbContext context)
        {
            var employers = await context.Employers.OrderBy(e => e.EmployerID).ToListAsync();
            var packages = await context.ServicePackages.OrderBy(p => p.PackageID).ToListAsync();

            string[] methods = { "BankTransfer", "VNPay", "Momo", "ZaloPay", "Cash" };

            // Trạng thái: 12 Completed, 4 Pending, 4 Failed
            string[] statuses = {
                "Completed","Completed","Completed","Completed",   // 0-3
                "Completed","Completed","Completed","Completed",   // 4-7
                "Completed","Completed","Completed","Completed",   // 8-11
                "Pending",  "Pending",  "Pending",  "Pending",    // 12-15
                "Failed",   "Failed",   "Failed",   "Failed",     // 16-19
            };

            var transactions = new List<Transaction>();
            for (int i = 0; i < 20; i++)
            {
                var emp = employers[i % employers.Count];
                var pkg = packages[i % packages.Count];
                transactions.Add(new Transaction
                {
                    EmployerID = emp.EmployerID,
                    PackageID = pkg.PackageID,
                    Amount = pkg.Price,
                    PaymentMethod = methods[i % methods.Length],
                    Status = statuses[i],
                    ExpiredAt = statuses[i] == "Completed"
                                        ? DateTime.UtcNow.AddDays(pkg.DurationDays)
                                        : null,       // Pending/Failed chưa kích hoạt
                    CreatedAt = DateTime.UtcNow.AddDays(-i)
                });
            }
            // Tổng: 20 bản ghi

            await context.Transactions.AddRangeAsync(transactions);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 15 – BLOG POSTS (20 bản ghi)
        //   Model BlogPost:
        //     - PostID     : int PK, tự sinh
        //     - AuthorID   : FK → User.UserID (NOT NULL)
        //     - Title      : string NOT NULL
        //     - Slug       : string NOT NULL (URL-friendly)
        //     - Excerpt    : string? (tóm tắt ngắn)
        //     - Content    : string? (HTML đầy đủ)
        //     - CoverURL   : string? (ảnh bìa – để null, upload sau)
        //     - IsPublished: bool
        //     - PublishedAt: DateTime? (null = nháp chưa công bố)
        //     - CreatedAt  : DateTime
        //
        //   Phân bổ: 16 bài đã xuất bản (IsPublished=true) + 4 bài nháp (false)
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedBlogPosts(AppDbContext context)
        {
            var admin = await context.Users.FirstAsync(u => u.Role == "Admin");

            // Tuple: (title, slug, excerpt, isPublished, publishedAt)
            // DateTime? dùng explicit type trong list để tránh lỗi null assignment
            var posts = new List<(string Title, string Slug, string Excerpt, bool IsPublished, DateTime? PublishedAt)>
            {
                // ── Đã xuất bản (16 bài) ──
                ("10 kỹ năng IT hot nhất năm 2026",                "10-ky-nang-it-hot-2026",           "Khám phá những kỹ năng công nghệ được săn đón nhất trong năm 2026.",                  true,  DateTime.UtcNow.AddDays(-30) ),
                ("Cách viết CV xin việc IT ấn tượng",             "cach-viet-cv-it-an-tuong",          "Hướng dẫn chi tiết cách tạo CV nổi bật giúp bạn được mời phỏng vấn.",                true,  DateTime.UtcNow.AddDays(-28) ),
                ("Lương lập trình viên tại Việt Nam năm 2026",    "luong-lap-trinh-vien-2026",         "Khảo sát mức lương thực tế của các vị trí IT phổ biến tại Việt Nam.",                 true,  DateTime.UtcNow.AddDays(-25) ),
                ("Remote work – xu hướng hay trở lại văn phòng?", "remote-work-hay-van-phong",         "Phân tích ưu nhược điểm của làm việc từ xa và xu hướng tuyển dụng hiện nay.",         true,  DateTime.UtcNow.AddDays(-22) ),
                ("Fresher IT: Làm gì để có job đầu tiên?",        "fresher-it-lam-gi-de-co-job",       "Lộ trình thực tế cho sinh viên IT mới ra trường tìm kiếm công việc.",                 true,  DateTime.UtcNow.AddDays(-20) ),
                ("Top 5 công ty IT tốt nhất để làm việc ở VN",   "top-5-cong-ty-it-tot-nhat",         "Đánh giá môi trường, phúc lợi và văn hóa của 5 công ty IT hàng đầu.",                true,  DateTime.UtcNow.AddDays(-18) ),
                ("Microservices vs Monolithic – chọn gì 2026?",   "microservices-vs-monolithic",       "So sánh kiến trúc phần mềm và khi nào nên dùng microservices.",                       true,  DateTime.UtcNow.AddDays(-15) ),
                ("Bí quyết vượt qua phỏng vấn kỹ thuật",         "bi-quyet-phong-van-ky-thuat",       "Các bước chuẩn bị và chiến lược giải bài leetcode để pass phỏng vấn.",               true,  DateTime.UtcNow.AddDays(-13) ),
                ("AI có thay thế lập trình viên không?",          "ai-co-thay-the-lap-trinh-vien",     "Phân tích tác động của AI generative đối với nghề lập trình trong tương lai.",        true,  DateTime.UtcNow.AddDays(-10) ),
                ("Học DevOps từ đầu – lộ trình 6 tháng",         "hoc-devops-tu-dau-6-thang",         "Lộ trình học DevOps từ căn bản: Linux, Docker, K8s, CI/CD và Cloud.",                 true,  DateTime.UtcNow.AddDays(-8)  ),
                ("UX Writing – nghề mới hot trong thiết kế",      "ux-writing-nghe-moi-hot",           "Tìm hiểu về UX Writing và cơ hội nghề nghiệp trong lĩnh vực thiết kế.",              true,  DateTime.UtcNow.AddDays(-6)  ),
                ("Làm thế nào để đàm phán lương hiệu quả?",      "dam-phan-luong-hieu-qua",           "Chiến lược và script thực tế giúp bạn đàm phán mức lương mong muốn.",                true,  DateTime.UtcNow.AddDays(-5)  ),
                ("Fintech Vietnam 2026 – cơ hội cho dev",         "fintech-vietnam-2026",              "Tổng quan thị trường fintech và các vị trí kỹ thuật đang được tuyển dụng.",            true,  DateTime.UtcNow.AddDays(-4)  ),
                ("Chuyển ngành sang IT – có muộn không?",         "chuyen-nganh-sang-it",              "Kinh nghiệm thực tế từ những người chuyển sang IT sau 25 tuổi.",                      true,  DateTime.UtcNow.AddDays(-3)  ),
                ("Portfolio dành cho Frontend Developer",         "portfolio-frontend-developer",      "Cách xây dựng portfolio ấn tượng và những dự án nên có khi apply.",                  true,  DateTime.UtcNow.AddDays(-2)  ),
                ("Clean Code – nguyên tắc nào quan trọng nhất?", "clean-code-nguyen-tac",             "Điểm lại các nguyên tắc Clean Code và cách áp dụng trong dự án thực tế.",            true,  DateTime.UtcNow.AddDays(-1)  ),
 
                // ── Bài nháp – chưa xuất bản (4 bài) ──
                ("Kinh nghiệm onboard tại startup vs corporate",  "startup-vs-corporate-onboard",      "So sánh trải nghiệm làm việc và phát triển sự nghiệp.",                               false, null),
                ("Golang – ngôn ngữ có nên học năm 2026?",       "golang-co-nen-hoc-2026",            "Đánh giá Golang từ góc độ thị trường tuyển dụng và độ khó học.",                      false, null),
                ("Xây dựng thương hiệu cá nhân cho dev",         "xay-dung-thuong-hieu-ca-nhan-dev",  "Hướng dẫn xây dựng personal brand qua GitHub, LinkedIn và blog.",                    false, null),
                ("Data Science vs Data Engineering – chọn gì?",  "data-science-vs-data-engineering",  "Phân biệt hai con đường sự nghiệp phổ biến trong ngành dữ liệu.",                    false, null),
            };
            // Tổng: 20 bản ghi

            var blogPosts = posts.Select(p => new BlogPost
            {
                AuthorID = admin.UserID,
                Title = p.Title,
                Slug = p.Slug,
                Excerpt = p.Excerpt,
                Content = $"<h2>{p.Title}</h2><p>{p.Excerpt}</p><p>Nội dung đang được cập nhật...</p>",
                IsPublished = p.IsPublished,
                PublishedAt = p.PublishedAt,
                CreatedAt = p.PublishedAt ?? DateTime.UtcNow
            }).ToArray();

            await context.BlogPosts.AddRangeAsync(blogPosts);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 16 – SYSTEM LOGS (20 bản ghi)
        //   Model SystemLog:
        //     - LogID    : int PK, tự sinh
        //     - UserID   : int? nullable (null = hành động hệ thống tự động)
        //     - Action   : string NOT NULL (tên hành động – viết hoa)
        //     - IPAddress: string?
        //     - Detail   : string? (mô tả chi tiết)
        //     - CreatedAt: DateTime
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedSystemLogs(AppDbContext context)
        {
            var users = await context.Users.OrderBy(u => u.UserID).ToListAsync();

            // Địa chỉ IP mẫu dùng xoay vòng
            string[] ips = { "113.161.12.45", "42.112.88.10", "203.171.0.22", "14.232.4.66", "1.53.200.100" };

            var logs = new[]
            {
                // [0-3] Hành động Admin
                new SystemLog { UserID=users[0].UserID,  Action="LOGIN",           IPAddress=ips[0], Detail="Admin đăng nhập thành công.",                          CreatedAt=DateTime.UtcNow.AddHours(-1)  },
                new SystemLog { UserID=users[0].UserID,  Action="DELETE_JOB",      IPAddress=ips[0], Detail="Admin xoá tin tuyển dụng vi phạm chính sách.",         CreatedAt=DateTime.UtcNow.AddHours(-13) },
                new SystemLog { UserID=users[0].UserID,  Action="VERIFY_EMPLOYER", IPAddress=ips[0], Detail="Admin xác thực công ty Zalo.",                         CreatedAt=DateTime.UtcNow.AddHours(-14) },
                new SystemLog { UserID=users[0].UserID,  Action="BAN_USER",        IPAddress=ips[0], Detail="Admin khoá tài khoản vi phạm điều khoản sử dụng.",     CreatedAt=DateTime.UtcNow.AddHours(-19) },
 
                // [4-9] Hành động Employer
                new SystemLog { UserID=users[4].UserID,  Action="LOGIN",           IPAddress=ips[1], Detail="Employer FPT đăng nhập.",                              CreatedAt=DateTime.UtcNow.AddHours(-2)  },
                new SystemLog { UserID=users[5].UserID,  Action="POST_JOB",        IPAddress=ips[2], Detail="VNG đăng tin: Backend Engineer – Java Spring Boot.",   CreatedAt=DateTime.UtcNow.AddHours(-3)  },
                new SystemLog { UserID=users[6].UserID,  Action="UPDATE_PROFILE",  IPAddress=ips[3], Detail="Tiki cập nhật thông tin công ty.",                     CreatedAt=DateTime.UtcNow.AddHours(-5)  },
                new SystemLog { UserID=users[7].UserID,  Action="PAYMENT",         IPAddress=ips[4], Detail="MoMo thanh toán gói Enterprise 2.490.000 VNĐ.",        CreatedAt=DateTime.UtcNow.AddHours(-6)  },
                new SystemLog { UserID=users[8].UserID,  Action="UPDATE_JOB",      IPAddress=ips[1], Detail="Shopee cập nhật tin: Machine Learning Engineer.",      CreatedAt=DateTime.UtcNow.AddHours(-17) },
                new SystemLog { UserID=users[9].UserID,  Action="PAYMENT_FAIL",    IPAddress=ips[2], Detail="Zalo thanh toán gói Pro Plus thất bại – timeout.",     CreatedAt=DateTime.UtcNow.AddHours(-16) },
 
                // [10-17] Hành động Candidate
                new SystemLog { UserID=users[10].UserID, Action="REGISTER",        IPAddress=ips[3], Detail="Ứng viên Nguyễn Văn An đăng ký tài khoản.",            CreatedAt=DateTime.UtcNow.AddHours(-11) },
                new SystemLog { UserID=users[11].UserID, Action="UPLOAD_CV",       IPAddress=ips[4], Detail="Lê Thị Bình upload CV mới.",                           CreatedAt=DateTime.UtcNow.AddHours(-8)  },
                new SystemLog { UserID=users[12].UserID, Action="APPLY_JOB",       IPAddress=ips[0], Detail="Phạm Mạnh Cường apply vị trí Data Engineer.",          CreatedAt=DateTime.UtcNow.AddHours(-4)  },
                new SystemLog { UserID=users[13].UserID, Action="SAVE_JOB",        IPAddress=ips[1], Detail="Võ Thị Duyên lưu tin: Machine Learning Engineer.",     CreatedAt=DateTime.UtcNow.AddHours(-7)  },
                new SystemLog { UserID=users[14].UserID, Action="VIEW_JOB",        IPAddress=ips[2], Detail="Trần Minh Em xem chi tiết tin: Senior DevOps.",        CreatedAt=DateTime.UtcNow.AddHours(-12) },
                new SystemLog { UserID=users[15].UserID, Action="CHANGE_PASSWORD", IPAddress=ips[3], Detail="Hoàng Thị Giang đổi mật khẩu thành công.",             CreatedAt=DateTime.UtcNow.AddHours(-10) },
                new SystemLog { UserID=users[16].UserID, Action="LOGIN_FAIL",      IPAddress=ips[4], Detail="Bùi Văn Hùng đăng nhập thất bại – sai mật khẩu.",     CreatedAt=DateTime.UtcNow.AddHours(-9)  },
                new SystemLog { UserID=users[17].UserID, Action="APPLY_JOB",       IPAddress=ips[0], Detail="Đỗ Hải Kỳ apply vị trí QA Automation Engineer.",      CreatedAt=DateTime.UtcNow.AddHours(-15) },
 
                // [18-19] Hành động Staff + Hệ thống tự động
                new SystemLog { UserID=users[1].UserID,  Action="LOGOUT",          IPAddress=ips[1], Detail="SuperAdmin đăng xuất.",                                CreatedAt=DateTime.UtcNow.AddHours(-20) },
                new SystemLog { UserID=null,             Action="SYSTEM_BACKUP",   IPAddress="127.0.0.1", Detail="Hệ thống tự động backup database lúc 02:00.",    CreatedAt=DateTime.UtcNow.AddHours(-22) },
            };
            // Tổng: 20 bản ghi (UserID có thể null với bản ghi hệ thống)

            await context.SystemLogs.AddRangeAsync(logs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 17 – INTERVIEWS (20 bản ghi)
        //   Model Interview:
        //     - InterviewID  : int PK, tự sinh
        //     - AppID        : FK → Application.AppID (NOT NULL, Cascade Delete)
        //     - InterviewDate: DateTime NOT NULL (giờ phỏng vấn)
        //     - Location     : string NOT NULL (địa điểm hoặc link Meet/Teams)
        //     - Notes        : string? (hướng dẫn cho ứng viên)
        //     - CreatedAt    : DateTime
        //
        //   Seed 20 cuộc phỏng vấn từ 20 Application đã seed ở Bước 11
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedInterviews(AppDbContext context)
        {
            var apps = await context.Applications.OrderBy(a => a.AppID).ToListAsync();

            string[] locations = {
                "Phòng họp A – FPT Software, 17 Duy Tân, Hà Nội",
                "https://meet.google.com/abc-defg-hij",
                "Văn phòng VNG, 182 Lê Đại Hành, Q.11, TP.HCM",
                "https://zoom.us/j/123456789",
                "Tiki HQ – 52 Út Tịch, Tân Bình, TP.HCM",
                "Microsoft Teams – link gửi qua email",
                "MoMo Office – 181 Cao Thắng, Q.10, TP.HCM",
                "https://meet.google.com/xyz-uvwx-yzab",
                "Shopee VN – 18 Nguyễn Hữu Thọ, Q.7, TP.HCM",
                "https://zoom.us/j/987654321",
                "Zalo – 182 Lê Đại Hành, Q.11, TP.HCM",
                "https://teams.microsoft.com/l/meetup-join/abc",
                "FPT – Phòng họp B, tầng 8",
                "https://meet.google.com/mno-pqrs-tuv",
                "VNG – Phòng phỏng vấn số 3",
                "https://zoom.us/j/112233445",
                "Tiki – Phòng glass, tầng 5",
                "https://meet.google.com/wxy-zabc-def",
                "MoMo – Phòng Tech Hub",
                "Shopee – Meeting Room Cali, tầng 12",
            };

            string?[] notes = {
                "Mang theo CV in màu và CCCD bản gốc.",
                "Phỏng vấn qua Google Meet, kiểm tra camera/mic trước 10 phút.",
                "Chuẩn bị trình bày 1 dự án đã làm trong 10 phút.",
                "Phỏng vấn kỹ thuật 60 phút + HR 30 phút.",
                "Dress code: business casual.",
                "Chuẩn bị câu hỏi cho nhà tuyển dụng.",
                "Phỏng vấn 2 vòng trong 1 buổi: Technical + Culture fit.",
                "Mang laptop cá nhân để làm bài test trực tiếp.",
                "Online interview – đường truyền ổn định tối thiểu 20Mbps.",
                "Đậu xe tại P4 tòa nhà, thang máy lên tầng 15.",
                null,
                "Chuẩn bị portfolio online, chia sẻ link trước khi vào phỏng vấn.",
                "Phỏng vấn tiếng Anh hoàn toàn.",
                null,
                "Gặp 3 interviewer: Tech Lead, Manager, HR.",
                "Chuẩn bị bài whiteboard coding về data structures.",
                "Ăn mặc lịch sự, phỏng vấn trực tiếp.",
                null,
                "Test tính cách MBTI sẽ được gửi qua email trước.",
                "Phỏng vấn thử thách kỹ năng giải quyết vấn đề trong 90 phút.",
            };

            var interviews = new List<Interview>();
            for (int i = 0; i < apps.Count && i < 20; i++)
            {
                interviews.Add(new Interview
                {
                    AppID = apps[i].AppID,
                    InterviewDate = DateTime.UtcNow.AddDays(i + 3)     // lịch phỏng vấn trong 3-22 ngày tới
                                            .AddHours(9 + (i % 4) * 2), // 09:00 / 11:00 / 13:00 / 15:00
                    Location = locations[i % locations.Length],
                    Notes = notes[i % notes.Length],
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                });
            }
            // Tổng: 20 bản ghi

            await context.Interviews.AddRangeAsync(interviews);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 18 – REPORTS (20 bản ghi)
        //   Model Report:
        //     - Id                  : int PK, tự sinh
        //     - ReporterId          : FK → User.UserID (NOT NULL, Restrict Delete)
        //     - ReporterType        : enum ReporterType { Candidate=1, Employer=2 }
        //     - ReportType          : enum ReportType { JobPost=1, Company=2, Spam=3, Fraud=4, InappropriateContent=5, Other=6 }
        //     - JobPostId           : FK → JobPost.JobID nullable (Restrict Delete)
        //     - CompanyId           : FK → Employer.EmployerID nullable (Restrict Delete)
        //     - ReportedEntityName  : string? (tên tin/công ty bị báo cáo)
        //     - Reason              : string NOT NULL (lý do ngắn gọn)
        //     - Description         : string? (mô tả chi tiết)
        //     - Status              : enum ReportStatus { Pending=1, InProgress=2, Resolved=3, Rejected=4 }
        //     - ProcessedByStaffId  : FK → Staff.Id nullable (SetNull Delete)
        //     - ProcessNote         : string?
        //     - ProcessedAt         : DateTime?
        //
        //   Phân bổ: 10 báo cáo JobPost + 6 báo cáo Company + 4 loại khác
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedReports(AppDbContext context)
        {
            var candidates = await context.Users.Where(u => u.Role == "Candidate").OrderBy(u => u.UserID).ToListAsync();
            var employers = await context.Users.Where(u => u.Role == "Employer").OrderBy(u => u.UserID).ToListAsync();
            var jobs = await context.JobPosts.OrderBy(j => j.JobID).ToListAsync();
            var empEntities = await context.Employers.OrderBy(e => e.EmployerID).ToListAsync();
            var staff = await context.Staff.OrderBy(s => s.Id).ToListAsync();

            int? StaffId(int i) => i < staff.Count ? staff[i].Id : (int?)null;

            var reports = new List<Report>();

            // ── Báo cáo JobPost (10 bản ghi) ──
            string[] jobReasons = {
                "Tin tuyển dụng có yêu cầu phi pháp",
                "Thông tin lương không trung thực – thực tế thấp hơn nhiều",
                "Tin đã hết hạn nhưng vẫn hiển thị",
                "Công việc không đúng mô tả, tính chất lừa đảo",
                "Yêu cầu nộp tiền cọc trước khi phỏng vấn",
                "Tin đăng trùng lặp nhiều lần trong ngày",
                "Yêu cầu thông tin cá nhân nhạy cảm không liên quan",
                "Công ty không tồn tại trên thực tế",
                "Mô tả công việc sử dụng ngôn từ phân biệt đối xử",
                "Tin tuyển dụng spam – đăng hàng loạt nội dung giống nhau",
            };
            ReportStatus[] reportStatuses = { ReportStatus.Pending, ReportStatus.InProgress, ReportStatus.Resolved, ReportStatus.Rejected };

            for (int i = 0; i < 10; i++)
            {
                var reporter = candidates[i % candidates.Count];
                var job = jobs[i % jobs.Count];
                bool resolved = i < 4; // 4 báo cáo đầu đã xử lý

                reports.Add(new Report
                {
                    ReporterId = reporter.UserID,
                    ReporterType = ReporterType.Candidate,
                    ReportType = i < 7 ? ReportType.JobPost : (i == 7 ? ReportType.Fraud : ReportType.Spam),
                    JobPostId = job.JobID,
                    CompanyId = null,
                    ReportedEntityName = job.Title,
                    Reason = jobReasons[i],
                    Description = $"Chi tiết vi phạm: {jobReasons[i]}. Phát hiện lúc {DateTime.UtcNow.AddDays(-i):dd/MM/yyyy HH:mm}.",
                    Status = reportStatuses[i % reportStatuses.Length],
                    ProcessedByStaffId = resolved ? StaffId(i % staff.Count) : null,
                    ProcessNote = resolved ? "Đã xem xét và xử lý theo chính sách nền tảng." : null,
                    ProcessedAt = resolved ? DateTime.UtcNow.AddDays(-i + 1) : null,
                    CreatedAt = DateTime.UtcNow.AddDays(-i - 1)
                });
            }

            // ── Báo cáo Company (6 bản ghi) ──
            string[] companyReasons = {
                "Công ty không trả lương sau phỏng vấn thử việc",
                "Môi trường làm việc độc hại, quản lý thiếu chuyên nghiệp",
                "Công ty yêu cầu làm thêm không lương",
                "Thông tin đăng ký công ty không hợp lệ",
                "Nhà tuyển dụng quấy rối ứng viên qua tin nhắn",
                "Công ty thu tiền phí tuyển dụng từ ứng viên",
            };

            for (int i = 0; i < 6; i++)
            {
                var reporter = candidates[(i + 2) % candidates.Count];
                var empEntity = empEntities[i % empEntities.Count];
                bool resolved = i == 0;

                reports.Add(new Report
                {
                    ReporterId = reporter.UserID,
                    ReporterType = ReporterType.Candidate,
                    ReportType = ReportType.Company,
                    JobPostId = null,
                    CompanyId = empEntity.EmployerID,
                    ReportedEntityName = empEntity.CompanyName,
                    Reason = companyReasons[i],
                    Description = $"Báo cáo về {empEntity.CompanyName}: {companyReasons[i]}.",
                    Status = resolved ? ReportStatus.Resolved : ReportStatus.Pending,
                    ProcessedByStaffId = resolved ? StaffId(0) : null,
                    ProcessNote = resolved ? "Đã liên hệ công ty và yêu cầu khắc phục." : null,
                    ProcessedAt = resolved ? DateTime.UtcNow.AddDays(-1) : null,
                    CreatedAt = DateTime.UtcNow.AddDays(-i - 2)
                });
            }

            // ── Báo cáo loại khác – do Employer tố ứng viên spam (4 bản ghi) ──
            for (int i = 0; i < 4; i++)
            {
                var empUser = employers[i % employers.Count];
                reports.Add(new Report
                {
                    ReporterId = empUser.UserID,
                    ReporterType = ReporterType.Employer,
                    ReportType = ReportType.Spam,
                    JobPostId = null,
                    CompanyId = null,
                    ReportedEntityName = $"Ứng viên spam #{i + 1}",
                    Reason = "Ứng viên gửi thư ứng tuyển hàng loạt nội dung không liên quan",
                    Description = "Hệ thống phát hiện ứng viên này đã nộp đơn vào hơn 50 vị trí trong 1 ngày.",
                    Status = ReportStatus.Pending,
                    ProcessedByStaffId = null,
                    CreatedAt = DateTime.UtcNow.AddDays(-i)
                });
            }
            // Tổng: 10 + 6 + 4 = 20 bản ghi

            await context.Reports.AddRangeAsync(reports);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 19 – SUPPORT TICKETS (20 bản ghi)
        //   Model SupportTicket:
        //     - Id                : int PK, tự sinh
        //     - UserId            : FK → User.UserID (NOT NULL, Restrict Delete)
        //     - Type              : enum TicketType { AccountIssue=1, JobPosting=2, Application=3, Billing=4, Technical=5, Other=6 }
        //     - Subject           : string NOT NULL (max 200)
        //     - Message           : string NOT NULL (max 5000) – nội dung câu hỏi/vấn đề
        //     - Status            : enum TicketStatus { Open=1, InProgress=2, Resolved=3, Closed=4 }
        //     - AssignedToStaffId : FK → Staff.Id nullable (SetNull Delete)
        //     - Priority          : int? (1=Thấp, 2=Trung bình, 3=Cao, 4=Khẩn)
        //     - StaffResponse     : string? (câu trả lời của Staff)
        //     - AssignedAt        : DateTime?
        //     - ResolvedAt        : DateTime?
        //
        //   Phân bổ: 6 Open + 6 InProgress + 5 Resolved + 3 Closed = 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedSupportTickets(AppDbContext context)
        {
            var users = await context.Users.Where(u => u.Role == "Candidate" || u.Role == "Employer")
                                              .OrderBy(u => u.UserID).ToListAsync();
            var staffList = await context.Staff.OrderBy(s => s.Id).ToListAsync();

            int? S(int i) => i < staffList.Count ? staffList[i].Id : (int?)null;

            // (subject, message, type, status, priority, hasResponse)
            var ticketData = new[]
            {
                // ── AccountIssue (4) ──
                ("Không đăng nhập được vào tài khoản",             "Tôi nhập đúng email và mật khẩu nhưng hệ thống vẫn báo sai. Đã thử đặt lại mật khẩu nhưng không nhận được OTP.",                  TicketType.AccountIssue, TicketStatus.Open,       2, false),
                ("Quên mật khẩu – không nhận được email OTP",      "Email OTP không về hộp thư, tôi đã kiểm tra spam folder nhưng vẫn không thấy. Email đăng ký là gmail.",                            TicketType.AccountIssue, TicketStatus.InProgress,  3, true ),
                ("Tài khoản bị khóa không rõ lý do",               "Tôi nhận được thông báo tài khoản bị hạn chế nhưng không vi phạm điều khoản nào. Yêu cầu mở khóa khẩn cấp.",                     TicketType.AccountIssue, TicketStatus.Resolved,    4, true ),
                ("Muốn thay đổi email đăng ký",                    "Email cũ không còn sử dụng được, tôi muốn đổi sang email mới mà vẫn giữ lịch sử ứng tuyển.",                                      TicketType.AccountIssue, TicketStatus.Closed,      1, true ),
 
                // ── JobPosting (4) ──
                ("Tin tuyển dụng không hiển thị sau khi đăng",     "Tôi đã đăng tin thành công (có mã xác nhận) nhưng tìm kiếm trên hệ thống không thấy tin xuất hiện.",                              TicketType.JobPosting,   TicketStatus.Open,       2, false),
                ("Không chỉnh sửa được tin đã đăng",              "Tin đăng bị lỗi thông tin lương, tôi vào chỉnh sửa nhưng nút Lưu không hoạt động trên trình duyệt Chrome.",                       TicketType.JobPosting,   TicketStatus.InProgress,  2, true ),
                ("Yêu cầu xóa tin tuyển dụng đã đóng",            "Vị trí này đã tuyển đủ người, tôi muốn xóa hoàn toàn tin khỏi hệ thống thay vì chỉ đóng.",                                       TicketType.JobPosting,   TicketStatus.Resolved,    1, true ),
                ("Tin bị từ chối duyệt – không rõ lý do",         "Hệ thống gửi email thông báo tin bị từ chối nhưng không ghi rõ vi phạm điều gì. Tôi cần phản hồi cụ thể để chỉnh sửa.",          TicketType.JobPosting,   TicketStatus.Open,       3, false),
 
                // ── Application (4) ──
                ("Không xem được CV của ứng viên",                 "Khi click vào đơn ứng tuyển, link tải CV bị lỗi 404. Tôi cần xem CV để quyết định phỏng vấn.",                                   TicketType.Application,  TicketStatus.InProgress,  3, true ),
                ("Hệ thống gửi email nhầm trạng thái ứng tuyển",  "Ứng viên nhận được email 'Offered' nhưng thực tế tôi chỉ mới chuyển sang trạng thái 'Interview'. Xin kiểm tra lại.",             TicketType.Application,  TicketStatus.Resolved,    4, true ),
                ("Muốn rút đơn ứng tuyển đã nộp",                 "Tôi đã tìm được việc khác và muốn rút đơn khỏi vị trí hiện tại để không làm mất thời gian của nhà tuyển dụng.",                 TicketType.Application,  TicketStatus.Closed,      1, true ),
                ("Thông báo ứng tuyển không hiển thị trên app",   "Trên web thì thấy thông báo, nhưng trên app mobile không có. Hệ thống có đồng bộ không?",                                          TicketType.Application,  TicketStatus.Open,       2, false),
 
                // ── Billing (4) ──
                ("Thanh toán thành công nhưng gói chưa kích hoạt", "Tôi đã thanh toán gói Pro qua VNPay, tài khoản ngân hàng đã bị trừ tiền nhưng gói dịch vụ vẫn hiển thị Free.",                  TicketType.Billing,      TicketStatus.InProgress,  4, true ),
                ("Yêu cầu xuất hóa đơn VAT",                      "Công ty chúng tôi cần hóa đơn VAT cho gói Enterprise vừa thanh toán để quyết toán thuế quý 2/2026.",                             TicketType.Billing,      TicketStatus.Open,       2, false),
                ("Muốn hoàn tiền gói dịch vụ chưa sử dụng",       "Tôi mua nhầm gói, đơn vị vừa thanh toán xong hôm qua nhưng chưa đăng tin nào. Yêu cầu hoàn tiền theo chính sách.",               TicketType.Billing,      TicketStatus.InProgress,  3, true ),
                ("Gói dịch vụ hết hạn trước thời hạn",            "Tôi mua gói 30 ngày nhưng sau 25 ngày hệ thống đã thông báo hết hạn. Đề nghị kiểm tra và bổ sung thêm 5 ngày.",                  TicketType.Billing,      TicketStatus.Resolved,    3, true ),
 
                // ── Technical (4) ──
                ("Trang upload CV bị lỗi 500",                     "Khi upload file PDF vượt 2MB, trang báo lỗi Internal Server Error. Tôi cần upload CV 3.5MB.",                                     TicketType.Technical,    TicketStatus.Open,       3, false),
                ("Tính năng tìm kiếm không hoạt động đúng",       "Tìm kiếm từ khóa '.NET Developer' trả về cả kết quả không liên quan như Marketing. Bộ lọc theo ngành không có tác dụng.",        TicketType.Technical,    TicketStatus.InProgress,  2, true ),
                ("Dashboard thống kê hiển thị số liệu sai",       "Dashboard admin hiển thị tổng ứng viên là 0 trong khi thực tế có nhiều đơn ứng tuyển. Có thể do lỗi cache.",                      TicketType.Technical,    TicketStatus.InProgress,  3, true ),
                ("Không nhận được email thông báo phỏng vấn",     "Đã xác nhận lịch phỏng vấn nhưng email xác nhận không đến. Đã kiểm tra spam, tất cả các folder đều không có.",                   TicketType.Technical,    TicketStatus.Open,       2, false),
            };
            // Tổng: 20 bản ghi

            var tickets = new List<SupportTicket>();
            for (int i = 0; i < ticketData.Length; i++)
            {
                var (subject, message, type, status, priority, hasResponse) = ticketData[i];
                var user = users[i % users.Count];
                int? staffId = status != TicketStatus.Open ? S(i % staffList.Count) : null;

                tickets.Add(new SupportTicket
                {
                    UserId = user.UserID,
                    Type = type,
                    Subject = subject,
                    Message = message,
                    Status = status,
                    AssignedToStaffId = staffId,
                    Priority = (TicketPriority)priority,
                    StaffResponse = hasResponse
                                            ? "Cảm ơn bạn đã liên hệ. Chúng tôi đã xem xét vấn đề và sẽ hỗ trợ bạn trong thời gian sớm nhất."
                                            : null,
                    AssignedAt = staffId.HasValue ? DateTime.UtcNow.AddDays(-i + 1) : null,
                    ResolvedAt = status is TicketStatus.Resolved or TicketStatus.Closed
                                            ? DateTime.UtcNow.AddDays(-i + 2)
                                            : null,
                    CreatedAt = DateTime.UtcNow.AddDays(-i - 1),
                    UpdatedAt = staffId.HasValue ? DateTime.UtcNow.AddDays(-i) : null
                });
            }

            await context.SupportTickets.AddRangeAsync(tickets);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════════
        // BƯỚC 20 – ACTIVITY LOGS (20 bản ghi)
        //   Model ActivityLog:
        //     - Id         : int PK, tự sinh
        //     - StaffId    : FK → Staff.Id (NOT NULL, Cascade Delete)
        //     - Action     : string NOT NULL (tên hành động)
        //     - Description: string? (chi tiết)
        //     - IpAddress  : string?
        //     - UserAgent  : string?
        //     - CreatedAt  : DateTime
        //
        //   Ghi lại hành động của 2 Staff đã seed ở Bước 2
        //   Mỗi Staff có 10 log → tổng 20
        // ══════════════════════════════════════════════════════════════
        private static async Task SeedActivityLogs(AppDbContext context)
        {
            var staffList = await context.Staff.OrderBy(s => s.Id).ToListAsync();

            // Đảm bảo có ít nhất 1 staff để seed
            if (!staffList.Any()) return;

            int S(int i) => staffList[i % staffList.Count].Id;
            string[] ips = { "113.161.12.45", "42.112.88.10", "203.171.0.22" };
            string ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0";

            // 20 bản ghi phân bổ theo 2 staff (10-10)
            var logs = new[]
            {
                // ── Staff 1 – Content Moderator (S0) – 10 log ──
                new ActivityLog { StaffId=S(0), Action="LOGIN",              Description="Content Moderator đăng nhập.",                                IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-1)  },
                new ActivityLog { StaffId=S(0), Action="REVIEW_JOB",         Description="Xem xét tin tuyển dụng #3 – Thực tập sinh Backend Python.",  IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-2)  },
                new ActivityLog { StaffId=S(0), Action="REJECT_JOB",         Description="Từ chối tin #7 – nội dung vi phạm chính sách giới tính.",    IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-3) },
                new ActivityLog { StaffId=S(0), Action="APPROVE_BLOG",       Description="Duyệt bài viết blog: '10 kỹ năng IT hot nhất năm 2026'.",    IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-4) },
                new ActivityLog { StaffId=S(0), Action="EDIT_BLOG",          Description="Sửa lỗi chính tả bài viết: 'Cách viết CV xin việc IT'.",     IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-5) },
                new ActivityLog { StaffId=S(0), Action="HANDLE_REPORT",      Description="Xử lý báo cáo #5 – tin tuyển dụng spam.",                    IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-6) },
                new ActivityLog { StaffId=S(0), Action="VERIFY_EMPLOYER",    Description="Xác thực tài khoản công ty FPT Software.",                    IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-7)  },
                new ActivityLog { StaffId=S(0), Action="VIEW_REPORT",        Description="Xem báo cáo vi phạm #12 – tin tuyển dụng lừa đảo.",          IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-8)  },
                new ActivityLog { StaffId=S(0), Action="APPROVE_JOB",        Description="Duyệt tin tuyển dụng: Machine Learning Engineer – Shopee.",   IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-9)  },
                new ActivityLog { StaffId=S(0), Action="LOGOUT",             Description="Content Moderator đăng xuất.",                               IpAddress=ips[0], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-10) },

                // ── Staff 2 – Customer Support (S1) – 10 log ──
                new ActivityLog { StaffId=S(1), Action="LOGIN",              Description="Customer Support đăng nhập ca chiều.",                        IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-11) },
                new ActivityLog { StaffId=S(1), Action="RESPOND_TICKET",     Description="Trả lời ticket #2 – hỗ trợ quên mật khẩu OTP.",             IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-12) },
                new ActivityLog { StaffId=S(1), Action="CLOSE_TICKET",       Description="Đóng ticket #4 – đổi email đăng ký thành công.",             IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-13) },
                new ActivityLog { StaffId=S(1), Action="ASSIGN_TICKET",      Description="Chuyển ticket #13 – yêu cầu hóa đơn VAT sang phòng kế toán.", IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-14) },
                new ActivityLog { StaffId=S(1), Action="RESPOND_TICKET",     Description="Trả lời ticket #9 – lỗi không xem được CV ứng viên.",        IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-15) },
                new ActivityLog { StaffId=S(1), Action="CREATE_TICKET",      Description="Tạo ticket mới #15 – yêu cầu cấp lại mật khẩu.",             IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-16) },
                new ActivityLog { StaffId=S(1), Action="ESCALATE_TICKET",    Description="Chuyển ticket #18 lên cấp quản lý.",                          IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-17) },
                new ActivityLog { StaffId=S(1), Action="REOPEN_TICKET",     Description="Mở lại ticket #20 theo yêu cầu khách hàng.",                  IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-18) },
                new ActivityLog { StaffId=S(1), Action="ADD_NOTE_TICKET",    Description="Thêm ghi chú ticket #17 – đã xử lý xong.",                   IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-19) },
                new ActivityLog { StaffId=S(1), Action="LOGOUT",             Description="Customer Support đăng xuất.",                               IpAddress=ips[1], UserAgent=ua, CreatedAt=DateTime.UtcNow.AddHours(-20) },
            };
            // Tổng: 10 + 10 = 20 bản ghi

            await context.ActivityLogs.AddRangeAsync(logs);
            await context.SaveChangesAsync();

            Console.WriteLine("✅ ActivityLogs seeded – 20 bản ghi.");
        }
    }
}