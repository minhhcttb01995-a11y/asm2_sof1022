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
