// [SERVICE-IMPL-HEADER-ADDED]
// JobModerationService — điều phối tính năng KIỂM DUYỆT AI bài đăng tuyển dụng:
//   1) Tính CompanyTrustScore và SimilarityPercent KHÁCH QUAN từ DB (không để AI đoán).
//   2) Gọi IGeminiService.AnalyzeJobModerationAsync để lấy điểm thô từng module.
//   3) TỰ TÍNH LẠI OverallRisk + Recommendation bằng C# theo đúng công thức trọng số +
//      "risk floor" cho các module nghiêm trọng (Scam/Adult/Violence/Hate) — KHÔNG bao
//      giờ dùng trực tiếp con số overallRisk/recommendation mà model tự đề xuất, vì:
//        - Model có thể cộng sai trọng số.
//        - Đây là lớp phòng thủ cuối cùng chống prompt injection: dù nội dung tin đăng có
//          chèn chỉ thị khiến model trả overallRisk=0/Approve, hệ thống vẫn tính lại từ
//          điểm modules thô nên kết quả cuối vẫn phản ánh đúng mức độ rủi ro thực tế.
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace JobConnect.Services;

public interface IJobModerationService
{
    /// <summary>
    /// Chấm 1 tin: nếu đã có log với ContentHash khớp nội dung hiện tại -> trả kết quả cũ
    /// từ DB (KHÔNG gọi AI). Nếu chưa có hoặc nội dung đã đổi -> gọi AI, lưu/ghi đè log, trả kết quả mới.
    /// </summary>
    Task<JobModerationResult> ModerateAsync(JobPost job, Employer employer);

    /// <summary>
    /// Chấm nhiều tin cùng lúc (dùng cho trang danh sách "Duyệt tin" — tự động hiện %
    /// rủi ro cho từng dòng khi Staff vừa mở trang). Trả về Dictionary JobId -> kết quả.
    /// Tin nào đã có cache hợp lệ sẽ không tốn lượt gọi AI nào.
    /// </summary>
    Task<Dictionary<int, JobModerationResult>> ModerateManyAsync(List<JobPost> jobs);
}

public class JobModerationService : IJobModerationService
{
    private readonly AppDbContext _db;
    private readonly IGeminiService _gemini;
    private readonly ILogger<JobModerationService> _logger;

    // Ngưỡng "risk floor": các module này nếu đạt từ mức này trở lên thì OverallRisk
    // không được phép thấp hơn chính điểm module đó, bất kể công thức trọng số ra sao.
    private const int SevereFloorThreshold = 70;
    // Từ ngưỡng này, ép Reject ngay lập tức bất kể OverallRisk tổng.
    private const int AutoRejectThreshold = 90;

    public JobModerationService(AppDbContext db, IGeminiService gemini, ILogger<JobModerationService> logger)
    {
        _db = db;
        _gemini = gemini;
        _logger = logger;
    }

