// [MODEL-HEADER-ADDED]
// Bảng DANH MỤC NGÀNH NGHỀ / LĨNH VỰC, dùng để phân loại JobPost và Skill.
// Hỗ trợ cây phân cấp (ParentId/Parent/InverseParent) — 1 danh mục cha có thể
// có nhiều danh mục con.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Category
{
    public int CategoryId { get; set; }

    public int? ParentId { get; set; }

    public string Name { get; set; } = null!;

    public string Type { get; set; } = null!;

    public string Slug { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Category> InverseParent { get; set; } = new List<Category>();

    public virtual ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();

    public virtual Category? Parent { get; set; }

    public virtual ICollection<Skill> Skills { get; set; } = new List<Skill>();

    // Compatibility alias for CategoryID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int CategoryID
    {
        get => CategoryId;
        set => CategoryId = value;
    }
}
