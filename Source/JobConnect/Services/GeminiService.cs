// [[SERVICE-IMPL-HEADER-ADDED]]
// ═══════════════════════════════════════════════════════════════════════════
// GeminiService — cài đặt IGeminiService: gọi API của Google Gemini (AI) qua
// HTTP để phục vụ 2 tính năng AI của hệ thống:
//   1) GenerateCvAsync: nhận thông tin thô người dùng nhập (họ tên, kỹ năng,
//      kinh nghiệm...) -> ghép thành 1 "prompt" (câu lệnh) yêu cầu Gemini viết
//      lại thành nội dung CV chuyên nghiệp, YÊU CẦU AI TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON
//      để code có thể parse (System.Text.Json) thành AiCvResult.
//   2) AnalyzeMatchAsync: gửi nội dung CV + nội dung tin tuyển dụng, yêu cầu AI
//      chấm % độ phù hợp + liệt kê điểm mạnh/điểm thiếu, trả về AiMatchResult.
// Cấu hình API Key + tên Model đọc từ appsettings.json (mục "GeminiSettings").
// Nếu chưa cấu hình ApiKey, các hàm trả về Success=false kèm thông báo lỗi rõ ràng
// thay vì gọi API và crash. HttpClient được cấu hình timeout 30s trong Program.cs.
// ═══════════════════════════════════════════════════════════════════════════
using System.Text;
using System.Text.Json;

namespace JobConnect.Services;

public class GeminiService : IGeminiService
{
    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly ILogger<GeminiService> _logger;

    private string ApiKey => _config["GeminiSettings:ApiKey"] ?? "";
    private string Model => _config["GeminiSettings:Model"] ?? "gemini-2.0-flash";

    public GeminiService(HttpClient http, IConfiguration config, ILogger<GeminiService> logger)
    {
        _http = http;
        _config = config;
        _logger = logger;
    }

    // ─── Public API ─────────────────────────────────────────────────────────

    public async Task<AiCvResult> GenerateCvAsync(AiCvRequest request)
    {
        if (string.IsNullOrWhiteSpace(ApiKey))
            return new AiCvResult { Success = false, Error = "Chưa cấu hình GeminiSettings:ApiKey trong appsettings.json." };

        var prompt = $@"Bạn là chuyên gia tuyển dụng và viết CV chuyên nghiệp. Dựa trên thông tin thô dưới đây, hãy viết lại thành nội dung CV chuyên nghiệp, súc tích, dùng tiếng Việt.

Họ tên: {request.FullName}
Vị trí ứng tuyển mong muốn: {request.JobTitle}
Số năm kinh nghiệm: {request.ExperienceYears}
Kỹ năng (thô): {request.Skills}
Học vấn (thô): {request.Education}
Quá trình làm việc (thô): {request.WorkHistory}
Thành tích / giải thưởng (thô): {request.Achievements}
Ngôn ngữ (thô): {request.Languages}

Hãy trả về DUY NHẤT một JSON object (không markdown, không giải thích thêm) đúng cấu trúc sau:
{{
  ""summary"": ""đoạn tóm tắt bản thân 3-4 câu, chuyên nghiệp, nêu bật thế mạnh"",
  ""skills"": [""kỹ năng 1"", ""kỹ năng 2"", ""...""],
  ""experience"": [""dòng mô tả kinh nghiệm 1 (dạng bullet, có động từ mạnh, số liệu nếu có)"", ""dòng 2""],
  ""education"": [""dòng học vấn 1"", ""dòng 2""],
  ""achievements"": [""thành tích 1"", ""thành tích 2""],
  ""languages"": [""VD: Tiếng Anh - Khá (giao tiếp tốt)"", ""VD: Tiếng Nhật - N3""]
}}";

        var json = await CallGeminiAsync(prompt);
        if (json == null)
            return new AiCvResult { Success = false, Error = "Không gọi được Gemini API. Kiểm tra API key hoặc kết nối mạng." };

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            return new AiCvResult
            {
                Success = true,
                Summary = root.TryGetProperty("summary", out var s) ? s.GetString() ?? "" : "",
                Skills = ReadStringArray(root, "skills"),
                Experience = ReadStringArray(root, "experience"),
                Education = ReadStringArray(root, "education"),
                Achievements = ReadStringArray(root, "achievements"),
                Languages = ReadStringArray(root, "languages")
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Không parse được JSON CV từ Gemini: {Json}", json);
            return new AiCvResult { Success = false, Error = "AI trả về dữ liệu không hợp lệ, vui lòng thử lại." };
        }
    }

