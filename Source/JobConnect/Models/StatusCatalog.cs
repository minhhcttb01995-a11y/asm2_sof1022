// [MODEL-HEADER-ADDED]
// Bảng DANH MỤC TRẠNG THÁI DÙNG CHUNG do Admin tự cấu hình (thêm/sửa/xóa) cho
// nhiều loại đối tượng (Candidate/Employer/Staff/Company/JobPost/BlogPost) — thay vì
// hard-code cứng trạng thái trong code, hệ thống tra bảng này để biết: trạng thái đó
// tên hiển thị là gì, màu badge gì, có chặn đăng nhập không (BlocksLogin), có hiển thị
// công khai không (ShowPublicly). Class StatusEntityTypes bên dưới là hằng số tiện dùng.
using System;

namespace JobConnect.Models;

/// <summary>
/// Danh mục "Trạng thái" do Admin tự quản lý (thêm/sửa/xóa),
/// áp dụng cho: Candidate, Employer, Staff, Company, JobPost.
/// </summary>
public partial class StatusCatalog
{
    public int Id { get; set; }

    /// <summary>Candidate | Employer | Staff | Company | JobPost</summary>
    public string EntityType { get; set; } = null!;

    /// <summary>Giá trị thực tế lưu vào cột Status của đối tượng tương ứng.</summary>
    /// <remarks>Will be auto-generated from Name if not provided</remarks>
    public string? Code { get; set; }

    /// <summary>Tên hiển thị (tiếng Việt).</summary>
    public string Name { get; set; } = null!;

    /// <summary>Class Tailwind cho badge màu, ví dụ: "bg-green-100 text-green-700".</summary>
    public string? ColorClass { get; set; }

    /// <summary>Mô tả chi tiết về trạng thái này.</summary>
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;

    /// <summary>Nếu true: user có Status = Code này sẽ KHÔNG đăng nhập được vào hệ thống.</summary>
    public bool BlocksLogin { get; set; }

    /// <summary>
    /// Áp dụng cho Company/JobPost/BlogPost (và Employer dùng chung status với Company):
    /// nếu true, bản ghi ở trạng thái này sẽ hiển thị công khai trên trang chủ/danh sách.
    /// Nếu false (vd: Banned, Pending, Rejected, Draft) sẽ bị ẩn khỏi trang công khai.
    /// </summary>
    public bool ShowPublicly { get; set; } = true;

    /// <summary>Trạng thái hệ thống mặc định - không cho phép xóa.</summary>
    public bool IsSystem { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}

/// <summary>Danh sách loại đối tượng áp dụng danh mục trạng thái.</summary>
public static class StatusEntityTypes
{
    public const string Candidate = "Candidate";
    public const string Employer = "Employer";
    public const string Staff = "Staff";
    public const string Company = "Company";
    public const string JobPost = "JobPost";
    public const string BlogPost = "BlogPost";

    public static readonly string[] All = { Candidate, Employer, Staff, Company, JobPost, BlogPost };

    public static readonly Dictionary<string, string> Labels = new()
    {
        [Candidate] = "Ứng viên",
        [Employer] = "Nhà tuyển dụng",
        [Staff] = "Nhân viên",
        [Company] = "Công ty",
        [JobPost] = "Tin tuyển dụng",
        [BlogPost] = "Bài viết Blog"
    };
}