    public async Task<JobModerationResult> ModerateAsync(JobPost job, Employer employer)
    {
        var contentHash = ComputeContentHash(job);

        var existingLog = await _db.JobModerationLogs
            .FirstOrDefaultAsync(l => l.JobId == job.JobId);

        // Nội dung tin không đổi từ lần chấm trước -> trả thẳng kết quả cũ, KHÔNG gọi AI.
        if (existingLog != null && existingLog.ContentHash == contentHash)
        {
            return FromLog(existingLog, fromCache: true);
        }

        // ═══════════════════ TẦNG 0 — RULE-BASED (C#, không AI, chạy tức thì) ═══════════════════
        // 4/9 module KHÔNG cần "hiểu ngôn ngữ" — có thể tính 100% bằng công thức/luật, không cần
        // gửi cho AI: Duplicate (so khớp với DB), CompanyTrust (dữ liệu tài khoản), Missing
        // Information (check các trường null), Fake Salary (luật số + từ khóa).
        var dbScoresTask = ComputeDbRuleScoresAsync(employer, job);
        var missingInfoModule = ComputeMissingInformationModule(job, employer);
        var fakeSalaryModule = ComputeFakeSalaryModule(job);

        // ═══════════════════ TẦNG 1 — HYBRID cho 5 module còn lại (Spam/Scam/Violence/Hate/Adult) ═══
        // Bước 1: chấm bằng RuleBasedContentModeration TRƯỚC (đồng bộ, tức thì, 0 token).
        // Bước 2: chỉ gọi AI khi kết quả rule rơi vào "vùng xám" — không đủ rõ ràng để tự tin
        // kết luận an toàn hay vi phạm. Đa số tin (rõ ràng sạch HOẶC rõ ràng vi phạm nặng) sẽ
        // KHÔNG cần gọi AI -> tiết kiệm phần lớn token mà vẫn giữ độ chính xác cho case khó.
        var ruleResult = RuleBasedContentModeration.ComputeAll(job);
        var needsAi = IsGrayZone(ruleResult.Modules);

        JobModerationResult result;
        if (!needsAi)
        {
            // Vùng an toàn/rõ ràng vi phạm -> dùng luôn kết quả rule-based, KHÔNG gọi AI.
            var (companyTrustScoreSkip, similarityPercentSkip) = await dbScoresTask;
            result = ruleResult;
            result.Summary = "Chấm bằng luật/từ khóa (rule-based) — không cần AI vì kết quả đủ rõ ràng.";
            result.Modules.Add(missingInfoModule);
            result.Modules.Add(fakeSalaryModule);
            result.Modules.Add(BuildTrustModule(companyTrustScoreSkip));
            result.Modules.Add(BuildDuplicateModule(similarityPercentSkip));

            RecalculateRisk(result);
            await SaveLogAsync(job.JobId, contentHash, result, existingLog);
            return result;
        }

        // Vùng xám -> gọi AI để phân xử thêm 5 module đó (song song với 2 query DB).
        var aiRequestTask = BuildAiRequestAndCallAsync(job, employer);
        await Task.WhenAll(dbScoresTask, aiRequestTask);

        var (companyTrustScore, similarityPercent) = dbScoresTask.Result;
        var aiResult = aiRequestTask.Result;

        if (!aiResult.Success)
        {
            // Gọi AI thất bại (hết quota/mất mạng): dùng tạm kết quả rule-based (vẫn có giá trị,
            // chỉ kém chính xác hơn AI ở vùng xám) thay vì trả lỗi trắng cho Staff.
            result = ruleResult;
            result.Summary = "AI không khả dụng — đang dùng kết quả rule-based tạm thời cho vùng xám.";
            result.Error = "Không gọi được AI để chấm lại vùng xám (nội dung tin đã đổi) — đang hiển thị kết quả ước tính bằng luật.";
        }
        else
        {
            result = aiResult;
        }

        // Ghép 5 module (AI hoặc rule-based fallback) + 4 module đã tính sẵn bằng luật.
        result.Modules.Add(missingInfoModule);
        result.Modules.Add(fakeSalaryModule);
        result.Modules.Add(BuildTrustModule(companyTrustScore));
        result.Modules.Add(BuildDuplicateModule(similarityPercent));

        RecalculateRisk(result);
        await SaveLogAsync(job.JobId, contentHash, result, existingLog);

        return result;
    }

    // Ngưỡng xác định "vùng xám": module rõ ràng SẠCH (< LowConfidenceThreshold) hoặc rõ ràng
    // VI PHẠM NẶNG (>= HighConfidenceThreshold) thì rule-based đã đủ tự tin, không cần gọi AI.
    private const int LowConfidenceThreshold = 15;
    private const int HighConfidenceThreshold = 75;

    private static bool IsGrayZone(List<JobModerationModule> ruleModules)
    {
        // Rõ ràng vi phạm nặng ở module nghiêm trọng (Scam/Violence/Hate/Adult) -> đủ tự tin
        // để REJECT thẳng, không cần AI xác nhận thêm.
        var severeNames = new[] { "ScamDetection", "ViolenceDetection", "HateSpeechDetection", "AdultContentDetection" };
        var maxSevere = ruleModules.Where(m => severeNames.Contains(m.Name)).Select(m => m.Score).DefaultIfEmpty(0).Max();
        if (maxSevere >= HighConfidenceThreshold) return false; // đủ tự tin -> không cần AI

        // Tất cả 5 module đều rất thấp -> đủ tự tin là tin sạch, không cần AI.
        var allLow = ruleModules.All(m => m.Score < LowConfidenceThreshold);
        if (allLow) return false;

        // Còn lại (mập mờ, không đủ rõ ràng theo cả 2 hướng) -> cần AI phân xử thêm.
        return true;
    }

