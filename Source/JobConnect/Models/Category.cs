using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Category
{
    [Key]
    public int CategoryID { get; set; }
    public int? ParentID { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;  // Industry|Location|Level|JobType
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    public Category? Parent { get; set; }
    public ICollection<Category> Children { get; set; } = new List<Category>();
    public ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();
    public ICollection<Skill> Skills { get; set; } = new List<Skill>();
}