    public async Task<AiMatchResult> AnalyzeMatchAsync(string candidateText, string jobText)
    {
        if (string.IsNullOrWhiteSpace(ApiKey))
            return new AiMatchResult { Success = false, Error = "Chưa cấu hình GeminiSettings:ApiKey trong appsettings.json." };

        var prompt = $@"Bạn là hệ thống AI đánh giá mức độ phù hợp giữa CV của ứng viên và tin tuyển dụng. Hãy phân tích kỹ nội dung CV thực tế bên dưới (được trích xuất từ file CV ứng viên nộp) so với yêu cầu công việc.

=== NỘI DUNG CV ỨNG VIÊN ===
{candidateText}

=== TIN TUYỂN DỤNG ===
{jobText}

Hãy trả về DUY NHẤT một JSON object (không markdown, không giải thích thêm) đúng cấu trúc sau:
{{
  ""matchPercent"": <số nguyên từ 0 đến 100, mức độ phù hợp>,
  ""strengths"": [""điểm phù hợp 1"", ""điểm phù hợp 2""],
  ""gaps"": [""điểm còn thiếu/chưa phù hợp 1"", ""điểm 2""],
  ""summary"": ""nhận xét tổng quan 2-3 câu""
}}";

        var json = await CallGeminiAsync(prompt);
        if (json == null)
            return new AiMatchResult { Success = false, Error = "Không gọi được Gemini API. Kiểm tra API key hoặc kết nối mạng." };

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            var percent = root.TryGetProperty("matchPercent", out var p) ? p.GetInt32() : 0;
            percent = Math.Clamp(percent, 0, 100);

            return new AiMatchResult
            {
                Success = true,
                MatchPercent = percent,
                Strengths = ReadStringArray(root, "strengths"),
                Gaps = ReadStringArray(root, "gaps"),
                Summary = root.TryGetProperty("summary", out var s) ? s.GetString() ?? "" : ""
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Không parse được JSON match từ Gemini: {Json}", json);
            return new AiMatchResult { Success = false, Error = "AI trả về dữ liệu không hợp lệ, vui lòng thử lại." };
        }
    }

    // ─── Internal helpers ───────────────────────────────────────────────────

    private static List<string> ReadStringArray(JsonElement root, string prop)
    {
        var list = new List<string>();
        if (root.TryGetProperty(prop, out var arr) && arr.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in arr.EnumerateArray())
            {
                var v = item.GetString();
                if (!string.IsNullOrWhiteSpace(v)) list.Add(v);
            }
        }
        return list;
    }

    private string GroqApiKey => _config["Groq:ApiKey"] ?? "";
    private string GroqModel => _config["Groq:Model"] ?? "llama-3.3-70b-versatile";

    /// <summary>
    /// Gọi AI để lấy phản hồi JSON. Thử Gemini trước; nếu Gemini lỗi (hết quota, sai key, mất mạng...)
    /// và đã cấu hình Groq, tự động fallback sang Groq (API tương thích chuẩn OpenAI) để không gián đoạn tính năng.
    /// </summary>
    private async Task<string?> CallGeminiAsync(string prompt)
    {
        var geminiResult = await CallGeminiRawAsync(prompt);
        if (geminiResult != null) return geminiResult;

        if (!string.IsNullOrWhiteSpace(GroqApiKey))
        {
            _logger.LogWarning("Gemini thất bại, đang thử fallback sang Groq...");
            return await CallGroqAsync(prompt);
        }

        return null;
    }

    private async Task<string?> CallGeminiRawAsync(string prompt)
    {
        try
        {
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/{Model}:generateContent?key={ApiKey}";

            var body = new
            {
                contents = new[]
                {
                    new { parts = new[] { new { text = prompt } } }
                },
                generationConfig = new
                {
                    temperature = 0.4,
                    response_mime_type = "application/json"
                }
            };

            var content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");
            var response = await _http.PostAsync(url, content);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Gemini API trả lỗi {Status}: {Body}", response.StatusCode, responseBody);
                return null;
            }

            using var doc = JsonDocument.Parse(responseBody);
            var text = doc.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();

            if (string.IsNullOrWhiteSpace(text)) return null;

            return StripJsonFences(text);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gọi Gemini API");
            return null;
        }
    }

    /// <summary>Gọi Groq (endpoint tương thích OpenAI Chat Completions) làm nguồn AI dự phòng.</summary>
    private async Task<string?> CallGroqAsync(string prompt)
    {
        try
        {
            var url = "https://api.groq.com/openai/v1/chat/completions";

            var body = new
            {
                model = GroqModel,
                temperature = 0.4,
                response_format = new { type = "json_object" },
                messages = new[]
                {
                    new { role = "user", content = prompt }
                }
            };

            using var request = new HttpRequestMessage(HttpMethod.Post, url);
            request.Headers.Add("Authorization", $"Bearer {GroqApiKey}");
            request.Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");

            var response = await _http.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Groq API trả lỗi {Status}: {Body}", response.StatusCode, responseBody);
                return null;
            }

            using var doc = JsonDocument.Parse(responseBody);
            var text = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            if (string.IsNullOrWhiteSpace(text)) return null;

            return StripJsonFences(text);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gọi Groq API (fallback)");
            return null;
        }
    }

    /// <summary>Phòng trường hợp model vẫn bọc JSON trong ```json ... ``` markdown fences.</summary>
    private static string StripJsonFences(string text)
    {
        text = text.Trim();
        if (text.StartsWith("```"))
        {
            var firstNewline = text.IndexOf('\n');
            text = text[(firstNewline + 1)..];
            var lastFence = text.LastIndexOf("```", StringComparison.Ordinal);
            if (lastFence >= 0) text = text[..lastFence];
        }
        return text.Trim();
    }
}