    /// <summary>
    /// Chạy 2 query DB (CompanyTrustScore, SimilarityPercent) TUẦN TỰ với nhau trong cùng 1 Task
    /// (bắt buộc vì dùng chung _db, EF Core không cho chạy song song trên cùng DbContext).
    /// </summary>
    private async Task<(int TrustScore, int SimilarityPercent)> ComputeDbRuleScoresAsync(Employer employer, JobPost job)
    {
        var trust = await CalculateCompanyTrustScoreAsync(employer);
        var similarity = await CalculateSimilarityPercentAsync(job);
        return (trust, similarity);
    }

    /// <summary>Ghép request + gọi AI — không đụng tới _db nên an toàn khi chạy song song với ComputeDbRuleScoresAsync.</summary>
    private async Task<JobModerationResult> BuildAiRequestAndCallAsync(JobPost job, Employer employer)
    {
        var request = new JobModerationRequest
        {
            JobTitle = job.Title ?? "",
            JobDescription = job.Description ?? "",
            Salary = FormatSalary(job),
            CompanyName = employer.CompanyName ?? "",
            Website = employer.Website,
            Email = employer.User?.Email,
            Location = job.Location,
            Requirements = job.Requirements,
            Benefits = job.Benefits,
            Skills = null
        };

        return await _gemini.AnalyzeJobModerationAsync(request);
    }

    /// <summary>
    /// Lưu ý: các tin trong danh sách được chấm TUẦN TỰ với nhau (từng tin gọi ModerateAsync),
    /// vì tất cả dùng chung 1 AppDbContext (_db) trong 1 request — EF Core không cho nhiều
    /// query chạy đồng thời trên cùng DbContext, nên không thể Parallel.ForEach qua các tin.
    /// Tuy nhiên BÊN TRONG mỗi tin, AI-call và DB-query đã chạy song song (xem ModerateAsync),
    /// nên tổng thời gian vẫn nhanh hơn đáng kể so với chấm tuần tự hoàn toàn từng bước.
    /// Muốn song song thật giữa các tin (VD: chấm 10 tin cùng lúc) cần dùng IDbContextFactory
    /// để mỗi tin có 1 DbContext riêng — có thể làm thêm nếu vẫn thấy chậm.
    /// </summary>
    public async Task<Dictionary<int, JobModerationResult>> ModerateManyAsync(List<JobPost> jobs)
    {
        var results = new Dictionary<int, JobModerationResult>();
        if (jobs.Count == 0) return results;

        foreach (var job in jobs)
        {
            var employer = job.Employer;
            if (employer == null)
            {
                results[job.JobId] = new JobModerationResult { Success = false, Error = "Thiếu dữ liệu Employer." };
                continue;
            }

            try
            {
                // Gọi từng tin qua ModerateAsync (đã tự check cache riêng theo ContentHash bên trong) —
                // tin nào không đổi nội dung so với lần trước sẽ không tốn lượt gọi AI nào.
                results[job.JobId] = await ModerateAsync(job, employer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi chấm AI cho JobId={JobId}", job.JobId);
                results[job.JobId] = new JobModerationResult { Success = false, Error = "Có lỗi xảy ra khi chấm tin này." };
            }
        }

        return results;
    }

    // ─── Cache: tính hash nội dung + đọc/ghi bảng JobModerationLog ─────────────

    private static string ComputeContentHash(JobPost job)
    {
        var raw = string.Join("|",
            job.Title, job.Description, job.Requirements, job.Benefits,
            job.SalaryMin, job.SalaryMax, job.SalaryNegotiable, job.Location);

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
        return Convert.ToHexString(bytes); // 64 ký tự hex
    }

    private async Task SaveLogAsync(int jobId, string contentHash, JobModerationResult result, JobModerationLog? existingLog)
    {
        var modulesJson = JsonSerializer.Serialize(result.Modules);

        if (existingLog != null)
        {
            existingLog.ContentHash = contentHash;
            existingLog.OverallRisk = result.OverallRisk;
            existingLog.Recommendation = result.Recommendation;
            existingLog.Summary = result.Summary;
            existingLog.ModulesJson = modulesJson;
            existingLog.UpdatedAt = DateTime.Now;
        }
        else
        {
            _db.JobModerationLogs.Add(new JobModerationLog
            {
                JobId = jobId,
                ContentHash = contentHash,
                OverallRisk = result.OverallRisk,
                Recommendation = result.Recommendation,
                Summary = result.Summary,
                ModulesJson = modulesJson,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            });
        }

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            // Không để lỗi lưu cache làm hỏng kết quả trả về cho Staff xem — chỉ log lại.
            _logger.LogError(ex, "Không lưu được JobModerationLog cho JobId={JobId}", jobId);
        }
    }

