// [[FILE-HEADER-ADDED]]
// Extension method tiện ích cho JobPost (VD: định dạng khoảng lương hiển thị, kiểm tra
// tin đã hết hạn hay chưa...) — gọi trực tiếp như job.XyzMethod() trong View/Controller.
using JobConnect.Models;

namespace JobConnect.Extensions;

/// <summary>
/// Extension methods cho JobPost, dùng chung ở mọi view để hiển thị mức lương
/// thay vì in nhầm giá trị bool SalaryNegotiable ra màn hình.
/// </summary>
public static class JobPostExtensions
{
    /// <summary>
    /// Trả về chuỗi mức lương đã định dạng để hiển thị, ví dụ:
    /// "10,000,000 - 18,000,000 VNĐ", "Từ 10,000,000 VNĐ", hoặc "Thỏa thuận".
    /// </summary>
    public static string FormatSalary(this JobPost job)
    {
        if (job.SalaryNegotiable || (job.SalaryMin == null && job.SalaryMax == null))
        {
            return "Thỏa thuận";
        }

        if (job.SalaryMin != null && job.SalaryMax != null)
        {
            return $"{job.SalaryMin:#,##0} - {job.SalaryMax:#,##0} VNĐ";
        }

        if (job.SalaryMin != null)
        {
            return $"Từ {job.SalaryMin:#,##0} VNĐ";
        }

        return $"Đến {job.SalaryMax:#,##0} VNĐ";
    }
}