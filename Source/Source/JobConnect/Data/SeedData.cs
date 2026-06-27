using JobConnect.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Text.Json;

namespace JobConnect.Data
{
    public static class SeedData
    {
        public static async Task Initialize(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            if (await context.Users.AnyAsync()) return;

            await SeedUsers(context);
            await SeedCategories(context);
            await SeedSkills(context);
            await SeedServicePackages(context);
            await SeedEmployersAndProfiles(context);
            await SeedCvFiles(context);
            await SeedCandidateSkills(context);
            await SeedJobPosts(context);
            await SeedApplications(context);
            await SeedSavedJobs(context);
            await SeedNotifications(context);
            await SeedTransactions(context);
            await SeedBlogPosts(context);
            await SeedSystemLogs(context);

            Console.WriteLine("✅ SeedData đã được thêm thành công!");
        }

        // ══════════════════════════════════════════════════════════
        // 1. USERS – 20 bản ghi (1 Admin, 9 Employer, 10 Candidate)
        // ══════════════════════════════════════════════════════════
        private static async Task SeedUsers(AppDbContext context)
        {
            const string hash = "$2a$12$vaYJo0gm6QIO/8Rz0l70f.FqhFezMmZIAYoys7AOnXY0lMaUuoJgC"; // Test@123
            const string adminHash = "$2a$12$r/CxcklkXm.X4XtZkpnhQO3E6n3gAXUvfrgS5E.O.dFtEvV/bUjEi"; // Admin@123

            var users = new[]
            {
                // ── Admin ──
                new User { Email="admin@jobconnect.vn",    PasswordHash=adminHash, Role="Admin",     FullName="Quản trị viên",        PhoneNumber="0987654321", Status="Active", CreatedAt=DateTime.UtcNow },
 
                // ── Employers ──
                new User { Email="hr@fptsoft.com",         PasswordHash=hash, Role="Employer",  FullName="Nguyễn Thị HR – FPT",    PhoneNumber="0909123456", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="recruit@vng.com.vn",     PasswordHash=hash, Role="Employer",  FullName="Lê Minh Tuyển – VNG",    PhoneNumber="0908234567", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="talent@tiki.vn",         PasswordHash=hash, Role="Employer",  FullName="Phạm Thị Lan – Tiki",    PhoneNumber="0907345678", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="hr@momo.vn",             PasswordHash=hash, Role="Employer",  FullName="Trần Hoàng Nam – MoMo",  PhoneNumber="0906456789", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="careers@vingroup.net",   PasswordHash=hash, Role="Employer",  FullName="Ngô Thị Mai – Vingroup", PhoneNumber="0905567890", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="hr@shopee.vn",           PasswordHash=hash, Role="Employer",  FullName="Bùi Thanh Tùng – Shopee",PhoneNumber="0904678901", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="talent@zalo.me",         PasswordHash=hash, Role="Employer",  FullName="Đặng Quốc Huy – Zalo",  PhoneNumber="0903789012", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="recruit@techcombank.com",PasswordHash=hash, Role="Employer",  FullName="Vũ Thị Hoa – Techcombank",PhoneNumber="0902890123",Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="hr@grab.com",            PasswordHash=hash, Role="Employer",  FullName="Phan Minh Đức – Grab",   PhoneNumber="0901901234", Status="Active", CreatedAt=DateTime.UtcNow },
 
                // ── Candidates ──
                new User { Email="an.nguyen@gmail.com",    PasswordHash=hash, Role="Candidate", FullName="Nguyễn Văn An",          PhoneNumber="0912111222", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="binh.le@gmail.com",      PasswordHash=hash, Role="Candidate", FullName="Lê Thị Bình",            PhoneNumber="0923222333", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="cuong.pham@gmail.com",   PasswordHash=hash, Role="Candidate", FullName="Phạm Mạnh Cường",        PhoneNumber="0934333444", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="duyen.vo@gmail.com",     PasswordHash=hash, Role="Candidate", FullName="Võ Thị Duyên",           PhoneNumber="0945444555", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="em.tran@gmail.com",      PasswordHash=hash, Role="Candidate", FullName="Trần Minh Em",           PhoneNumber="0956555666", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="giang.hoang@gmail.com",  PasswordHash=hash, Role="Candidate", FullName="Hoàng Thị Giang",        PhoneNumber="0967666777", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="hung.bui@gmail.com",     PasswordHash=hash, Role="Candidate", FullName="Bùi Văn Hùng",           PhoneNumber="0978777888", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="ky.do@gmail.com",        PasswordHash=hash, Role="Candidate", FullName="Đỗ Hải Kỳ",             PhoneNumber="0989888999", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="lan.dang@gmail.com",     PasswordHash=hash, Role="Candidate", FullName="Đặng Thị Lan",           PhoneNumber="0990999000", Status="Active", CreatedAt=DateTime.UtcNow },
                new User { Email="minh.cao@gmail.com",     PasswordHash=hash, Role="Candidate", FullName="Cao Xuân Minh",          PhoneNumber="0911000111", Status="Active", CreatedAt=DateTime.UtcNow },
            };

            await context.Users.AddRangeAsync(users);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 2. CATEGORIES – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedCategories(AppDbContext context)
        {
            var cats = new[]
            {
                // Industry (8)
                new Category { Name="Công nghệ thông tin",      Type="Industry", Slug="cong-nghe-thong-tin" },
                new Category { Name="Marketing & Truyền thông", Type="Industry", Slug="marketing" },
                new Category { Name="Tài chính – Kế toán",      Type="Industry", Slug="tai-chinh-ke-toan" },
                new Category { Name="Kỹ thuật – Cơ khí",        Type="Industry", Slug="ky-thuat-co-khi" },
                new Category { Name="Y tế – Dược phẩm",         Type="Industry", Slug="y-te-duoc-pham" },
                new Category { Name="Thiết kế – Mỹ thuật",      Type="Industry", Slug="thiet-ke" },
                new Category { Name="Giáo dục – Đào tạo",       Type="Industry", Slug="giao-duc-dao-tao" },
                new Category { Name="Bán hàng – Kinh doanh",    Type="Industry", Slug="ban-hang-kinh-doanh" },
                // Location (6)
                new Category { Name="Hà Nội",           Type="Location", Slug="ha-noi" },
                new Category { Name="TP. Hồ Chí Minh",  Type="Location", Slug="ho-chi-minh" },
                new Category { Name="Đà Nẵng",          Type="Location", Slug="da-nang" },
                new Category { Name="Cần Thơ",          Type="Location", Slug="can-tho" },
                new Category { Name="Hải Phòng",        Type="Location", Slug="hai-phong" },
                new Category { Name="Bình Dương",       Type="Location", Slug="binh-duong" },
                // Level (4)
                new Category { Name="Fresher", Type="Level", Slug="fresher" },
                new Category { Name="Junior",  Type="Level", Slug="junior" },
                new Category { Name="Middle",  Type="Level", Slug="middle" },
                new Category { Name="Senior",  Type="Level", Slug="senior" },
                // JobType (2)
                new Category { Name="FullTime",    Type="JobType", Slug="full-time" },
                new Category { Name="Internship",  Type="JobType", Slug="internship" },
            };

            await context.Categories.AddRangeAsync(cats);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 3. SKILLS – 30 bản ghi với Category và IsActive
        // ══════════════════════════════════════════════════════════
        private static async Task SeedSkills(AppDbContext context)
        {
            var skills = new[]
            {
                // Programming Skills
                new Skill { Name="JavaScript",    Description="Ngôn ngữ lập trình web phía client/server", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="TypeScript",    Description="JavaScript có kiểu tĩnh", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Python",        Description="Ngôn ngữ đa dụng, phổ biến trong AI/Data", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Java",          Description="Ngôn ngữ hướng đối tượng enterprise", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="C#",            Description="Ngôn ngữ .NET của Microsoft", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name=".NET Core",     Description="Framework cross-platform của Microsoft", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="React.js",      Description="Thư viện UI của Facebook", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Angular",       Description="Framework SPA của Google", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Vue.js",        Description="Framework JavaScript linh hoạt", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Node.js",       Description="Runtime JavaScript phía server", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="PHP",           Description="Ngôn ngữ lập trình web server-side", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Go",            Description="Ngôn ngữ lập trình của Google", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Rust",          Description="Ngôn ngữ hệ thống an toàn bộ nhớ", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Swift",         Description="Ngôn ngữ lập trình iOS", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Kotlin",        Description="Ngôn ngữ lập trình Android hiện đại", Category=SkillCategory.Programming, IsActive=true },

                // Database Skills
                new Skill { Name="SQL Server",    Description="Hệ quản trị CSDL của Microsoft", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="MySQL",         Description="Hệ quản trị CSDL mã nguồn mở", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="PostgreSQL",    Description="CSDL quan hệ mã nguồn mở cao cấp", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="MongoDB",       Description="CSDL NoSQL hướng tài liệu", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Redis",         Description="In-memory data store, caching", Category=SkillCategory.Programming, IsActive=true },

                // DevOps Skills
                new Skill { Name="Docker",        Description="Containerization platform", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Kubernetes",    Description="Container orchestration platform", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="AWS",           Description="Amazon Web Services cloud platform", Category=SkillCategory.Programming, IsActive=true },
                new Skill { Name="Azure",         Description="Microsoft Azure cloud platform", Category=SkillCategory.Programming, IsActive=true },

                // Design Skills
                new Skill { Name="Figma",         Description="Công cụ thiết kế UI/UX", Category=SkillCategory.Design, IsActive=true },
                new Skill { Name="Adobe XD",      Description="Công cụ thiết kế UI/UX của Adobe", Category=SkillCategory.Design, IsActive=true },
                new Skill { Name="Photoshop",     Description="Phần mềm chỉnh sửa ảnh chuyên nghiệp", Category=SkillCategory.Design, IsActive=true },
                new Skill { Name="Illustrator",   Description="Phần mềm thiết kế đồ họa vector", Category=SkillCategory.Design, IsActive=true },

                // Marketing Skills
                new Skill { Name="SEO",           Description="Tối ưu hóa công cụ tìm kiếm", Category=SkillCategory.Marketing, IsActive=true },
                new Skill { Name="Google Ads",    Description="Quảng cáo trên Google", Category=SkillCategory.Marketing, IsActive=true },
                new Skill { Name="Facebook Ads",  Description="Quảng cáo trên Facebook", Category=SkillCategory.Marketing, IsActive=true },

                // Soft Skills
                new Skill { Name="Communication", Description="Kỹ năng giao tiếp hiệu quả", Category=SkillCategory.SoftSkills, IsActive=true },
                new Skill { Name="Teamwork",      Description="Kỹ năng làm việc nhóm", Category=SkillCategory.SoftSkills, IsActive=true },
                new Skill { Name="Problem Solving", Description="Kỹ năng giải quyết vấn đề", Category=SkillCategory.SoftSkills, IsActive=true },

                // Language Skills
                new Skill { Name="English",       Description="Kỹ năng tiếng Anh chuyên ngành", Category=SkillCategory.Language, IsActive=true },
                new Skill { Name="Japanese",      Description="Kỹ năng tiếng Nhật", Category=SkillCategory.Language, IsActive=true },
                new Skill { Name="Korean",        Description="Kỹ năng tiếng Hàn", Category=SkillCategory.Language, IsActive=true },
            };

            await context.Skills.AddRangeAsync(skills);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 4. SERVICE PACKAGES – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedServicePackages(AppDbContext context)
        {
            var pkgs = new[]
            {
                new ServicePackage { Name="Miễn phí",         Price=0,          DurationDays=30,  MaxJobPosts=3,   MaxFeatured=0,  Description="Đăng tối đa 3 tin/tháng, không nổi bật.",              IsActive=true  },
                new ServicePackage { Name="Starter",          Price=299000,     DurationDays=30,  MaxJobPosts=5,   MaxFeatured=1,  Description="5 tin/tháng, 1 tin nổi bật – phù hợp startup nhỏ.",   IsActive=true  },
                new ServicePackage { Name="Basic",            Price=599000,     DurationDays=30,  MaxJobPosts=8,   MaxFeatured=2,  Description="8 tin/tháng, 2 tin nổi bật.",                          IsActive=true  },
                new ServicePackage { Name="Pro",              Price=990000,     DurationDays=30,  MaxJobPosts=15,  MaxFeatured=3,  Description="15 tin/tháng, 3 tin nổi bật, hỗ trợ ưu tiên.",        IsActive=true  },
                new ServicePackage { Name="Pro Plus",         Price=1490000,    DurationDays=30,  MaxJobPosts=25,  MaxFeatured=5,  Description="25 tin/tháng, 5 tin nổi bật, badge xác thực.",         IsActive=true  },
                new ServicePackage { Name="Business",         Price=1990000,    DurationDays=30,  MaxJobPosts=50,  MaxFeatured=8,  Description="50 tin/tháng, 8 tin nổi bật, hiển thị logo.",          IsActive=true  },
                new ServicePackage { Name="Enterprise",       Price=2490000,    DurationDays=30,  MaxJobPosts=999, MaxFeatured=10, Description="Không giới hạn tin, 10 tin nổi bật, logo premium.",    IsActive=true  },
                new ServicePackage { Name="Enterprise Annual",Price=19900000,   DurationDays=365, MaxJobPosts=999, MaxFeatured=15, Description="Gói năm Enterprise – tiết kiệm 33%.",                  IsActive=true  },
                new ServicePackage { Name="Seasonal 3 tháng",Price=2500000,    DurationDays=90,  MaxJobPosts=30,  MaxFeatured=6,  Description="Gói 3 tháng linh hoạt cho doanh nghiệp theo mùa.",    IsActive=true  },
                new ServicePackage { Name="Campus Recruit",   Price=799000,     DurationDays=30,  MaxJobPosts=10,  MaxFeatured=2,  Description="Tuyển dụng sinh viên, hiển thị trang Campus.",         IsActive=true  },
                new ServicePackage { Name="Tech Talent",      Price=1290000,    DurationDays=30,  MaxJobPosts=20,  MaxFeatured=4,  Description="Dành riêng cho nhà tuyển dụng ngành IT.",              IsActive=true  },
                new ServicePackage { Name="Remote Hire",      Price=890000,     DurationDays=30,  MaxJobPosts=12,  MaxFeatured=3,  Description="Tập trung tin Remote cho ứng viên toàn quốc.",         IsActive=true  },
                new ServicePackage { Name="Headhunter",       Price=3490000,    DurationDays=30,  MaxJobPosts=999, MaxFeatured=20, Description="Dành cho công ty headhunting – không giới hạn tin.",   IsActive=true  },
                new ServicePackage { Name="SME Pack",         Price=690000,     DurationDays=30,  MaxJobPosts=10,  MaxFeatured=2,  Description="Gói dành cho doanh nghiệp vừa và nhỏ.",                IsActive=true  },
                new ServicePackage { Name="Trial 7 ngày",     Price=99000,      DurationDays=7,   MaxJobPosts=2,   MaxFeatured=1,  Description="Dùng thử 7 ngày với đầy đủ tính năng cơ bản.",         IsActive=true  },
                new ServicePackage { Name="Flash Sale Q1",    Price=499000,     DurationDays=30,  MaxJobPosts=10,  MaxFeatured=3,  Description="Gói khuyến mãi đầu năm – giá ưu đãi.",                 IsActive=false },
                new ServicePackage { Name="Flash Sale Q3",    Price=499000,     DurationDays=30,  MaxJobPosts=10,  MaxFeatured=3,  Description="Gói khuyến mãi quý 3.",                                IsActive=false },
                new ServicePackage { Name="Internship Pack",  Price=390000,     DurationDays=30,  MaxJobPosts=6,   MaxFeatured=1,  Description="Đăng tin thực tập sinh với chi phí thấp.",              IsActive=true  },
                new ServicePackage { Name="Agency Pro",       Price=4990000,    DurationDays=30,  MaxJobPosts=999, MaxFeatured=30, Description="Dành cho agency tuyển dụng lớn – tối đa hiển thị.",    IsActive=true  },
                new ServicePackage { Name="Platinum Annual",  Price=39900000,   DurationDays=365, MaxJobPosts=999, MaxFeatured=50, Description="Gói năm cao cấp nhất – đối tác chiến lược.",           IsActive=true  },
            };

            await context.ServicePackages.AddRangeAsync(pkgs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 5. EMPLOYERS (9) + CANDIDATE PROFILES (10) + 1 Admin profile
        // ══════════════════════════════════════════════════════════
        private static async Task SeedEmployersAndProfiles(AppDbContext context)
        {
            // ── Employers ──
            var empData = new[]
            {
                ("hr@fptsoft.com",         "FPT Software",   "Công nghệ thông tin","1000+", "17 Duy Tân, Cầu Giấy, Hà Nội",          "https://fpt-software.com",      "FPT Software là công ty phần mềm hàng đầu VN với hơn 27.000 nhân viên.", true,  false),
                ("recruit@vng.com.vn",     "VNG Corporation","Công nghệ thông tin","1000+", "182 Lê Đại Hành, Q.11, TP.HCM",          "https://vng.com.vn",            "VNG sở hữu Zalo, ZaloPay và nhiều sản phẩm internet hàng đầu VN.",       true,  false),
                ("talent@tiki.vn",         "Tiki",           "Thương mại điện tử", "1000+", "52 Út Tịch, Tân Bình, TP.HCM",           "https://tiki.vn",               "Tiki – sàn TMĐT hàng đầu với cam kết giao hàng 2H.",                     true,  false),
                ("hr@momo.vn",             "MoMo",           "Fintech",            "500-999","181 Cao Thắng, Q.10, TP.HCM",            "https://momo.vn",               "MoMo – ví điện tử số 1 Việt Nam, hơn 31 triệu người dùng.",              true,  false),
                ("careers@vingroup.net",   "Vingroup",       "Đa ngành",           "1000+", "7 Bà Triệu, Hoàn Kiếm, Hà Nội",         "https://vingroup.net",          "Vingroup – tập đoàn kinh tế tư nhân lớn nhất Việt Nam.",                 true,  false),
                ("hr@shopee.vn",           "Shopee Vietnam", "Thương mại điện tử", "1000+", "18 Nguyễn Hữu Thọ, Q.7, TP.HCM",        "https://shopee.vn",             "Shopee – nền tảng TMĐT hàng đầu Đông Nam Á.",                           true,  false),
                ("talent@zalo.me",         "Zalo",           "Công nghệ thông tin","500-999","182 Lê Đại Hành, Q.11, TP.HCM",          "https://zalo.me",               "Zalo – ứng dụng nhắn tin và mạng xã hội số 1 Việt Nam.",                 true,  false),
                ("recruit@techcombank.com","Techcombank",    "Ngân hàng",          "1000+", "191 Bà Triệu, Hai Bà Trưng, Hà Nội",    "https://techcombank.com.vn",    "Techcombank – ngân hàng tư nhân lớn, tiên phong chuyển đổi số.",         true,  false),
                ("hr@grab.com",            "Grab Vietnam",   "Công nghệ – Vận tải","1000+", "Crescent Plaza, Q.7, TP.HCM",            "https://grab.com/vn",           "Grab – siêu ứng dụng đặt xe, giao đồ ăn và thanh toán tại ĐNÁ.",        false, false),
            };

            foreach (var (email, name, industry, size, address, website, desc, verified, locked) in empData)
            {
                var u = await context.Users.FirstAsync(x => x.Email == email);
                string? whyWorkHereJson = email == "hr@fptsoft.com"
                    ? JsonSerializer.Serialize(new List<CompanyHighlight>
                    {
                        new()
                        {
                            Icon = "diversity_3",
                            Title = "Môi trường đa văn hóa",
                            Description = "Hợp tác cùng đội ngũ đa dạng trong môi trường năng động và cởi mở.",
                            IsHighlighted = false
                        },
                        new()
                        {
                            Icon = "rocket_launch",
                            Title = "Cơ hội thăng tiến",
                            Description = "Lộ trình phát triển sự nghiệp rõ ràng với chương trình đào tạo chuyên sâu.",
                            IsHighlighted = false
                        },
                        new()
                        {
                            Icon = "redeem",
                            Title = "Phúc lợi hấp dẫn",
                            Description = "Bảo hiểm sức khoẻ cao cấp, hỗ trợ ăn trưa, phòng gym hiện đại và các hoạt động teambuilding định kỳ hàng năm.",
                            IsHighlighted = true
                        }
                    })
                    : null;

                await context.Employers.AddAsync(new Employer
                {
                    UserID = u.UserID,
                    CompanyName = name,
                    Industry = industry,
                    CompanySize = size,
                    Address = address,
                    Website = website,
                    Description = desc,
                    WhyWorkHereJson = whyWorkHereJson,
                    IsVerified = verified,
                    IsLocked = locked,
                    CreatedAt = DateTime.UtcNow
                });
            }
            await context.SaveChangesAsync();

            // ── Candidate Profiles (10) ──
            var cpData = new[]
            {
                ("an.nguyen@gmail.com",   "Nam", "Hà Nội",          new DateTime(1998,3,15),  "Lập trình viên .NET 3 năm kinh nghiệm, thành thạo EF Core và SQL Server.",        3,  15_000_000m, true ),
                ("binh.le@gmail.com",     "Nữ",  "TP. Hồ Chí Minh", new DateTime(2000,7,20),  "Frontend Developer React.js, yêu thích thiết kế UI/UX sáng tạo.",                 2,  12_000_000m, true ),
                ("cuong.pham@gmail.com",  "Nam", "Đà Nẵng",          new DateTime(1997,11,5),  "Full-stack Developer Node.js + Vue.js, 4 năm kinh nghiệm.",                       4,  20_000_000m, true ),
                ("duyen.vo@gmail.com",    "Nữ",  "TP. Hồ Chí Minh", new DateTime(1999,5,12),  "Data Analyst, thành thạo Python Pandas, SQL và Power BI.",                         3,  18_000_000m, false),
                ("em.tran@gmail.com",     "Nam", "Hà Nội",          new DateTime(1996,9,25),  "DevOps Engineer, kinh nghiệm CI/CD với Docker và Kubernetes.",                    5,  30_000_000m, true ),
                ("giang.hoang@gmail.com", "Nữ",  "Cần Thơ",         new DateTime(2001,2,8),   "Tester (Manual + Automation) với Selenium và Postman.",                            2,  10_000_000m, true ),
                ("hung.bui@gmail.com",    "Nam", "Hải Phòng",       new DateTime(1998,6,18),  "Mobile Developer Flutter, đã publish 3 app lên Store.",                            3,  15_000_000m, true ),
                ("ky.do@gmail.com",       "Nam", "Bình Dương",       new DateTime(2002,4,30),  "Fresher IT mới tốt nghiệp, biết C# .NET và SQL cơ bản.",                          0,  8_000_000m,  true ),
                ("lan.dang@gmail.com",    "Nữ",  "Hà Nội",          new DateTime(1997,12,3),  "UI/UX Designer với 3 năm kinh nghiệm Figma và Adobe XD.",                          3,  18_000_000m, false),
                ("minh.cao@gmail.com",    "Nam", "TP. Hồ Chí Minh", new DateTime(1995,8,22),  "Java Backend Developer 5 năm, thành thạo Spring Boot và microservices.",           5,  35_000_000m, true ),
            };

            foreach (var (email, gender, address, dob, summary, expYears, salary, isOpen) in cpData)
            {
                var u = await context.Users.FirstAsync(x => x.Email == email);
                await context.CandidateProfiles.AddAsync(new CandidateProfile
                {
                    UserID = u.UserID,
                    FullName = u.FullName,
                    Gender = gender,
                    Address = address,
                    DateOfBirth = dob,
                    Summary = summary,
                    ExperienceYears = expYears,
                    DesiredSalary = salary,
                    IsOpenToWork = isOpen
                });
            }
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 6. CV FILES – 20 bản ghi (2 CV / ứng viên)
        // ══════════════════════════════════════════════════════════
        private static async Task SeedCvFiles(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles.ToListAsync();
            var cvs = new List<CvFile>();
            var names = new[] { "An", "Binh", "Cuong", "Duyen", "Em", "Giang", "Hung", "Ky", "Lan", "Minh" };

            for (int i = 0; i < profiles.Count; i++)
            {
                var n = names[i % names.Length];
                cvs.Add(new CvFile
                {
                    ProfileID = profiles[i].ProfileID,
                    FileName = $"CV_{n}_Main.pdf",
                    FilePath = $"/uploads/cvs/cv_{n.ToLower()}_main.pdf",
                    FileSize = 512_000 + i * 10_000,
                    IsDefault = true,
                    UploadedAt = DateTime.UtcNow.AddDays(-30 + i)
                });
                cvs.Add(new CvFile
                {
                    ProfileID = profiles[i].ProfileID,
                    FileName = $"CV_{n}_EN.pdf",
                    FilePath = $"/uploads/cvs/cv_{n.ToLower()}_en.pdf",
                    FileSize = 480_000 + i * 8_000,
                    IsDefault = false,
                    UploadedAt = DateTime.UtcNow.AddDays(-15 + i)
                });
            }

            await context.CvFiles.AddRangeAsync(cvs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 7. CANDIDATE SKILLS – 20 bản ghi (2 skill / ứng viên)
        // ══════════════════════════════════════════════════════════
        private static async Task SeedCandidateSkills(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles.ToListAsync();
            var skills = await context.Skills.ToListAsync();

            // Mỗi profile lấy 2 skill theo index
            var candidateSkills = new List<CandidateSkill>();
            ProficiencyLevel[] levels = { ProficiencyLevel.Beginner, ProficiencyLevel.Intermediate, ProficiencyLevel.Advanced, ProficiencyLevel.Expert };

            for (int i = 0; i < profiles.Count; i++)
            {
                var skill1 = skills[i % skills.Count];
                var skill2 = skills[(i + 1) % skills.Count];

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
                    ProficiencyLevel = levels[(i + 1) % 4],
                    YearsOfExperience = (decimal)(i % 3 + 1),
                    LastUsedDate = DateTime.Now.AddMonths(-((i + 1) % 12))
                });
            }

            await context.CandidateSkills.AddRangeAsync(candidateSkills);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 8. JOB POSTS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedJobPosts(AppDbContext context)
        {
            var employers = await context.Employers.ToListAsync();
            var itCatID = (await context.Categories.FirstAsync(c => c.Slug == "cong-nghe-thong-tin")).CategoryID;
            var mktCatID = (await context.Categories.FirstAsync(c => c.Slug == "marketing")).CategoryID;
            var finCatID = (await context.Categories.FirstAsync(c => c.Slug == "tai-chinh-ke-toan")).CategoryID;
            var desCatID = (await context.Categories.FirstAsync(c => c.Slug == "thiet-ke")).CategoryID;

            int E(int i) => employers[i % employers.Count].EmployerID;

            var jobs = new[]
            {
                new JobPost { EmployerID=E(0), CategoryID=itCatID,  Title=".NET Developer (C# / ASP.NET Core)",
                    Description="Phát triển và bảo trì ứng dụng web ASP.NET Core MVC, API RESTful.",
                    Requirements="- 1+ năm C#/.NET\n- SQL Server, EF Core\n- HTML/CSS cơ bản",
                    Benefits="- Lương cạnh tranh\n- Thưởng quý\n- Bảo hiểm cao cấp",
                    SalaryMin=15_000_000, SalaryMax=30_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true, ViewCount=320, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(0), CategoryID=itCatID,  Title="Frontend Developer – React.js",
                    Description="Xây dựng giao diện web hiện đại với React.js và TailwindCSS.",
                    Requirements="- 1+ năm React.js\n- HTML, CSS, JS\n- Git, REST API",
                    Benefits="- Remote 2 ngày/tuần\n- Môi trường startup năng động",
                    SalaryMin=12_000_000, SalaryMax=25_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(45), Status="Open", IsFeatured=true, ViewCount=210, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(0), CategoryID=itCatID,  Title="Thực tập sinh Backend Python",
                    Description="Hỗ trợ team backend phát triển tính năng mới bằng Python/Django.",
                    Requirements="- Sinh viên năm 3-4 CNTT\n- Python cơ bản\n- Chăm chỉ, ham học",
                    Benefits="- Phụ cấp 3-5 triệu/tháng\n- Xét tuyển chính thức sau thực tập",
                    SalaryMin=3_000_000, SalaryMax=5_000_000, SalaryNegotiable=false,
                    JobType="Internship", Location="Hà Nội", ExperienceLevel="Fresher",
                    Deadline=DateTime.UtcNow.AddDays(60), Status="Open", IsFeatured=false, ViewCount=95, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(1), CategoryID=itCatID,  Title="Backend Engineer – Java Spring Boot",
                    Description="Thiết kế và phát triển microservices hiệu suất cao cho nền tảng game.",
                    Requirements="- 2+ năm Java Spring Boot\n- Kafka, Redis\n- Kinh nghiệm scale hệ thống",
                    Benefits="- Stock option\n- 13+ tháng lương\n- Laptop MacBook Pro",
                    SalaryMin=25_000_000, SalaryMax=50_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true, ViewCount=450, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(1), CategoryID=itCatID,  Title="Senior DevOps Engineer",
                    Description="Xây dựng hạ tầng cloud, CI/CD pipeline cho hệ thống triệu người dùng.",
                    Requirements="- 3+ năm DevOps\n- Docker, K8s, Terraform\n- AWS hoặc GCP",
                    Benefits="- 40-70 triệu\n- Remote 100%\n- Ngân sách học tập 20tr/năm",
                    SalaryMin=40_000_000, SalaryMax=70_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(25), Status="Open", IsFeatured=true, ViewCount=380, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(2), CategoryID=itCatID,  Title="Data Engineer – Python / Spark",
                    Description="Xây dựng data pipeline xử lý hàng triệu đơn hàng/ngày.",
                    Requirements="- Python, SQL\n- Apache Spark, Airflow\n- Data warehouse",
                    Benefits="- Thưởng dự án\n- Đội ngũ Data mạnh\n- Free lunch",
                    SalaryMin=20_000_000, SalaryMax=40_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(35), Status="Open", IsFeatured=false, ViewCount=170, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(2), CategoryID=itCatID,  Title="iOS Developer – Swift",
                    Description="Phát triển tính năng mới và tối ưu hiệu năng ứng dụng iOS Tiki.",
                    Requirements="- 2+ năm Swift\n- UIKit, SwiftUI\n- App Store submission",
                    Benefits="- MacBook + iPhone mới nhất\n- Flexible hours\n- Thưởng cuối năm",
                    SalaryMin=22_000_000, SalaryMax=45_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(40), Status="Open", IsFeatured=true, ViewCount=260, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(3), CategoryID=itCatID,  Title="Android Developer – Kotlin",
                    Description="Xây dựng tính năng thanh toán và ví điện tử trên Android.",
                    Requirements="- 2+ năm Kotlin/Android\n- Bảo mật tài chính\n- Payment SDK",
                    Benefits="- Bảo hiểm gia đình\n- WFH thứ 6",
                    SalaryMin=20_000_000, SalaryMax=38_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=140, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(3), CategoryID=finCatID, Title="Risk Analyst – Fintech",
                    Description="Phân tích rủi ro tín dụng và gian lận trong hệ thống thanh toán.",
                    Requirements="- Tốt nghiệp Tài chính/Kinh tế\n- SQL, Python cơ bản\n- Risk model",
                    Benefits="- Lương + thưởng KPI\n- Đào tạo fintech chuyên sâu",
                    SalaryMin=18_000_000, SalaryMax=30_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(20), Status="Open", IsFeatured=false, ViewCount=88, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(4), CategoryID=itCatID,  Title="Senior .NET Architect",
                    Description="Thiết kế kiến trúc hệ thống VinID và hệ sinh thái Vin.",
                    Requirements="- 5+ năm .NET\n- Microservices, event-driven\n- Azure/AWS",
                    Benefits="- 60-90 triệu\n- Xe đưa đón\n- Ưu đãi mua nhà Vinhomes",
                    SalaryMin=60_000_000, SalaryMax=90_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true, ViewCount=520, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(4), CategoryID=mktCatID, Title="Performance Marketing Manager",
                    Description="Lên kế hoạch và triển khai chiến dịch Google/Facebook Ads quy mô lớn.",
                    Requirements="- 3+ năm performance marketing\n- Google Ads, Meta Ads\n- Phân tích số liệu",
                    Benefits="- Ngân sách marketing lớn\n- Thưởng KPI",
                    SalaryMin=20_000_000, SalaryMax=40_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(28), Status="Open", IsFeatured=false, ViewCount=105, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(5), CategoryID=itCatID,  Title="Machine Learning Engineer",
                    Description="Xây dựng mô hình gợi ý sản phẩm và xếp hạng tìm kiếm cho Shopee.",
                    Requirements="- Python, TensorFlow/PyTorch\n- Recommendation system\n- MLOps",
                    Benefits="- Dữ liệu lớn\n- Công bố paper\n- Lương cao cấp",
                    SalaryMin=35_000_000, SalaryMax=65_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true, ViewCount=610, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(5), CategoryID=desCatID, Title="Senior UI/UX Designer",
                    Description="Thiết kế trải nghiệm người dùng cho app Shopee iOS và Android.",
                    Requirements="- 3+ năm UI/UX\n- Figma thành thạo\n- Portfolio mạnh",
                    Benefits="- Apple devices mới nhất\n- Design system riêng",
                    SalaryMin=25_000_000, SalaryMax=45_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(35), Status="Open", IsFeatured=true, ViewCount=290, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(6), CategoryID=itCatID,  Title="Node.js Backend Developer",
                    Description="Phát triển API cho hệ thống chat real-time Zalo hàng triệu concurrent users.",
                    Requirements="- 2+ năm Node.js\n- WebSocket, Redis Pub/Sub\n- High-load system",
                    Benefits="- Hệ thống triệu user\n- Sản phẩm made-in-VN\n- Thưởng KPI",
                    SalaryMin=20_000_000, SalaryMax=38_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(25), Status="Open", IsFeatured=false, ViewCount=195, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(6), CategoryID=itCatID,  Title="QA Automation Engineer",
                    Description="Viết automation test cho web và mobile, tích hợp vào CI/CD pipeline.",
                    Requirements="- 1+ năm Selenium/Appium\n- Java hoặc Python\n- Agile/Scrum",
                    Benefits="- Cấp chứng chỉ ISTQB\n- Giờ giấc linh hoạt",
                    SalaryMin=13_000_000, SalaryMax=22_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=78, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(7), CategoryID=finCatID, Title="Core Banking Developer – T24",
                    Description="Phát triển và tích hợp giải pháp core banking T24 cho ngân hàng số.",
                    Requirements="- 2+ năm T24 Temenos\n- jBC, OFS\n- Banking domain",
                    Benefits="- Lương top-market\n- Bảo hiểm 24/7\n- Chứng chỉ quốc tế",
                    SalaryMin=25_000_000, SalaryMax=50_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=true, ViewCount=230, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(7), CategoryID=finCatID, Title="Business Analyst – Digital Banking",
                    Description="Phân tích nghiệp vụ ngân hàng số, viết tài liệu yêu cầu cho team Dev.",
                    Requirements="- 2+ năm BA\n- Sản phẩm ngân hàng\n- Tiếng Anh tốt",
                    Benefits="- Môi trường tài chính chuyên nghiệp\n- ESOP cổ phiếu",
                    SalaryMin=18_000_000, SalaryMax=32_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Middle",
                    Deadline=DateTime.UtcNow.AddDays(20), Status="Open", IsFeatured=false, ViewCount=112, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(8), CategoryID=itCatID,  Title="Flutter Developer",
                    Description="Phát triển ứng dụng Grab Driver và Grab Passenger trên Flutter.",
                    Requirements="- 1+ năm Flutter/Dart\n- Maps SDK\n- App Store/Play Store",
                    Benefits="- GrabFood miễn phí\n- GrabCar ưu đãi\n- Môi trường quốc tế",
                    SalaryMin=18_000_000, SalaryMax=35_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=148, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(8), CategoryID=mktCatID, Title="Content Marketing Executive",
                    Description="Sản xuất nội dung blog, social media và email marketing cho Grab Vietnam.",
                    Requirements="- 1+ năm content marketing\n- Viết tốt TV/TA\n- SEO cơ bản",
                    Benefits="- Môi trường đa văn hóa\n- GrabCar miễn phí\n- Trợ cấp ăn trưa",
                    SalaryMin=10_000_000, SalaryMax=18_000_000, SalaryNegotiable=false,
                    JobType="FullTime", Location="TP. Hồ Chí Minh", ExperienceLevel="Junior",
                    Deadline=DateTime.UtcNow.AddDays(15), Status="Open", IsFeatured=false, ViewCount=63, CreatedAt=DateTime.UtcNow },

                new JobPost { EmployerID=E(0), CategoryID=itCatID,  Title="Scrum Master / Agile Coach",
                    Description="Hướng dẫn team Agile, tổ chức ceremonies, loại bỏ impediment.",
                    Requirements="- Chứng chỉ CSM/PSM\n- 3+ năm Scrum Master\n- Kỹ năng coaching",
                    Benefits="- Ngân sách coaching 30tr/năm\n- Hội thảo quốc tế",
                    SalaryMin=25_000_000, SalaryMax=45_000_000, SalaryNegotiable=true,
                    JobType="FullTime", Location="Hà Nội", ExperienceLevel="Senior",
                    Deadline=DateTime.UtcNow.AddDays(30), Status="Open", IsFeatured=false, ViewCount=87, CreatedAt=DateTime.UtcNow },
            };

            await context.JobPosts.AddRangeAsync(jobs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 9. APPLICATIONS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedApplications(AppDbContext context)
        {
            var profiles = await context.CandidateProfiles.ToListAsync();
            var jobs = await context.JobPosts.ToListAsync();
            var cvFiles = await context.CvFiles.Where(c => c.IsDefault).ToListAsync();

            string[] statuses = { "Pending", "Reviewing", "Interview", "Offered", "Rejected" };
            string[] letters =
            {
                "Kính gửi, tôi rất quan tâm đến vị trí này và tin rằng kinh nghiệm của tôi phù hợp.",
                "Tôi có 3 năm kinh nghiệm trong lĩnh vực này và mong được đóng góp cho công ty.",
                "Với kỹ năng và đam mê, tôi tự tin có thể hoàn thành tốt các yêu cầu công việc.",
                "Đây là cơ hội tôi đang tìm kiếm để phát triển sự nghiệp. Rất mong nhận được phản hồi.",
                "Tôi đã theo dõi công ty từ lâu và muốn trở thành một phần của đội ngũ.",
                "Kỹ năng lập trình và tư duy phân tích của tôi sẽ là tài sản quý giá cho team.",
                "Tôi đã tham khảo kỹ JD và tự tin đáp ứng được trên 90% yêu cầu đặt ra.",
                "Mong muốn đóng góp vào sự phát triển của công ty với nhiệt huyết và chuyên môn.",
                "Tôi đang tìm kiếm môi trường thách thức để phát triển và công ty này là lựa chọn lý tưởng.",
                "Với background đa dạng, tôi có thể đảm nhận vai trò này ngay từ đầu.",
                "Tôi có kinh nghiệm làm việc trong môi trường Agile và hiểu rõ quy trình phát triển phần mềm.",
                "Sản phẩm của công ty luôn là nguồn cảm hứng của tôi, xin được ứng tuyển.",
                "Thành tích nổi bật: giảm 30% thời gian deploy nhờ cải thiện CI/CD pipeline.",
                "Tôi vừa hoàn thành khóa học chuyên sâu và sẵn sàng áp dụng ngay vào công việc.",
                "Mong được thảo luận thêm về vị trí này trong buổi phỏng vấn.",
                "Tôi đã làm việc tại môi trường tương tự và hiểu sâu về domain này.",
                "Portfolio của tôi bao gồm các dự án thực tế liên quan trực tiếp đến JD.",
                "Tôi sẵn sàng bắt đầu ngay lập tức nếu được chấp nhận.",
                "Tiếng Anh thành thạo, có thể làm việc với đối tác nước ngoài.",
                "Rất mong được gặp gỡ team và tìm hiểu thêm về văn hóa công ty."
            };

            // Tạo 20 application với cặp (profile, job) không trùng nhau
            var apps = new List<Application>();
            var usedPairs = new HashSet<(int, int)>();

            int count = 0;
            for (int i = 0; i < profiles.Count && count < 20; i++)
            {
                for (int j = 0; j < jobs.Count && count < 20; j++)
                {
                    var key = (profiles[i].ProfileID, jobs[j].JobID);
                    if (usedPairs.Contains(key)) continue;
                    usedPairs.Add(key);

                    var cv = cvFiles.FirstOrDefault(c => c.ProfileID == profiles[i].ProfileID);
                    apps.Add(new Application
                    {
                        JobID = jobs[j].JobID,
                        ProfileID = profiles[i].ProfileID,
                        CVID = cv?.CvID,
                        CoverLetter = letters[count % letters.Length],
                        Status = statuses[count % statuses.Length],
                        AppliedAt = DateTime.UtcNow.AddDays(-count),
                        UpdatedAt = count % 2 == 0 ? DateTime.UtcNow.AddDays(-count + 1) : null
                    });
                    count++;
                }
            }

            await context.Applications.AddRangeAsync(apps);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 10. SAVED JOBS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedSavedJobs(AppDbContext context)
        {
            var candidateUsers = await context.Users.Where(u => u.Role == "Candidate").ToListAsync();
            var jobs = await context.JobPosts.ToListAsync();

            var saved = new List<SavedJob>();
            var usedPairs = new HashSet<(int, int)>();

            int count = 0;
            for (int i = 0; i < candidateUsers.Count && count < 20; i++)
            {
                for (int j = 0; j < jobs.Count && count < 20; j++)
                {
                    var key = (candidateUsers[i].UserID, jobs[j].JobID);
                    if (usedPairs.Contains(key)) continue;
                    usedPairs.Add(key);

                    saved.Add(new SavedJob
                    {
                        UserID = candidateUsers[i].UserID,
                        JobID = jobs[j].JobID,
                        SavedAt = DateTime.UtcNow.AddDays(-count)
                    });
                    count++;
                }
            }

            await context.SavedJobs.AddRangeAsync(saved);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 11. NOTIFICATIONS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedNotifications(AppDbContext context)
        {
            var users = await context.Users.ToListAsync();
            var jobs = await context.JobPosts.ToListAsync();

            var notifs = new[]
            {
                new Notification { UserID=users[1].UserID,  Title="Hồ sơ được xét duyệt",             Content="Hồ sơ ứng tuyển .NET Developer của bạn đang được xem xét.",           Type="Application", IsRead=false, RelatedID=jobs[0].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-1)  },
                new Notification { UserID=users[2].UserID,  Title="Mời phỏng vấn",                    Content="Chúc mừng! Bạn được mời phỏng vấn vị trí Frontend Developer.",          Type="Application", IsRead=false, RelatedID=jobs[1].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-2)  },
                new Notification { UserID=users[3].UserID,  Title="Hồ sơ bị từ chối",                 Content="Rất tiếc, hồ sơ của bạn không phù hợp với vị trí hiện tại.",            Type="Application", IsRead=true,  RelatedID=jobs[2].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-5)  },
                new Notification { UserID=users[4].UserID,  Title="Nhận được offer",                   Content="Chúc mừng! Bạn đã nhận được offer từ VNG Corporation.",                  Type="Application", IsRead=false, RelatedID=jobs[3].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-3)  },
                new Notification { UserID=users[5].UserID,  Title="Tin tuyển dụng mới phù hợp",       Content="Có 3 tin tuyển dụng mới phù hợp với kỹ năng của bạn.",                  Type="System",      IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-6)  },
                new Notification { UserID=users[6].UserID,  Title="Nhắc nhở deadline ứng tuyển",      Content="Tin tuyển dụng 'iOS Developer' sẽ hết hạn trong 2 ngày.",               Type="System",      IsRead=true,  RelatedID=jobs[6].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-8)  },
                new Notification { UserID=users[7].UserID,  Title="Thanh toán thành công",             Content="Gói Pro đã được kích hoạt. Hiệu lực đến 30/07/2026.",                   Type="Payment",     IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-4)  },
                new Notification { UserID=users[8].UserID,  Title="Hồ sơ đang được xem xét",          Content="Nhà tuyển dụng Tiki đang xem xét hồ sơ của bạn.",                       Type="Application", IsRead=true,  RelatedID=jobs[6].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-10) },
                new Notification { UserID=users[9].UserID,  Title="Tài khoản xác thực thành công",    Content="Công ty MoMo đã được xác thực. Bạn có thể đăng tin tuyển dụng.",         Type="System",      IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-12) },
                new Notification { UserID=users[10].UserID, Title="CV của bạn được tải về",            Content="Nhà tuyển dụng FPT Software đã tải CV của bạn.",                         Type="Application", IsRead=false, RelatedID=jobs[0].JobID,  CreatedAt=DateTime.UtcNow.AddHours(-7)  },
                new Notification { UserID=users[11].UserID, Title="Gói dịch vụ sắp hết hạn",          Content="Gói Enterprise của bạn sẽ hết hạn sau 7 ngày. Hãy gia hạn ngay.",        Type="Payment",     IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddDays(-1)   },
                new Notification { UserID=users[12].UserID, Title="Lịch phỏng vấn được xác nhận",     Content="Phỏng vấn với Shopee lúc 9:00 ngày 28/06/2026 đã được xác nhận.",        Type="Application", IsRead=true,  RelatedID=jobs[11].JobID, CreatedAt=DateTime.UtcNow.AddHours(-9)  },
                new Notification { UserID=users[13].UserID, Title="Hệ thống bảo trì",                 Content="Hệ thống sẽ bảo trì từ 01:00-03:00 ngày 26/06/2026.",                   Type="System",      IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-15) },
                new Notification { UserID=users[14].UserID, Title="Hồ sơ nổi bật trong tuần",         Content="Hồ sơ của bạn nằm trong top 10% được xem nhiều nhất tuần này.",          Type="System",      IsRead=true,  RelatedID=null,           CreatedAt=DateTime.UtcNow.AddDays(-2)   },
                new Notification { UserID=users[15].UserID, Title="Nhà tuyển dụng theo dõi bạn",      Content="Zalo đã thêm bạn vào danh sách ứng viên tiềm năng.",                    Type="Application", IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-11) },
                new Notification { UserID=users[16].UserID, Title="Thanh toán thất bại",               Content="Giao dịch thanh toán gói Pro Plus thất bại. Vui lòng thử lại.",          Type="Payment",     IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddHours(-13) },
                new Notification { UserID=users[17].UserID, Title="Ứng viên mới ứng tuyển",           Content="Có 5 ứng viên mới ứng tuyển vào vị trí Flutter Developer.",              Type="Application", IsRead=true,  RelatedID=jobs[17].JobID, CreatedAt=DateTime.UtcNow.AddHours(-14) },
                new Notification { UserID=users[18].UserID, Title="Hồ sơ cần cập nhật",               Content="Hồ sơ của bạn chưa có ảnh đại diện. Hãy cập nhật để nổi bật hơn.",      Type="System",      IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddDays(-3)   },
                new Notification { UserID=users[19].UserID, Title="Chào mừng đến JobConnect!",        Content="Cảm ơn bạn đã đăng ký. Hãy hoàn thiện hồ sơ để tìm việc hiệu quả hơn.", Type="System",      IsRead=true,  RelatedID=null,           CreatedAt=DateTime.UtcNow.AddDays(-5)   },
                new Notification { UserID=users[0].UserID,  Title="Báo cáo hệ thống tuần",            Content="Tuần này: 150 ứng viên mới, 45 tin tuyển dụng, 320 đơn ứng tuyển.",     Type="System",      IsRead=false, RelatedID=null,           CreatedAt=DateTime.UtcNow.AddDays(-1)   },
            };

            await context.Notifications.AddRangeAsync(notifs);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 12. TRANSACTIONS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedTransactions(AppDbContext context)
        {
            var employers = await context.Employers.ToListAsync();
            var packages = await context.ServicePackages.ToListAsync();

            string[] methods = { "BankTransfer", "VNPay", "Momo", "ZaloPay", "Cash" };
            string[] statuses = { "Completed", "Completed", "Completed", "Pending", "Failed" };

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
                    Status = statuses[i % statuses.Length],
                    ExpiredAt = DateTime.UtcNow.AddDays(pkg.DurationDays),
                    CreatedAt = DateTime.UtcNow.AddDays(-i)
                });
            }

            await context.Transactions.AddRangeAsync(transactions);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 13. BLOG POSTS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedBlogPosts(AppDbContext context)
        {
            var admin = await context.Users.FirstAsync(u => u.Role == "Admin");

            // Khai báo tường minh kiểu tuple để DateTime? chấp nhận cả giá trị lẫn null
            var posts = new List<(string Title, string Slug, string Excerpt, bool IsPublished, DateTime? PublishedAt)>
            {
                ("10 kỹ năng IT hot nhất năm 2026",                   "10-ky-nang-it-hot-nhat-2026",         "Khám phá những kỹ năng công nghệ được săn đón nhất trong năm 2026.",                   true,  DateTime.UtcNow.AddDays(-30)),
                ("Cách viết CV xin việc IT ấn tượng",                 "cach-viet-cv-it-an-tuong",            "Hướng dẫn chi tiết cách tạo CV nổi bật giúp bạn được mời phỏng vấn.",                 true,  DateTime.UtcNow.AddDays(-28)),
                ("Lương lập trình viên tại Việt Nam năm 2026",        "luong-lap-trinh-vien-2026",           "Khảo sát mức lương thực tế của các vị trí IT phổ biến tại Việt Nam.",                  true,  DateTime.UtcNow.AddDays(-25)),
                ("Remote work – xu hướng hay trở lại văn phòng?",     "remote-work-hay-van-phong",           "Phân tích ưu nhược điểm của làm việc từ xa và xu hướng tuyển dụng hiện nay.",          true,  DateTime.UtcNow.AddDays(-22)),
                ("Fresher IT: Làm gì để có job đầu tiên?",            "fresher-it-lam-gi-de-co-job",         "Lộ trình thực tế cho sinh viên IT mới ra trường tìm kiếm công việc.",                  true,  DateTime.UtcNow.AddDays(-20)),
                ("Top 5 công ty công nghệ tốt nhất để làm việc ở VN", "top-5-cong-ty-cong-nghe-tot-nhat",   "Đánh giá môi trường làm việc, phúc lợi và văn hóa của 5 công ty IT hàng đầu.",         true,  DateTime.UtcNow.AddDays(-18)),
                ("Microservices vs Monolithic – chọn gì năm 2026?",   "microservices-vs-monolithic",         "So sánh kiến trúc phần mềm và khi nào nên dùng microservices.",                        true,  DateTime.UtcNow.AddDays(-15)),
                ("Bí quyết vượt qua phỏng vấn kỹ thuật Google",       "bi-quyet-phong-van-google",           "Các bước chuẩn bị và chiến lược giải bài leetcode để pass phỏng vấn big tech.",        true,  DateTime.UtcNow.AddDays(-13)),
                ("AI có thay thế lập trình viên không?",               "ai-co-thay-the-lap-trinh-vien",       "Phân tích tác động của AI generative đối với nghề lập trình trong tương lai.",         true,  DateTime.UtcNow.AddDays(-10)),
                ("Học DevOps từ đầu – lộ trình 6 tháng",              "hoc-devops-tu-dau-6-thang",           "Lộ trình học DevOps từ căn bản: Linux, Docker, K8s, CI/CD và Cloud.",                  true,  DateTime.UtcNow.AddDays(-8) ),
                ("UX Writing – nghề mới hot trong ngành thiết kế",     "ux-writing-nghe-moi-hot",             "Tìm hiểu về UX Writing và cơ hội nghề nghiệp trong lĩnh vực thiết kế sản phẩm.",      true,  DateTime.UtcNow.AddDays(-6) ),
                ("Làm thế nào để đàm phán lương hiệu quả?",           "dam-phan-luong-hieu-qua",             "Chiến lược và script thực tế giúp bạn đàm phán mức lương mong muốn.",                 true,  DateTime.UtcNow.AddDays(-5) ),
                ("Fintech Vietnam 2026 – cơ hội cho dev",              "fintech-vietnam-2026",                "Tổng quan thị trường fintech và các vị trí kỹ thuật đang được tuyển dụng.",             true,  DateTime.UtcNow.AddDays(-4) ),
                ("Chuyển ngành sang IT – có muộn không?",              "chuyen-nganh-sang-it",                "Kinh nghiệm thực tế từ những người chuyển sang IT sau 25 tuổi.",                      true,  DateTime.UtcNow.AddDays(-3) ),
                ("Portfolio dành cho Frontend Developer",              "portfolio-frontend-developer",        "Cách xây dựng portfolio ấn tượng và những dự án nên có khi apply việc.",              true,  DateTime.UtcNow.AddDays(-2) ),
                ("Clean Code – nguyên tắc nào quan trọng nhất?",      "clean-code-nguyen-tac-quan-trong",    "Điểm lại các nguyên tắc Clean Code và cách áp dụng trong dự án thực tế.",             true,  DateTime.UtcNow.AddDays(-1) ),
                ("Kinh nghiệm onboard tại startup vs corporate",       "startup-vs-corporate-onboard",        "So sánh trải nghiệm làm việc và phát triển sự nghiệp tại startup và tập đoàn lớn.",  false, null),
                ("Golang – ngôn ngữ có nên học năm 2026?",            "golang-co-nen-hoc-2026",              "Đánh giá Golang từ góc độ thị trường tuyển dụng và độ khó học.",                      false, null),
                ("Xây dựng thương hiệu cá nhân cho dev",              "xay-dung-thuong-hieu-ca-nhan-dev",    "Hướng dẫn xây dựng personal brand qua GitHub, LinkedIn và blog cá nhân.",             false, null),
                ("Data Science vs Data Engineering – chọn gì?",       "data-science-vs-data-engineering",    "Phân biệt hai con đường sự nghiệp phổ biến trong ngành dữ liệu.",                    false, null),
            };

            var blogPosts = posts.Select(p => new BlogPost
            {
                AuthorID = admin.UserID,
                Title = p.Title,
                Slug = p.Slug,
                Excerpt = p.Excerpt,
                Content = $"<h2>{p.Title}</h2><p>{p.Excerpt}</p><p>Nội dung bài viết đang được cập nhật...</p>",
                IsPublished = p.IsPublished,
                PublishedAt = p.PublishedAt,                    // DateTime? – OK
                CreatedAt = p.PublishedAt.HasValue ? p.PublishedAt.Value : DateTime.UtcNow
            }).ToArray();

            await context.BlogPosts.AddRangeAsync(blogPosts);
            await context.SaveChangesAsync();
        }

        // ══════════════════════════════════════════════════════════
        // 14. SYSTEM LOGS – 20 bản ghi
        // ══════════════════════════════════════════════════════════
        private static async Task SeedSystemLogs(AppDbContext context)
        {
            var users = await context.Users.ToListAsync();

            string[] ips = { "113.161.12.45", "42.112.88.10", "203.171.0.22", "14.232.4.66", "1.53.200.100" };
            var logs = new[]
            {
                new SystemLog { UserID=users[0].UserID,  Action="LOGIN",             IPAddress=ips[0], Detail="Admin đăng nhập thành công.",                        CreatedAt=DateTime.UtcNow.AddHours(-1)  },
                new SystemLog { UserID=users[1].UserID,  Action="LOGIN",             IPAddress=ips[1], Detail="Employer FPT đăng nhập.",                            CreatedAt=DateTime.UtcNow.AddHours(-2)  },
                new SystemLog { UserID=users[2].UserID,  Action="POST_JOB",          IPAddress=ips[2], Detail="VNG đăng tin: Backend Engineer – Java Spring Boot.", CreatedAt=DateTime.UtcNow.AddHours(-3)  },
                new SystemLog { UserID=users[3].UserID,  Action="APPLY_JOB",         IPAddress=ips[3], Detail="Ứng viên Tiki apply vị trí iOS Developer.",          CreatedAt=DateTime.UtcNow.AddHours(-4)  },
                new SystemLog { UserID=users[4].UserID,  Action="UPDATE_PROFILE",    IPAddress=ips[4], Detail="MoMo cập nhật thông tin công ty.",                   CreatedAt=DateTime.UtcNow.AddHours(-5)  },
                new SystemLog { UserID=users[5].UserID,  Action="PAYMENT",           IPAddress=ips[0], Detail="Vingroup thanh toán gói Enterprise 2.490.000 VNĐ.",  CreatedAt=DateTime.UtcNow.AddHours(-6)  },
                new SystemLog { UserID=users[6].UserID,  Action="SAVE_JOB",          IPAddress=ips[1], Detail="Ứng viên lưu tin: Machine Learning Engineer.",       CreatedAt=DateTime.UtcNow.AddHours(-7)  },
                new SystemLog { UserID=users[7].UserID,  Action="UPLOAD_CV",         IPAddress=ips[2], Detail="Zalo ứng viên upload CV mới.",                       CreatedAt=DateTime.UtcNow.AddHours(-8)  },
                new SystemLog { UserID=users[8].UserID,  Action="LOGIN_FAIL",        IPAddress=ips[3], Detail="Đăng nhập thất bại – sai mật khẩu lần 1.",           CreatedAt=DateTime.UtcNow.AddHours(-9)  },
                new SystemLog { UserID=users[9].UserID,  Action="LOGOUT",            IPAddress=ips[4], Detail="Grab employer đăng xuất.",                           CreatedAt=DateTime.UtcNow.AddHours(-10) },
                new SystemLog { UserID=users[10].UserID, Action="REGISTER",          IPAddress=ips[0], Detail="Ứng viên mới đăng ký tài khoản.",                    CreatedAt=DateTime.UtcNow.AddHours(-11) },
                new SystemLog { UserID=users[11].UserID, Action="CHANGE_PASSWORD",   IPAddress=ips[1], Detail="Đổi mật khẩu thành công.",                          CreatedAt=DateTime.UtcNow.AddHours(-12) },
                new SystemLog { UserID=users[12].UserID, Action="VIEW_JOB",          IPAddress=ips[2], Detail="Xem chi tiết tin: Senior .NET Architect.",           CreatedAt=DateTime.UtcNow.AddHours(-13) },
                new SystemLog { UserID=users[13].UserID, Action="DELETE_JOB",        IPAddress=ips[3], Detail="Admin xoá tin tuyển dụng vi phạm chính sách.",       CreatedAt=DateTime.UtcNow.AddHours(-14) },
                new SystemLog { UserID=users[14].UserID, Action="VERIFY_EMPLOYER",   IPAddress=ips[4], Detail="Admin xác thực công ty Grab Vietnam.",               CreatedAt=DateTime.UtcNow.AddHours(-15) },
                new SystemLog { UserID=users[15].UserID, Action="APPLY_JOB",         IPAddress=ips[0], Detail="Ứng viên apply: QA Automation Engineer.",            CreatedAt=DateTime.UtcNow.AddHours(-16) },
                new SystemLog { UserID=users[16].UserID, Action="PAYMENT_FAIL",      IPAddress=ips[1], Detail="Thanh toán gói Pro Plus thất bại – timeout.",        CreatedAt=DateTime.UtcNow.AddHours(-17) },
                new SystemLog { UserID=users[17].UserID, Action="UPDATE_JOB",        IPAddress=ips[2], Detail="Cập nhật tin tuyển dụng: Flutter Developer.",        CreatedAt=DateTime.UtcNow.AddHours(-18) },
                new SystemLog { UserID=users[18].UserID, Action="BAN_USER",          IPAddress=ips[3], Detail="Admin khóa tài khoản vi phạm điều khoản sử dụng.",  CreatedAt=DateTime.UtcNow.AddHours(-19) },
                new SystemLog { UserID=null,             Action="SYSTEM_BACKUP",     IPAddress="127.0.0.1", Detail="Hệ thống tự động backup database lúc 02:00.",   CreatedAt=DateTime.UtcNow.AddHours(-20) },
            };

            await context.SystemLogs.AddRangeAsync(logs);
            await context.SaveChangesAsync();
        }
    }
}