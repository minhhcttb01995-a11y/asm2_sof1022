// [MODEL-HEADER-ADDED]
// Bảng BÀI VIẾT BLOG (tin tức/chia sẻ) do User (thường là Staff/Admin) đăng.
// Có slug (đường dẫn URL thân thiện), trạng thái xuất bản (IsPublished/Status)
// và ngày xuất bản (PublishedAt). Các property viết hoa (PostID, CoverURL...)
// chỉ là alias tương thích ngược cho code/view cũ.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class BlogPost
{
    public int PostId { get; set; }

    /// <summary>Mã bài blog - ngẫu nhiên, không trùng (VD: BL9Q3M7Z).</summary>
    public string? BlogCode { get; set; }

    public int AuthorId { get; set; }

    public string Title { get; set; } = null!;

    public string Slug { get; set; } = null!;

    public string? Excerpt { get; set; }

    public string? Content { get; set; }

    public string? CoverUrl { get; set; }

    // Compatibility aliases (some views/controllers use PostID / CoverURL)
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int PostID
    {
        get => PostId;
        set => PostId = value;
    }

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? CoverURL
    {
        get => CoverUrl;
        set => CoverUrl = value;
    }

    public bool IsPublished { get; set; }

    public string? Status { get; set; }

    public DateTime? PublishedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual User Author { get; set; } = null!;

    // Compatibility alias for AuthorID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int AuthorID
    {
        get => AuthorId;
        set => AuthorId = value;
    }
}
