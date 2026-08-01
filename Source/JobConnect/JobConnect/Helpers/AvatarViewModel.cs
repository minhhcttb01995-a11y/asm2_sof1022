// [[FILE-HEADER-ADDED]]
// ViewModel nhỏ gói dữ liệu cần thiết để render 1 avatar (URL ảnh hoặc chữ cái + màu nền).
namespace JobConnect.Helpers;

public class AvatarViewModel
{
    public string? ImageUrl { get; set; }
    public string? Name { get; set; }
    public int SizePx { get; set; } = 40;
}
