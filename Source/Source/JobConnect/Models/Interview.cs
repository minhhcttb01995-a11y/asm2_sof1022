using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobConnect.Models
{
    public class Interview
    {
        [Key]
        public int InterviewID { get; set; }

        [Required]
        public int AppID { get; set; }

        [Required]
        [Display(Name = "Thời gian phỏng vấn")]
        public DateTime InterviewDate { get; set; }

        [Required]
        [MaxLength(200)]
        [Display(Name = "Địa điểm/Link trực tuyến")]
        public string Location { get; set; } = string.Empty;

        [MaxLength(1000)]
        [Display(Name = "Ghi chú/Hướng dẫn")]
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation properties
        [ForeignKey("AppID")]
        public virtual Application? Application { get; set; }
    }
}
