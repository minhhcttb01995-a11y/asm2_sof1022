// ═══════════════════════════════════════════════════════════════════════════
// ProfileCompletionHelper — kiểm tra hồ sơ Ứng viên / Nhà tuyển dụng đã ĐẦY ĐỦ
// thông tin bắt buộc hay chưa, và tự động chuyển tài khoản (User.Status) từ
// "Pending" (Chờ xác thực) sang "Active" (Đang hoạt động) ngay khi hồ sơ đủ.
//
// Quy tắc chung của hệ thống:
//   • Tài khoản MỚI đăng ký (sau khi xác thực OTP email) sẽ ở trạng thái
//     User.Status = "Pending" (hiển thị "Chờ xác thực" — xem StatusCatalog,
//     EntityType = Candidate/Employer).
//   • Ứng viên: phải bổ sung đủ họ tên, số điện thoại, địa chỉ, vị trí mong
//     muốn VÀ có ít nhất 1 CV thì mới được coi là "đủ thông tin".
//   • Nhà tuyển dụng: phải bổ sung đủ thông tin cá nhân người đại diện (giới
//     tính, CCCD) VÀ thông tin công ty (tên công ty thật — không còn là tên
//     placeholder tự sinh, mã số thuế, lĩnh vực, địa chỉ) thì mới "đủ thông tin".
//   • Ngay khi đủ, TryAutoActivateAsync sẽ tự chuyển Status -> "Active" và gửi
//     kèm 1 thông báo (Notification) báo tài khoản đã được kích hoạt.
//   • Trước khi đủ thông tin, các luồng nghiệp vụ quan trọng (VD: ứng tuyển
//     của Candidate, đăng tin của Employer) sẽ CHẶN lại và gửi Notification
//     nhắc hoàn thiện hồ sơ (xem JobController.Apply, EmployerController.PostJob).
// ═══════════════════════════════════════════════════════════════════════════
using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Helpers;

public static class ProfileCompletionHelper
{
    /// <summary>
    /// Hồ sơ ứng viên được coi là ĐẦY ĐỦ khi có họ tên, số điện thoại, địa chỉ,
    /// vị trí mong muốn (JobTitle) và ít nhất 1 CV đã tải lên.
    /// </summary>
    public static bool IsCandidateProfileComplete(CandidateProfile? profile, bool hasCv)
    {
        if (profile == null) return false;

        return !string.IsNullOrWhiteSpace(profile.FullName)
            && !string.IsNullOrWhiteSpace(profile.Phone)
            && !string.IsNullOrWhiteSpace(profile.Address)
            && !string.IsNullOrWhiteSpace(profile.JobTitle)
            && hasCv;
    }

    /// <summary>
    /// Hồ sơ nhà tuyển dụng được coi là ĐẦY ĐỦ khi có thông tin công ty (tên
    /// công ty thật, mã số thuế, lĩnh vực, địa chỉ) VÀ thông tin cá nhân người
    /// đại diện (giới tính, CCCD).
    /// </summary>
    public static bool IsEmployerProfileComplete(Employer? employer)
    {
        if (employer == null) return false;
        if (string.IsNullOrWhiteSpace(employer.CompanyName)) return false;

        // Tên công ty placeholder được FixOrphanEmployers/CreateCompany tự sinh
        // ra dạng "[Chưa đặt tên] ..." — không tính là đã đặt tên công ty thật.
        if (employer.CompanyName.TrimStart().StartsWith("[Chưa đặt tên]"))
            return false;

        return !string.IsNullOrWhiteSpace(employer.TaxCode)
            && !string.IsNullOrWhiteSpace(employer.Industry)
            && !string.IsNullOrWhiteSpace(employer.Address)
            && !string.IsNullOrWhiteSpace(employer.Gender)
            && !string.IsNullOrWhiteSpace(employer.CCCD);
    }

    /// <summary>
    /// Nếu tài khoản đang ở trạng thái "Pending" (Chờ xác thực) và hồ sơ tương
    /// ứng (Candidate/Employer) đã đủ thông tin, tự động chuyển User.Status
    /// sang "Active" và thêm 1 Notification thông báo cho họ biết.
    /// Trả về true nếu vừa kích hoạt. LƯU Ý: hàm này chỉ Add/gán thay đổi vào
    /// DbContext, người gọi phải tự SaveChangesAsync() sau đó.
    /// </summary>
    public static async Task<bool> TryAutoActivateAsync(AppDbContext db, User? user)
    {
        if (user == null) return false;
        if (!string.Equals(user.Status, "Pending", StringComparison.OrdinalIgnoreCase))
            return false;

        bool complete;

        if (user.Role == "Candidate")
        {
            var profile = await db.CandidateProfiles
                .Include(p => p.CvFiles)
                .FirstOrDefaultAsync(p => p.UserId == user.UserId);
            complete = IsCandidateProfileComplete(profile, profile?.CvFiles.Any() == true);
        }
        else if (user.Role == "Employer")
        {
            var employer = await db.Employers.FirstOrDefaultAsync(e => e.UserId == user.UserId);
            complete = IsEmployerProfileComplete(employer);
        }
        else
        {
            // Staff/Admin không áp dụng logic "chờ xác thực hồ sơ" này.
            return false;
        }

        if (!complete) return false;

        user.Status = "Active";
        user.UpdatedAt = DateTime.Now;

        db.Notifications.Add(new Notification
        {
            UserId = user.UserId,
            Title = "Tài khoản đã được kích hoạt",
            Content = "Bạn đã bổ sung đầy đủ thông tin. Tài khoản của bạn hiện đã chuyển sang trạng thái \"Đang hoạt động\".",
            Type = "AccountActivated",
            IsRead = false,
            CreatedAt = DateTime.Now
        });

        return true;
    }

    /// <summary>
    /// Gửi (hoặc nhắc lại, tối đa 1 lần/giờ để tránh spam) thông báo yêu cầu bổ
    /// sung đầy đủ thông tin trước khi được phép dùng 1 chức năng nào đó (ứng
    /// tuyển với Candidate, đăng tin/dùng hệ thống với Employer).
    /// </summary>
    public static async Task RemindIncompleteAsync(AppDbContext db, int userId, string title, string content, string type = "ProfileIncomplete")
    {
        var alreadyReminded = await db.Notifications.AnyAsync(n =>
            n.UserId == userId && n.Type == type && n.CreatedAt > DateTime.Now.AddHours(-1));

        if (alreadyReminded) return;

        db.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = title,
            Content = content,
            Type = type,
            IsRead = false,
            CreatedAt = DateTime.Now
        });
    }
}