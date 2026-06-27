using JobConnect.Data;
using JobConnect.Models;
using JobConnect.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobConnect.Controllers;

[Authorize(Roles = "Admin")]
public class AdminController : Controller
{
    private readonly AppDbContext _db;
    private readonly IJobService _jobSvc;
    private readonly ISkillService _skillSvc;
    public AdminController(AppDbContext db, IJobService jobSvc, ISkillService skillSvc) { _db = db; _jobSvc = jobSvc; _skillSvc = skillSvc; }

    public IActionResult Index() => RedirectToAction("Dashboard");

    // GET /Admin/CandidateSkills/{profileId}
    public async Task<IActionResult> CandidateSkills(int profileId)
    {
        var profile = await _db.CandidateProfiles
            .Include(p => p.User)
            .Include(p => p.CandidateSkills)
                .ThenInclude(cs => cs.Skill)
            .FirstOrDefaultAsync(p => p.ProfileID == profileId);

        if (profile == null) return NotFound();

        return View(profile);
    }

    // GET /Admin/Dashboard
    public async Task<IActionResult> Dashboard()
    {
        ViewBag.UserCount = await _db.Users.CountAsync();
        ViewBag.CandidateCount = await _db.Users.CountAsync(u => u.Role == "Candidate");
        ViewBag.EmployerCount = await _db.Employers.CountAsync();
        ViewBag.JobCount = await _db.JobPosts.CountAsync();
        ViewBag.OpenJobCount = await _db.JobPosts.CountAsync(j => j.Status == "Open");
        ViewBag.PendingJobCount = await _db.JobPosts.CountAsync(j => j.Status == "Pending");
        ViewBag.AppCount = await _db.Applications.CountAsync();
        ViewBag.BannedCount = await _db.Users.CountAsync(u => u.Status == "Banned");
        ViewBag.AppPending = await _db.Applications.CountAsync(a => a.Status == "Pending");
        ViewBag.AppAccepted = await _db.Applications.CountAsync(a => a.Status == "Accepted");
        ViewBag.AppRejected = await _db.Applications.CountAsync(a => a.Status == "Rejected");
        ViewBag.AppInterview = await _db.Applications.CountAsync(a => a.Status == "Interview");
        ViewBag.PendingJobs = await _db.JobPosts
            .Include(j => j.Employer).Where(j => j.Status == "Pending")
            .OrderByDescending(j => j.CreatedAt).Take(8).ToListAsync();
        ViewBag.NewUsers = await _db.Users
            .OrderByDescending(u => u.CreatedAt).Take(5).ToListAsync();
        ViewBag.NewApps = await _db.Applications
            .Include(a => a.CandidateProfile)
            .Include(a => a.Job).ThenInclude(j => j!.Employer)
            .OrderByDescending(a => a.AppliedAt).Take(5).ToListAsync();
        return View();
    }

    // ====================== USERS ======================

