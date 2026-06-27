using JobConnect.Data;
using JobConnect.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Controllers
{
    public class AdminReviewController : Controller
    {
        private readonly AppDbContext _db;
        public AdminReviewController(AppDbContext db) => _db = db;

        // 1. Trang danh sách quản lý tất cả đánh giá dành cho Admin
        public async Task<IActionResult> Index(string? keyword, int page = 1)
        {
            const int pageSize = 10;
            var q = _db.Reviews
                .Include(r => r.Application)
                .ThenInclude(a => a!.Job)
                .Include(r => r.Reviewer)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                q = q.Where(r => r.Title!.Contains(keyword) || r.Content!.Contains(keyword));
            }

            var total = await q.CountAsync();
            var results = await q.OrderByDescending(r => r.CreatedAt)
                                  .Skip((page - 1) * pageSize)
                                  .Take(pageSize)
                                  .ToListAsync();

            ViewBag.Keyword = keyword;
            ViewBag.TotalPages = (int)Math.Ceiling(total / (double)pageSize);
            ViewBag.Page = page;

            return View(results);
        }

        // 2. Chức năng xóa đánh giá (Admin)
        [HttpPost]
        public async Task<IActionResult> Delete(int id)
        {
            var review = await _db.Reviews.FindAsync(id);
            if (review == null) return NotFound();

            _db.Reviews.Remove(review);
            await _db.SaveChangesAsync();

            TempData["Success"] = "Xóa đánh giá thành công!";
            return RedirectToAction(nameof(Index));
        }

        // 3. ĐÃ FIX LỖI: Tính năng Nhà tuyển dụng phản hồi đánh giá công ty
        [HttpPost]
        public async Task<IActionResult> ReplyReview(int reviewId, string replyContent)
        {
            if (string.IsNullOrWhiteSpace(replyContent))
            {
                TempData["Error"] = "Nội dung phản hồi không được để trống!";
                return Redirect(Request.Headers["Referer"].ToString() ?? "/");
            }

            var review = await _db.Reviews.FindAsync(reviewId);
            if (review == null) return NotFound();

            review.EmployerReply = replyContent.Trim();
            _db.Reviews.Update(review);
            await _db.SaveChangesAsync();

            TempData["Success"] = "Đã gửi phản hồi đánh giá thành công!";

            // Chuyển hướng an toàn về lại trang cũ thông qua HTTP Referer
            return Redirect(Request.Headers["Referer"].ToString() ?? "/");
        }
    }
}