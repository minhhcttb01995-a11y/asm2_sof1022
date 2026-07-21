// [[FILE-HEADER-ADDED]]
// Hàm tiện ích trả về class CSS (màu badge Tailwind) tương ứng với 1 giá trị Status,
// dùng để hiển thị nhãn trạng thái có màu sắc nhất quán trên toàn bộ giao diện.
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.AspNetCore.Razor.TagHelpers;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Extensions;

/// <summary>
/// TagHelper để hiển thị badge trạng thái dựa trên StatusCatalog
/// Usage: <status-badge entity-type="Candidate" code="Active" />
/// </summary>
[HtmlTargetElement("status-badge")]
public class StatusBadgeTagHelper : TagHelper
{
    private readonly AppDbContext _db;

    public StatusBadgeTagHelper(AppDbContext db)
    {
        _db = db;
    }

    [HtmlAttributeName("entity-type")]
    public string EntityType { get; set; } = string.Empty;

    [HtmlAttributeName("code")]
    public string Code { get; set; } = string.Empty;

    [HtmlAttributeName("class")]
    public string? AdditionalClass { get; set; }

    public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
    {
        output.TagName = "span";
        output.TagMode = TagMode.StartTagAndEndTag;

        // Lấy thông tin status từ StatusCatalog
        var status = await _db.StatusCatalogs
            .FirstOrDefaultAsync(s => s.EntityType == EntityType && s.Code == Code);

        if (status != null && status.IsActive)
        {
            // Sử dụng ColorClass từ StatusCatalog
            var cssClass = !string.IsNullOrEmpty(status.ColorClass) 
                ? status.ColorClass 
                : "bg-gray-100 text-gray-700";
            
            if (!string.IsNullOrEmpty(AdditionalClass))
            {
                cssClass += $" {AdditionalClass}";
            }

            output.Attributes.SetAttribute("class", cssClass);
            output.Content.SetContent(status.Name);
        }
        else
        {
            // Fallback nếu không tìm thấy hoặc không active
            var cssClass = "bg-gray-100 text-gray-700";
            if (!string.IsNullOrEmpty(AdditionalClass))
            {
                cssClass += $" {AdditionalClass}";
            }

            output.Attributes.SetAttribute("class", cssClass);
            output.Content.SetContent(Code);
        }
    }
}
