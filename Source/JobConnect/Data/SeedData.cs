using JobConnect.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace JobConnect.Data
{
    public static class SeedData
    {
        public static async Task Initialize(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Nếu đã có dữ liệu thì bỏ qua
            if (await context.Users.AnyAsync()) return;

            await SeedUsers(context);
            await SeedCategories(context);
            await SeedSkills(context);
            await SeedServicePackages(context);
            await SeedEmployersAndProfiles(context);
            await SeedJobPosts(context);

            await context.SaveChangesAsync();
            Console.WriteLine("✅ SeedData đã được thêm thành công!");
        }

        private static async Task SeedUsers(AppDbContext context)
        {
            var users = new[]
            {
                new User
                {
                    Email = "admin@jobconnect.vn",
                    PasswordHash = "$2a$12$kbsNIGHBywXo9EWFA6JtmuTNjkJ5SyKdxhx/0X.V0MyT5KPMCM.72", // Admin@123
                    Role = "Admin",
                    FullName = "Quản trị viên",
                    PhoneNumber = "0987654321",
                    Status = "Active",
                    CreatedAt = DateTime.UtcNow
                },
                new User
                {
                    Email = "hr@fptsoft.com",
                    PasswordHash = "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/MIJthivqi", // Test@123
                    Role = "Employer",
                    FullName = "Nguyễn Thị HR",
                    PhoneNumber = "0909123456",
                    Status = "Active",
                    CreatedAt = DateTime.UtcNow
                },
                new User
                {
                    Email = "candidate@gmail.com",
                    PasswordHash = "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/MIJthivqi", // Test@123
                    Role = "Candidate",
                    FullName = "Trần Văn Ứng Viên",
                    PhoneNumber = "0901234567",
                    Status = "Active",
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Users.AddRangeAsync(users);
            await context.SaveChangesAsync();
        }

        private static async Task SeedCategories(AppDbContext context)
        {
            var categories = new[]
            {
                new Category { Name = "Công nghệ thông tin", Type = "Industry", Slug = "cong-nghe-thong-tin" },
                new Category { Name = "Marketing & Truyền thông", Type = "Industry", Slug = "marketing" },
                new Category { Name = "Tài chính – Kế toán", Type = "Industry", Slug = "tai-chinh-ke-toan" },
                new Category { Name = "Kỹ thuật – Cơ khí", Type = "Industry", Slug = "ky-thuat-co-khi" },
                new Category { Name = "Y tế – Dược phẩm", Type = "Industry", Slug = "y-te-duoc-pham" },
                new Category { Name = "Thiết kế – Mỹ thuật", Type = "Industry", Slug = "thiet-ke" },

                new Category { Name = "Hà Nội", Type = "Location", Slug = "ha-noi" },
                new Category { Name = "TP. Hồ Chí Minh", Type = "Location", Slug = "ho-chi-minh" },
                new Category { Name = "Đà Nẵng", Type = "Location", Slug = "da-nang" },
                new Category { Name = "Cần Thơ", Type = "Location", Slug = "can-tho" },

                new Category { Name = "Fresher", Type = "Level", Slug = "fresher" },
                new Category { Name = "Junior", Type = "Level", Slug = "junior" },
                new Category { Name = "Middle", Type = "Level", Slug = "middle" },
                new Category { Name = "Senior", Type = "Level", Slug = "senior" },

                new Category { Name = "FullTime", Type = "JobType", Slug = "full-time" },
                new Category { Name = "PartTime", Type = "JobType", Slug = "part-time" },
                new Category { Name = "Internship", Type = "JobType", Slug = "internship" },
                new Category { Name = "Remote", Type = "JobType", Slug = "remote" }
            };

            await context.Categories.AddRangeAsync(categories);
            await context.SaveChangesAsync();
        }

        private static async Task SeedSkills(AppDbContext context)
        {
            var skills = new[]
            {
                new Skill { Name = "JavaScript" }, new Skill { Name = "Python" },
                new Skill { Name = "Java" }, new Skill { Name = "C#" },
                new Skill { Name = ".NET Core" }, new Skill { Name = "React.js" },
                new Skill { Name = "Angular" }, new Skill { Name = "SQL Server" },
                new Skill { Name = "MySQL" }, new Skill { Name = "MongoDB" },
                new Skill { Name = "PHP" }, new Skill { Name = "HTML/CSS" },
                new Skill { Name = "Figma" }, new Skill { Name = "Project Management" },
                new Skill { Name = "English" }
            };

            await context.Skills.AddRangeAsync(skills);
            await context.SaveChangesAsync();
        }

        private static async Task SeedServicePackages(AppDbContext context)
        {
            var packages = new[]
            {
                new ServicePackage
                {
                    Name = "Miễn phí",
                    Price = 0,
                    DurationDays = 30,
                    MaxJobPosts = 3,
                    MaxFeatured = 0,
                    Description = "Đăng tối đa 3 tin/tháng, không nổi bật",
                    IsActive = true
                },
                new ServicePackage
                {
                    Name = "Pro",
                    Price = 990000,
                    DurationDays = 30,
                    MaxJobPosts = 15,
                    MaxFeatured = 3,
                    Description = "15 tin/tháng, 3 tin nổi bật, hỗ trợ ưu tiên",
                    IsActive = true
                },
                new ServicePackage
                {
                    Name = "Enterprise",
                    Price = 2490000,
                    DurationDays = 30,
                    MaxJobPosts = 999,
                    MaxFeatured = 10,
                    Description = "Không giới hạn tin, 10 tin nổi bật, logo premium",
                    IsActive = true
                }
            };

            await context.ServicePackages.AddRangeAsync(packages);
            await context.SaveChangesAsync();
        }

        private static async Task SeedEmployersAndProfiles(AppDbContext context)
        {
            var admin = await context.Users.FirstAsync(u => u.Email == "admin@jobconnect.vn");
            var employerUser = await context.Users.FirstAsync(u => u.Email == "hr@fptsoft.com");
            var candidateUser = await context.Users.FirstAsync(u => u.Email == "candidate@gmail.com");

            // Employer
            var employer = new Employer
            {
                UserID = employerUser.UserID,
                CompanyName = "FPT Software",
                Industry = "Công nghệ thông tin",
                CompanySize = "1000+",
                Address = "17 Duy Tân, Cầu Giấy, Hà Nội",
                Website = "https://www.fpt-software.com",
                IsVerified = true,
                Description = "FPT Software là công ty phần mềm hàng đầu Việt Nam với hơn 27.000 nhân viên toàn cầu.",
                CreatedAt = DateTime.UtcNow
            };
            await context.Employers.AddAsync(employer);
            await context.SaveChangesAsync();

            // Candidate Profile
            var profile = new CandidateProfile
            {
                UserID = candidateUser.UserID,
                Gender = "Nam",
                Address = "Hà Nội",
                Summary = "Lập trình viên với 2 năm kinh nghiệm về .NET và SQL Server.",
                ExperienceYears = 2,
                IsOpenToWork = true
            };
            await context.CandidateProfiles.AddAsync(profile);
            await context.SaveChangesAsync();
        }

        private static async Task SeedJobPosts(AppDbContext context)
        {
            var employer = await context.Employers.FirstAsync();

            var jobPosts = new[]
            {
                new JobPost
                {
                    EmployerID = employer.EmployerID,
                    CategoryID = (await context.Categories.FirstAsync(c => c.Slug == "cong-nghe-thong-tin")).CategoryID,
                    Title = ".NET Developer (C# / ASP.NET Core)",
                    Description = "Phát triển và bảo trì các ứng dụng web sử dụng ASP.NET Core MVC, API RESTful.",
                    Requirements = "- Tối thiểu 1 năm kinh nghiệm C#/.NET\n- Biết SQL Server, EF Core\n- Có kiến thức HTML/CSS cơ bản",
                    Benefits = "- Lương hấp dẫn theo năng lực\n- Thưởng hiệu suất hàng quý\n- Bảo hiểm sức khỏe cao cấp",
                    SalaryMin = 15000000,
                    SalaryMax = 30000000,
                    SalaryNegotiable = false,
                    JobType = "FullTime",
                    Location = "Hà Nội",
                    ExperienceLevel = "Junior",
                    Deadline = DateTime.UtcNow.AddDays(30),
                    Status = "Open",
                    IsFeatured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new JobPost
                {
                    EmployerID = employer.EmployerID,
                    CategoryID = (await context.Categories.FirstAsync(c => c.Slug == "cong-nghe-thong-tin")).CategoryID,
                    Title = "Frontend Developer – React.js",
                    Description = "Xây dựng giao diện web hiện đại với React.js và TailwindCSS.",
                    Requirements = "- 1+ năm kinh nghiệm React.js\n- Thành thạo HTML, CSS, JavaScript\n- Biết Git, REST API",
                    Benefits = "- Remote 2 ngày/tuần\n- Môi trường startup năng động",
                    SalaryMin = 12000000,
                    SalaryMax = 25000000,
                    SalaryNegotiable = false,
                    JobType = "FullTime",
                    Location = "TP. Hồ Chí Minh",
                    ExperienceLevel = "Junior",
                    Deadline = DateTime.UtcNow.AddDays(45),
                    Status = "Open",
                    IsFeatured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new JobPost
                {
                    EmployerID = employer.EmployerID,
                    CategoryID = (await context.Categories.FirstAsync(c => c.Slug == "cong-nghe-thong-tin")).CategoryID,
                    Title = "Thực tập sinh IT – Backend Python",
                    Description = "Hỗ trợ team backend phát triển các tính năng mới bằng Python/Django.",
                    Requirements = "- Đang học năm 3-4 CNTT\n- Biết Python cơ bản\n- Ham học hỏi, chăm chỉ",
                    Benefits = "- Phụ cấp 3-5 triệu/tháng\n- Hỗ trợ xét tuyển chính thức sau thực tập",
                    SalaryMin = 3000000,
                    SalaryMax = 5000000,
                    SalaryNegotiable = false,
                    JobType = "Internship",
                    Location = "Hà Nội",
                    ExperienceLevel = "Fresher",
                    Deadline = DateTime.UtcNow.AddDays(60),
                    Status = "Open",
                    IsFeatured = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.JobPosts.AddRangeAsync(jobPosts);
            await context.SaveChangesAsync();
        }
    }
}