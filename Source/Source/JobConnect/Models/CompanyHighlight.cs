namespace JobConnect.Models;

public class CompanyHighlight
{
    public string Icon { get; set; } = "star";
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsHighlighted { get; set; }
}
