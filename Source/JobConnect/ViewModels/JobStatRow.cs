namespace JobConnect.ViewModels;

public class JobStatRow
{
    public int JobId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? Deadline { get; set; }
    public int ViewCount { get; set; }
    public int ApplyCount { get; set; }
    public double ConversionRate { get; set; }
}
