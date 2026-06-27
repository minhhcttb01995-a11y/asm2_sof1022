using JobConnect.Data;
using JobConnect.Models; // ĐÃ THÊM: Để nhận diện class CompanyReview
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers
{
    public class CompanyController : Controller
    {
        private readonly AppDbContext _db;
        public CompanyController(AppDbContext db) => _db = db;

        // GET /Company
        public async Task<IActionResult> Index(string? keyword, string? industry, int page = 1)
        {
            const int pageSize = 12;
            var q = _db.Employers
                .Where(e => !e.IsLocked)   // Không hiện công ty bị khoá
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
                q = q.Where(e => e.CompanyName.Contains(keyword));

            if (!string.IsNullOrWhiteSpace(industry))
                q = q.Where(e => e.Industry == industry);

            var total = await q.CountAsync();
            var results = await q.OrderByDescending(e => e.IsVerified)
                                  .Skip((page - 1) * pageSize).Take(pageSize)
                                  .ToListAsync();

            ViewBag.Keyword = keyword;
            ViewBag.Industry = industry;
            ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
            ViewBag.Page = page;
            ViewBag.Industries = await _db.Categories.Where(c => c.Type == "Industry").ToListAsync();
            return View(results);
        }

        // GET /Company/Detail/5
        public async Task<IActionResult> Detail(int id)
        {
            var emp = await _db.Employers
                .Include(e => e.User)
                .FirstOrDefaultAsync(e => e.EmployerID == id && !e.IsLocked);

            if (emp == null) return NotFound();

            var jobs = await _db.JobPosts
                .Where(j => j.EmployerID == id && j.Status == "Open")
                .OrderByDescending(j => j.CreatedAt)
                .ToListAsync();

            // SỬA TẠI ĐÂY: Lấy danh sách ép về kiểu CompanyReview tường minh
            List<CompanyReview> reviews = await _db.Reviews
                .Where(r => r.EmployerID == id)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            ViewBag.Jobs = jobs;
            ViewBag.Reviews = reviews;

            return View(emp);
        }
        // 1. GET: /Company/WriteReview/5 (Hiển thị giao diện nhập đánh giá cho công ty có ID là 5)
        [HttpGet]
        public async Task<IActionResult> WriteReview(int id)
        {
            var company = await _db.Employers.FindAsync(id);
            if (company == null) return NotFound();

            // Truyền thông tin công ty sang View để hiển thị tên/logo cho đẹp
            ViewBag.CompanyName = company.CompanyName;
            ViewBag.EmployerID = id;

            return View();
        }

        // 2. POST: /Company/WriteReview (Hệ thống xử lý khi ứng viên bấm nút "Gửi đánh giá")
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> WriteReview(CompanyReview model)
        {
            if (ModelState.IsValid)
            {
                model.CreatedAt = DateTime.Now;
                model.ReviewType = "CandidateToEmployer";

                // Mẹo test: Nếu hệ thống chưa làm đăng nhập, ta gán tạm ID = 1 cho khỏi lỗi dữ liệu liên kết
                if (model.ReviewerID == 0) model.ReviewerID = 1;
                if (model.RevieweeID == 0) model.RevieweeID = 1;
                if (model.AppID == 0) model.AppID = 1;

                _db.Reviews.Add(model);
                await _db.SaveChangesAsync();

                TempData["Success"] = "Cảm ơn bạn đã gửi đánh giá thành công!";
                // Gửi xong thì tự động quay về trang chi tiết công ty đó luôn
                return RedirectToAction("Detail", "Company", new { id = model.EmployerID });
            }

            // Nếu dữ liệu nhập lỗi, giữ ứng viên ở lại trang và hiển thị lại lỗi
            return View(model);
        }
    }
}