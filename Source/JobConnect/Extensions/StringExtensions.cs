using JobConnect.Extensions;
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