    private static JobModerationResult FromLog(JobModerationLog log, bool fromCache)
    {
        List<JobModerationModule> modules;
        try
        {
            modules = JsonSerializer.Deserialize<List<JobModerationModule>>(log.ModulesJson) ?? new();
        }
        catch
        {
            modules = new();
        }

        return new JobModerationResult
        {
            Success = true,
            OverallRisk = log.OverallRisk,
            Recommendation = log.Recommendation,
            Summary = log.Summary ?? "",
            Modules = modules,
            RiskRecalculatedByServer = true,
            FromCache = fromCache
        };
    }

    // ─── Tính CompanyTrustScore khách quan (0-100, cao = uy tín) ───────────────
    // Không dùng AI để đoán độ uy tín công ty theo tên — dùng dữ liệu thật trong DB.
    private async Task<int> CalculateCompanyTrustScoreAsync(Employer employer)
    {
        int score = 50; // điểm khởi điểm trung tính

        if (employer.IsVerified) score += 30;
        if (employer.IsLocked) score -= 50;
        if (!string.IsNullOrWhiteSpace(employer.TaxCode)) score += 10;
        if (!string.IsNullOrWhiteSpace(employer.Website)) score += 5;

        // Tài khoản càng lâu năm càng đáng tin (tối đa +15)
        var accountAgeDays = (DateTime.Now - employer.CreatedAt).TotalDays;
        if (accountAgeDays >= 180) score += 15;
        else if (accountAgeDays >= 30) score += 5;

        // Bị report nhiều thì trừ điểm, report đã xử lý (không còn Pending) ảnh hưởng ít hơn
        var reportCount = await _db.Reports
            .Where(r => r.CompanyId == employer.EmployerId)
            .CountAsync();
        score -= Math.Min(reportCount * 8, 40);

        return Math.Clamp(score, 0, 100);
    }

    // ─── Tính SimilarityPercent khách quan (0-100) ─────────────────────────────
    // So khớp thô (tỷ lệ từ trùng nhau) giữa tiêu đề+mô tả bài đăng này với các bài
    // đăng ĐANG HOẠT ĐỘNG khác của CÙNG employer — phát hiện đăng trùng lặp nhiều lần.
    // Đây là thuật toán đơn giản (Jaccard trên tập từ), đủ dùng làm tín hiệu tham khảo
    // cho module DuplicateDetection chứ không thay thế được hệ thống chống trùng chuyên sâu.
    private async Task<int> CalculateSimilarityPercentAsync(JobPost job)
    {
        var others = await _db.JobPosts
            .Where(j => j.EmployerId == job.EmployerId
                        && j.JobId != job.JobId
                        && j.Status != "Deleted")
            .Select(j => new { j.Title, j.Description })
            .Take(50)
            .ToListAsync();

        if (others.Count == 0) return 0;

        var baseTokens = Tokenize($"{job.Title} {job.Description}");
        if (baseTokens.Count == 0) return 0;

        int best = 0;
        foreach (var other in others)
        {
            var otherTokens = Tokenize($"{other.Title} {other.Description}");
            if (otherTokens.Count == 0) continue;

            var intersect = baseTokens.Intersect(otherTokens).Count();
            var union = baseTokens.Union(otherTokens).Count();
            if (union == 0) continue;

            var percent = (int)Math.Round(intersect * 100.0 / union);
            if (percent > best) best = percent;
        }

        return best;
    }

