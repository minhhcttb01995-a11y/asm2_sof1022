// [MODEL-HEADER-ADDED]
// Bảng các ĐIỂM NỔI BẬT / LÝ DO NÊN LÀM VIỆC ở công ty (hiển thị ở trang chi tiết
// công ty, mục "Why work here"), do Employer tự cấu hình cho công ty của mình.
namespace JobConnect.Models;

public class CompanyHighlight
{
    public int Id { get; set; }
    public string Icon { get; set; } = "star";
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsHighlighted { get; set; }
    public int? EmployerId { get; set; }
    public virtual Employer? Employer { get; set; }
}
