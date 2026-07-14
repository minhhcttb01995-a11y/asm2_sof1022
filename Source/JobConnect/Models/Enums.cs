namespace JobConnect.Models;

// Trạng thái ticket hỗ trợ (SupportTicket.Status)
public enum TicketStatus
{
    Open = 0,
    InProgress = 1,
    Resolved = 2,
    Closed = 3
}

// Loại ticket hỗ trợ (SupportTicket.Type)
public enum TicketType
{
    Technical = 0,
    Billing = 1,
    AccountIssue = 2,
    JobPosting = 3,
    Application = 4,
    Other = 5
}

// Trạng thái nhân viên (Staff.Status)
public enum StaffStatus
{
    Active = 0,
    Locked = 1,
    Deleted = 2
}

// Nhóm kỹ năng (dùng ở phần hiển thị Skill, nếu cần)
public enum SkillCategory
{
    Programming = 0,
    Design = 1,
    Marketing = 2,
    Language = 3,
    SoftSkills = 4
}

// Loại report (Report.ReportType)
public enum ReportType
{
    JobPost = 0,
    Company = 1,
    Spam = 2,
    Fraud = 3,
    InappropriateContent = 4
}

// Trạng thái xử lý report (Report.Status)
public enum ReportStatus
{
    Pending = 0,
    InProgress = 1,
    Resolved = 2,
    Rejected = 3
}

// Loại người báo cáo (Report.ReporterType)
public enum ReporterType
{
    Candidate = 0,
    Employer = 1
}

// Mức độ thành thạo kỹ năng (CandidateSkill.ProficiencyLevel)
public enum ProficiencyLevel
{
    Beginner = 0,
    Intermediate = 1,
    Advanced = 2,
    Expert = 3
}