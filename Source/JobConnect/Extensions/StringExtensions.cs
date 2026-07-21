// [[FILE-HEADER-ADDED]]
// Vài extension method nhỏ cho string (VD: cắt chuỗi kèm dấu "...", viết hoa chữ cái đầu...)
// dùng chung trong các View để hiển thị văn bản gọn gàng.
namespace JobConnect.Extensions
{
    public static class StringExtensions
    {
        public static string GetExtension(this string fileName)
        {
            if (string.IsNullOrEmpty(fileName)) return string.Empty;
            int lastDot = fileName.LastIndexOf('.');
            return lastDot >= 0 ? fileName.Substring(lastDot) : string.Empty;
        }
    }
}