    public async Task<IActionResult> Users(string? keyword, string? role, int page = 1)
    {
        const int ps = 20;
        var q = _db.Users.AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword));
        if (!string.IsNullOrWhiteSpace(role))
            q = q.Where(u => u.Role == role);
        var total = await q.CountAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page; ViewBag.Keyword = keyword; ViewBag.Role = role;
        return View(await q.OrderByDescending(u => u.CreatedAt).Skip((page - 1) * ps).Take(ps).ToListAsync());
    }

    public async Task<IActionResult> UserDetail(int id)
    {
        var user = await _db.Users
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.CvFiles)
            .Include(u => u.CandidateProfile).ThenInclude(p => p!.Applications).ThenInclude(a => a.Job)
            .Include(u => u.Employer).ThenInclude(e => e!.JobPosts)
            .FirstOrDefaultAsync(u => u.UserID == id);
        if (user == null) return NotFound();
        return View(user);
    }

    public IActionResult CreateUser() => View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateUser(string fullName, string email, string password, string role)
    {
        if (await _db.Users.AnyAsync(u => u.Email == email))
        {
            ModelState.AddModelError("", "Email đã tồn tại.");
            return View();
        }
        var user = new User
        {
            FullName = fullName,
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = role,
            Status = "Active",
            CreatedAt = DateTime.Now
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        if (role == "Candidate")
        {
            _db.CandidateProfiles.Add(new CandidateProfile { UserID = user.UserID, FullName = fullName });
            await _db.SaveChangesAsync();
        }
        TempData["Success"] = $"Đã tạo tài khoản {email} thành công!";
        return RedirectToAction("Users");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BanUser(int userId, string? returnUrl)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.Status = user.Status == "Active" ? "Banned" : "Active";
            user.UpdatedAt = DateTime.Now;
            await _db.SaveChangesAsync();
            TempData["Success"] = user.Status == "Banned"
                ? $"Đã khoá tài khoản {user.Email}."
                : $"Đã mở khoá tài khoản {user.Email}.";
        }
        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction("Users");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteUser(int userId)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();
        if (user.Role == "Admin") { TempData["Error"] = "Không thể xóa tài khoản Admin."; return RedirectToAction("Users"); }
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã xóa tài khoản {user.Email}.";
        return RedirectToAction("Users");
    }

    // ====================== JOBS ======================

    public async Task<IActionResult> Jobs(string? status, int page = 1)
    {
        const int ps = 20;
        var q = _db.JobPosts.Include(j => j.Employer).AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) q = q.Where(j => j.Status == status);
        var total = await q.CountAsync();
        ViewBag.TotalPages = (int)Math.Ceiling(total / (double)ps);
        ViewBag.Page = page; ViewBag.Status = status;
        return View(await q.OrderByDescending(j => j.CreatedAt).Skip((page - 1) * ps).Take(ps).ToListAsync());
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SetJobStatus(int jobId, string status, string? filterStatus)
    {
        var validStatuses = new[] { "Open", "Pending", "Rejected", "Closed", "Draft" };
        if (!validStatuses.Contains(status)) return BadRequest();
        var job = await _db.JobPosts.Include(j => j.Employer).FirstOrDefaultAsync(j => j.JobID == jobId);
        if (job == null) return NotFound();
        job.Status = status;
        job.UpdatedAt = DateTime.Now;
        var notifyTitle = status switch
        {
            "Open" => $"Tin \"{job.Title}\" đã được duyệt và đang hiển thị!",
            "Rejected" => $"Tin \"{job.Title}\" đã bị từ chối bởi Admin.",
            "Closed" => $"Tin \"{job.Title}\" đã bị đóng bởi Admin.",
            "Pending" => $"Tin \"{job.Title}\" được chuyển về trạng thái chờ duyệt.",
            _ => null
        };
        if (notifyTitle != null && job.Employer != null)
            _db.Notifications.Add(new Notification { UserID = job.Employer.UserID, Title = notifyTitle, Type = "System", RelatedID = job.JobID });
        await _db.SaveChangesAsync();
        TempData["Success"] = status switch
        {
            "Open" => $"Đã duyệt tin \"{job.Title}\".",
            "Rejected" => $"Đã từ chối tin \"{job.Title}\".",
            "Closed" => $"Đã đóng tin \"{job.Title}\".",
            "Pending" => $"Đã chuyển tin \"{job.Title}\" về chờ duyệt.",
            _ => "Đã cập nhật trạng thái."
        };
        return RedirectToAction("Jobs", new { status = filterStatus });
    }

    // ====================== COMPANIES ======================

    public async Task<IActionResult> Companies(string? q, string? status, int page = 1)
    {
        var query = _db.Employers.Include(c => c.User).Include(c => c.JobPosts).AsQueryable();
        if (!string.IsNullOrEmpty(q))
            query = query.Where(c => c.CompanyName.Contains(q) || c.User!.Email.Contains(q));
        if (status == "Verified") query = query.Where(c => c.IsVerified);
        else if (status == "Unverified") query = query.Where(c => !c.IsVerified);
        else if (status == "Locked") query = query.Where(c => c.IsLocked);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;
        return View(await query.OrderByDescending(c => c.EmployerID).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    public async Task<IActionResult> CompanyDetail(int id)
    {
        var emp = await _db.Employers
            .Include(e => e.User).Include(e => e.JobPosts)
            .FirstOrDefaultAsync(e => e.EmployerID == id);
        if (emp == null) return NotFound();
        return View(emp);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveCompany(int id)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null) { c.IsVerified = true; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã xác minh công ty.";
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SuspendCompany(int id)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null) { c.IsVerified = false; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã hủy xác minh công ty.";
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> LockCompany(int id, string? returnUrl)
    {
        var c = await _db.Employers.FindAsync(id);
        if (c != null)
        {
            c.IsLocked = !c.IsLocked;
            await _db.SaveChangesAsync();
            TempData["Success"] = c.IsLocked
                ? $"Đã khoá công ty \"{c.CompanyName}\"."
                : $"Đã mở khoá công ty \"{c.CompanyName}\".";
        }
        if (!string.IsNullOrEmpty(returnUrl)) return Redirect(returnUrl);
        return RedirectToAction("Companies");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteCompany(int id)
    {
        var c = await _db.Employers.Include(e => e.JobPosts).FirstOrDefaultAsync(e => e.EmployerID == id);
        if (c == null) return NotFound();
        _db.JobPosts.RemoveRange(c.JobPosts);
        _db.Employers.Remove(c);
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã xóa công ty \"{c.CompanyName}\" và toàn bộ tin tuyển dụng liên quan.";
        return RedirectToAction("Companies");
    }

    // ============== ĐĂNG TIN HỘ NHÀ TUYỂN DỤNG ==============

    public async Task<IActionResult> PostJobForEmployer(int id)
    {
        var employer = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerID == id);
        if (employer == null) return NotFound();
        ViewBag.Employer = employer;
        ViewBag.Categories = await _db.Categories.ToListAsync();
        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PostJobForEmployer(
        int employerId, string title, string? description, string? requirements,
        string? benefits, decimal? salaryMin, decimal? salaryMax,
        bool salaryNegotiable, string jobType, string? location,
        string? experienceLevel, DateTime? deadline, int? categoryId, bool isDraft)
    {
        var employer = await _db.Employers.FindAsync(employerId);
        if (employer == null) return NotFound();
        var job = new JobPost
        {
            EmployerID = employerId,
            Title = title,
            Description = description,
            Requirements = requirements,
            Benefits = benefits,
            SalaryMin = salaryMin,
            SalaryMax = salaryMax,
            SalaryNegotiable = salaryNegotiable,
            JobType = jobType,
            Location = location,
            ExperienceLevel = experienceLevel,
            Deadline = deadline,
            CategoryID = categoryId,
            Status = isDraft ? "Draft" : "Open",
            CreatedAt = DateTime.Now
        };
        _db.JobPosts.Add(job);
        await _db.SaveChangesAsync();
        _db.Notifications.Add(new Notification
        {
            UserID = employer.UserID,
            Title = "Admin đã đăng tin tuyển dụng hỗ trợ bạn",
            Content = $"Tin \"{title}\" đã được Admin đăng với trạng thái {(isDraft ? "Nháp" : "Đang mở")}.",
            Type = "System",
            RelatedID = job.JobID
        });
        await _db.SaveChangesAsync();
        TempData["Success"] = $"Đã đăng tin \"{title}\" cho {employer.CompanyName} thành công!";
        return RedirectToAction("CompanyDetail", new { id = employerId });
    }

    // ============== HỖ TRỢ ỨNG VIÊN / CV ==============

    public async Task<IActionResult> EmployerApplications(int id, string? status)
    {
        var employer = await _db.Employers.Include(e => e.User).FirstOrDefaultAsync(e => e.EmployerID == id);
        if (employer == null) return NotFound();
        var query = _db.Applications
            .Include(a => a.CandidateProfile).ThenInclude(c => c!.User)
            .Include(a => a.Job)
            .Include(a => a.CvFile)
            .Where(a => a.Job!.EmployerID == id)
            .AsQueryable();
        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);
        ViewBag.Employer = employer;
        ViewBag.FilterStatus = status;
        return View(await query.OrderByDescending(a => a.AppliedAt).ToListAsync());
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> FixCvApplication(int applicationId, string action, int employerId)
    {
        var app = await _db.Applications
            .Include(a => a.CandidateProfile).ThenInclude(c => c!.User)
            .Include(a => a.Job)
            .FirstOrDefaultAsync(a => a.AppID == applicationId);
        if (app == null)
        {
            TempData["Error"] = "Không tìm thấy đơn ứng tuyển.";
            return RedirectToAction("EmployerApplications", new { id = employerId });
        }
        string msg;
        switch (action)
        {
            case "reset":
                app.Status = "Pending";
                app.CVID = null;
                app.UpdatedAt = DateTime.Now;
                msg = $"Đã reset CV đơn của {app.CandidateProfile?.User?.FullName}. Ứng viên có thể nộp lại.";
                if (app.CandidateProfile != null)
                {
                    _db.Notifications.Add(new Notification
                    {
                        UserID = app.CandidateProfile!.UserID,
                        Title = "Admin đã hỗ trợ reset CV của bạn",
                        Content = $"CV ở đơn ứng tuyển vị trí \"{app.Job?.Title}\" đã được Admin reset. Vui lòng nộp lại CV mới.",
                        Type = "System",
                        RelatedID = app.AppID
                    });
                }
                break;
            case "delete":
                _db.Applications.Remove(app);
                msg = $"Đã xóa đơn ứng tuyển của {app.CandidateProfile?.User?.FullName}.";
                break;
            case "approve":
                app.Status = "Accepted";
                app.UpdatedAt = DateTime.Now;
                msg = $"Đã duyệt đơn ứng tuyển của {app.CandidateProfile?.User?.FullName}.";
                if (app.CandidateProfile != null)
                {
                    _db.Notifications.Add(new Notification
                    {
                        UserID = app.CandidateProfile!.UserID,
                        Title = "Đơn ứng tuyển được chấp nhận",
                        Content = $"Admin đã duyệt đơn ứng tuyển vị trí \"{app.Job?.Title}\" của bạn.",
                        Type = "System",
                        RelatedID = app.AppID
                    });
                }
                break;
            default:
                TempData["Error"] = "Hành động không hợp lệ.";
                return RedirectToAction("EmployerApplications", new { id = employerId });
        }
        await _db.SaveChangesAsync();
        TempData["Success"] = msg;
        return RedirectToAction("EmployerApplications", new { id = employerId });
    }

    // ====================== BLOG ======================

    public async Task<IActionResult> Blog(string? q, string? status, int page = 1)
    {
        var query = _db.BlogPosts.Include(p => p.Author).AsQueryable();
        if (!string.IsNullOrEmpty(q)) query = query.Where(p => p.Title.Contains(q));
        if (status == "Published") query = query.Where(p => p.IsPublished);
        else if (status == "Draft") query = query.Where(p => !p.IsPublished);
        int pageSize = 15;
        ViewBag.TotalPages = (int)Math.Ceiling(await query.CountAsync() / (double)pageSize);
        ViewBag.Page = page; ViewBag.Q = q; ViewBag.Status = status;
        return View(await query.OrderByDescending(p => p.PostID).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync());
    }

    public IActionResult BlogCreate() => View();

    public async Task<IActionResult> BlogEdit(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post == null) return NotFound();
        return View(post);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogEdit(int PostID, string Title, string? Slug, string? Excerpt, string? CoverURL, string Content, string Status)
    {
        var post = await _db.BlogPosts.FindAsync(PostID);
        if (post == null) return NotFound();
        post.Title = Title;
        post.Slug = string.IsNullOrEmpty(Slug) ? Title.ToLower().Replace(" ", "-") : Slug;
        post.Excerpt = Excerpt;
        post.Content = Content;
        post.IsPublished = Status == "Published";
        post.PublishedAt = post.IsPublished ? (post.PublishedAt ?? DateTime.Now) : null;
        if (!string.IsNullOrEmpty(CoverURL) && CoverURL.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            try { post.CoverURL = await _jobSvc.SaveImageFromDataUriAsync(CoverURL, "uploads/blog/cover"); }
            catch { }
        }
        else post.CoverURL = CoverURL;
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã cập nhật bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogCreate(string Title, string? Slug, string? Excerpt, string? CoverURL, string Content, string Status)
    {
        var uid = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var slug = string.IsNullOrEmpty(Slug) ? Title.ToLower().Replace(" ", "-") : Slug;
        string? coverPath = CoverURL;
        if (!string.IsNullOrEmpty(CoverURL) && CoverURL.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            try { coverPath = await _jobSvc.SaveImageFromDataUriAsync(CoverURL, "uploads/blog/cover"); }
            catch { coverPath = null; }
        }
        _db.BlogPosts.Add(new BlogPost
        {
            Title = Title,
            Slug = slug,
            Excerpt = Excerpt,
            CoverURL = coverPath,
            Content = Content,
            IsPublished = Status == "Published",
            AuthorID = uid,
            PublishedAt = Status == "Published" ? DateTime.Now : null
        });
        await _db.SaveChangesAsync();
        TempData["Success"] = "Đã lưu bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogPublish(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post != null) { post.IsPublished = true; post.PublishedAt = DateTime.Now; await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã đăng bài viết.";
        return RedirectToAction("Blog");
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> BlogDelete(int id)
    {
        var post = await _db.BlogPosts.FindAsync(id);
        if (post != null) { _db.BlogPosts.Remove(post); await _db.SaveChangesAsync(); }
        TempData["Success"] = "Đã xóa bài viết.";
        return RedirectToAction("Blog");
    }

    // ====================== REPORTS ======================

    public async Task<IActionResult> Reports()
    {
        ViewBag.TotalUsers = await _db.Users.CountAsync();
        ViewBag.TotalJobs = await _db.JobPosts.CountAsync();
        ViewBag.TotalApps = await _db.Applications.CountAsync();
        ViewBag.TotalCompanies = await _db.Employers.CountAsync(c => c.IsVerified);
        var sixMonths = DateTime.Now.AddMonths(-5);
        ViewBag.MonthlyApps = await _db.Applications
            .Where(a => a.AppliedAt >= sixMonths)
            .GroupBy(a => new { a.AppliedAt.Year, a.AppliedAt.Month })
            .Select(g => new { Month = g.Key.Month + "/" + g.Key.Year, Count = g.Count() })
            .OrderBy(g => g.Month)
            .Select(g => ValueTuple.Create(g.Month, g.Count))
            .ToListAsync();
        ViewBag.TopCategories = await _db.JobPosts
            .Where(j => j.Category != null)
            .GroupBy(j => j.Category!.Name)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();
        ViewBag.TopCompanies = await _db.JobPosts
            .GroupBy(j => j.Employer.CompanyName)
            .Select(g => new { Name = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count).Take(5)
            .Select(g => ValueTuple.Create(g.Name, g.Count))
            .ToListAsync();
        ViewBag.AppStatus = await _db.Applications
            .GroupBy(a => a.Status)
            .Select(g => ValueTuple.Create(g.Key, g.Count()))
            .ToListAsync();
        ViewBag.RecentUsers = await _db.Users
            .OrderByDescending(u => u.CreatedAt).Take(10).ToListAsync();
        return View();
    }

    // ====================== SKILLS ======================

    // GET /Admin/Skills
    public async Task<IActionResult> Skills(string? category, string? keyword, int page = 1)
    {
        var skills = await _skillSvc.GetAllAsync();

        // Filter by category
        if (!string.IsNullOrEmpty(category) && Enum.TryParse<SkillCategory>(category, out var cat))
        {
            skills = skills.Where(s => s.Category == cat).ToList();
        }

        // Filter by keyword
        if (!string.IsNullOrEmpty(keyword))
        {
            skills = skills.Where(s => s.Name.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                                      (s.Description != null && s.Description.Contains(keyword, StringComparison.OrdinalIgnoreCase)))
                          .ToList();
        }

        // Pagination
        const int pageSize = 10;
        var pagedSkills = skills.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        var totalPages = (int)Math.Ceiling(skills.Count / (double)pageSize);

        ViewBag.Skills = pagedSkills;
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.CategoryFilter = category;
        ViewBag.KeywordFilter = keyword;
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();

        return View();
    }

    // GET /Admin/Skill/Create
    public IActionResult SkillCreate()
    {
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View();
    }

    // POST /Admin/Skill/Create
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillCreate(Skill model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
            return View(model);
        }

        var result = await _skillSvc.CreateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã tạo kỹ năng mới thành công!";
            return RedirectToAction("Skills");
        }

        TempData["Error"] = "Tên kỹ năng đã tồn tại!";
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(model);
    }

    // GET /Admin/Skill/Edit/5
    public async Task<IActionResult> SkillEdit(int id)
    {
        var skill = await _skillSvc.GetByIdAsync(id);
        if (skill == null)
            return NotFound();

        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(skill);
    }

    // POST /Admin/Skill/Edit
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillEdit(Skill model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
            return View(model);
        }

        var result = await _skillSvc.UpdateAsync(model);
        if (result)
        {
            TempData["Success"] = "Đã cập nhật kỹ năng thành công!";
            return RedirectToAction("Skills");
        }

        TempData["Error"] = "Tên kỹ năng đã tồn tại hoặc có lỗi xảy ra!";
        ViewBag.Categories = Enum.GetValues(typeof(SkillCategory)).Cast<SkillCategory>();
        return View(model);
    }

    // POST /Admin/Skill/Delete/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillDelete(int id)
    {
        var result = await _skillSvc.DeleteAsync(id);
        if (result)
        {
            TempData["Success"] = "Đã xóa kỹ năng thành công!";
        }
        else
        {
            TempData["Error"] = "Không thể xóa kỹ năng này (đang được sử dụng bởi ứng viên)!";
        }
        return RedirectToAction("Skills");
    }

    // POST /Admin/Skill/Toggle/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SkillToggle(int id)
    {
        var result = await _skillSvc.ToggleActiveAsync(id);
        if (result)
        {
            TempData["Success"] = "Đã thay đổi trạng thái kỹ năng!";
        }
        else
        {
            TempData["Error"] = "Có lỗi xảy ra!";
        }
        return RedirectToAction("Skills");
    }

    // ====================== CATEGORIES (Industry) ======================

    // GET /Admin/Categories
    public async Task<IActionResult> Categories(string? keyword, string? type, int page = 1)
    {
        int pageSize = 10;
        var query = _db.Categories.AsQueryable();

        // Filter by type (default to Industry)
        if (string.IsNullOrEmpty(type))
        {
            type = "Industry";
        }
        query = query.Where(c => c.Type == type);

        // Search by keyword
        if (!string.IsNullOrEmpty(keyword))
        {
            query = query.Where(c => c.Name.Contains(keyword) || c.Slug.Contains(keyword));
        }

        var totalItems = await query.CountAsync();
        var categories = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewBag.Categories = categories;
        ViewBag.KeywordFilter = keyword;
        ViewBag.TypeFilter = type;
        ViewBag.Page = page;
        ViewBag.PageSize = pageSize;
        ViewBag.TotalItems = totalItems;
        ViewBag.TotalPages = (int)Math.Ceiling((double)totalItems / pageSize);

        return View();
    }

    // GET /Admin/Category/Create
    public IActionResult CategoryCreate()
    {
        ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
        return View();
    }

    // POST /Admin/Category/Create
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryCreate(Category model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        // Check if slug exists
        if (await _db.Categories.AnyAsync(c => c.Slug == model.Slug))
        {
            TempData["Error"] = "Slug đã tồn tại!";
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        model.CreatedAt = DateTime.Now;
        // model.UpdatedAt không gán khi tạo mới

        _db.Categories.Add(model);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã tạo danh mục thành công!";
        return RedirectToAction("Categories", new { type = model.Type });
    }

    // GET /Admin/Category/Edit/5
    public async Task<IActionResult> CategoryEdit(int id)
    {
        var category = await _db.Categories.FindAsync(id);
        if (category == null) return NotFound();

        ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
        return View(category);
    }

    // POST /Admin/Category/Edit
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryEdit(Category model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        var category = await _db.Categories.FindAsync(model.CategoryID);
        if (category == null) return NotFound();

        // Check if slug exists (excluding current)
        if (await _db.Categories.AnyAsync(c => c.Slug == model.Slug && c.CategoryID != model.CategoryID))
        {
            TempData["Error"] = "Slug đã tồn tại!";
            ViewBag.Types = new[] { "Industry", "Location", "Level", "JobType" };
            return View(model);
        }

        category.Name = model.Name;
        category.Type = model.Type;
        category.Slug = model.Slug;
        category.UpdatedAt = DateTime.Now;

        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã cập nhật danh mục thành công!";
        return RedirectToAction("Categories", new { type = category.Type });
    }

    // POST /Admin/Category/Delete/5
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> CategoryDelete(int id)
    {
        var category = await _db.Categories.FindAsync(id);
        if (category == null) return NotFound();

        _db.Categories.Remove(category);
        await _db.SaveChangesAsync();

        TempData["Success"] = "Đã xóa danh mục thành công!";
        return RedirectToAction("Categories", new { type = category.Type });
    }
}