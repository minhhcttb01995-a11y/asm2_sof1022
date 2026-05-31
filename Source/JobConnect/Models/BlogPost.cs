using System;
using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class BlogPost
{
    [Key]
    public int PostID { get; set; }

    public int AuthorID { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Excerpt { get; set; }
    public string? Content { get; set; }
    public string? CoverURL { get; set; }
    public bool IsPublished { get; set; }
    public DateTime? PublishedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation
    public User? Author { get; set; }
}
