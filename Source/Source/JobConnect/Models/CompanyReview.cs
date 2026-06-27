using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models
{
    public class CompanyReview
    {
        [Key]
        public int CompanyReviewID { get; set; }

        // Các trường ID liên kết dữ liệu (Foreign Keys)
        public int AppID { get; set; }
        public int ReviewerID { get; set; }
        public int RevieweeID { get; set; }
        public int EmployerID { get; set; }

        public int Rating { get; set; }

        // Thêm dấu ? để xử lý lỗi "Non-nullable property must contain a non-null value"
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? AuthorName { get; set; }
        public string? EmployerReply { get; set; }
        public string? ReviewType { get; set; } // Ví dụ: CandidateToEmployer hoặc ngược lại

        public bool IsAnonymous { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // ===== CÁC THUỘC TÍNH LIÊN KẾT (Navigation Properties) =====
        // Sửa lỗi: không tìm thấy định nghĩa cho 'Application', 'Reviewer', 'Reviewee'
        [ForeignKey("AppID")]
        public virtual Application? Application { get; set; }

        [ForeignKey("ReviewerID")]
        public virtual User? Reviewer { get; set; }

        [ForeignKey("RevieweeID")]
        public virtual User? Reviewee { get; set; }
    }
}