using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models
{
    public class CvFile
    {
        [Key]
        public int CVID { get; set; }
        public int ProfileID { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string FilePath { get; set; } = string.Empty;
        public int? FileSize { get; set; }
        public bool IsDefault { get; set; } = false;
        public DateTime UploadedAt { get; set; } = DateTime.Now;
        // Navigation
        public CandidateProfile CandidateProfile { get; set; } = null!;
    }
}