// [[SERVICE-IMPL-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// CvTextExtractionService — đọc NỘI DUNG VĂN BẢN thô từ file CV (PDF/DOCX) mà
// ứng viên đã upload, phục vụ 2 tính năng: (1) LocalCvMatchService so khớp CV
// với tin tuyển dụng bằng thuật toán từ khóa nội bộ (không cần AI), và
// (2) GeminiService gửi văn bản này cho AI phân tích độ phù hợp.
// - PDF: dùng thư viện iText7 (PdfDocument + PdfTextExtractor) đọc từng trang.
// - DOCX: dùng DocumentFormat.OpenXml đọc các đoạn văn (Paragraph) trong body.
// - File .doc (Word cũ, định dạng binary) KHÔNG được hỗ trợ -> trả về rỗng.
// Mọi lỗi đọc file đều được bắt (try/catch) và trả về chuỗi rỗng thay vì crash.
// ═══════════════════════════════════════════════════════════════════════════
using System.Text;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using iText.Kernel.Pdf;
using iText.Kernel.Pdf.Canvas.Parser;

namespace JobConnect.Services;

public interface ICvTextExtractionService
{
    /// <summary>
    /// Đọc nội dung text từ file CV (PDF hoặc DOCX) trên đĩa.
    /// Trả về chuỗi rỗng nếu không đọc được (file .doc cũ, file lỗi, ảnh scan không có text...).
    /// </summary>
    Task<string> ExtractTextAsync(string absoluteFilePath);
}

public class CvTextExtractionService : ICvTextExtractionService
{
    private readonly ILogger<CvTextExtractionService> _logger;

    public CvTextExtractionService(ILogger<CvTextExtractionService> logger)
    {
        _logger = logger;
    }

    public Task<string> ExtractTextAsync(string absoluteFilePath)
    {
        try
        {
            var ext = Path.GetExtension(absoluteFilePath).ToLowerInvariant();

            return ext switch
            {
                ".pdf" => Task.FromResult(ExtractFromPdf(absoluteFilePath)),
                ".docx" => Task.FromResult(ExtractFromDocx(absoluteFilePath)),
                // .doc (định dạng Word cũ, binary) không có thư viện đọc thuần .NET ổn định —
                // trả về rỗng, phía trên sẽ báo người dùng nên tải lại CV dạng PDF/DOCX.
                _ => Task.FromResult(string.Empty)
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Không đọc được nội dung file CV: {Path}", absoluteFilePath);
            return Task.FromResult(string.Empty);
        }
    }

    private static string ExtractFromPdf(string path)
    {
        var sb = new StringBuilder();
        using var reader = new PdfReader(path);
        using var pdfDoc = new PdfDocument(reader);
        for (int i = 1; i <= pdfDoc.GetNumberOfPages(); i++)
        {
            var page = pdfDoc.GetPage(i);
            sb.AppendLine(PdfTextExtractor.GetTextFromPage(page));
        }
        return sb.ToString();
    }

    private static string ExtractFromDocx(string path)
    {
        var sb = new StringBuilder();
        using var doc = WordprocessingDocument.Open(path, false);
        var body = doc.MainDocumentPart?.Document?.Body;
        if (body == null) return string.Empty;

        foreach (var text in body.Descendants<Text>())
        {
            sb.Append(text.Text);
            sb.Append(' ');
        }
        return sb.ToString();
    }
}