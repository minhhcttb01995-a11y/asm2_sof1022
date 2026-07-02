using JobConnect.Models;

namespace JobConnect.ViewModels.Staff;

public class StaffIndexViewModel
{
    public List<StaffListItemViewModel> StaffList { get; set; } = new();
    public int CurrentPage { get; set; } = 1;
    public int TotalPages { get; set; }
    public int PageSize { get; set; } = 10;
    public int TotalCount { get; set; }

    // Filters
    public string? SearchTerm { get; set; }
    public StaffStatus? StatusFilter { get; set; }
    public string? DepartmentFilter { get; set; }
    public string? SortBy { get; set; }
    public bool SortDescending { get; set; } = false;
}

public class StaffListItemViewModel
{
    public int Id { get; set; }
    public int ApplicationUserId { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Avatar { get; set; }
    public string Position { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public StaffStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