    private static HashSet<string> Tokenize(string text)
    {
        return text.ToLowerInvariant()
            .Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)
            .Where(w => w.Length > 2)
            .ToHashSet();
    }

    private static string FormatSalary(JobPost job)
    {
        if (job.SalaryNegotiable) return "Thỏa thuận";
        if (job.SalaryMin.HasValue && job.SalaryMax.HasValue) return $"{job.SalaryMin:N0} - {job.SalaryMax:N0} VNĐ";
        if (job.SalaryMin.HasValue) return $"Từ {job.SalaryMin:N0} VNĐ";
        if (job.SalaryMax.HasValue) return $"Đến {job.SalaryMax:N0} VNĐ";
        return "Không ghi";
    }

    // ═══════════════════ TẦNG 0 — CÁC MODULE TÍNH BẰNG LUẬT (không cần AI) ═══════════════════

    /// <summary>MissingInformationDetection — kiểm tra rỗng/null trực tiếp trên field, không cần AI.</summary>
    private static JobModerationModule ComputeMissingInformationModule(JobPost job, Employer employer)
    {
        var issues = new List<JobModerationIssue>();

        void Check(bool isMissing, string label)
        {
            if (isMissing) issues.Add(new JobModerationIssue { Issue = $"Thiếu {label}" });
        }

        Check(string.IsNullOrWhiteSpace(employer.CompanyName), "tên công ty");
        Check(string.IsNullOrWhiteSpace(employer.Address), "địa chỉ công ty");
        Check(string.IsNullOrWhiteSpace(employer.User?.Email), "email công ty");
        Check(string.IsNullOrWhiteSpace(employer.Website), "website công ty");
        Check(string.IsNullOrWhiteSpace(job.Description), "mô tả công việc");
        Check(string.IsNullOrWhiteSpace(job.Benefits), "quyền lợi");
        Check(string.IsNullOrWhiteSpace(job.Requirements), "yêu cầu công việc");
        Check(job.Deadline == null, "hạn tuyển");
        Check(string.IsNullOrWhiteSpace(job.Location), "địa điểm làm việc");

        // Mỗi mục thiếu +12 điểm, tối đa 100. Thiếu >=5 mục -> "nghiêm trọng" (>=60).
        var score = Math.Clamp(issues.Count * 12, 0, 100);

        return new JobModerationModule { Name = "MissingInformationDetection", Score = score, Issues = issues };
    }

    // Các cụm từ phóng đại/mơ hồ về lương — nếu xuất hiện thì luôn coi là dấu hiệu đáng ngờ.
    private static readonly string[] VagueSalaryPhrases =
    {
        "lương không giới hạn", "thu nhập không giới hạn", "thu nhập khủng",
        "không giới hạn thu nhập", "lương khủng"
    };

    /// <summary>
    /// FakeSalaryDetection — chấm bằng luật số + từ khóa (không cần AI phán đoán "hợp lý
    /// theo ngành" vì dễ đoán sai; các dấu hiệu dưới đây đều là dấu hiệu CỤ THỂ, kiểm tra được
    /// thẳng bằng C# không cần hiểu ngôn ngữ sâu).
    /// </summary>
    private static JobModerationModule ComputeFakeSalaryModule(JobPost job)
    {
        var issues = new List<JobModerationIssue>();
        int score = 0;

        var text = $"{job.Title} {job.Description}".ToLowerInvariant();
        foreach (var phrase in VagueSalaryPhrases)
        {
            if (text.Contains(phrase))
            {
                issues.Add(new JobModerationIssue { Issue = "Dùng cụm từ phóng đại về lương", Evidence = phrase });
                score += 40;
            }
        }

        if (!job.SalaryNegotiable && job.SalaryMin.HasValue && job.SalaryMax.HasValue)
        {
            // Lương Min > Max là dữ liệu VÔ LÝ TUYỆT ĐỐI (không có cách nào hợp lý hóa được,
            // khác với các dấu hiệu khác chỉ là "đáng ngờ") -> chấm thẳng điểm tối đa 100,
            // kết hợp với FakeSalaryFloorThreshold bên dưới (RecalculateRisk) để ép Reject
            // ngay lập tức, không phụ thuộc trọng số 0.15 vốn có thể bị pha loãng bởi các
            // module khác đang thấp.
            if (job.SalaryMin.Value > job.SalaryMax.Value)
            {
                issues.Add(new JobModerationIssue
                {
                    Issue = "Lương tối thiểu lớn hơn lương tối đa (dữ liệu không hợp lệ)",
                    Evidence = $"{job.SalaryMin:N0} - {job.SalaryMax:N0}"
                });
                score += 100;
            }
            // Khoảng lương chênh lệch quá lớn (Max > 10 lần Min) -> câu view.
            else if (job.SalaryMin.Value > 0 && job.SalaryMax.Value / job.SalaryMin.Value >= 10)
            {
                issues.Add(new JobModerationIssue
                {
                    Issue = "Khoảng lương chênh lệch bất thường (Max/Min >= 10 lần)",
                    Evidence = $"{job.SalaryMin:N0} - {job.SalaryMax:N0}"
                });
                score += 30;
            }

            // Số tiền cực lớn cho các vị trí phổ thông (heuristic: > 100 triệu/tháng là bất thường
            // với đa số vị trí trừ khi ghi rõ là năm/dự án — dữ liệu Salary hiện là theo tháng).
            if (job.SalaryMax.Value >= 100_000_000)
            {
                issues.Add(new JobModerationIssue
                {
                    Issue = "Mức lương tối đa vượt bất thường (>= 100 triệu/tháng)",
                    Evidence = $"{job.SalaryMax:N0} VNĐ"
                });
                score += 40;
            }
        }
        else if (!job.SalaryNegotiable && !job.SalaryMin.HasValue && !job.SalaryMax.HasValue)
        {
            // Không ghi lương và cũng không chọn "thỏa thuận" -> thiếu thông tin, chỉ chấm nhẹ.
            issues.Add(new JobModerationIssue { Issue = "Không ghi mức lương và không đánh dấu thỏa thuận" });
            score += 15;
        }

        return new JobModerationModule
        {
            Name = "FakeSalaryDetection",
            Score = Math.Clamp(score, 0, 100),
            Issues = issues
        };
    }

    /// <summary>CompanyTrustDetection — quy đổi CompanyTrustScore (đã tính ở CalculateCompanyTrustScoreAsync) sang Score rủi ro.</summary>
    private static JobModerationModule BuildTrustModule(int companyTrustScore)
    {
        int score = companyTrustScore switch
        {
            >= 80 => 0,
            >= 60 => 20,
            >= 40 => 50,
            _ => 80
        };

        return new JobModerationModule
        {
            Name = "CompanyTrustDetection",
            Score = score,
            Issues = new List<JobModerationIssue>
            {
                new() { Issue = $"CompanyTrustScore = {companyTrustScore}/100 (tính từ xác minh, tuổi tài khoản, số report)" }
            }
        };
    }

    /// <summary>DuplicateDetection — dùng trực tiếp SimilarityPercent đã tính (Jaccard với các tin khác của cùng employer).</summary>
    private static JobModerationModule BuildDuplicateModule(int similarityPercent)
    {
        var issues = new List<JobModerationIssue>();
        if (similarityPercent > 0)
        {
            issues.Add(new JobModerationIssue
            {
                Issue = $"Trùng {similarityPercent}% nội dung với 1 tin khác cùng nhà tuyển dụng"
            });
        }

        return new JobModerationModule { Name = "DuplicateDetection", Score = similarityPercent, Issues = issues };
    }


    private void RecalculateRisk(JobModerationResult result)
    {
        int GetScore(string name) => result.Modules.FirstOrDefault(m => m.Name == name)?.Score ?? 0;

        var spam = GetScore("SpamDetection");
        var scam = GetScore("ScamDetection");
        var violence = GetScore("ViolenceDetection");
        var hate = GetScore("HateSpeechDetection");
        var adult = GetScore("AdultContentDetection");
        var salary = GetScore("FakeSalaryDetection");
        var duplicate = GetScore("DuplicateDetection");
        var missing = GetScore("MissingInformationDetection");
        var trust = GetScore("CompanyTrustDetection");

        double baseRisk =
            spam * 0.10 +
            scam * 0.25 +
            violence * 0.05 +
            hate * 0.10 +
            adult * 0.10 +
            salary * 0.15 +
            duplicate * 0.10 +
            missing * 0.05 +
            trust * 0.10;

        // Risk floor cho các vi phạm RẤT NẶNG (Scam/Adult/Violence/Hate): overall risk không
        // được thấp hơn chính điểm module đó -> có thể đẩy thẳng lên "Reject".
        var severeCandidates = new[] { scam, adult, violence, hate }
            .Where(s => s >= SevereFloorThreshold);

        double overallRisk = baseRisk;
        if (severeCandidates.Any())
            overallRisk = Math.Max(overallRisk, severeCandidates.Max());

        // Risk floor RIÊNG cho Spam: nội dung rác/vô nghĩa (VD: "<p>CăDwad</p>") có trọng số
        // trong công thức chỉ 0.10 -> dù chấm Spam=90-100, phần đóng góp vào baseRisk chỉ
        // ~9-10 điểm, không đủ vượt ngưỡng 40 để vào ManualReview, khiến tin rác vẫn hiện "An
        // toàn". Có 2 mức floor:
        //   - Spam >= 70 (rác vừa, VD viết hoa/emoji nhiều nhưng còn có nội dung thật) ->
        //     ManualReview (>=40), để Staff còn quyết định.
        //   - Spam >= 90 (rác TOÀN PHẦN, gần như không có nội dung nghĩa nào — mức chỉ đạt
        //     được khi content quá ngắn/vô nghĩa, xem ComputeSpam) -> ép thẳng Reject (>=70)
        //     vì tin hoàn toàn không có giá trị thật, không cần Staff cân nhắc thêm.
        const int SpamFloorThreshold = 70;
        const int SpamFloorMinRisk = 45; // > 40 để chắc chắn rơi vào ManualReview
        const int SpamSevereFloorThreshold = 90;
        const int SpamSevereFloorMinRisk = 75; // > 70 để chắc chắn rơi vào Reject
        if (spam >= SpamSevereFloorThreshold)
            overallRisk = Math.Max(overallRisk, SpamSevereFloorMinRisk);
        else if (spam >= SpamFloorThreshold)
            overallRisk = Math.Max(overallRisk, SpamFloorMinRisk);

        // Risk floor RIÊNG cho FakeSalary khi dữ liệu VÔ LÝ TUYỆT ĐỐI (Min > Max — không có
        // cách giải thích hợp lý nào cho trường hợp này, khác các dấu hiệu "đáng ngờ" khác).
        // ComputeFakeSalaryModule chấm thẳng 100 điểm cho case này -> ở đây ép Reject luôn,
        // không để trọng số 0.15 làm loãng mất tín hiệu rõ ràng này.
        const int FakeSalarySevereFloorThreshold = 100;
        const int FakeSalarySevereFloorMinRisk = 75; // > 70 để chắc chắn rơi vào Reject
        bool salaryIsInvalidData = salary >= FakeSalarySevereFloorThreshold;
        if (salaryIsInvalidData)
            overallRisk = Math.Max(overallRisk, FakeSalarySevereFloorMinRisk);

        overallRisk = Math.Clamp(overallRisk, 0, 100);

        string recommendation;
        if (scam >= AutoRejectThreshold || adult >= AutoRejectThreshold ||
            violence >= AutoRejectThreshold || hate >= AutoRejectThreshold ||
            spam >= SpamSevereFloorThreshold || salaryIsInvalidData)
        {
            recommendation = "Reject";
        }
        else if (overallRisk >= 70) recommendation = "Reject";
        else if (overallRisk >= 40) recommendation = "ManualReview";
        else recommendation = "Approve";

        result.OverallRisk = (int)Math.Round(overallRisk);
        result.Recommendation = recommendation;
        result.RiskRecalculatedByServer = true;
    }
}