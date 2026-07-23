/* =========================================================
   JobConnectDB21 - XOA VA TAO LAI HOAN TOAN TU DAU
   CANH BAO: Script nay se XOA SACH du lieu cu trong JobConnectDB21
   Chi chay khi ban chac chan muon lam lai tu dau.

   PHIEN BAN DU LIEU THUC TE (FICTIONAL NHUNG REALISTIC):
   - Toan bo cong ty la CONG TY GIA DINH (khong dung thuong hieu that)
     nhung thong tin nganh nghe / dia chi / quy mo duoc xay dung sat voi
     thi truong lao dong Viet Nam.
   - Tin tuyen dung, bai blog, tin nhan, thong bao... duoc viet lai voi
     noi dung da dang, chi tiet hon thay vi cau truc lap lai.
   - So luong ban ghi moi bang duoc tang len de du lieu phong phu hon.
   ========================================================= */

USE master;
GO

IF DB_ID('JobConnectDB27') IS NOT NULL
BEGIN
    ALTER DATABASE JobConnectDB27 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JobConnectDB27;
END
GO

CREATE DATABASE JobConnectDB27;
GO

USE JobConnectDB27;
GO

/* ================= USERS ================= */
CREATE TABLE Users (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    UserCode        NVARCHAR(20)    NULL,
    Email           NVARCHAR(200)   NOT NULL,
    PasswordHash    NVARCHAR(MAX)   NOT NULL,
    Role            NVARCHAR(50)    NOT NULL,
    FullName        NVARCHAR(200)   NOT NULL,
    PhoneNumber     NVARCHAR(20)    NULL,
    AvatarUrl       NVARCHAR(500)   NULL,
    DeletedAt       DATETIME2       NULL,
    Status          NVARCHAR(50)    NOT NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2       NULL,
    LastLoginAt     DATETIME2       NULL,
    OtpCode         NVARCHAR(10)    NULL,
    OtpExpiry       DATETIME2       NULL,
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
GO
CREATE UNIQUE INDEX UQ_Users_UserCode ON Users(UserCode) WHERE UserCode IS NOT NULL;
GO

/* ================= CATEGORIES ================= */
CREATE TABLE Categories (
    CategoryID      INT IDENTITY(1,1) PRIMARY KEY,
    ParentID        INT NULL,
    Name            NVARCHAR(150) NOT NULL,
    Type            NVARCHAR(50)  NOT NULL,
    Slug            NVARCHAR(150) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentID) REFERENCES Categories(CategoryID)
);
CREATE INDEX IX_Categories_ParentID ON Categories(ParentID);
GO

/* ================= SKILLS ================= */
CREATE TABLE Skills (
    SkillID         INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NULL,
    CategoryID      INT NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT UQ_Skills_Name UNIQUE (Name),
    CONSTRAINT FK_Skills_Category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
CREATE INDEX IX_Skills_CategoryID ON Skills(CategoryID);
GO

/* ================= EMPLOYERS ================= */
CREATE TABLE Employers (
    EmployerId      INT IDENTITY(1,1) PRIMARY KEY,
    CompanyCode     NVARCHAR(20)  NULL,
    UserId          INT NOT NULL,
    CompanyName     NVARCHAR(200) NOT NULL,
    TaxCode         NVARCHAR(50)  NULL,
    Industry        NVARCHAR(100) NULL,
    CompanySize     NVARCHAR(50)  NULL,
    Address         NVARCHAR(300) NULL,
    Website         NVARCHAR(300) NULL,
    LogoURL         NVARCHAR(500) NULL,
    CoverURL         NVARCHAR(500) NULL,
    IsVerified      BIT NOT NULL DEFAULT 0,
    IsLocked        BIT NOT NULL DEFAULT 0,
    IsFeatured      BIT NOT NULL DEFAULT 0,
    Status          NVARCHAR(50)    NOT NULL DEFAULT 'Active',
    Description     NVARCHAR(MAX) NULL,
    WhyWorkHereJson NVARCHAR(MAX) NULL,
    Gender          NVARCHAR(20)  NULL,
    CCCD            NVARCHAR(20)  NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT UQ_Employers_UserId UNIQUE (UserId),
    CONSTRAINT FK_Employers_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO
CREATE UNIQUE INDEX UQ_Employers_CompanyCode ON Employers(CompanyCode) WHERE CompanyCode IS NOT NULL;
GO
CREATE UNIQUE INDEX UQ_Employers_CCCD ON Employers(CCCD) WHERE CCCD IS NOT NULL;
GO

/* ================= CANDIDATE PROFILES ================= */
CREATE TABLE CandidateProfiles (
    ProfileId       INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL,
    FullName        NVARCHAR(100) NULL,
    Phone           NVARCHAR(15)  NULL,
    Avatar          NVARCHAR(500) NULL,
    DateOfBirth     DATETIME2 NULL,
    Gender          NVARCHAR(20)  NULL,
    Address         NVARCHAR(200) NULL,
    JobTitle        NVARCHAR(100) NULL,
    Summary         NVARCHAR(1000) NULL,
    ExperienceYears INT NOT NULL DEFAULT 0,
    DesiredSalary   DECIMAL(15,0) NULL,
    IsOpenToWork    BIT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_CandidateProfiles_UserId UNIQUE (UserId),
    CONSTRAINT FK_CandidateProfiles_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO

/* ================= STAFF ================= */
CREATE TABLE Staff (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    ApplicationUserId   INT NOT NULL,
    EmployeeCode        NVARCHAR(20)  NOT NULL,
    CCCD                NVARCHAR(20)  NULL,
    FullName            NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(100) NOT NULL,
    Phone               NVARCHAR(20)  NULL,
    Gender              NVARCHAR(20)  NULL,
    Avatar              NVARCHAR(500) NULL,
    Position            NVARCHAR(100) NOT NULL,
    Department          NVARCHAR(100) NOT NULL,
    Status              NVARCHAR(50)    NOT NULL DEFAULT 'Active',
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2 NULL,
    CONSTRAINT UQ_Staff_ApplicationUserId UNIQUE (ApplicationUserId),
    CONSTRAINT UQ_Staff_EmployeeCode UNIQUE (EmployeeCode),
    CONSTRAINT UQ_Staff_CCCD UNIQUE (CCCD),
    CONSTRAINT FK_Staff_User FOREIGN KEY (ApplicationUserId) REFERENCES Users(UserId)
);
GO

/* ================= JOB POSTS ================= */
CREATE TABLE JobPosts (
    JobID           INT IDENTITY(1,1) PRIMARY KEY,
    JobCode         NVARCHAR(20)  NULL,
    EmployerId      INT NOT NULL,
    CategoryID      INT NULL,
    Title           NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    Requirements    NVARCHAR(MAX) NULL,
    Benefits        NVARCHAR(MAX) NULL,
    SalaryMin       DECIMAL(15,0) NULL,
    SalaryMax       DECIMAL(15,0) NULL,
    SalaryNegotiable BIT NOT NULL DEFAULT 0,
    JobType         NVARCHAR(50)  NOT NULL,
    Location        NVARCHAR(200) NULL,
    ExperienceLevel NVARCHAR(50)  NULL,
    Deadline        DATETIME2 NULL,
    Status          NVARCHAR(50)  NOT NULL,
    ViewCount       INT NOT NULL DEFAULT 0,
    IsFeatured      BIT NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT FK_JobPosts_Employer FOREIGN KEY (EmployerId) REFERENCES Employers(EmployerId),
    CONSTRAINT FK_JobPosts_Category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
CREATE INDEX IX_JobPosts_EmployerId ON JobPosts(EmployerId);
GO
CREATE UNIQUE INDEX UQ_JobPosts_JobCode ON JobPosts(JobCode) WHERE JobCode IS NOT NULL;
CREATE INDEX IX_JobPosts_CategoryID ON JobPosts(CategoryID);
GO

/* ================= CV FILES ================= */
CREATE TABLE CvFiles (
    Cvid            INT IDENTITY(1,1) PRIMARY KEY,
    ProfileId       INT NOT NULL,
    FileName        NVARCHAR(200) NOT NULL,
    FilePath        NVARCHAR(500) NOT NULL,
    FileSize        BIGINT NULL,
    IsDefault       BIT NOT NULL DEFAULT 0,
    UploadedAt      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_CvFiles_Profile FOREIGN KEY (ProfileId) REFERENCES CandidateProfiles(ProfileId)
);
CREATE INDEX IX_CvFiles_ProfileId ON CvFiles(ProfileId);
GO

/* ================= APPLICATIONS ================= */
CREATE TABLE Applications (
    AppID           INT IDENTITY(1,1) PRIMARY KEY,
    JobID           INT NOT NULL,
    ProfileId       INT NOT NULL,
    Cvid            INT NULL,
    CoverLetter     NVARCHAR(1000) NULL,
    Status          NVARCHAR(50) NOT NULL,
    AppliedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT FK_Applications_Job FOREIGN KEY (JobID) REFERENCES JobPosts(JobID),
    CONSTRAINT FK_Applications_Profile FOREIGN KEY (ProfileId) REFERENCES CandidateProfiles(ProfileId),
    CONSTRAINT FK_Applications_Cv FOREIGN KEY (Cvid) REFERENCES CvFiles(Cvid),
    CONSTRAINT UQ_Applications_JobID_ProfileId UNIQUE (JobID, ProfileId)
);
CREATE INDEX IX_Applications_Cvid ON Applications(Cvid);
CREATE INDEX IX_Applications_JobID ON Applications(JobID);
CREATE INDEX IX_Applications_ProfileId ON Applications(ProfileId);
GO

/* ================= INTERVIEWS ================= */
CREATE TABLE Interviews (
    InterviewID     INT IDENTITY(1,1) PRIMARY KEY,
    AppID           INT NOT NULL,
    InterviewDate   DATETIME2 NOT NULL,
    Location        NVARCHAR(200) NOT NULL,
    Notes           NVARCHAR(1000) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Interviews_App FOREIGN KEY (AppID) REFERENCES Applications(AppID)
);
CREATE INDEX IX_Interviews_AppID ON Interviews(AppID);
GO

/* ================= CANDIDATE SKILLS ================= */
CREATE TABLE CandidateSkills (
    ProfileId           INT NOT NULL,
    SkillID              INT NOT NULL,
    ProficiencyLevel     INT NOT NULL,
    YearsOfExperience    DECIMAL(5,2) NOT NULL DEFAULT 0,
    LastUsedDate         DATETIME2 NULL,
    CreatedAt            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt            DATETIME2 NULL,
    CONSTRAINT PK_CandidateSkills PRIMARY KEY (ProfileId, SkillID),
    CONSTRAINT FK_CandidateSkills_Profile FOREIGN KEY (ProfileId) REFERENCES CandidateProfiles(ProfileId),
    CONSTRAINT FK_CandidateSkills_Skill FOREIGN KEY (SkillID) REFERENCES Skills(SkillID)
);
CREATE INDEX IX_CandidateSkills_SkillID ON CandidateSkills(SkillID);
GO

/* ================= SAVED JOBS ================= */
CREATE TABLE SavedJobs (
    SaveID          INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL,
    JobID           INT NOT NULL,
    SavedAt         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SavedJobs_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_SavedJobs_Job FOREIGN KEY (JobID) REFERENCES JobPosts(JobID),
    CONSTRAINT UQ_SavedJobs_UserId_JobID UNIQUE (UserId, JobID)
);
CREATE INDEX IX_SavedJobs_JobID ON SavedJobs(JobID);
CREATE INDEX IX_SavedJobs_UserId ON SavedJobs(UserId);
GO

/* ================= COMPANY FOLLOWS ================= */
CREATE TABLE CompanyFollows (
    FollowID        INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL,
    EmployerId      INT NOT NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_CompanyFollows_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_CompanyFollows_Employer FOREIGN KEY (EmployerId) REFERENCES Employers(EmployerId),
    CONSTRAINT UQ_CompanyFollows_UserId_EmployerId UNIQUE (UserId, EmployerId)
);
CREATE INDEX IX_CompanyFollows_UserId ON CompanyFollows(UserId);
CREATE INDEX IX_CompanyFollows_EmployerId ON CompanyFollows(EmployerId);
GO

/* ================= MESSAGES ================= */
CREATE TABLE Messages (
    MessageID       INT IDENTITY(1,1) PRIMARY KEY,
    SenderID        INT NOT NULL,
    ReceiverID      INT NOT NULL,
    Content         NVARCHAR(MAX) NOT NULL,
    IsRead          BIT NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    JobID           INT NULL,
    CONSTRAINT FK_Messages_Sender FOREIGN KEY (SenderID) REFERENCES Users(UserId),
    CONSTRAINT FK_Messages_Receiver FOREIGN KEY (ReceiverID) REFERENCES Users(UserId),
    CONSTRAINT FK_Messages_Job FOREIGN KEY (JobID) REFERENCES JobPosts(JobID)
);
CREATE INDEX IX_Messages_JobID ON Messages(JobID);
CREATE INDEX IX_Messages_ReceiverID ON Messages(ReceiverID);
CREATE INDEX IX_Messages_SenderID ON Messages(SenderID);
GO

/* ================= NOTIFICATIONS ================= */
CREATE TABLE Notifications (
    NotifId         INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL,
    Title           NVARCHAR(200) NOT NULL,
    Content         NVARCHAR(MAX) NULL,
    Type            NVARCHAR(50) NOT NULL,
    IsRead          BIT NOT NULL DEFAULT 0,
    RelatedId       INT NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Notifications_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
CREATE INDEX IX_Notifications_UserId ON Notifications(UserId);
GO

/* ================= BLOG POSTS ================= */
CREATE TABLE BlogPosts (
    PostID          INT IDENTITY(1,1) PRIMARY KEY,
    BlogCode        NVARCHAR(20)  NULL,
    AuthorID        INT NOT NULL,
    Title           NVARCHAR(300) NOT NULL,
    Slug            NVARCHAR(300) NOT NULL,
    Excerpt         NVARCHAR(MAX) NULL,
    Content         NVARCHAR(MAX) NULL,
    CoverURL        NVARCHAR(500) NULL,
    IsPublished     BIT NOT NULL DEFAULT 0,
    PublishedAt     DATETIME2 NULL,
    Status          NVARCHAR(50) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT FK_BlogPosts_Author FOREIGN KEY (AuthorID) REFERENCES Users(UserId)
);
CREATE INDEX IX_BlogPosts_AuthorID ON BlogPosts(AuthorID);
GO
CREATE UNIQUE INDEX UQ_BlogPosts_BlogCode ON BlogPosts(BlogCode) WHERE BlogCode IS NOT NULL;
GO

/* ================= ACTIVITY LOGS ================= */
CREATE TABLE ActivityLogs (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    StaffId         INT NOT NULL,
    Action          NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NULL,
    IpAddress       NVARCHAR(100) NULL,
    UserAgent       NVARCHAR(500) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_ActivityLogs_Staff FOREIGN KEY (StaffId) REFERENCES Staff(Id)
);
CREATE INDEX IX_ActivityLogs_StaffId ON ActivityLogs(StaffId);
GO

/* ================= REPORTS ================= */
CREATE TABLE Reports (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    ReporterId          INT NOT NULL,
    ReporterType        INT NOT NULL,
    ReportType          INT NOT NULL,
    JobPostId           INT NULL,
    CompanyId           INT NULL,
    ReportedEntityName  NVARCHAR(100) NULL,
    Reason              NVARCHAR(500) NOT NULL,
    Description         NVARCHAR(2000) NULL,
    Status              INT NOT NULL DEFAULT 0,
    ProcessedByStaffId  INT NULL,
    ProcessNote         NVARCHAR(500) NULL,
    ProcessedAt         DATETIME2 NULL,
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Reports_Reporter FOREIGN KEY (ReporterId) REFERENCES Users(UserId),
    CONSTRAINT FK_Reports_JobPost FOREIGN KEY (JobPostId) REFERENCES JobPosts(JobID),
    CONSTRAINT FK_Reports_Company FOREIGN KEY (CompanyId) REFERENCES Employers(EmployerId),
    CONSTRAINT FK_Reports_Staff FOREIGN KEY (ProcessedByStaffId) REFERENCES Staff(Id)
);
CREATE INDEX IX_Reports_CompanyId ON Reports(CompanyId);
CREATE INDEX IX_Reports_JobPostId ON Reports(JobPostId);
CREATE INDEX IX_Reports_ProcessedByStaffId ON Reports(ProcessedByStaffId);
CREATE INDEX IX_Reports_ReporterId ON Reports(ReporterId);
GO

/* ================= SUPPORT TICKETS ================= */
CREATE TABLE SupportTickets (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    UserId              INT NOT NULL,
    Type                INT NOT NULL,
    Subject             NVARCHAR(200) NOT NULL,
    Message             NVARCHAR(MAX) NOT NULL,
    Status              INT NOT NULL DEFAULT 0,
    AssignedToStaffId   INT NULL,
    Priority            INT NOT NULL DEFAULT 0,
    StaffResponse       NVARCHAR(MAX) NULL,
    AssignedAt          DATETIME2 NULL,
    ResolvedAt          DATETIME2 NULL,
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2 NULL,
    CONSTRAINT FK_SupportTickets_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_SupportTickets_Staff FOREIGN KEY (AssignedToStaffId) REFERENCES Staff(Id)
);
CREATE INDEX IX_SupportTickets_AssignedToStaffId ON SupportTickets(AssignedToStaffId);
CREATE INDEX IX_SupportTickets_UserId ON SupportTickets(UserId);
GO


/* ================= CvJobChecks ================= */
CREATE TABLE CvJobChecks (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    ProfileId           INT NOT NULL,
    JobID               INT NOT NULL,
    OriginalFileName    NVARCHAR(255) NOT NULL,
    FileType            NVARCHAR(10)  NOT NULL,   -- 'pdf' | 'docx'
    MatchPercent        INT NOT NULL,
    MatchedPointsJson   NVARCHAR(MAX) NULL,       -- JSON array string
    MissingPointsJson   NVARCHAR(MAX) NULL,       -- JSON array string
    Summary             NVARCHAR(MAX) NULL,
    CheckedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_CvJobChecks_Profile FOREIGN KEY (ProfileId) REFERENCES CandidateProfiles(ProfileId),
    CONSTRAINT FK_CvJobChecks_Job FOREIGN KEY (JobID) REFERENCES JobPosts(JobID)
);
GO

CREATE INDEX IX_CvJobChecks_ProfileId ON CvJobChecks(ProfileId);
CREATE INDEX IX_CvJobChecks_JobID ON CvJobChecks(JobID);
GO

/* ================= SYSTEM LOGS ================= */
CREATE TABLE SystemLogs (
    LogID           INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NULL,
    Action          NVARCHAR(200) NOT NULL,
    IPAddress       NVARCHAR(100) NULL,
    Detail          NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SystemLogs_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
CREATE INDEX IX_SystemLogs_UserId ON SystemLogs(UserId);
GO

/* ================= PASSWORD RESET TOKENS ================= */
CREATE TABLE PasswordResetTokens (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Email           NVARCHAR(200) NOT NULL,
    Code            NVARCHAR(6) NOT NULL,
    ExpiresAt       DATETIME2 NOT NULL,
    IsUsed          BIT NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* ================= COMPANY HIGHLIGHT ================= */
CREATE TABLE CompanyHighlight (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Icon            NVARCHAR(MAX) NOT NULL,
    Title           NVARCHAR(MAX) NOT NULL,
    Description     NVARCHAR(MAX) NOT NULL,
    IsHighlighted   BIT NOT NULL,
    EmployerId      INT NULL,
    CONSTRAINT FK_CompanyHighlight_Employers FOREIGN KEY (EmployerId) REFERENCES Employers(EmployerId)
);
CREATE INDEX IX_CompanyHighlight_EmployerId ON CompanyHighlight(EmployerId);
GO

/* ================= STATUS CATALOG ================= */
CREATE TABLE StatusCatalog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EntityType NVARCHAR(50) NOT NULL,
    Code NVARCHAR(50) NULL,
    Name NVARCHAR(100) NOT NULL,
    ColorClass NVARCHAR(50) NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    BlocksLogin BIT NOT NULL DEFAULT 0,
    ShowPublicly BIT NOT NULL DEFAULT 1,
    IsSystem BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT UQ_StatusCatalog_EntityType_Code UNIQUE (EntityType, Code)
);
GO

CREATE INDEX IX_StatusCatalog_EntityType ON StatusCatalog(EntityType);
GO
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, Description, IsActive, BlocksLogin, ShowPublicly, IsSystem) VALUES
('Candidate', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('Candidate', 'Pending', N'Chờ xác thực', 'bg-yellow-100 text-yellow-700', NULL, 1, 0, 1, 1),
('Candidate', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', NULL, 1, 1, 1, 1),
('Employer', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('Employer', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', NULL, 1, 0, 0, 1),
('Employer', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', NULL, 1, 0, 1, 1),
('Employer', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', NULL, 1, 1, 0, 1),
('Staff', 'Active', N'Đang làm việc', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('Staff', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', NULL, 1, 1, 1, 1),
('Staff', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', NULL, 1, 1, 1, 1),
('Company', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('Company', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', NULL, 1, 0, 0, 1),
('Company', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', NULL, 1, 0, 1, 1),
('Company', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', NULL, 1, 0, 0, 1),
('JobPost', 'Active', N'Đã duyệt', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('JobPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', NULL, 1, 0, 0, 1),
('JobPost', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', NULL, 1, 0, 0, 1),
('JobPost', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', NULL, 1, 0, 0, 1),
('JobPost', 'Draft', N'Bản nháp', 'bg-purple-100 text-purple-700', NULL, 1, 0, 0, 1),
('BlogPost', 'Published', N'Đã xuất bản', 'bg-green-100 text-green-700', NULL, 1, 0, 1, 1),
('BlogPost', 'Draft', N'Bản nháp', 'bg-yellow-100 text-yellow-700', NULL, 1, 0, 0, 1),
('BlogPost', 'Pending', N'Chờ duyệt', 'bg-blue-100 text-blue-700', NULL, 1, 0, 0, 1);
GO

ALTER DATABASE JobConnectDB21 SET MULTI_USER;
GO

INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('admin@jobconnect.vn', '$2a$12$xEdibtJ6BHiCSdnXA9EWK.fSTt/Zi8Op3YdzvtyzBDOXxIabpHEgS', 'Admin', N'Quản Trị Viên', '0901000001', 'Active');
GO
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('staff01@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Nguyễn Thị Hà', '0901001001', 'Active'),
('staff02@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trần Văn Bảo', '0901001002', 'Active'),
('staff03@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lê Thị Cúc', '0901001003', 'Active'),
('staff04@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Phạm Văn Dũng', '0901001004', 'Active'),
('staff05@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Hoàng Thị Em', '0901001005', 'Active'),
('staff06@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Vũ Văn Phát', '0901001006', 'Active'),
('staff07@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đặng Thị Giang', '0901001007', 'Active'),
('staff08@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Bùi Văn Hải', '0901001008', 'Active'),
('staff09@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Ngô Thị Ích', '0901001009', 'Active'),
('staff10@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đỗ Văn Khang', '0901001010', 'Active'),
('staff11@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đinh Thị Lan', '0901001011', 'Active'),
('staff12@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trương Văn Minh', '0901001012', 'Active'),
('staff13@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lý Thị Ngọc', '0901001013', 'Active'),
('staff14@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Phan Văn Oai', '0901001014', 'Active'),
('staff15@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Tô Thị Phượng', '0901001015', 'Active'),
('staff16@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Cao Văn Quang', '0901001016', 'Active'),
('staff17@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Hà Thị Rin', '0901001017', 'Active'),
('staff18@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lương Văn Sinh', '0901001018', 'Active'),
('staff19@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trịnh Thị Thảo', '0901001019', 'Active'),
('staff20@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Dương Văn Út', '0901001020', 'Active'),
('staff21@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Mai Thị Vy', '0901001021', 'Active'),
('staff22@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Chu Văn Thắng', '0901001022', 'Active'),
('staff23@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Kiều Thị Yến', '0901001023', 'Active'),
('staff24@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Tăng Văn Long', '0901001024', 'Active'),
('staff25@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Vương Thị Hồng', '0901001025', 'Active');
GO
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('employer01@company1.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Nguyễn Văn An', '0901111001', 'Active'),
('employer02@company2.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trần Thị Bình', '0901111002', 'Active'),
('employer03@company3.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lê Minh Cường', '0901111003', 'Active'),
('employer04@company4.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Phạm Thị Dung', '0901111004', 'Active'),
('employer05@company5.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Hoàng Văn Em', '0901111005', 'Active'),
('employer06@company6.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Vũ Thị Phương', '0901111006', 'Active'),
('employer07@company7.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đặng Văn Giàu', '0901111007', 'Active'),
('employer08@company8.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Bùi Thị Hoa', '0901111008', 'Active'),
('employer09@company9.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Ngô Văn Inh', '0901111009', 'Active'),
('employer10@company10.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đỗ Thị Kim', '0901111010', 'Active'),
('employer11@company11.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đinh Văn Long', '0901111011', 'Active'),
('employer12@company12.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trương Thị Mỹ', '0901111012', 'Active'),
('employer13@company13.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lý Văn Nghĩa', '0901111013', 'Active'),
('employer14@company14.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Phan Thị Oanh', '0901111014', 'Active'),
('employer15@company15.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Tô Văn Phú', '0901111015', 'Active'),
('employer16@company16.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Cao Thị Quyên', '0901111016', 'Active'),
('employer17@company17.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Hà Văn Rồng', '0901111017', 'Active'),
('employer18@company18.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lương Thị Sang', '0901111018', 'Active'),
('employer19@company19.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trịnh Văn Tài', '0901111019', 'Active'),
('employer20@company20.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Dương Thị Uyên', '0901111020', 'Active'),
('employer21@company21.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Bạch Văn Vinh', '0901111021', 'Active'),
('employer22@company22.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đàm Thị Xuân', '0901111022', 'Active'),
('employer23@company23.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Ứng Văn Yên', '0901111023', 'Active'),
('employer24@company24.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Kha Thị Ánh', '0901111024', 'Active'),
('employer25@company25.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Sử Văn Bằng', '0901111025', 'Active'),
('employer26@company26.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Quách Thị Cẩm', '0901111026', 'Active'),
('employer27@company27.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Tạ Văn Đạt', '0901111027', 'Active'),
('employer28@company28.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Vòng Thị Hạnh', '0901111028', 'Active'),
('employer29@company29.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Chiêm Văn Khải', '0901111029', 'Active'),
('employer30@company30.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Diệp Thị Linh', '0901111030', 'Active');
GO
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('candidate01@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đỗ Thị Phương', '0912001001', 'Active'),
('candidate02@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Vũ Quang Huy', '0912001002', 'Active'),
('candidate03@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Ngô Thị Lan', '0912001003', 'Active'),
('candidate04@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Bùi Văn Khoa', '0912001004', 'Active'),
('candidate05@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lý Thị Mai', '0912001005', 'Active'),
('candidate06@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đinh Văn Nam', '0912001006', 'Active'),
('candidate07@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Phan Thị Oanh', '0912001007', 'Active'),
('candidate08@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Tô Minh Phúc', '0912001008', 'Active'),
('candidate09@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Cao Thị Quỳnh', '0912001009', 'Active'),
('candidate10@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Hà Văn Sơn', '0912001010', 'Active'),
('candidate11@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lương Thị Trang', '0912001011', 'Active'),
('candidate12@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Mai Văn Uy', '0912001012', 'Active'),
('candidate13@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Trịnh Thị Vân', '0912001013', 'Active'),
('candidate14@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Dương Văn Xuân', '0912001014', 'Active'),
('candidate15@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Nguyễn Thị Yến', '0912001015', 'Active'),
('candidate16@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Trần Văn Ánh', '0912001016', 'Active'),
('candidate17@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lê Thị Bích', '0912001017', 'Active'),
('candidate18@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Phạm Văn Cảnh', '0912001018', 'Active'),
('candidate19@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Hoàng Thị Duyên', '0912001019', 'Active'),
('candidate20@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Vũ Văn Giang', '0912001020', 'Active'),
('candidate21@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đặng Thị Hằng', '0912001021', 'Active'),
('candidate22@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Bùi Văn Inh', '0912001022', 'Active'),
('candidate23@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Ngô Thị Kiều', '0912001023', 'Active'),
('candidate24@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đỗ Văn Lâm', '0912001024', 'Active'),
('candidate25@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đinh Thị Minh', '0912001025', 'Active'),
('candidate26@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Trương Văn Nghị', '0912001026', 'Active'),
('candidate27@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lý Thị Oanh', '0912001027', 'Active'),
('candidate28@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Phan Văn Phúc', '0912001028', 'Active'),
('candidate29@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Tô Thị Quý', '0912001029', 'Active'),
('candidate30@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Cao Văn Rạng', '0912001030', 'Active');
GO
UPDATE Users SET UserCode =
    CASE Role
        WHEN 'Admin'     THEN 'AD'  + RIGHT('000000' + CAST(UserId AS VARCHAR(6)), 6)
        WHEN 'Staff'     THEN 'NV'  + RIGHT('000000' + CAST(UserId AS VARCHAR(6)), 6)
        WHEN 'Employer'  THEN 'NTD' + RIGHT('000000' + CAST(UserId AS VARCHAR(6)), 6)
        WHEN 'Candidate' THEN 'UV'  + RIGHT('000000' + CAST(UserId AS VARCHAR(6)), 6)
        ELSE 'ND' + RIGHT('000000' + CAST(UserId AS VARCHAR(6)), 6)
    END;
GO
INSERT INTO Staff (ApplicationUserId, EmployeeCode, CCCD, FullName, Email, Phone, Gender, Position, Department, Status) VALUES
(2, 'EMP002', '031099056037', N'Nguyễn Thị Hà', 'staff01@jobconnect.vn', '0901001001', N'Nữ', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(3, 'EMP003', '032099056074', N'Trần Văn Bảo', 'staff02@jobconnect.vn', '0901001002', N'Nam', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(4, 'EMP004', '033099056111', N'Lê Thị Cúc', 'staff03@jobconnect.vn', '0901001003', N'Nữ', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(5, 'EMP005', '034099056148', N'Phạm Văn Dũng', 'staff04@jobconnect.vn', '0901001004', N'Nam', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(6, 'EMP006', '035099056185', N'Hoàng Thị Em', 'staff05@jobconnect.vn', '0901001005', N'Nữ', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(7, 'EMP007', '036099056222', N'Vũ Văn Phát', 'staff06@jobconnect.vn', '0901001006', N'Nam', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(8, 'EMP008', '037099056259', N'Đặng Thị Giang', 'staff07@jobconnect.vn', '0901001007', N'Nữ', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(9, 'EMP009', '038099056296', N'Bùi Văn Hải', 'staff08@jobconnect.vn', '0901001008', N'Nam', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(10, 'EMP010', '039099056333', N'Ngô Thị Ích', 'staff09@jobconnect.vn', '0901001009', N'Nữ', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(11, 'EMP011', '0310099056370', N'Đỗ Văn Khang', 'staff10@jobconnect.vn', '0901001010', N'Nam', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(12, 'EMP012', '0311099056407', N'Đinh Thị Lan', 'staff11@jobconnect.vn', '0901001011', N'Nữ', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(13, 'EMP013', '0312099056444', N'Trương Văn Minh', 'staff12@jobconnect.vn', '0901001012', N'Nam', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(14, 'EMP014', '0313099056481', N'Lý Thị Ngọc', 'staff13@jobconnect.vn', '0901001013', N'Nữ', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(15, 'EMP015', '0314099056518', N'Phan Văn Oai', 'staff14@jobconnect.vn', '0901001014', N'Nam', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(16, 'EMP016', '0315099056555', N'Tô Thị Phượng', 'staff15@jobconnect.vn', '0901001015', N'Nữ', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(17, 'EMP017', '0316099056592', N'Cao Văn Quang', 'staff16@jobconnect.vn', '0901001016', N'Nam', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(18, 'EMP018', '0317099056629', N'Hà Thị Rin', 'staff17@jobconnect.vn', '0901001017', N'Nữ', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(19, 'EMP019', '0318099056666', N'Lương Văn Sinh', 'staff18@jobconnect.vn', '0901001018', N'Nam', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(20, 'EMP020', '0319099056703', N'Trịnh Thị Thảo', 'staff19@jobconnect.vn', '0901001019', N'Nữ', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(21, 'EMP021', '0320099056740', N'Dương Văn Út', 'staff20@jobconnect.vn', '0901001020', N'Nam', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(22, 'EMP022', '0321099056777', N'Mai Thị Vy', 'staff21@jobconnect.vn', '0901001021', N'Nữ', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(23, 'EMP023', '0322099056814', N'Chu Văn Thắng', 'staff22@jobconnect.vn', '0901001022', N'Nam', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(24, 'EMP024', '0323099056851', N'Kiều Thị Yến', 'staff23@jobconnect.vn', '0901001023', N'Nữ', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(25, 'EMP025', '0324099056888', N'Tăng Văn Long', 'staff24@jobconnect.vn', '0901001024', N'Nam', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(26, 'EMP026', '0325099056925', N'Vương Thị Hồng', 'staff25@jobconnect.vn', '0901001025', N'Nữ', N'Chuyên viên vận hành', N'Kinh doanh', 'Active');
GO
UPDATE Staff SET EmployeeCode = 'NV' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 6));
GO
INSERT INTO Categories (ParentID, Name, Type, Slug, Description) VALUES
(NULL, N'Công nghệ thông tin', 'Industry', N'cong-nghe-thong-tin', N'Ngành IT, phần mềm, lập trình'),
(NULL, N'Tài chính - Ngân hàng', 'Industry', N'tai-chinh-ngan-hang', N'Ngành tài chính, ngân hàng, bảo hiểm'),
(NULL, N'Marketing - Truyền thông', 'Industry', N'marketing-truyen-thong', N'Ngành marketing, quảng cáo, truyền thông'),
(NULL, N'Kinh doanh - Bán lẻ', 'Industry', N'kinh-doanh-ban-le', N'Ngành sales, bán lẻ, thương mại'),
(NULL, N'Nhân sự - Hành chính', 'Industry', N'nhan-su-hanh-chinh', N'Ngành HR, hành chính văn phòng'),
(NULL, N'Sản xuất - Cơ khí', 'Industry', N'san-xuat-co-khi', N'Ngành sản xuất, cơ khí, vận hành nhà máy'),
(NULL, N'Vận tải - Logistics', 'Industry', N'van-tai-logistics', N'Ngành vận tải, kho vận, chuỗi cung ứng'),
(NULL, N'Y tế - Dược phẩm', 'Industry', N'y-te-duoc-pham', N'Ngành y tế, chăm sóc sức khỏe, dược phẩm'),
(NULL, N'Giáo dục - Đào tạo', 'Industry', N'giao-duc-dao-tao', N'Ngành giáo dục, đào tạo'),
(NULL, N'Bất động sản - Xây dựng', 'Industry', N'bat-dong-san-xay-dung', N'Ngành bất động sản, xây dựng');
GO
INSERT INTO Categories (ParentID, Name, Type, Slug, Description) VALUES
-- ── Ngành 1: Công nghệ thông tin (20 danh mục) ──
(1, N'Backend Developer', 'JobType', N'backend-developer', N'Lập trình viên backend'),
(1, N'Frontend Developer', 'JobType', N'frontend-developer', N'Lập trình viên frontend'),
(1, N'DevOps / Cloud Engineer', 'JobType', N'devops-cloud-engineer', N'DevOps, Cloud engineer'),
(1, N'Mobile Developer', 'JobType', N'mobile-developer', N'Lập trình viên di động iOS/Android'),
(1, N'Data Engineer / Analyst', 'JobType', N'data-engineer-analyst', N'Kỹ sư/Chuyên viên dữ liệu'),
(1, N'QA/QC Engineer', 'JobType', N'qa-qc-engineer', N'Kiểm thử phần mềm'),
(1, N'Fullstack Developer', 'JobType', N'fullstack-developer', N'Lập trình viên fullstack'),
(1, N'AI / Machine Learning Engineer', 'JobType', N'ai-ml-engineer', N'Kỹ sư trí tuệ nhân tạo, học máy'),
(1, N'Security Engineer', 'JobType', N'security-engineer', N'Kỹ sư an ninh mạng, bảo mật hệ thống'),
(1, N'Business Analyst (IT)', 'JobType', N'business-analyst-it', N'Phân tích nghiệp vụ công nghệ thông tin'),
(1, N'UI/UX Designer', 'JobType', N'ui-ux-designer', N'Thiết kế giao diện và trải nghiệm người dùng'),
(1, N'Database Administrator', 'JobType', N'database-administrator', N'Quản trị cơ sở dữ liệu'),
(1, N'System Administrator', 'JobType', N'system-administrator', N'Quản trị hệ thống máy chủ'),
(1, N'Embedded Systems Engineer', 'JobType', N'embedded-systems-engineer', N'Kỹ sư hệ thống nhúng'),
(1, N'Blockchain Developer', 'JobType', N'blockchain-developer', N'Lập trình viên blockchain'),
(1, N'Game Developer', 'JobType', N'game-developer', N'Lập trình viên game'),
(1, N'IT Support / Helpdesk', 'JobType', N'it-support-helpdesk', N'Hỗ trợ kỹ thuật IT'),
(1, N'Network Engineer', 'JobType', N'network-engineer', N'Kỹ sư mạng máy tính'),
(1, N'Technical Lead / CTO', 'JobType', N'technical-lead-cto', N'Trưởng nhóm kỹ thuật, Giám đốc công nghệ'),
(1, N'Scrum Master / Agile Coach', 'JobType', N'scrum-master-agile-coach', N'Scrum Master, huấn luyện Agile'),
-- ── Ngành 2: Tài chính - Ngân hàng (20 danh mục) ──
(2, N'Kế toán tổng hợp', 'JobType', N'ke-toan-tong-hop', N'Kế toán tổng hợp'),
(2, N'Chuyên viên tài chính', 'JobType', N'chuyen-vien-tai-chinh', N'Phân tích tài chính'),
(2, N'Giao dịch viên ngân hàng', 'JobType', N'giao-dich-vien-ngan-hang', N'Giao dịch viên ngân hàng'),
(2, N'Kiểm toán nội bộ', 'JobType', N'kiem-toan-noi-bo', N'Kiểm toán viên nội bộ'),
(2, N'Chuyên viên tín dụng', 'JobType', N'chuyen-vien-tin-dung', N'Thẩm định và quản lý tín dụng'),
(2, N'Chuyên viên phân tích đầu tư', 'JobType', N'chuyen-vien-phan-tich-dau-tu', N'Phân tích và tư vấn đầu tư tài chính'),
(2, N'Chuyên viên bảo hiểm', 'JobType', N'chuyen-vien-bao-hiem', N'Tư vấn và quản lý bảo hiểm'),
(2, N'Chuyên viên quản lý rủi ro', 'JobType', N'chuyen-vien-quan-ly-rui-ro', N'Phân tích và kiểm soát rủi ro tài chính'),
(2, N'Giám đốc tài chính (CFO)', 'JobType', N'giam-doc-tai-chinh-cfo', N'Giám đốc tài chính doanh nghiệp'),
(2, N'Kế toán thuế', 'JobType', N'ke-toan-thue', N'Nghiệp vụ khai báo và quyết toán thuế'),
(2, N'Chuyên viên ngân hàng số', 'JobType', N'chuyen-vien-ngan-hang-so', N'Phát triển và vận hành dịch vụ ngân hàng số'),
(2, N'Chuyên viên quản lý tài sản', 'JobType', N'chuyen-vien-quan-ly-tai-san', N'Quản lý và tối ưu danh mục tài sản'),
(2, N'Nhân viên thanh toán quốc tế', 'JobType', N'nhan-vien-thanh-toan-quoc-te', N'Xử lý giao dịch và thanh toán quốc tế'),
(2, N'Chuyên viên thẩm định tín dụng', 'JobType', N'chuyen-vien-tham-dinh-tin-dung', N'Thẩm định hồ sơ tín dụng khách hàng'),
(2, N'Chuyên viên môi giới chứng khoán', 'JobType', N'chuyen-vien-moi-gioi-chung-khoan', N'Tư vấn và môi giới đầu tư chứng khoán'),
(2, N'Chuyên viên Fintech', 'JobType', N'chuyen-vien-fintech', N'Phát triển sản phẩm công nghệ tài chính'),
(2, N'Trưởng phòng kế toán', 'JobType', N'truong-phong-ke-toan', N'Quản lý bộ phận kế toán doanh nghiệp'),
(2, N'Kế toán công nợ', 'JobType', N'ke-toan-cong-no', N'Theo dõi và xử lý công nợ phải thu/phải trả'),
(2, N'Chuyên viên tư vấn tài chính cá nhân', 'JobType', N'chuyen-vien-tu-van-tai-chinh-ca-nhan', N'Tư vấn hoạch định tài chính cá nhân'),
(2, N'Kiểm soát viên nội bộ', 'JobType', N'kiem-soat-vien-noi-bo', N'Giám sát tuân thủ quy trình nội bộ'),
-- ── Ngành 3: Marketing - Truyền thông (20 danh mục) ──
(3, N'Digital Marketing', 'JobType', N'digital-marketing', N'Chuyên viên marketing kỹ thuật số'),
(3, N'Content Creator', 'JobType', N'content-creator', N'Sáng tạo nội dung đa nền tảng'),
(3, N'SEO Specialist', 'JobType', N'seo-specialist', N'Tối ưu hóa công cụ tìm kiếm'),
(3, N'Social Media Marketing', 'JobType', N'social-media-marketing', N'Quản lý và phát triển mạng xã hội'),
(3, N'Brand Manager', 'JobType', N'brand-manager', N'Quản lý thương hiệu doanh nghiệp'),
(3, N'Product Marketing Manager', 'JobType', N'product-marketing-manager', N'Marketing sản phẩm và go-to-market'),
(3, N'Performance Marketing', 'JobType', N'performance-marketing', N'Chạy quảng cáo và tối ưu hiệu suất'),
(3, N'Email Marketing', 'JobType', N'email-marketing', N'Xây dựng và triển khai chiến dịch email'),
(3, N'Event Marketing', 'JobType', N'event-marketing', N'Tổ chức sự kiện và hoạt động marketing'),
(3, N'PR Manager', 'JobType', N'pr-manager', N'Quan hệ công chúng và truyền thông'),
(3, N'Copywriter', 'JobType', N'copywriter', N'Viết nội dung quảng cáo và bán hàng'),
(3, N'Graphic Designer', 'JobType', N'graphic-designer', N'Thiết kế đồ họa ấn phẩm và truyền thông'),
(3, N'Video Editor', 'JobType', N'video-editor', N'Dựng và chỉnh sửa video truyền thông'),
(3, N'Influencer Marketing', 'JobType', N'influencer-marketing', N'Quản lý hợp tác KOL/Influencer'),
(3, N'Community Manager', 'JobType', N'community-manager', N'Xây dựng và quản lý cộng đồng thương hiệu'),
(3, N'Marketing Analyst', 'JobType', N'marketing-analyst', N'Phân tích dữ liệu và hiệu quả marketing'),
(3, N'E-commerce Marketing', 'JobType', N'e-commerce-marketing', N'Marketing trên các sàn thương mại điện tử'),
(3, N'Trade Marketing', 'JobType', N'trade-marketing', N'Marketing tại điểm bán và kênh phân phối'),
(3, N'Creative Director', 'JobType', N'creative-director', N'Giám đốc sáng tạo nội dung truyền thông'),
(3, N'Market Research Analyst', 'JobType', N'market-research-analyst', N'Nghiên cứu và phân tích thị trường'),
-- ── Ngành 4: Kinh doanh - Bán lẻ (20 danh mục) ──
(4, N'Nhân viên kinh doanh', 'JobType', N'nhan-vien-kinh-doanh', N'Sales, kinh doanh trực tiếp'),
(4, N'Quản lý cửa hàng', 'JobType', N'quan-ly-cua-hang', N'Quản lý điểm bán lẻ'),
(4, N'Trưởng phòng kinh doanh', 'JobType', N'truong-phong-kinh-doanh', N'Quản lý đội ngũ kinh doanh'),
(4, N'Key Account Manager', 'JobType', N'key-account-manager', N'Quản lý khách hàng trọng điểm'),
(4, N'Nhân viên tư vấn bán hàng', 'JobType', N'nhan-vien-tu-van-ban-hang', N'Tư vấn và giới thiệu sản phẩm tại quầy'),
(4, N'Giám sát bán hàng', 'JobType', N'giam-sat-ban-hang', N'Giám sát hoạt động bán hàng khu vực'),
(4, N'Nhân viên chăm sóc khách hàng', 'JobType', N'nhan-vien-cham-soc-khach-hang', N'Hỗ trợ và chăm sóc khách hàng sau bán'),
(4, N'Business Development Manager', 'JobType', N'business-development-manager', N'Phát triển kinh doanh và đối tác mới'),
(4, N'Nhân viên kinh doanh xuất nhập khẩu', 'JobType', N'nhan-vien-kinh-doanh-xnk', N'Kinh doanh thương mại quốc tế'),
(4, N'Nhân viên thương mại điện tử', 'JobType', N'nhan-vien-thuong-mai-dien-tu', N'Kinh doanh trên các sàn thương mại điện tử'),
(4, N'Quản lý khu vực (Area Manager)', 'JobType', N'quan-ly-khu-vuc', N'Quản lý hệ thống cửa hàng theo khu vực'),
(4, N'Nhân viên telesales', 'JobType', N'nhan-vien-telesales', N'Bán hàng qua điện thoại'),
(4, N'Nhân viên bán hàng B2B', 'JobType', N'nhan-vien-ban-hang-b2b', N'Kinh doanh giữa doanh nghiệp với doanh nghiệp'),
(4, N'Trưởng nhóm bán hàng', 'JobType', N'truong-nhom-ban-hang', N'Lãnh đạo và huấn luyện nhóm kinh doanh'),
(4, N'Category Manager', 'JobType', N'category-manager', N'Quản lý ngành hàng và danh mục sản phẩm'),
(4, N'Procurement Officer', 'JobType', N'procurement-officer', N'Chuyên viên mua hàng và đàm phán nhà cung cấp'),
(4, N'Nhân viên merchandising', 'JobType', N'nhan-vien-merchandising', N'Trưng bày và quản lý hàng hóa tại quầy kệ'),
(4, N'Sales Operations', 'JobType', N'sales-operations', N'Vận hành và hỗ trợ hoạt động kinh doanh'),
(4, N'Nhân viên phát triển đại lý', 'JobType', N'nhan-vien-phat-trien-dai-ly', N'Xây dựng và mở rộng mạng lưới đại lý'),
(4, N'Giám đốc kinh doanh', 'JobType', N'giam-doc-kinh-doanh', N'Lãnh đạo chiến lược kinh doanh toàn công ty'),
-- ── Ngành 5: Nhân sự - Hành chính (20 danh mục) ──
(5, N'Chuyên viên tuyển dụng', 'JobType', N'chuyen-vien-tuyen-dung', N'Tuyển dụng nhân sự'),
(5, N'Hành chính nhân sự tổng hợp', 'JobType', N'hanh-chinh-nhan-su', N'Hành chính - Nhân sự tổng hợp'),
(5, N'Trưởng phòng nhân sự (HR Manager)', 'JobType', N'truong-phong-nhan-su', N'Quản lý phòng nhân sự doanh nghiệp'),
(5, N'Chuyên viên đào tạo và phát triển', 'JobType', N'chuyen-vien-dao-tao-phat-trien', N'Thiết kế và triển khai chương trình đào tạo nội bộ'),
(5, N'Chuyên viên C&B', 'JobType', N'chuyen-vien-cb', N'Quản lý lương thưởng và phúc lợi nhân viên'),
(5, N'Chuyên viên quan hệ lao động', 'JobType', N'chuyen-vien-quan-he-lao-dong', N'Quản lý quan hệ lao động và hợp đồng'),
(5, N'Giám đốc nhân sự (CHRO)', 'JobType', N'giam-doc-nhan-su-chro', N'Lãnh đạo chiến lược nhân sự toàn công ty'),
(5, N'Nhân viên hành chính', 'JobType', N'nhan-vien-hanh-chinh', N'Hỗ trợ công tác hành chính văn phòng'),
(5, N'Thư ký / Trợ lý giám đốc', 'JobType', N'thu-ky-tro-ly-giam-doc', N'Hỗ trợ và điều phối công việc cấp lãnh đạo'),
(5, N'Chuyên viên HRIS', 'JobType', N'chuyen-vien-hris', N'Quản lý hệ thống thông tin nhân sự'),
(5, N'HR Business Partner', 'JobType', N'hr-business-partner', N'Đối tác nhân sự chiến lược cho các bộ phận'),
(5, N'Nhân viên lễ tân', 'JobType', N'nhan-vien-le-tan', N'Tiếp đón khách và hỗ trợ văn phòng'),
(5, N'Chuyên viên văn thư lưu trữ', 'JobType', N'chuyen-vien-van-thu-luu-tru', N'Quản lý hồ sơ, văn bản và lưu trữ'),
(5, N'Quản lý tòa nhà', 'JobType', N'quan-ly-toa-nha', N'Vận hành và bảo trì cơ sở vật chất'),
(5, N'Chuyên viên an toàn lao động', 'JobType', N'chuyen-vien-an-toan-lao-dong', N'Giám sát và thực thi an toàn lao động'),
(5, N'Talent Acquisition Specialist', 'JobType', N'talent-acquisition-specialist', N'Tuyển dụng nhân tài cấp cao'),
(5, N'OD Specialist', 'JobType', N'od-specialist', N'Phát triển tổ chức và văn hóa doanh nghiệp'),
(5, N'Payroll Specialist', 'JobType', N'payroll-specialist', N'Tính toán và xử lý lương nhân viên'),
(5, N'Nhân viên bảo vệ', 'JobType', N'nhan-vien-bao-ve', N'Bảo đảm an ninh tại nơi làm việc'),
(5, N'Chuyên viên phúc lợi nhân viên', 'JobType', N'chuyen-vien-phuc-loi', N'Xây dựng và quản lý chương trình phúc lợi'),
-- ── Ngành 6: Sản xuất - Cơ khí (20 danh mục) ──
(6, N'Kỹ sư sản xuất', 'JobType', N'ky-su-san-xuat', N'Quản lý quy trình và dây chuyền sản xuất'),
(6, N'Kỹ sư cơ khí', 'JobType', N'ky-su-co-khi', N'Thiết kế và vận hành hệ thống cơ khí'),
(6, N'Kỹ sư điện / Điện tử', 'JobType', N'ky-su-dien-dien-tu', N'Vận hành và bảo trì hệ thống điện nhà máy'),
(6, N'Kỹ sư chất lượng (QA/QC)', 'JobType', N'ky-su-chat-luong-qa-qc', N'Kiểm soát chất lượng sản phẩm'),
(6, N'Kỹ sư vận hành nhà máy', 'JobType', N'ky-su-van-hanh-nha-may', N'Quản lý vận hành thiết bị và nhà máy'),
(6, N'Kỹ thuật viên bảo trì', 'JobType', N'ky-thuat-vien-bao-tri', N'Bảo dưỡng và sửa chữa thiết bị sản xuất'),
(6, N'Kỹ sư tự động hóa', 'JobType', N'ky-su-tu-dong-hoa', N'Lập trình PLC/SCADA và tự động hóa dây chuyền'),
(6, N'Công nhân kỹ thuật', 'JobType', N'cong-nhan-ky-thuat', N'Vận hành máy móc và dây chuyền sản xuất'),
(6, N'Trưởng ca sản xuất', 'JobType', N'truong-ca-san-xuat', N'Quản lý và điều phối ca sản xuất'),
(6, N'Kỹ sư công nghệ thực phẩm', 'JobType', N'ky-su-cong-nghe-thuc-pham', N'Phát triển và kiểm soát quy trình chế biến thực phẩm'),
(6, N'Kỹ sư hóa chất', 'JobType', N'ky-su-hoa-chat', N'Ứng dụng hóa học trong sản xuất công nghiệp'),
(6, N'Kỹ sư môi trường', 'JobType', N'ky-su-moi-truong', N'Quản lý chất thải và bảo vệ môi trường nhà máy'),
(6, N'Giám sát sản xuất', 'JobType', N'giam-sat-san-xuat', N'Giám sát tiến độ và chất lượng sản xuất'),
(6, N'Kỹ sư vật liệu', 'JobType', N'ky-su-vat-lieu', N'Nghiên cứu và phát triển vật liệu công nghiệp'),
(6, N'Kỹ sư thiết kế cơ khí (CAD/CAM)', 'JobType', N'ky-su-thiet-ke-co-khi', N'Thiết kế chi tiết cơ khí bằng phần mềm CAD/CAM'),
(6, N'Quản lý nhà máy', 'JobType', N'quan-ly-nha-may', N'Điều hành toàn bộ hoạt động nhà máy'),
(6, N'Kỹ sư hàn', 'JobType', N'ky-su-han', N'Kiểm tra và thi công hàn kết cấu'),
(6, N'Kỹ sư R&D', 'JobType', N'ky-su-r-and-d', N'Nghiên cứu và phát triển sản phẩm mới'),
(6, N'Chuyên viên an toàn nhà máy (HSE)', 'JobType', N'chuyen-vien-hse', N'Quản lý sức khỏe, an toàn và môi trường'),
(6, N'Kỹ sư dệt may', 'JobType', N'ky-su-det-may', N'Kỹ thuật và quản lý chất lượng ngành may mặc'),
-- ── Ngành 7: Vận tải - Logistics (20 danh mục) ──
(7, N'Nhân viên logistics', 'JobType', N'nhan-vien-logistics', N'Điều phối vận tải và kho vận'),
(7, N'Điều phối vận tải', 'JobType', N'dieu-phoi-van-tai', N'Lên kế hoạch và điều phối vận chuyển hàng hóa'),
(7, N'Nhân viên kho vận', 'JobType', N'nhan-vien-kho-van', N'Quản lý xuất nhập hàng hóa trong kho'),
(7, N'Chuyên viên xuất nhập khẩu', 'JobType', N'chuyen-vien-xuat-nhap-khau', N'Thủ tục và nghiệp vụ xuất nhập khẩu hàng hóa'),
(7, N'Nhân viên hải quan', 'JobType', N'nhan-vien-hai-quan', N'Khai báo và thông quan hàng hóa'),
(7, N'Lái xe tải / Tài xế', 'JobType', N'lai-xe-tai-tai-xe', N'Vận chuyển hàng hóa và khách hàng'),
(7, N'Quản lý kho', 'JobType', N'quan-ly-kho', N'Quản lý hoạt động kho bãi và tồn kho'),
(7, N'Freight Forwarder', 'JobType', N'freight-forwarder', N'Giao nhận và môi giới vận chuyển quốc tế'),
(7, N'Chuyên viên chuỗi cung ứng', 'JobType', N'chuyen-vien-chuoi-cung-ung', N'Quản lý và tối ưu hóa chuỗi cung ứng'),
(7, N'Nhân viên giao nhận hàng hóa', 'JobType', N'nhan-vien-giao-nhan', N'Tiếp nhận và bàn giao hàng hóa'),
(7, N'Kỹ thuật viên xe', 'JobType', N'ky-thuat-vien-xe', N'Bảo dưỡng và sửa chữa phương tiện vận tải'),
(7, N'Trưởng phòng logistics', 'JobType', N'truong-phong-logistics', N'Quản lý phòng vận hành logistics'),
(7, N'Nhân viên chứng từ xuất nhập khẩu', 'JobType', N'nhan-vien-chung-tu-xnk', N'Chuẩn bị và xử lý bộ chứng từ XNK'),
(7, N'Chuyên viên mua hàng', 'JobType', N'chuyen-vien-mua-hang', N'Tìm kiếm và đàm phán với nhà cung cấp'),
(7, N'Nhân viên giao hàng', 'JobType', N'nhan-vien-giao-hang', N'Giao hàng đến tay khách hàng cuối'),
(7, N'Giám sát kho', 'JobType', N'giam-sat-kho', N'Giám sát hoạt động kho hàng ngày'),
(7, N'Nhân viên kiểm soát tồn kho', 'JobType', N'nhan-vien-kiem-soat-ton-kho', N'Theo dõi và kiểm đếm hàng tồn kho'),
(7, N'Chuyên viên phân tích logistics', 'JobType', N'chuyen-vien-phan-tich-logistics', N'Phân tích dữ liệu và tối ưu quy trình logistics'),
(7, N'Nhân viên vận hành bến bãi', 'JobType', N'nhan-vien-van-hanh-ben-bai', N'Quản lý và điều hành bến bãi, cảng hàng hóa'),
(7, N'Quản lý vận tải quốc tế', 'JobType', N'quan-ly-van-tai-quoc-te', N'Quản lý hoạt động vận chuyển xuyên biên giới'),
-- ── Ngành 8: Y tế - Dược phẩm (20 danh mục) ──
(8, N'Dược sĩ', 'JobType', N'duoc-si', N'Dược sĩ nhà thuốc và bệnh viện'),
(8, N'Bác sĩ đa khoa', 'JobType', N'bac-si-da-khoa', N'Khám chữa bệnh tổng quát'),
(8, N'Điều dưỡng viên', 'JobType', N'dieu-duong-vien', N'Chăm sóc và hỗ trợ điều trị bệnh nhân'),
(8, N'Kỹ thuật viên xét nghiệm', 'JobType', N'ky-thuat-vien-xet-nghiem', N'Thực hiện các xét nghiệm lâm sàng'),
(8, N'Nhân viên kinh doanh dược', 'JobType', N'nhan-vien-kinh-doanh-duoc', N'Giới thiệu và bán sản phẩm dược phẩm'),
(8, N'Chuyên viên nghiên cứu lâm sàng', 'JobType', N'chuyen-vien-nghien-cuu-lam-sang', N'Thử nghiệm và đánh giá thuốc, thiết bị y tế'),
(8, N'Kỹ thuật viên hình ảnh', 'JobType', N'ky-thuat-vien-hinh-anh', N'Vận hành thiết bị X-quang và siêu âm'),
(8, N'Nhân viên y tế công ty', 'JobType', N'nhan-vien-y-te-cong-ty', N'Chăm sóc sức khỏe nhân viên tại doanh nghiệp'),
(8, N'Chuyên viên đảm bảo chất lượng dược', 'JobType', N'chuyen-vien-qa-pharma', N'Kiểm soát chất lượng sản xuất dược phẩm'),
(8, N'Bác sĩ chuyên khoa', 'JobType', N'bac-si-chuyen-khoa', N'Chuyên gia y tế theo lĩnh vực chuyên sâu'),
(8, N'Hộ lý / Điều dưỡng hỗ trợ', 'JobType', N'ho-ly-dieu-duong-ho-tro', N'Hỗ trợ chăm sóc và vệ sinh bệnh nhân'),
(8, N'Trình dược viên', 'JobType', N'trinh-duoc-vien', N'Giới thiệu sản phẩm thuốc tới bác sĩ và bệnh viện'),
(8, N'Quản lý nhà thuốc', 'JobType', N'quan-ly-nha-thuoc', N'Điều hành hoạt động chuỗi nhà thuốc'),
(8, N'Kỹ sư thiết bị y tế', 'JobType', N'ky-su-thiet-bi-y-te', N'Lắp đặt và bảo trì thiết bị y tế'),
(8, N'Chuyên viên dinh dưỡng', 'JobType', N'chuyen-vien-dinh-duong', N'Tư vấn chế độ dinh dưỡng và sức khỏe'),
(8, N'Chuyên viên sức khỏe tâm thần', 'JobType', N'chuyen-vien-suc-khoe-tam-than', N'Tư vấn và hỗ trợ sức khỏe tâm lý'),
(8, N'Kỹ thuật viên vật lý trị liệu', 'JobType', N'ky-thuat-vien-vat-ly-tri-lieu', N'Phục hồi chức năng và vật lý trị liệu'),
(8, N'Quản lý phòng khám', 'JobType', N'quan-ly-phong-kham', N'Điều hành hoạt động phòng khám tư nhân'),
(8, N'Chuyên viên y tế dự phòng', 'JobType', N'chuyen-vien-y-te-du-phong', N'Phòng chống dịch bệnh và y tế cộng đồng'),
(8, N'Nhân viên hành chính bệnh viện', 'JobType', N'nhan-vien-hanh-chinh-benh-vien', N'Hỗ trợ hành chính và quản lý hồ sơ bệnh nhân'),
-- ── Ngành 9: Giáo dục - Đào tạo (20 danh mục) ──
(9, N'Giáo viên - Giảng viên', 'JobType', N'giao-vien-giang-vien', N'Giảng dạy các môn học tại trường và trung tâm'),
(9, N'Giáo viên tiếng Anh', 'JobType', N'giao-vien-tieng-anh', N'Giảng dạy tiếng Anh giao tiếp và học thuật'),
(9, N'Gia sư', 'JobType', N'gia-su', N'Dạy kèm cá nhân cho học sinh'),
(9, N'Chuyên viên đào tạo doanh nghiệp', 'JobType', N'chuyen-vien-dao-tao-doanh-nghiep', N'Thiết kế và giảng dạy chương trình đào tạo nội bộ'),
(9, N'Quản lý trung tâm đào tạo', 'JobType', N'quan-ly-trung-tam-dao-tao', N'Điều hành hoạt động trung tâm dạy học'),
(9, N'Nhân viên tư vấn tuyển sinh', 'JobType', N'nhan-vien-tu-van-tuyen-sinh', N'Tư vấn học sinh và phụ huynh về chương trình học'),
(9, N'Chuyên viên thiết kế chương trình học', 'JobType', N'chuyen-vien-thiet-ke-chuong-trinh', N'Xây dựng giáo trình và chương trình đào tạo'),
(9, N'Giáo viên mầm non', 'JobType', N'giao-vien-mam-non', N'Chăm sóc và giáo dục trẻ mầm non'),
(9, N'Nhân viên hỗ trợ học vụ', 'JobType', N'nhan-vien-ho-tro-hoc-vu', N'Hỗ trợ quản lý hồ sơ và học vụ sinh viên'),
(9, N'Chuyên viên E-learning', 'JobType', N'chuyen-vien-e-learning', N'Xây dựng nội dung học trực tuyến'),
(9, N'Giáo viên âm nhạc / nghệ thuật', 'JobType', N'giao-vien-am-nhac-nghe-thuat', N'Giảng dạy âm nhạc, mỹ thuật và nghệ thuật'),
(9, N'Huấn luyện viên thể thao', 'JobType', N'huan-luyen-vien-the-thao', N'Hướng dẫn và đào tạo thể chất cho học viên'),
(9, N'Chuyên viên tâm lý học đường', 'JobType', N'chuyen-vien-tam-ly-hoc-duong', N'Tư vấn tâm lý và hỗ trợ học sinh'),
(9, N'Trưởng phòng đào tạo', 'JobType', N'truong-phong-dao-tao', N'Quản lý và phát triển chiến lược đào tạo'),
(9, N'Điều phối viên chương trình quốc tế', 'JobType', N'dieu-phoi-chuong-trinh-quoc-te', N'Tổ chức và quản lý hợp tác giáo dục quốc tế'),
(9, N'Giáo viên dạy nghề (STEM)', 'JobType', N'giao-vien-day-nghe-stem', N'Đào tạo kỹ năng nghề và STEM cho học sinh'),
(9, N'Chuyên viên kiểm định chất lượng giáo dục', 'JobType', N'chuyen-vien-kiem-dinh-giao-duc', N'Đánh giá và kiểm định chất lượng cơ sở giáo dục'),
(9, N'Nhân viên thư viện', 'JobType', N'nhan-vien-thu-vien', N'Quản lý sách báo và tài liệu thư viện'),
(9, N'Giám đốc học thuật', 'JobType', N'giam-doc-hoc-thuat', N'Lãnh đạo chuyên môn và chương trình học thuật'),
(9, N'Nhân viên hợp tác quốc tế', 'JobType', N'nhan-vien-hop-tac-quoc-te', N'Kết nối và phát triển hợp tác đối ngoại giáo dục'),
-- ── Ngành 10: Bất động sản - Xây dựng (20 danh mục) ──
(10, N'Kỹ sư xây dựng', 'JobType', N'ky-su-xay-dung', N'Kỹ sư giám sát thi công công trình'),
(10, N'Kiến trúc sư', 'JobType', N'kien-truc-su', N'Thiết kế kiến trúc công trình dân dụng và công nghiệp'),
(10, N'Nhân viên kinh doanh bất động sản', 'JobType', N'nhan-vien-kinh-doanh-bds', N'Tư vấn mua bán và cho thuê bất động sản'),
(10, N'Kỹ sư giám sát công trình', 'JobType', N'ky-su-giam-sat-cong-trinh', N'Giám sát kỹ thuật và tiến độ thi công'),
(10, N'Quản lý dự án xây dựng', 'JobType', N'quan-ly-du-an-xay-dung', N'Lập kế hoạch và điều hành dự án xây dựng'),
(10, N'Kỹ sư thiết kế kết cấu', 'JobType', N'ky-su-thiet-ke-ket-cau', N'Thiết kế kết cấu bê tông và thép công trình'),
(10, N'Nhân viên định giá bất động sản', 'JobType', N'nhan-vien-dinh-gia-bds', N'Thẩm định giá trị tài sản và bất động sản'),
(10, N'Kỹ sư điện công trình', 'JobType', N'ky-su-dien-cong-trinh', N'Thiết kế và giám sát hệ thống điện công trình'),
(10, N'Kỹ sư kết cấu', 'JobType', N'ky-su-ket-cau', N'Tính toán và thiết kế kết cấu công trình'),
(10, N'Nhân viên môi giới bất động sản', 'JobType', N'nhan-vien-moi-gioi-bds', N'Trung gian giao dịch mua bán bất động sản'),
(10, N'Kỹ sư cơ điện lạnh (MEP)', 'JobType', N'ky-su-mep', N'Thiết kế và giám sát hệ thống M&E công trình'),
(10, N'Trưởng nhóm kinh doanh BĐS', 'JobType', N'truong-nhom-kinh-doanh-bds', N'Dẫn dắt đội kinh doanh bất động sản'),
(10, N'Chuyên viên pháp lý bất động sản', 'JobType', N'chuyen-vien-phap-ly-bds', N'Tư vấn pháp lý giao dịch bất động sản'),
(10, N'Kỹ sư địa kỹ thuật', 'JobType', N'ky-su-dia-ky-thuat', N'Khảo sát địa chất và nền móng công trình'),
(10, N'Nhân viên quản lý tòa nhà', 'JobType', N'nhan-vien-quan-ly-toa-nha', N'Vận hành và bảo trì tòa nhà văn phòng/căn hộ'),
(10, N'Kỹ sư hoàn thiện nội thất', 'JobType', N'ky-su-hoan-thien-noi-that', N'Thi công và giám sát hoàn thiện nội thất'),
(10, N'Chuyên viên phát triển dự án BĐS', 'JobType', N'chuyen-vien-phat-trien-du-an-bds', N'Nghiên cứu và phát triển dự án bất động sản mới'),
(10, N'Nhân viên thiết kế nội thất', 'JobType', N'nhan-vien-thiet-ke-noi-that', N'Sáng tạo và trình bày phương án thiết kế nội thất'),
(10, N'Kỹ thuật viên khảo sát', 'JobType', N'ky-thuat-vien-khao-sat', N'Đo đạc địa hình và khảo sát thực địa'),
(10, N'Giám đốc dự án xây dựng', 'JobType', N'giam-doc-du-an-xay-dung', N'Lãnh đạo và chịu trách nhiệm toàn bộ dự án xây dựng');
GO
INSERT INTO Categories (ParentID, Name, Type, Slug, Description) VALUES
(NULL, N'Hà Nội', 'Location', N'ha-noi', N'Địa điểm làm việc: Hà Nội'),
(NULL, N'TP. Hồ Chí Minh', 'Location', N'tp-ho-chi-minh', N'Địa điểm làm việc: TP. Hồ Chí Minh'),
(NULL, N'Đà Nẵng', 'Location', N'da-nang', N'Địa điểm làm việc: Đà Nẵng'),
(NULL, N'Hải Phòng', 'Location', N'hai-phong', N'Địa điểm làm việc: Hải Phòng'),
(NULL, N'Cần Thơ', 'Location', N'can-tho', N'Địa điểm làm việc: Cần Thơ'),
(NULL, N'Bình Dương', 'Location', N'binh-duong', N'Địa điểm làm việc: Bình Dương'),
(NULL, N'Đồng Nai', 'Location', N'dong-nai', N'Địa điểm làm việc: Đồng Nai'),
(NULL, N'Nha Trang', 'Location', N'nha-trang', N'Địa điểm làm việc: Nha Trang');
GO
INSERT INTO Skills (Name, Description, CategoryID, IsActive) VALUES
(N'C#', N'Ngôn ngữ lập trình C#', 1, 1),
(N'Java', N'Ngôn ngữ lập trình Java', 1, 1),
(N'Python', N'Ngôn ngữ lập trình Python', 1, 1),
(N'ReactJS', N'Thư viện JavaScript ReactJS', 1, 1),
(N'Angular', N'Framework Angular', 1, 1),
(N'SQL Server', N'Hệ quản trị CSDL SQL Server', 1, 1),
(N'Docker', N'Công nghệ container Docker', 1, 1),
(N'Kubernetes', N'Điều phối container Kubernetes', 1, 1),
(N'Node.js', N'Môi trường chạy JavaScript phía server', 1, 1),
(N'AWS / Azure / GCP', N'Điện toán đám mây AWS, Azure, Google Cloud', 1, 1),
(N'Quản lý dự án', N'Kỹ năng quản lý dự án phần mềm', 1, 1),
(N'Kiểm thử phần mềm', N'Kiểm thử QA/QC và automation', 1, 1),
(N'Thiết kế UI/UX', N'Thiết kế giao diện và trải nghiệm người dùng', 1, 1),
(N'Excel nâng cao', N'Kỹ năng Excel nâng cao cho tài chính', 2, 1),
(N'Phân tích tài chính', N'Phân tích báo cáo tài chính doanh nghiệp', 2, 1),
(N'Kế toán thuế', N'Nghiệp vụ khai báo và quyết toán thuế', 2, 1),
(N'Phần mềm kế toán', N'Thành thạo MISA, Fast Accounting, SAP', 2, 1),
(N'Kiểm toán', N'Kỹ năng kiểm toán nội bộ và độc lập', 2, 1),
(N'Quản lý rủi ro TC', N'Nhận diện và kiểm soát rủi ro tài chính', 2, 1),
(N'Tài chính doanh nghiệp', N'Hoạch định và phân tích tài chính DN', 2, 1),
(N'Google Ads', N'Quảng cáo tìm kiếm và hiển thị Google Ads', 3, 1),
(N'SEO', N'Tối ưu công cụ tìm kiếm On-page/Off-page', 3, 1),
(N'Facebook Ads', N'Quảng cáo mạng xã hội Facebook/Instagram', 3, 1),
(N'Content Marketing', N'Xây dựng và phân phối nội dung marketing', 3, 1),
(N'Canva / Photoshop', N'Thiết kế đồ họa cơ bản với Canva, Photoshop', 3, 1),
(N'Google Analytics', N'Phân tích dữ liệu web với Google Analytics', 3, 1),
(N'Email Marketing', N'Xây dựng chiến dịch email và automation', 3, 1),
(N'Đàm phán', N'Kỹ năng đàm phán và thuyết phục khách hàng', 4, 1),
(N'Chăm sóc khách hàng', N'Kỹ năng CSKH và xử lý khiếu nại', 4, 1),
(N'CRM', N'Sử dụng phần mềm quản lý khách hàng CRM', 4, 1),
(N'Kỹ năng thuyết trình', N'Kỹ năng trình bày và thuyết phục', 4, 1),
(N'Quản lý đại lý', N'Xây dựng và phát triển mạng lưới đại lý', 4, 1),
(N'Phân tích thị trường', N'Nghiên cứu và phân tích xu hướng thị trường', 4, 1),
(N'Tuyển dụng', N'Kỹ năng tuyển dụng và đánh giá ứng viên', 5, 1),
(N'Phỏng vấn', N'Kỹ năng phỏng vấn hành vi và năng lực', 5, 1),
(N'Phần mềm HRMS', N'Sử dụng hệ thống quản lý nhân sự HRMS', 5, 1),
(N'Tính lương (C&B)', N'Kỹ năng tính toán lương và phúc lợi nhân viên', 5, 1),
(N'Đào tạo nội bộ', N'Thiết kế và triển khai chương trình đào tạo', 5, 1),
(N'Luật lao động', N'Am hiểu Bộ luật Lao động và quy định BHXH', 5, 1),
(N'AutoCAD', N'Thiết kế kỹ thuật 2D/3D bằng AutoCAD', 6, 1),
(N'PLC / SCADA', N'Lập trình PLC và hệ thống điều khiển SCADA', 6, 1),
(N'Quản lý chất lượng ISO', N'Áp dụng tiêu chuẩn ISO 9001/14001/45001', 6, 1),
(N'Lean Manufacturing', N'Áp dụng Lean, 5S, Kaizen trong sản xuất', 6, 1),
(N'An toàn lao động', N'Quy định và thực hành an toàn lao động', 6, 1),
(N'Bảo trì thiết bị', N'Lập kế hoạch và thực hiện bảo trì máy móc', 6, 1),
(N'Xuất nhập khẩu', N'Nghiệp vụ và thủ tục xuất nhập khẩu hàng hóa', 7, 1),
(N'Quản lý kho (WMS)', N'Vận hành hệ thống quản lý kho WMS', 7, 1),
(N'Hải quan', N'Khai báo và thông quan hàng hóa xuất nhập khẩu', 7, 1),
(N'Điều phối vận tải', N'Lên kế hoạch và tối ưu tuyến đường vận chuyển', 7, 1),
(N'Chuỗi cung ứng', N'Quản lý và tối ưu hóa chuỗi cung ứng', 7, 1),
(N'Incoterms', N'Am hiểu các điều kiện thương mại quốc tế', 7, 1),
(N'Dược lâm sàng', N'Kiến thức dược lâm sàng và tương tác thuốc', 8, 1),
(N'Chăm sóc bệnh nhân', N'Kỹ năng chăm sóc và theo dõi bệnh nhân', 8, 1),
(N'Kiến thức y tế', N'Kiến thức y tế cơ bản và sơ cấp cứu', 8, 1),
(N'Tư vấn thuốc', N'Kỹ năng tư vấn và hướng dẫn sử dụng thuốc', 8, 1),
(N'Thiết bị y tế', N'Vận hành và bảo trì thiết bị y tế', 8, 1),
(N'GMP / GLP', N'Quy trình sản xuất và kiểm nghiệm dược phẩm', 8, 1),
(N'Giảng dạy', N'Phương pháp giảng dạy tích cực và hiệu quả', 9, 1),
(N'Soạn giáo án', N'Xây dựng giáo trình và kế hoạch bài học', 9, 1),
(N'Tiếng Anh', N'Giao tiếp và giảng dạy tiếng Anh', 9, 1),
(N'E-learning', N'Thiết kế và phát triển nội dung học trực tuyến', 9, 1),
(N'Tâm lý học đường', N'Tư vấn và hỗ trợ tâm lý cho học sinh', 9, 1),
(N'Quản lý lớp học', N'Kỹ năng tổ chức và quản lý lớp học hiệu quả', 9, 1),
(N'AutoCAD xây dựng', N'Vẽ kỹ thuật công trình bằng AutoCAD', 10, 1),
(N'Revit / BIM', N'Thiết kế mô hình thông tin công trình (BIM)', 10, 1),
(N'Quản lý dự án XD', N'Lập kế hoạch và giám sát dự án xây dựng', 10, 1),
(N'Thẩm định giá BĐS', N'Định giá tài sản và bất động sản', 10, 1),
(N'Pháp lý bất động sản', N'Thủ tục pháp lý mua bán và chuyển nhượng BĐS', 10, 1),
(N'Dự toán công trình', N'Lập và kiểm soát dự toán chi phí xây dựng', 10, 1);
INSERT INTO Employers (UserId, CompanyName, TaxCode, Industry, CompanySize, Address, Website, IsVerified, Status, Description, WhyWorkHereJson) VALUES
(27, N'Công ty CP Công nghệ Sao Việt', N'90000001', N'Công nghệ thông tin', N'500-1000', N'Số 17 đường Nguyễn Trãi, Quận 1, Hà Nội', N'https://côngtycpcôngnghệsa.vn', 1, N'Active', N'Phát triển phần mềm và giải pháp doanh nghiệp cho khách hàng trong và ngoài nước, tập trung vào các dự án outsourcing và sản phẩm SaaS.

Được thành lập từ năm 2006 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty CP Công nghệ Sao Việt không ngừng triển khai chương trình trách nhiệm xã hội (CSR), đóng góp cho cộng đồng địa phương, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng. Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban.

Trụ sở chính của công ty đặt tại Số 17 đường Nguyễn Trãi, Quận 1, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Công nghệ Sao Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(28, N'Công ty TNHH Giải pháp Số Hưng Thịnh', N'90000002', N'Công nghệ thông tin', N'100-500', N'Số 24 đường Lê Lợi, Quận 3, TP. Hồ Chí Minh', N'https://côngtytnhhgiảipháp.vn', 1, N'Active', N'Chuyên cung cấp dịch vụ chuyển đổi số, tư vấn giải pháp ERP và phát triển ứng dụng di động cho doanh nghiệp vừa và nhỏ.

Được thành lập từ năm 2007 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty TNHH Giải pháp Số Hưng Thịnh không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 24 đường Lê Lợi, Quận 3, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty TNHH Giải pháp Số Hưng Thịnh luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(29, N'Công ty CP Ví điện tử An Phát', N'90000003', N'Fintech', N'500-1000', N'Số 31 đường Trần Hưng Đạo, Quận 7, TP. Hồ Chí Minh', N'https://côngtycpvíđiệntửan.vn', 1, N'Active', N'Cung cấp dịch vụ ví điện tử, thanh toán trực tuyến và các giải pháp tài chính số cho hàng triệu người dùng.

Được thành lập từ năm 2008 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực fintech với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành fintech.

Trong những năm gần đây, Công ty CP Ví điện tử An Phát không ngừng đầu tư nâng cấp hệ thống công nghệ, cơ sở vật chất nhằm tối ưu hiệu quả vận hành, khẳng định vị thế trong ngành fintech tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 31 đường Trần Hưng Đạo, Quận 7, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Ví điện tử An Phát luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực fintech", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành fintech", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(30, N'Công ty CP Thương mại Điện tử Việt Tiến', N'90000004', N'Thương mại điện tử', N'500-1000', N'Số 38 đường Hai Bà Trưng, Quận 10, TP. Hồ Chí Minh', N'https://côngtycpthươngmạiđ.vn', 1, N'Active', N'Vận hành sàn thương mại điện tử với danh mục hàng trăm nghìn sản phẩm, phục vụ người tiêu dùng trên toàn quốc.

Được thành lập từ năm 2009 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thương mại điện tử với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thương mại điện tử.

Trong những năm gần đây, Công ty CP Thương mại Điện tử Việt Tiến không ngừng triển khai chương trình trách nhiệm xã hội (CSR), đóng góp cho cộng đồng địa phương, khẳng định vị thế trong ngành thương mại điện tử tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 38 đường Hai Bà Trưng, Quận 10, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Thương mại Điện tử Việt Tiến luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thương mại điện tử", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành thương mại điện tử", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(31, N'Công ty TNHH Bán lẻ Trực tuyến Minh Long', N'90000005', N'Thương mại điện tử', N'1000+', N'Số 45 đường Nguyễn Văn Linh, Cầu Giấy, TP. Hồ Chí Minh', N'https://côngtytnhhbánlẻtrự.vn', 1, N'Active', N'Nền tảng bán lẻ trực tuyến kết nối nhà bán hàng và người tiêu dùng, phát triển hệ thống logistics riêng.

Được thành lập từ năm 2010 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thương mại điện tử với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thương mại điện tử.

Trong những năm gần đây, Công ty TNHH Bán lẻ Trực tuyến Minh Long không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành thương mại điện tử tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 45 đường Nguyễn Văn Linh, Cầu Giấy, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty TNHH Bán lẻ Trực tuyến Minh Long luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thương mại điện tử", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành thương mại điện tử", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(32, N'Tổng Công ty Viễn thông Đông Á', N'90000006', N'Viễn thông', N'1000+', N'Số 52 đường Phạm Văn Đồng, Đống Đa, Hà Nội', N'https://tổngcôngtyviễnthôn.vn', 1, N'Active', N'Cung cấp dịch vụ viễn thông, internet băng rộng và hạ tầng mạng cho khách hàng cá nhân và doanh nghiệp.

Được thành lập từ năm 2011 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực viễn thông với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành viễn thông.

Trong những năm gần đây, Tổng Công ty Viễn thông Đông Á không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành viễn thông tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban.

Trụ sở chính của công ty đặt tại Số 52 đường Phạm Văn Đồng, Đống Đa, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Tổng Công ty Viễn thông Đông Á luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực viễn thông", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành viễn thông", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(33, N'Công ty CP Thực phẩm Sữa Phương Nam', N'90000007', N'Thực phẩm - Đồ uống', N'1000+', N'Số 59 đường Điện Biên Phủ, Hai Bà Trưng, TP. Hồ Chí Minh', N'https://côngtycpthựcphẩmsữ.vn', 1, N'Active', N'Sản xuất và phân phối các sản phẩm sữa, đồ uống dinh dưỡng với hệ thống nhà máy đạt chuẩn quốc tế.

Được thành lập từ năm 2012 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thực phẩm - đồ uống với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thực phẩm - đồ uống.

Trong những năm gần đây, Công ty CP Thực phẩm Sữa Phương Nam không ngừng đầu tư nâng cấp hệ thống công nghệ, cơ sở vật chất nhằm tối ưu hiệu quả vận hành, khẳng định vị thế trong ngành thực phẩm - đồ uống tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ. Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban.

Trụ sở chính của công ty đặt tại Số 59 đường Điện Biên Phủ, Hai Bà Trưng, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Thực phẩm Sữa Phương Nam luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thực phẩm - đồ uống", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành thực phẩm - đồ uống", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(34, N'Ngân hàng TMCP Kỹ Nghệ Việt', N'90000008', N'Ngân hàng - Tài chính', N'1000+', N'Số 66 đường Cách Mạng Tháng Tám, Thanh Xuân, Hà Nội', N'https://ngânhàngtmcpkỹnghệ.vn', 1, N'Active', N'Cung cấp dịch vụ ngân hàng bán lẻ, doanh nghiệp và ngân hàng số cho khách hàng trên cả nước.

Được thành lập từ năm 2013 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.

Trong những năm gần đây, Ngân hàng TMCP Kỹ Nghệ Việt không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành ngân hàng - tài chính tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 66 đường Cách Mạng Tháng Tám, Thanh Xuân, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Ngân hàng TMCP Kỹ Nghệ Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành ngân hàng - tài chính", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(35, N'Tập đoàn Bất động sản Hoàng Gia Land', N'90000009', N'Bất động sản', N'1000+', N'Số 73 đường Nguyễn Huệ, Long Biên, Hà Nội', N'https://tậpđoànbấtđộngsảnh.vn', 1, N'Active', N'Phát triển các dự án khu đô thị, nhà ở và bất động sản nghỉ dưỡng quy mô lớn.

Được thành lập từ năm 2014 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực bất động sản với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành bất động sản.

Trong những năm gần đây, Tập đoàn Bất động sản Hoàng Gia Land không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành bất động sản tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 73 đường Nguyễn Huệ, Long Biên, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Tập đoàn Bất động sản Hoàng Gia Land luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực bất động sản", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành bất động sản", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(36, N'Công ty CP Công nghệ Vận tải Đi Chung', N'90000010', N'Công nghệ - Vận tải', N'500-1000', N'Số 80 đường Võ Văn Kiệt, Hải Châu, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệvậ.vn', 1, N'Active', N'Nền tảng gọi xe công nghệ và giao hàng, kết nối tài xế và khách hàng qua ứng dụng di động.

Được thành lập từ năm 2015 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ - vận tải với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ - vận tải.

Trong những năm gần đây, Công ty CP Công nghệ Vận tải Đi Chung không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành công nghệ - vận tải tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 80 đường Võ Văn Kiệt, Hải Châu, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Công nghệ Vận tải Đi Chung luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ - vận tải", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ - vận tải", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(37, N'Tập đoàn Công nghệ Bình Minh', N'90000011', N'Công nghệ thông tin', N'500-1000', N'Số 87 đường Láng Hạ, Ninh Kiều, Hà Nội', N'https://tậpđoàncôngnghệbìn.vn', 1, N'Active', N'Đầu tư và phát triển các công ty con trong lĩnh vực công nghệ, an ninh mạng và trí tuệ nhân tạo.

Được thành lập từ năm 2016 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Tập đoàn Công nghệ Bình Minh không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài.

Trụ sở chính của công ty đặt tại Số 87 đường Láng Hạ, Ninh Kiều, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Tập đoàn Công nghệ Bình Minh luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(38, N'Công ty CP Hàng tiêu dùng Đại Dương', N'90000012', N'Hàng tiêu dùng', N'1000+', N'Số 94 đường Trường Chinh, Sơn Trà, TP. Hồ Chí Minh', N'https://côngtycphàngtiêudù.vn', 1, N'Active', N'Sản xuất và phân phối các mặt hàng tiêu dùng nhanh (FMCG) với hệ thống phân phối rộng khắp cả nước.

Được thành lập từ năm 2017 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực hàng tiêu dùng với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành hàng tiêu dùng.

Trong những năm gần đây, Công ty CP Hàng tiêu dùng Đại Dương không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành hàng tiêu dùng tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 94 đường Trường Chinh, Sơn Trà, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Hàng tiêu dùng Đại Dương luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực hàng tiêu dùng", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành hàng tiêu dùng", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(39, N'Ngân hàng TMCP Thịnh Vượng Sài Gòn', N'90000013', N'Ngân hàng - Tài chính', N'1000+', N'Số 101 đường Kim Mã, Quận 1, TP. Hồ Chí Minh', N'https://ngânhàngtmcpthịnhv.vn', 1, N'Active', N'Cung cấp các sản phẩm tín dụng, tiết kiệm và dịch vụ ngân hàng số cho khách hàng cá nhân và SME.

Được thành lập từ năm 2018 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.

Trong những năm gần đây, Ngân hàng TMCP Thịnh Vượng Sài Gòn không ngừng đạt chứng nhận ISO 9001:2015 về hệ thống quản lý chất lượng, khẳng định vị thế trong ngành ngân hàng - tài chính tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng. Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài.

Trụ sở chính của công ty đặt tại Số 101 đường Kim Mã, Quận 1, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Ngân hàng TMCP Thịnh Vượng Sài Gòn luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành ngân hàng - tài chính", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(40, N'Công ty CP Hàng không Cánh Việt', N'90000014', N'Hàng không', N'500-1000', N'Số 108 đường Xuân Thủy, Quận 3, TP. Hồ Chí Minh', N'https://côngtycphàngkhôngc.vn', 1, N'Active', N'Khai thác các đường bay nội địa và quốc tế, cung cấp dịch vụ vận chuyển hành khách và hàng hóa.

Được thành lập từ năm 2019 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực hàng không với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành hàng không.

Trong những năm gần đây, Công ty CP Hàng không Cánh Việt không ngừng đầu tư nâng cấp hệ thống công nghệ, cơ sở vật chất nhằm tối ưu hiệu quả vận hành, khẳng định vị thế trong ngành hàng không tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ. Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban.

Trụ sở chính của công ty đặt tại Số 108 đường Xuân Thủy, Quận 3, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Hàng không Cánh Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực hàng không", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành hàng không", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(41, N'Công ty TNHH Phần mềm Kim Cương', N'90000015', N'Công nghệ thông tin', N'500-1000', N'Số 115 đường Tôn Đức Thắng, Quận 7, Hà Nội', N'https://côngtytnhhphầnmềmk.vn', 1, N'Active', N'Gia công phần mềm cho thị trường Nhật Bản, Mỹ và châu Âu, tập trung vào các dự án ngân hàng và bảo hiểm.

Được thành lập từ năm 2020 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty TNHH Phần mềm Kim Cương không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài.

Trụ sở chính của công ty đặt tại Số 115 đường Tôn Đức Thắng, Quận 7, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty TNHH Phần mềm Kim Cương luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(42, N'Công ty CP Giải pháp Công nghệ Phương Đông', N'90000016', N'Công nghệ thông tin', N'100-500', N'Số 122 đường Nguyễn Trãi, Quận 10, TP. Hồ Chí Minh', N'https://côngtycpgiảiphápcô.vn', 1, N'Active', N'Phát triển sản phẩm phần mềm quản lý doanh nghiệp và tư vấn chuyển đổi số cho khách hàng SME.

Được thành lập từ năm 2005 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty CP Giải pháp Công nghệ Phương Đông không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 122 đường Nguyễn Trãi, Quận 10, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Giải pháp Công nghệ Phương Đông luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(43, N'Công ty TNHH Phần mềm Toàn Cầu Việt', N'90000017', N'Công nghệ thông tin', N'100-500', N'Số 129 đường Lê Lợi, Cầu Giấy, TP. Hồ Chí Minh', N'https://côngtytnhhphầnmềmt.vn', 1, N'Active', N'Cung cấp dịch vụ phát triển phần mềm theo yêu cầu và giải pháp kiểm thử tự động cho đối tác nước ngoài.

Được thành lập từ năm 2006 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty TNHH Phần mềm Toàn Cầu Việt không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 129 đường Lê Lợi, Cầu Giấy, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty TNHH Phần mềm Toàn Cầu Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(44, N'Công ty CP Công nghệ Tân Tiến', N'90000018', N'Công nghệ thông tin', N'100-500', N'Số 136 đường Trần Hưng Đạo, Đống Đa, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệtâ.vn', 0, N'Pending', N'Xây dựng nền tảng phần mềm cho lĩnh vực bán lẻ và chuỗi cung ứng, đang trong quá trình xác minh thông tin doanh nghiệp.

Được thành lập từ năm 2007 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty CP Công nghệ Tân Tiến không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 136 đường Trần Hưng Đạo, Đống Đa, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Công nghệ Tân Tiến luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(45, N'Công ty CP Giải pháp Phần mềm Kết Nối', N'90000019', N'Công nghệ thông tin', N'1000+', N'Số 143 đường Hai Bà Trưng, Hai Bà Trưng, TP. Hồ Chí Minh', N'https://côngtycpgiảiphápph.vn', 0, N'Pending', N'Gia công phần mềm quy mô lớn cho khách hàng quốc tế, đang chờ xác minh hồ sơ pháp lý trên hệ thống.

Được thành lập từ năm 2008 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.

Trong những năm gần đây, Công ty CP Giải pháp Phần mềm Kết Nối không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành công nghệ thông tin tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 143 đường Hai Bà Trưng, Hai Bà Trưng, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Giải pháp Phần mềm Kết Nối luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ thông tin", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(46, N'Công ty CP Ô tô Điện Việt Phong', N'90000020', N'Sản xuất ô tô', N'1000+', N'Số 150 đường Nguyễn Văn Linh, Thanh Xuân, Hải Phòng', N'https://côngtycpôtôđiệnviệ.vn', 0, N'Pending', N'Sản xuất và lắp ráp ô tô điện, đầu tư nhà máy công nghệ cao, hiện đang hoàn thiện hồ sơ xác minh doanh nghiệp.

Được thành lập từ năm 2009 và có trụ sở chính tại Hải Phòng, công ty hoạt động trong lĩnh vực sản xuất ô tô với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành sản xuất ô tô.

Trong những năm gần đây, Công ty CP Ô tô Điện Việt Phong không ngừng hợp tác với nhiều đối tác, khách hàng doanh nghiệp lớn trong và ngoài nước, khẳng định vị thế trong ngành sản xuất ô tô tại thị trường Việt Nam. Với quy mô nhân sự 1000+ người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 150 đường Nguyễn Văn Linh, Thanh Xuân, Hải Phòng, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Ô tô Điện Việt Phong luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực sản xuất ô tô", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành sản xuất ô tô", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(47, N'Công ty CP Công nghệ Di Chuyển Xanh', N'90000021', N'Công nghệ - Vận tải', N'500-1000', N'Số 157 đường Phạm Văn Đồng, Long Biên, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệdi.vn', 1, N'Active', N'Nền tảng gọi xe công nghệ tập trung vào phương tiện thân thiện môi trường.

Được thành lập từ năm 2010 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ - vận tải với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ - vận tải.

Trong những năm gần đây, Công ty CP Công nghệ Di Chuyển Xanh không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành công nghệ - vận tải tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 157 đường Phạm Văn Đồng, Long Biên, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Công nghệ Di Chuyển Xanh luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ - vận tải", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành công nghệ - vận tải", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(48, N'Công ty CP Dược phẩm An Khang', N'90000022', N'Y tế - Dược phẩm', N'500-1000', N'Số 164 đường Điện Biên Phủ, Hải Châu, Hà Nội', N'https://côngtycpdượcphẩman.vn', 1, N'Active', N'Sản xuất và phân phối dược phẩm, thực phẩm chức năng, vận hành chuỗi nhà thuốc trên toàn quốc.

Được thành lập từ năm 2011 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực y tế - dược phẩm với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành y tế - dược phẩm.

Trong những năm gần đây, Công ty CP Dược phẩm An Khang không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành y tế - dược phẩm tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 164 đường Điện Biên Phủ, Hải Châu, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Dược phẩm An Khang luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực y tế - dược phẩm", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành y tế - dược phẩm", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(49, N'Công ty CP Giáo dục Trí Việt', N'90000023', N'Giáo dục - Đào tạo', N'100-500', N'Số 171 đường Cách Mạng Tháng Tám, Ninh Kiều, TP. Hồ Chí Minh', N'https://côngtycpgiáodụctrí.vn', 1, N'Active', N'Cung cấp chương trình đào tạo kỹ năng, ngoại ngữ và luyện thi trực tuyến.

Được thành lập từ năm 2012 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực giáo dục - đào tạo với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành giáo dục - đào tạo.

Trong những năm gần đây, Công ty CP Giáo dục Trí Việt không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành giáo dục - đào tạo tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 171 đường Cách Mạng Tháng Tám, Ninh Kiều, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Giáo dục Trí Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực giáo dục - đào tạo", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành giáo dục - đào tạo", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(50, N'Công ty CP Xây dựng Thành Đô', N'90000024', N'Bất động sản - Xây dựng', N'500-1000', N'Số 178 đường Nguyễn Huệ, Sơn Trà, Hà Nội', N'https://côngtycpxâydựngthà.vn', 1, N'Active', N'Thi công các công trình dân dụng, công nghiệp và hạ tầng giao thông.

Được thành lập từ năm 2013 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực bất động sản - xây dựng với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành bất động sản - xây dựng.

Trong những năm gần đây, Công ty CP Xây dựng Thành Đô không ngừng mở rộng thêm chi nhánh/văn phòng đại diện tại các thành phố lớn nhằm phục vụ khách hàng tốt hơn, khẳng định vị thế trong ngành bất động sản - xây dựng tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Đội ngũ lãnh đạo luôn khuyến khích tinh thần học hỏi, chủ động chia sẻ kiến thức và hỗ trợ lẫn nhau giữa các phòng ban.

Trụ sở chính của công ty đặt tại Số 178 đường Nguyễn Huệ, Sơn Trà, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Xây dựng Thành Đô luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực bất động sản - xây dựng", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành bất động sản - xây dựng", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(51, N'Công ty CP Logistics Miền Trung', N'90000025', N'Vận tải - Logistics', N'100-500', N'Số 185 đường Võ Văn Kiệt, Quận 1, Đà Nẵng', N'https://côngtycplogisticsm.vn', 1, N'Active', N'Cung cấp dịch vụ vận chuyển hàng hóa, kho bãi và giao nhận cho khu vực miền Trung.

Được thành lập từ năm 2014 và có trụ sở chính tại Đà Nẵng, công ty hoạt động trong lĩnh vực vận tải - logistics với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành vận tải - logistics.

Trong những năm gần đây, Công ty CP Logistics Miền Trung không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành vận tải - logistics tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 185 đường Võ Văn Kiệt, Quận 1, Đà Nẵng, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Logistics Miền Trung luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực vận tải - logistics", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành vận tải - logistics", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(52, N'Công ty CP Bán lẻ Điện máy Phú Cường', N'90000026', N'Kinh doanh - Bán lẻ', N'500-1000', N'Số 192 đường Láng Hạ, Quận 3, Hà Nội', N'https://côngtycpbánlẻđiệnm.vn', 1, N'Active', N'Vận hành hệ thống siêu thị điện máy và đồ gia dụng trên toàn quốc.

Được thành lập từ năm 2015 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực kinh doanh - bán lẻ với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành kinh doanh - bán lẻ.

Trong những năm gần đây, Công ty CP Bán lẻ Điện máy Phú Cường không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành kinh doanh - bán lẻ tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 192 đường Láng Hạ, Quận 3, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Bán lẻ Điện máy Phú Cường luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực kinh doanh - bán lẻ", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành kinh doanh - bán lẻ", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(53, N'Công ty CP Truyền thông Sáng Tạo Việt', N'90000027', N'Marketing - Truyền thông', N'100-500', N'Số 199 đường Trường Chinh, Quận 7, TP. Hồ Chí Minh', N'https://côngtycptruyềnthôn.vn', 1, N'Active', N'Cung cấp dịch vụ truyền thông, sản xuất nội dung số và quảng cáo cho các nhãn hàng.

Được thành lập từ năm 2016 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực marketing - truyền thông với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành marketing - truyền thông.

Trong những năm gần đây, Công ty CP Truyền thông Sáng Tạo Việt không ngừng đầu tư nâng cấp hệ thống công nghệ, cơ sở vật chất nhằm tối ưu hiệu quả vận hành, khẳng định vị thế trong ngành marketing - truyền thông tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng. Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài.

Trụ sở chính của công ty đặt tại Số 199 đường Trường Chinh, Quận 7, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Truyền thông Sáng Tạo Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực marketing - truyền thông", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành marketing - truyền thông", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(54, N'Công ty CP Bảo hiểm Niềm Tin Việt', N'90000028', N'Ngân hàng - Tài chính', N'500-1000', N'Số 16 đường Kim Mã, Quận 10, Hà Nội', N'https://côngtycpbảohiểmniề.vn', 1, N'Active', N'Cung cấp các sản phẩm bảo hiểm nhân thọ và phi nhân thọ cho khách hàng cá nhân, doanh nghiệp.

Được thành lập từ năm 2017 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.

Trong những năm gần đây, Công ty CP Bảo hiểm Niềm Tin Việt không ngừng triển khai chương trình trách nhiệm xã hội (CSR), đóng góp cho cộng đồng địa phương, khẳng định vị thế trong ngành ngân hàng - tài chính tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng. Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài.

Trụ sở chính của công ty đặt tại Số 16 đường Kim Mã, Quận 10, Hà Nội, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Bảo hiểm Niềm Tin Việt luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành ngân hàng - tài chính", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(55, N'Công ty CP Năng lượng Xanh Toàn Cầu', N'90000029', N'Sản xuất - Cơ khí', N'500-1000', N'Số 23 đường Xuân Thủy, Cầu Giấy, Đồng Nai', N'https://côngtycpnănglượngx.vn', 1, N'Active', N'Đầu tư và vận hành các nhà máy năng lượng tái tạo, sản xuất thiết bị cơ điện.

Được thành lập từ năm 2018 và có trụ sở chính tại Đồng Nai, công ty hoạt động trong lĩnh vực sản xuất - cơ khí với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành sản xuất - cơ khí.

Trong những năm gần đây, Công ty CP Năng lượng Xanh Toàn Cầu không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành sản xuất - cơ khí tại thị trường Việt Nam. Với quy mô nhân sự 500-1000 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Không gian văn phòng được thiết kế hiện đại, thoải mái, có khu vực sinh hoạt chung dành cho nhân viên nghỉ ngơi giữa giờ.

Trụ sở chính của công ty đặt tại Số 23 đường Xuân Thủy, Cầu Giấy, Đồng Nai, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty CP Năng lượng Xanh Toàn Cầu luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực sản xuất - cơ khí", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành sản xuất - cơ khí", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]'),
(56, N'Công ty TNHH Thời trang Việt Xinh', N'90000030', N'Kinh doanh - Bán lẻ', N'100-500', N'Số 30 đường Tôn Đức Thắng, Đống Đa, TP. Hồ Chí Minh', N'https://côngtytnhhthờitran.vn', 1, N'Active', N'Thiết kế, sản xuất và phân phối thời trang nội địa qua hệ thống cửa hàng và kênh online.

Được thành lập từ năm 2019 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực kinh doanh - bán lẻ với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành kinh doanh - bán lẻ.

Trong những năm gần đây, Công ty TNHH Thời trang Việt Xinh không ngừng được vinh danh trong bảng xếp hạng doanh nghiệp tiêu biểu của ngành, khẳng định vị thế trong ngành kinh doanh - bán lẻ tại thị trường Việt Nam. Với quy mô nhân sự 100-500 người, công ty duy trì bộ máy tổ chức tinh gọn nhưng hiệu quả, các phòng ban phối hợp chặt chẽ để đảm bảo chất lượng sản phẩm/dịch vụ cung cấp ra thị trường.

Các hoạt động gắn kết nội bộ như du lịch hè, tiệc cuối năm, giải thể thao được tổ chức thường niên nhằm xây dựng văn hóa gắn bó lâu dài. Công ty tổ chức đánh giá hiệu suất nhân viên định kỳ theo quý, gắn liền với chính sách thưởng minh bạch, rõ ràng.

Trụ sở chính của công ty đặt tại Số 30 đường Tôn Đức Thắng, Đống Đa, TP. Hồ Chí Minh, thuận tiện di chuyển và kết nối với các đối tác, khách hàng trong khu vực. Công ty TNHH Thời trang Việt Xinh luôn chào đón những ứng viên có năng lực, tinh thần cầu tiến và mong muốn gắn bó phát triển sự nghiệp lâu dài cùng doanh nghiệp.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực kinh doanh - bán lẻ", "Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý", "Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân", "Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn", "Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc", "Được tham gia các dự án thực tế ngay từ giai đoạn đầu, tích lũy kinh nghiệm chuyên môn trong ngành kinh doanh - bán lẻ", "Chính sách nghỉ phép, chế độ bảo hiểm đầy đủ theo quy định, hỗ trợ thêm bảo hiểm sức khỏe nâng cao", "Không gian làm việc hiện đại, trang thiết bị đầy đủ phục vụ công việc hiệu quả"]');

GO
UPDATE Employers SET CompanyCode = 'CTY' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 6));
GO
UPDATE Employers SET IsFeatured = 1
WHERE EmployerId IN (1,3,4,6,8,9,10,11);
GO
INSERT INTO CandidateProfiles (UserId, FullName, Phone, DateOfBirth, Gender, Address, JobTitle, Summary, ExperienceYears, DesiredSalary, IsOpenToWork) VALUES
(57, N'Đỗ Thị Phương', '0912001001', '1994-02-02', N'Nữ', N'Hà Nội', N'Frontend Developer', N'Ứng viên có 1 năm kinh nghiệm ở vị trí Frontend Developer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 1, 11500000, 1),
(58, N'Vũ Quang Huy', '0912001002', '1995-03-03', N'Nam', N'TP. Hồ Chí Minh', N'Backend Developer', N'Ứng viên có 2 năm kinh nghiệm ở vị trí Backend Developer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 2, 14000000, 1),
(59, N'Ngô Thị Lan', '0912001003', '1996-04-04', N'Nữ', N'Đà Nẵng', N'Data Analyst', N'Ứng viên có 3 năm kinh nghiệm ở vị trí Data Analyst, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 3, 16500000, 1),
(60, N'Bùi Văn Khoa', '0912001004', '1997-05-05', N'Nam', N'Hải Phòng', N'DevOps Engineer', N'Ứng viên có 4 năm kinh nghiệm ở vị trí DevOps Engineer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 4, 19000000, 0),
(61, N'Lý Thị Mai', '0912001005', '1998-06-06', N'Nữ', N'Cần Thơ', N'UI/UX Designer', N'Ứng viên có 5 năm kinh nghiệm ở vị trí UI/UX Designer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 5, 19000000, 1),
(62, N'Đinh Văn Nam', '0912001006', '1999-07-07', N'Nam', N'Nha Trang', N'Project Manager', N'Ứng viên có 6 năm kinh nghiệm ở vị trí Project Manager, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 6, 21500000, 1),
(63, N'Phan Thị Oanh', '0912001007', '2000-08-08', N'Nữ', N'Bình Dương', N'Kế toán tổng hợp', N'Ứng viên có 7 năm kinh nghiệm ở vị trí Kế toán tổng hợp, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 7, 24000000, 1),
(64, N'Tô Minh Phúc', '0912001008', '2001-09-09', N'Nam', N'Đồng Nai', N'Digital Marketing Specialist', N'Ứng viên có 8 năm kinh nghiệm ở vị trí Digital Marketing Specialist, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 8, 26500000, 0),
(65, N'Cao Thị Quỳnh', '0912001009', '2002-10-10', N'Nữ', N'Hà Nội', N'Nhân viên kinh doanh', N'Ứng viên có 1 năm kinh nghiệm ở vị trí Nhân viên kinh doanh, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 1, 13000000, 1),
(66, N'Hà Văn Sơn', '0912001010', '1993-11-11', N'Nam', N'TP. Hồ Chí Minh', N'Full-stack Developer', N'Ứng viên có 2 năm kinh nghiệm ở vị trí Full-stack Developer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 2, 13000000, 1),
(67, N'Lương Thị Trang', '0912001011', '1994-12-12', N'Nữ', N'Đà Nẵng', N'HR Executive', N'Ứng viên có 3 năm kinh nghiệm ở vị trí HR Executive, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 3, 15500000, 1),
(68, N'Mai Văn Uy', '0912001012', '1995-01-13', N'Nam', N'Hải Phòng', N'Mobile Developer', N'Ứng viên có 4 năm kinh nghiệm ở vị trí Mobile Developer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 4, 18000000, 0),
(69, N'Trịnh Thị Vân', '0912001013', '1996-02-14', N'Nữ', N'Cần Thơ', N'Business Analyst', N'Ứng viên có 5 năm kinh nghiệm ở vị trí Business Analyst, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 5, 20500000, 1),
(70, N'Dương Văn Xuân', '0912001014', '1997-03-15', N'Nam', N'Nha Trang', N'QA/QC Engineer', N'Ứng viên có 6 năm kinh nghiệm ở vị trí QA/QC Engineer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 6, 23000000, 1),
(71, N'Nguyễn Thị Yến', '0912001015', '1998-04-16', N'Nữ', N'Bình Dương', N'Data Scientist', N'Ứng viên có 7 năm kinh nghiệm ở vị trí Data Scientist, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 7, 23000000, 1),
(72, N'Trần Văn Ánh', '0912001016', '1999-05-17', N'Nam', N'Đồng Nai', N'System Administrator', N'Ứng viên có 8 năm kinh nghiệm ở vị trí System Administrator, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 8, 25500000, 0),
(73, N'Lê Thị Bích', '0912001017', '2000-06-18', N'Nữ', N'Hà Nội', N'Content Writer', N'Ứng viên có 1 năm kinh nghiệm ở vị trí Content Writer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 1, 12000000, 1),
(74, N'Phạm Văn Cảnh', '0912001018', '2001-07-19', N'Nam', N'TP. Hồ Chí Minh', N'Customer Support Specialist', N'Ứng viên có 2 năm kinh nghiệm ở vị trí Customer Support Specialist, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 2, 14500000, 1),
(75, N'Hoàng Thị Duyên', '0912001019', '2002-08-20', N'Nữ', N'Đà Nẵng', N'Product Owner', N'Ứng viên có 3 năm kinh nghiệm ở vị trí Product Owner, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 3, 17000000, 1),
(76, N'Vũ Văn Giang', '0912001020', '1993-09-21', N'Nam', N'Hải Phòng', N'Cloud Engineer', N'Ứng viên có 4 năm kinh nghiệm ở vị trí Cloud Engineer, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 4, 17000000, 0),
(77, N'Đặng Thị Hằng', '0912001021', '1994-10-22', N'Nữ', N'Cần Thơ', N'Kỹ sư xây dựng', N'Ứng viên có 5 năm kinh nghiệm ở vị trí Kỹ sư xây dựng, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 5, 19500000, 1),
(78, N'Bùi Văn Inh', '0912001022', '1995-11-23', N'Nam', N'Nha Trang', N'Dược sĩ', N'Ứng viên có 6 năm kinh nghiệm ở vị trí Dược sĩ, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 6, 22000000, 1),
(79, N'Ngô Thị Kiều', '0912001023', '1996-12-24', N'Nữ', N'Bình Dương', N'Giáo viên tiếng Anh', N'Ứng viên có 7 năm kinh nghiệm ở vị trí Giáo viên tiếng Anh, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 7, 24500000, 1),
(80, N'Đỗ Văn Lâm', '0912001024', '1997-01-25', N'Nam', N'Đồng Nai', N'Nhân viên Logistics', N'Ứng viên có 8 năm kinh nghiệm ở vị trí Nhân viên Logistics, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 8, 27000000, 0),
(81, N'Đinh Thị Minh', '0912001025', '1998-02-26', N'Nữ', N'Hà Nội', N'Chuyên viên tuyển dụng', N'Ứng viên có 1 năm kinh nghiệm ở vị trí Chuyên viên tuyển dụng, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 1, 11000000, 1),
(82, N'Trương Văn Nghị', '0912001026', '1999-03-27', N'Nam', N'TP. Hồ Chí Minh', N'SEO Specialist', N'Ứng viên có 2 năm kinh nghiệm ở vị trí SEO Specialist, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 2, 13500000, 1),
(83, N'Lý Thị Oanh', '0912001027', '2000-04-01', N'Nữ', N'Đà Nẵng', N'Kế toán thuế', N'Ứng viên có 3 năm kinh nghiệm ở vị trí Kế toán thuế, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 3, 16000000, 1),
(84, N'Phan Văn Phúc', '0912001028', '2001-05-02', N'Nam', N'Hải Phòng', N'Giao dịch viên ngân hàng', N'Ứng viên có 4 năm kinh nghiệm ở vị trí Giao dịch viên ngân hàng, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 4, 18500000, 0),
(85, N'Tô Thị Quý', '0912001029', '2002-06-03', N'Nữ', N'Cần Thơ', N'Trưởng nhóm kinh doanh', N'Ứng viên có 5 năm kinh nghiệm ở vị trí Trưởng nhóm kinh doanh, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 5, 21000000, 1),
(86, N'Cao Văn Rạng', '0912001030', '1993-07-04', N'Nam', N'Nha Trang', N'Chuyên viên phân tích tài chính', N'Ứng viên có 6 năm kinh nghiệm ở vị trí Chuyên viên phân tích tài chính, đã tham gia nhiều dự án thực tế và mong muốn phát triển sự nghiệp lâu dài trong lĩnh vực liên quan.', 6, 21000000, 1);
GO
INSERT INTO JobPosts (EmployerId, CategoryID, Title, Description, Requirements, Benefits, SalaryMin, SalaryMax, SalaryNegotiable, JobType, Location, ExperienceLevel, Deadline, Status, IsFeatured) VALUES
(1, 11, N'Backend Developer (.NET/Java)', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Backend Developer (.NET/Java) làm việc tại Hà Nội, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.

Công cụ / hệ thống sử dụng trong công việc: SQL Server/PostgreSQL/MySQL, Kubernetes, Docker, AWS/Azure/GCP.

Vị trí Backend Developer (.NET/Java) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Backend Developer (.NET/Java) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Backend Developer (.NET/Java).', 14000000, 28000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-15', 'Active', 1),
(2, 12, N'Frontend Developer (ReactJS)', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Frontend Developer (ReactJS) làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.

Công cụ / hệ thống sử dụng trong công việc: Kubernetes, Docker, Redis, CI/CD (Jenkins/GitHub Actions).

Vị trí Frontend Developer (ReactJS) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Frontend Developer (ReactJS) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Frontend Developer (ReactJS).', 12000000, 24000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-30', 'Active', 0),
(3, 13, N'DevOps / Cloud Engineer', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí DevOps / Cloud Engineer làm việc tại Đà Nẵng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.

Công cụ / hệ thống sử dụng trong công việc: Docker, Redis, Kubernetes, RESTful API/GraphQL.

Vị trí DevOps / Cloud Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí DevOps / Cloud Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 38.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí DevOps / Cloud Engineer.', 18000000, 38000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-09-10', 'Active', 0),
(4, 14, N'Mobile Developer (iOS/Android)', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Mobile Developer (iOS/Android) làm việc tại Hải Phòng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.

Công cụ / hệ thống sử dụng trong công việc: Postman, Git/GitLab, Docker, Linux server.

Vị trí Mobile Developer (iOS/Android) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Mobile Developer (iOS/Android) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Mobile Developer (iOS/Android).', 14000000, 28000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-09-25', 'Closed', 0),
(5, 15, N'Data Engineer / Data Analyst', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Data Engineer / Data Analyst làm việc tại Cần Thơ, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.

Công cụ / hệ thống sử dụng trong công việc: Docker, CI/CD (Jenkins/GitHub Actions), Linux server, RESTful API/GraphQL.

Vị trí Data Engineer / Data Analyst sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Data Engineer / Data Analyst hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Data Engineer / Data Analyst.', 14000000, 26000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-10-05', 'Pending', 0),
(6, 16, N'QA/QC Engineer', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí QA/QC Engineer làm việc tại Bình Dương, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)

Công cụ / hệ thống sử dụng trong công việc: Kubernetes, Redis, Git/GitLab, CI/CD (Jenkins/GitHub Actions).

Vị trí QA/QC Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí QA/QC Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí QA/QC Engineer.', 10000000, 20000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-10-20', 'Active', 0),
(7, 17, N'Fullstack Developer', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Fullstack Developer làm việc tại Đồng Nai, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: Kafka/RabbitMQ, Redis, Docker, Jira/Confluence.

Vị trí Fullstack Developer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Fullstack Developer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Fullstack Developer.', 15000000, 30000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-11-01', 'Active', 0),
(8, 18, N'AI / Machine Learning Engineer', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí AI / Machine Learning Engineer làm việc tại Nha Trang, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.

Công cụ / hệ thống sử dụng trong công việc: Redis, Git/GitLab, SQL Server/PostgreSQL/MySQL, Postman.

Vị trí AI / Machine Learning Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí AI / Machine Learning Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 45.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí AI / Machine Learning Engineer.', 20000000, 45000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-11-15', 'Active', 1),
(9, 19, N'Security Engineer', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Security Engineer làm việc tại Hà Nội, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.

Công cụ / hệ thống sử dụng trong công việc: Docker, Kubernetes, Linux server, Jira/Confluence.

Vị trí Security Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Security Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 36.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Security Engineer.', 18000000, 36000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-30', 'Closed', 0),
(10, 20, N'Business Analyst (IT)', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Business Analyst (IT) làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.

Công cụ / hệ thống sử dụng trong công việc: Kubernetes, SQL Server/PostgreSQL/MySQL, Postman, Docker.

Vị trí Business Analyst (IT) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Business Analyst (IT) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Business Analyst (IT).', 13000000, 24000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-12-15', 'Pending', 0),
(11, 11, N'Senior Backend Developer', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Senior Backend Developer làm việc tại Đà Nẵng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.

Công cụ / hệ thống sử dụng trong công việc: SQL Server/PostgreSQL/MySQL, Docker, Jira/Confluence, Postman.

Vị trí Senior Backend Developer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Senior Backend Developer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 40.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Senior Backend Developer.', 22000000, 40000000, 0, 'Contract', N'Đà Nẵng', 'Middle', '2026-07-31', 'Active', 0),
(12, 12, N'Junior Frontend Developer', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Junior Frontend Developer làm việc tại Hải Phòng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Kubernetes, CI/CD (Jenkins/GitHub Actions), Redis, AWS/Azure/GCP.

Vị trí Junior Frontend Developer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Junior Frontend Developer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 15.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Junior Frontend Developer.', 8000000, 15000000, 0, 'PartTime', N'Hải Phòng', 'Senior', '2026-08-20', 'Active', 0),
(13, 13, N'Site Reliability Engineer', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Site Reliability Engineer làm việc tại Cần Thơ, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Redis, Linux server, Jira/Confluence, CI/CD (Jenkins/GitHub Actions).

Vị trí Site Reliability Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Site Reliability Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 40.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Site Reliability Engineer.', 20000000, 40000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-09-05', 'Active', 0),
(14, 14, N'React Native Developer', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí React Native Developer làm việc tại Bình Dương, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.

Công cụ / hệ thống sử dụng trong công việc: Git/GitLab, CI/CD (Jenkins/GitHub Actions), AWS/Azure/GCP, Docker.

Vị trí React Native Developer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí React Native Developer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí React Native Developer.', 15000000, 28000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-09-20', 'Closed', 0),
(15, 15, N'Data Scientist', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Data Scientist làm việc tại Đồng Nai, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Viết tài liệu kỹ thuật, sơ đồ luồng dữ liệu và đặc tả API.

Công cụ / hệ thống sử dụng trong công việc: AWS/Azure/GCP, Jira/Confluence, RESTful API/GraphQL, Git/GitLab.

Vị trí Data Scientist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Data Scientist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 35.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Data Scientist.', 18000000, 35000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-10-10', 'Pending', 1),
(16, 16, N'Test Automation Engineer', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Test Automation Engineer làm việc tại Nha Trang, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Git/GitLab, SQL Server/PostgreSQL/MySQL, CI/CD (Jenkins/GitHub Actions), Kafka/RabbitMQ.

Vị trí Test Automation Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Test Automation Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Test Automation Engineer.', 13000000, 24000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-10-25', 'Active', 0),
(17, 21, N'UI/UX Designer', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí UI/UX Designer làm việc tại Hà Nội, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thực hiện code review, đảm bảo chất lượng mã nguồn theo coding convention.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.

Công cụ / hệ thống sử dụng trong công việc: Postman, SQL Server/PostgreSQL/MySQL, Kubernetes, Docker.

Vị trí UI/UX Designer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí UI/UX Designer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí UI/UX Designer.', 12000000, 22000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-11-08', 'Active', 0),
(18, 22, N'Database Administrator', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Database Administrator làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp với QA để kiểm thử, đảm bảo chất lượng trước khi release.

Công cụ / hệ thống sử dụng trong công việc: RESTful API/GraphQL, Linux server, SQL Server/PostgreSQL/MySQL, Kubernetes.

Vị trí Database Administrator sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Database Administrator hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Thành thạo ít nhất một ngôn ngữ lập trình liên quan đến vị trí ứng tuyển.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Database Administrator.', 14000000, 26000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-22', 'Active', 0),
(19, 28, N'Network Engineer', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Network Engineer làm việc tại Đà Nẵng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thiết kế, xây dựng và tối ưu hóa hệ thống/tính năng theo yêu cầu nghiệp vụ.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.

Công cụ / hệ thống sử dụng trong công việc: SQL Server/PostgreSQL/MySQL, Docker, Kubernetes, Redis.

Vị trí Network Engineer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Network Engineer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Không gian làm việc mở, có khu vực nghỉ ngơi, chơi game giải trí.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Network Engineer.', 13000000, 24000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-12-05', 'Closed', 0),
(20, 30, N'Scrum Master / Agile Coach', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Scrum Master / Agile Coach làm việc tại Hải Phòng, thuộc lĩnh vực Công nghệ thông tin. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tối ưu hiệu năng truy vấn cơ sở dữ liệu và thời gian phản hồi hệ thống.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Triển khai giám sát (monitoring/logging) hệ thống bằng Grafana, ELK Stack.
- Debug, xử lý sự cố hệ thống production và viết báo cáo sự cố (RCA)
- Nghiên cứu, đề xuất áp dụng công nghệ mới nhằm cải thiện hiệu suất hệ thống.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia daily standup, sprint planning và retrospective theo mô hình Agile/Scrum.

Công cụ / hệ thống sử dụng trong công việc: Postman, Kafka/RabbitMQ, Git/GitLab, Docker.

Vị trí Scrum Master / Agile Coach sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Scrum Master / Agile Coach hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên có chứng chỉ chuyên môn (AWS, Azure, PMP, Scrum Master...)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững quy trình phát triển phần mềm Agile/Scrum.
- Có tư duy giải quyết vấn đề tốt, khả năng debug độc lập.
- Hiểu biết về cấu trúc dữ liệu, giải thuật và thiết kế hệ thống (system design)
- Có kinh nghiệm làm việc với cơ sở dữ liệu quan hệ và/hoặc NoSQL.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cấp phát laptop/thiết bị làm việc hiệu năng cao, màn hình rộng.
- Ngân sách mua sách chuyên môn, tài khoản học online (Udemy, Pluralsight)
- Được tham gia các hội thảo công nghệ, tech talk nội bộ hàng tháng.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Scrum Master / Agile Coach.', 18000000, 32000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-12-20', 'Pending', 0),
(21, 31, N'Kế toán tổng hợp', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Kế toán tổng hợp làm việc tại Cần Thơ, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.

Công cụ / hệ thống sử dụng trong công việc: phần mềm kế toán MISA/Fast, Excel nâng cao (Pivot, VBA), SAP/Oracle Financials, Bloomberg Terminal.

Vị trí Kế toán tổng hợp sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kế toán tổng hợp hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kế toán tổng hợp.', 9000000, 16000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-08-15', 'Active', 1),
(22, 32, N'Chuyên viên tài chính', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Chuyên viên tài chính làm việc tại Bình Dương, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, Excel nâng cao (Pivot, VBA), Core Banking, SAP/Oracle Financials.

Vị trí Chuyên viên tài chính sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên tài chính hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên tài chính.', 12000000, 22000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-08-30', 'Active', 0),
(23, 33, N'Giao dịch viên ngân hàng', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí Giao dịch viên ngân hàng làm việc tại Đồng Nai, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.

Công cụ / hệ thống sử dụng trong công việc: Excel nâng cao (Pivot, VBA), Core Banking, hệ thống quản lý rủi ro (RMS), phần mềm kế toán MISA/Fast.

Vị trí Giao dịch viên ngân hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Giao dịch viên ngân hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giao dịch viên ngân hàng.', 8000000, 14000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-09-10', 'Active', 0),
(24, 34, N'Kiểm toán nội bộ', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Kiểm toán nội bộ làm việc tại Nha Trang, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.

Công cụ / hệ thống sử dụng trong công việc: phần mềm kế toán MISA/Fast, Excel nâng cao (Pivot, VBA), Core Banking, Bloomberg Terminal.

Vị trí Kiểm toán nội bộ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kiểm toán nội bộ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kiểm toán nội bộ.', 14000000, 24000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-09-25', 'Closed', 0),
(25, 35, N'Chuyên viên tín dụng', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Chuyên viên tín dụng làm việc tại Hà Nội, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Power BI, SAP/Oracle Financials, Core Banking, Bloomberg Terminal.

Vị trí Chuyên viên tín dụng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên tín dụng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên tín dụng.', 11000000, 20000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-10-05', 'Pending', 0),
(26, 36, N'Chuyên viên phân tích đầu tư', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Chuyên viên phân tích đầu tư làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, SAP/Oracle Financials, Power BI, phần mềm kế toán MISA/Fast.

Vị trí Chuyên viên phân tích đầu tư sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên phân tích đầu tư hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên phân tích đầu tư.', 15000000, 28000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-20', 'Active', 0),
(27, 37, N'Chuyên viên bảo hiểm', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí Chuyên viên bảo hiểm làm việc tại Đà Nẵng, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.

Công cụ / hệ thống sử dụng trong công việc: Core Banking, SAP/Oracle Financials, Excel nâng cao (Pivot, VBA), phần mềm kế toán MISA/Fast.

Vị trí Chuyên viên bảo hiểm sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên bảo hiểm hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên bảo hiểm.', 10000000, 18000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-11-01', 'Active', 0),
(28, 38, N'Chuyên viên quản lý rủi ro', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Chuyên viên quản lý rủi ro làm việc tại Hải Phòng, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.

Công cụ / hệ thống sử dụng trong công việc: SAP/Oracle Financials, Core Banking, phần mềm kế toán MISA/Fast, Power BI.

Vị trí Chuyên viên quản lý rủi ro sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên quản lý rủi ro hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên quản lý rủi ro.', 16000000, 28000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-11-15', 'Active', 1),
(29, 40, N'Kế toán thuế', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Kế toán thuế làm việc tại Cần Thơ, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.

Công cụ / hệ thống sử dụng trong công việc: Core Banking, SAP/Oracle Financials, hệ thống quản lý rủi ro (RMS), phần mềm kế toán MISA/Fast.

Vị trí Kế toán thuế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kế toán thuế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kế toán thuế.', 9000000, 16000000, 0, 'FullTime', N'Cần Thơ', 'Senior', '2026-11-30', 'Closed', 0),
(30, 41, N'Chuyên viên ngân hàng số', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Chuyên viên ngân hàng số làm việc tại Bình Dương, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, Core Banking, Power BI, Excel nâng cao (Pivot, VBA).

Vị trí Chuyên viên ngân hàng số sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên ngân hàng số hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên ngân hàng số.', 14000000, 24000000, 0, 'Remote', N'Bình Dương', 'Junior', '2026-12-15', 'Pending', 0),
(1, 31, N'Trưởng nhóm kế toán', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Trưởng nhóm kế toán làm việc tại Đồng Nai, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: SAP/Oracle Financials, hệ thống quản lý rủi ro (RMS), Power BI, Excel nâng cao (Pivot, VBA).

Vị trí Trưởng nhóm kế toán sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Trưởng nhóm kế toán hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng nhóm kế toán.', 18000000, 30000000, 0, 'Contract', N'Đồng Nai', 'Middle', '2026-07-31', 'Active', 0),
(2, 32, N'Chuyên viên tư vấn tài chính', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Chuyên viên tư vấn tài chính làm việc tại Nha Trang, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: Power BI, Core Banking, hệ thống quản lý rủi ro (RMS), Excel nâng cao (Pivot, VBA).

Vị trí Chuyên viên tư vấn tài chính sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên tư vấn tài chính hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên tư vấn tài chính.', 13000000, 22000000, 0, 'PartTime', N'Nha Trang', 'Senior', '2026-08-20', 'Active', 0),
(3, 33, N'Nhân viên thanh toán quốc tế', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Nhân viên thanh toán quốc tế làm việc tại Hà Nội, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý rủi ro (RMS), SAP/Oracle Financials, Excel nâng cao (Pivot, VBA), Power BI.

Vị trí Nhân viên thanh toán quốc tế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên thanh toán quốc tế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 17.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên thanh toán quốc tế.', 10000000, 17000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-09-05', 'Active', 0),
(4, 35, N'Chuyên viên thẩm định tín dụng', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Chuyên viên thẩm định tín dụng làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm kế toán MISA/Fast, Excel nâng cao (Pivot, VBA), Core Banking, SAP/Oracle Financials.

Vị trí Chuyên viên thẩm định tín dụng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên thẩm định tín dụng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên thẩm định tín dụng.', 13000000, 22000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-20', 'Closed', 0),
(5, 36, N'Chuyên viên môi giới chứng khoán', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Chuyên viên môi giới chứng khoán làm việc tại Đà Nẵng, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: Power BI, Bloomberg Terminal, Core Banking, SAP/Oracle Financials.

Vị trí Chuyên viên môi giới chứng khoán sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên môi giới chứng khoán hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 25.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên môi giới chứng khoán.', 12000000, 25000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-10-10', 'Pending', 1),
(6, 37, N'Chuyên viên Fintech', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Chuyên viên Fintech làm việc tại Hải Phòng, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.

Công cụ / hệ thống sử dụng trong công việc: Excel nâng cao (Pivot, VBA), Core Banking, hệ thống quản lý rủi ro (RMS), phần mềm kế toán MISA/Fast.

Vị trí Chuyên viên Fintech sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên Fintech hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên Fintech.', 14000000, 26000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-10-25', 'Active', 0),
(7, 38, N'Kiểm soát viên nội bộ', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Kiểm soát viên nội bộ làm việc tại Cần Thơ, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.

Công cụ / hệ thống sử dụng trong công việc: Power BI, Core Banking, Excel nâng cao (Pivot, VBA), SAP/Oracle Financials.

Vị trí Kiểm soát viên nội bộ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kiểm soát viên nội bộ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kiểm soát viên nội bộ.', 13000000, 22000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-11-08', 'Active', 0),
(8, 40, N'Kế toán công nợ', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Kế toán công nợ làm việc tại Bình Dương, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tuân thủ quy định pháp luật về tài chính, ngân hàng và phòng chống rửa tiền.
- Tư vấn sản phẩm, dịch vụ tài chính phù hợp với nhu cầu khách hàng.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, Core Banking, Power BI, Excel nâng cao (Pivot, VBA).

Vị trí Kế toán công nợ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kế toán công nợ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Tốt nghiệp chuyên ngành Tài chính - Ngân hàng, Kế toán, Kiểm toán hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kế toán công nợ.', 8000000, 14000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-11-22', 'Active', 0),
(9, 41, N'Chuyên viên quản lý tài sản', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Chuyên viên quản lý tài sản làm việc tại Đồng Nai, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Theo dõi công nợ, dòng tiền, lập kế hoạch thu chi cho doanh nghiệp.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, Core Banking, Power BI, hệ thống quản lý rủi ro (RMS).

Vị trí Chuyên viên quản lý tài sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên quản lý tài sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên quản lý tài sản.', 16000000, 28000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-12-05', 'Closed', 0),
(10, 34, N'Chuyên viên định giá tài sản', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Chuyên viên định giá tài sản làm việc tại Nha Trang, thuộc lĩnh vực Tài chính - Ngân hàng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo tài chính, báo cáo quản trị định kỳ theo tháng/quý/năm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, đối chiếu số liệu kế toán, chứng từ đảm bảo tính chính xác.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với các phòng ban lập ngân sách và kiểm soát chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Thẩm định hồ sơ khách hàng, phân tích năng lực tài chính và rủi ro tín dụng.

Công cụ / hệ thống sử dụng trong công việc: Bloomberg Terminal, Core Banking, SAP/Oracle Financials, hệ thống quản lý rủi ro (RMS).

Vị trí Chuyên viên định giá tài sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên định giá tài sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Nắm vững chuẩn mực kế toán Việt Nam (VAS), ưu tiên biết IFRS.
- Ưu tiên có chứng chỉ CFA, ACCA, CPA hoặc chứng chỉ hành nghề kế toán.
- Có khả năng phân tích số liệu, tư duy logic và cẩn thận, tỉ mỉ.
- Trung thực, có đạo đức nghề nghiệp, chịu được áp lực số liệu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng theo doanh số/KPI hằng tháng và thưởng cuối năm hấp dẫn.
- Được đào tạo nghiệp vụ chuyên sâu và hỗ trợ thi chứng chỉ hành nghề.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ vay vốn ưu đãi dành cho nhân viên nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên định giá tài sản.', 14000000, 24000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-12-20', 'Pending', 0),
(11, 51, N'Digital Marketing Specialist', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Digital Marketing Specialist làm việc tại Hà Nội, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Meta Business Suite, SEO tools (Ahrefs, SEMrush), Mailchimp/HubSpot.

Vị trí Digital Marketing Specialist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Digital Marketing Specialist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Digital Marketing Specialist.', 10000000, 20000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-15', 'Active', 1),
(12, 52, N'Content Creator / Writer', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Content Creator / Writer làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.

Công cụ / hệ thống sử dụng trong công việc: SEO tools (Ahrefs, SEMrush), Canva/Adobe Photoshop/Illustrator, Mailchimp/HubSpot, Google Ads/Facebook Ads Manager.

Vị trí Content Creator / Writer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Content Creator / Writer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Content Creator / Writer.', 8000000, 16000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-30', 'Active', 0),
(13, 53, N'SEO Specialist', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí SEO Specialist làm việc tại Đà Nẵng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: Google Analytics/GA4, Mailchimp/HubSpot, Meta Business Suite, CapCut/Premiere Pro.

Vị trí SEO Specialist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí SEO Specialist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí SEO Specialist.', 10000000, 18000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-09-10', 'Active', 0),
(14, 54, N'Social Media Marketing', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Social Media Marketing làm việc tại Hải Phòng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Google Analytics/GA4, Canva/Adobe Photoshop/Illustrator, SEO tools (Ahrefs, SEMrush), Google Ads/Facebook Ads Manager.

Vị trí Social Media Marketing sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Social Media Marketing hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Social Media Marketing.', 9000000, 16000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-09-25', 'Closed', 0),
(15, 55, N'Brand Manager', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Brand Manager làm việc tại Cần Thơ, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.

Công cụ / hệ thống sử dụng trong công việc: Google Analytics/GA4, Mailchimp/HubSpot, SEO tools (Ahrefs, SEMrush), Meta Business Suite.

Vị trí Brand Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Brand Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Brand Manager.', 18000000, 32000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-10-05', 'Pending', 0),
(16, 56, N'Product Marketing Manager', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Product Marketing Manager làm việc tại Bình Dương, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: SEO tools (Ahrefs, SEMrush), Meta Business Suite, Canva/Adobe Photoshop/Illustrator, Google Analytics/GA4.

Vị trí Product Marketing Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Product Marketing Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Product Marketing Manager.', 16000000, 28000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-10-20', 'Active', 0),
(17, 57, N'Performance Marketing', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Performance Marketing làm việc tại Đồng Nai, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Meta Business Suite, Canva/Adobe Photoshop/Illustrator, Google Analytics/GA4.

Vị trí Performance Marketing sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Performance Marketing hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Performance Marketing.', 12000000, 22000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-11-01', 'Active', 0),
(18, 58, N'Email Marketing Specialist', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Email Marketing Specialist làm việc tại Nha Trang, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Canva/Adobe Photoshop/Illustrator, Meta Business Suite, Mailchimp/HubSpot.

Vị trí Email Marketing Specialist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Email Marketing Specialist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Email Marketing Specialist.', 10000000, 18000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-11-15', 'Active', 1),
(19, 59, N'Event Marketing Executive', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Event Marketing Executive làm việc tại Hà Nội, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: Google Ads/Facebook Ads Manager, Mailchimp/HubSpot, CapCut/Premiere Pro, SEO tools (Ahrefs, SEMrush).

Vị trí Event Marketing Executive sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Event Marketing Executive hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Event Marketing Executive.', 9000000, 16000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-30', 'Closed', 0),
(20, 60, N'PR Manager', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí PR Manager làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.

Công cụ / hệ thống sử dụng trong công việc: Meta Business Suite, Mailchimp/HubSpot, Google Ads/Facebook Ads Manager, Canva/Adobe Photoshop/Illustrator.

Vị trí PR Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí PR Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí PR Manager.', 16000000, 28000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-12-15', 'Pending', 0),
(21, 61, N'Copywriter', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Copywriter làm việc tại Đà Nẵng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: Canva/Adobe Photoshop/Illustrator, Mailchimp/HubSpot, CapCut/Premiere Pro, Meta Business Suite.

Vị trí Copywriter sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Copywriter hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 17.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Copywriter.', 9000000, 17000000, 0, 'Contract', N'Đà Nẵng', 'Middle', '2026-07-31', 'Active', 0),
(22, 62, N'Graphic Designer', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Graphic Designer làm việc tại Hải Phòng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: SEO tools (Ahrefs, SEMrush), Meta Business Suite, Google Ads/Facebook Ads Manager, CapCut/Premiere Pro.

Vị trí Graphic Designer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Graphic Designer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Graphic Designer.', 9000000, 18000000, 0, 'PartTime', N'Hải Phòng', 'Senior', '2026-08-20', 'Active', 0),
(23, 63, N'Video Editor', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí Video Editor làm việc tại Cần Thơ, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Meta Business Suite, Mailchimp/HubSpot, Canva/Adobe Photoshop/Illustrator.

Vị trí Video Editor sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Video Editor hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Video Editor.', 10000000, 20000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-09-05', 'Active', 0),
(24, 64, N'Influencer Marketing Executive', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Influencer Marketing Executive làm việc tại Bình Dương, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.

Công cụ / hệ thống sử dụng trong công việc: Canva/Adobe Photoshop/Illustrator, Google Ads/Facebook Ads Manager, Mailchimp/HubSpot, CapCut/Premiere Pro.

Vị trí Influencer Marketing Executive sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Influencer Marketing Executive hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Influencer Marketing Executive.', 11000000, 20000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-09-20', 'Closed', 0),
(25, 65, N'Community Manager', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Community Manager làm việc tại Đồng Nai, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.

Công cụ / hệ thống sử dụng trong công việc: Canva/Adobe Photoshop/Illustrator, Mailchimp/HubSpot, SEO tools (Ahrefs, SEMrush), Google Analytics/GA4.

Vị trí Community Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Community Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Community Manager.', 10000000, 18000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-10-10', 'Pending', 1),
(26, 66, N'Marketing Analyst', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Marketing Analyst làm việc tại Nha Trang, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.

Công cụ / hệ thống sử dụng trong công việc: SEO tools (Ahrefs, SEMrush), Canva/Adobe Photoshop/Illustrator, Mailchimp/HubSpot, Google Ads/Facebook Ads Manager.

Vị trí Marketing Analyst sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Marketing Analyst hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Marketing Analyst.', 12000000, 22000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-10-25', 'Active', 0),
(27, 67, N'E-commerce Marketing', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí E-commerce Marketing làm việc tại Hà Nội, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, SEO tools (Ahrefs, SEMrush), Canva/Adobe Photoshop/Illustrator, Google Ads/Facebook Ads Manager.

Vị trí E-commerce Marketing sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí E-commerce Marketing hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí E-commerce Marketing.', 11000000, 20000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-11-08', 'Active', 0),
(28, 68, N'Trade Marketing Executive', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Trade Marketing Executive làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Lên kế hoạch, triển khai và tối ưu các chiến dịch marketing đa kênh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Meta Business Suite, Google Ads/Facebook Ads Manager, SEO tools (Ahrefs, SEMrush).

Vị trí Trade Marketing Executive sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trade Marketing Executive hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Thành thạo công cụ thiết kế/chỉnh sửa nội dung cơ bản.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Biết phân tích dữ liệu chiến dịch để đưa ra đề xuất tối ưu.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 19.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trade Marketing Executive.', 11000000, 19000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-22', 'Active', 0),
(29, 69, N'Creative Director', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Creative Director làm việc tại Đà Nẵng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Xây dựng và duy trì mối quan hệ với KOL/KOC, đối tác truyền thông.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với đội thiết kế, sản xuất nội dung để đảm bảo tiến độ campaign.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.

Công cụ / hệ thống sử dụng trong công việc: Google Ads/Facebook Ads Manager, Meta Business Suite, SEO tools (Ahrefs, SEMrush), Canva/Adobe Photoshop/Illustrator.

Vị trí Creative Director sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Creative Director hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 40.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Creative Director.', 22000000, 40000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-12-05', 'Closed', 0),
(30, 70, N'Market Research Analyst', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Market Research Analyst làm việc tại Hải Phòng, thuộc lĩnh vực Marketing - Truyền thông. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý ngân sách quảng cáo, tối ưu chi phí trên các nền tảng.
- Nghiên cứu thị trường, đối thủ cạnh tranh và insight khách hàng mục tiêu.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Theo dõi, đo lường hiệu quả chiến dịch qua các chỉ số KPI (CTR, CPA, ROAS)
- Sáng tạo nội dung (bài viết, hình ảnh, video) phù hợp định vị thương hiệu.

Công cụ / hệ thống sử dụng trong công việc: CapCut/Premiere Pro, Meta Business Suite, Canva/Adobe Photoshop/Illustrator, Mailchimp/HubSpot.

Vị trí Market Research Analyst sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Market Research Analyst hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng viết tốt, có khả năng kể chuyện thương hiệu (storytelling)
- Ưu tiên có portfolio hoặc sản phẩm truyền thông đã thực hiện.
- Có tư duy sáng tạo, cập nhật xu hướng marketing/truyền thông liên tục.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Ngân sách thử nghiệm công cụ, nền tảng quảng cáo mới.
- Không gian làm việc trẻ trung, năng động, khuyến khích sáng tạo.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được chủ động đề xuất ý tưởng sáng tạo, tham gia trực tiếp vào chiến dịch lớn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Market Research Analyst.', 12000000, 22000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-12-20', 'Pending', 0),
(1, 71, N'Nhân viên kinh doanh', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Nhân viên kinh doanh làm việc tại Cần Thơ, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên kinh doanh sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên kinh doanh hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 15.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kinh doanh.', 8000000, 15000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-08-15', 'Active', 1),
(2, 72, N'Quản lý cửa hàng', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Quản lý cửa hàng làm việc tại Bình Dương, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base).

Vị trí Quản lý cửa hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý cửa hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý cửa hàng.', 12000000, 20000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-08-30', 'Active', 0),
(3, 73, N'Trưởng phòng kinh doanh', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Trưởng phòng kinh doanh làm việc tại Đồng Nai, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.

Công cụ / hệ thống sử dụng trong công việc: Excel báo cáo doanh số, Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base), phần mềm quản lý bán hàng (POS).

Vị trí Trưởng phòng kinh doanh sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trưởng phòng kinh doanh hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 35.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng phòng kinh doanh.', 20000000, 35000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-09-10', 'Active', 0),
(4, 74, N'Key Account Manager', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Key Account Manager làm việc tại Nha Trang, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, CRM (Salesforce/HubSpot/Base).

Vị trí Key Account Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Key Account Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Key Account Manager.', 18000000, 32000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-09-25', 'Closed', 0),
(5, 75, N'Nhân viên tư vấn bán hàng', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Nhân viên tư vấn bán hàng làm việc tại Hà Nội, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên tư vấn bán hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên tư vấn bán hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 13.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên tư vấn bán hàng.', 7000000, 13000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-10-05', 'Pending', 0),
(6, 76, N'Giám sát bán hàng', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Giám sát bán hàng làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base).

Vị trí Giám sát bán hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Giám sát bán hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám sát bán hàng.', 12000000, 20000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-20', 'Active', 0),
(7, 77, N'Nhân viên chăm sóc khách hàng', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Nhân viên chăm sóc khách hàng làm việc tại Đà Nẵng, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base), Zalo OA/Zalo Business, Excel báo cáo doanh số.

Vị trí Nhân viên chăm sóc khách hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên chăm sóc khách hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên chăm sóc khách hàng.', 7000000, 12000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-11-01', 'Active', 0),
(8, 78, N'Business Development Manager', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Business Development Manager làm việc tại Hải Phòng, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base), Zalo OA/Zalo Business, Excel báo cáo doanh số.

Vị trí Business Development Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Business Development Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 36.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Business Development Manager.', 20000000, 36000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-11-15', 'Active', 1),
(9, 79, N'Nhân viên kinh doanh XNK', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Nhân viên kinh doanh XNK làm việc tại Cần Thơ, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), Zalo OA/Zalo Business, Excel báo cáo doanh số, CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên kinh doanh XNK sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên kinh doanh XNK hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kinh doanh XNK.', 10000000, 18000000, 0, 'FullTime', N'Cần Thơ', 'Senior', '2026-11-30', 'Closed', 0),
(10, 80, N'Nhân viên thương mại điện tử', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Nhân viên thương mại điện tử làm việc tại Bình Dương, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.

Công cụ / hệ thống sử dụng trong công việc: CRM (Salesforce/HubSpot/Base), Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS), Zalo OA/Zalo Business.

Vị trí Nhân viên thương mại điện tử sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên thương mại điện tử hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên thương mại điện tử.', 10000000, 18000000, 0, 'Remote', N'Bình Dương', 'Junior', '2026-12-15', 'Pending', 0),
(11, 81, N'Quản lý khu vực (Area Manager)', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Quản lý khu vực (Area Manager) làm việc tại Đồng Nai, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.

Công cụ / hệ thống sử dụng trong công việc: CRM (Salesforce/HubSpot/Base), phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business.

Vị trí Quản lý khu vực (Area Manager) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý khu vực (Area Manager) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 38.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý khu vực (Area Manager).', 22000000, 38000000, 0, 'Contract', N'Đồng Nai', 'Middle', '2026-07-31', 'Active', 0),
(12, 82, N'Nhân viên Telesales', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Nhân viên Telesales làm việc tại Nha Trang, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), Zalo OA/Zalo Business, Excel báo cáo doanh số, CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên Telesales sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên Telesales hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 13.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên Telesales.', 7000000, 13000000, 0, 'PartTime', N'Nha Trang', 'Senior', '2026-08-20', 'Active', 0),
(13, 83, N'Nhân viên bán hàng B2B', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Nhân viên bán hàng B2B làm việc tại Hà Nội, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên bán hàng B2B sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên bán hàng B2B hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên bán hàng B2B.', 10000000, 18000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-09-05', 'Active', 0),
(14, 84, N'Trưởng nhóm bán hàng', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Trưởng nhóm bán hàng làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base), Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS).

Vị trí Trưởng nhóm bán hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Trưởng nhóm bán hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng nhóm bán hàng.', 14000000, 24000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-20', 'Closed', 0),
(15, 85, N'Category Manager', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Category Manager làm việc tại Đà Nẵng, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base).

Vị trí Category Manager sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Category Manager hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Category Manager.', 18000000, 30000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-10-10', 'Pending', 1),
(16, 86, N'Procurement Officer', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Procurement Officer làm việc tại Hải Phòng, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Nghiên cứu thị trường, phân tích đối thủ để đề xuất chiến lược bán hàng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: CRM (Salesforce/HubSpot/Base), phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business.

Vị trí Procurement Officer sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Procurement Officer hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Procurement Officer.', 12000000, 20000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-10-25', 'Active', 0),
(17, 87, N'Nhân viên Merchandising', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Nhân viên Merchandising làm việc tại Cần Thơ, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: CRM (Salesforce/HubSpot/Base), phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business.

Vị trí Nhân viên Merchandising sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên Merchandising hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên Merchandising.', 8000000, 14000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-11-08', 'Active', 0),
(18, 88, N'Sales Operations', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Sales Operations làm việc tại Bình Dương, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tìm kiếm, tiếp cận và chăm sóc khách hàng tiềm năng theo khu vực phụ trách.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.

Công cụ / hệ thống sử dụng trong công việc: Zalo OA/Zalo Business, Excel báo cáo doanh số, phần mềm quản lý bán hàng (POS), CRM (Salesforce/HubSpot/Base).

Vị trí Sales Operations sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Sales Operations hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Sales Operations.', 11000000, 20000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-11-22', 'Active', 0),
(19, 89, N'Nhân viên phát triển đại lý', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Nhân viên phát triển đại lý làm việc tại Đồng Nai, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Xây dựng và duy trì mối quan hệ lâu dài với khách hàng hiện hữu.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với bộ phận marketing triển khai chương trình khuyến mãi tại điểm bán.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý bán hàng (POS), Excel báo cáo doanh số, Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base).

Vị trí Nhân viên phát triển đại lý sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên phát triển đại lý hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên phát triển đại lý.', 10000000, 18000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-12-05', 'Closed', 0),
(20, 90, N'Giám đốc kinh doanh', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Giám đốc kinh doanh làm việc tại Nha Trang, thuộc lĩnh vực Kinh doanh - Bán lẻ. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Đào tạo, hướng dẫn nhân viên bán hàng mới (đối với vị trí giám sát/quản lý)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo doanh số, dự báo kinh doanh định kỳ theo tuần/tháng.
- Tư vấn sản phẩm/dịch vụ, đàm phán và chốt hợp đồng với khách hàng.

Công cụ / hệ thống sử dụng trong công việc: Excel báo cáo doanh số, Zalo OA/Zalo Business, CRM (Salesforce/HubSpot/Base), phần mềm quản lý bán hàng (POS).

Vị trí Giám đốc kinh doanh sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Giám đốc kinh doanh hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có kinh nghiệm bán hàng/kinh doanh trong ngành liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động, chịu được áp lực doanh số và mục tiêu KPI.
- Có kỹ năng giao tiếp, đàm phán và thuyết phục khách hàng tốt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có phương tiện di chuyển cá nhân (đối với vị trí thị trường)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 35.000.000 đ - 60.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Có xe công ty/hỗ trợ xăng xe, điện thoại cho vị trí kinh doanh thị trường.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng nóng cho các hợp đồng lớn, vượt chỉ tiêu.
- Thu nhập không giới hạn, hoa hồng hấp dẫn theo doanh số thực tế.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám đốc kinh doanh.', 35000000, 60000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-12-20', 'Pending', 0),
(21, 91, N'Chuyên viên tuyển dụng', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Chuyên viên tuyển dụng làm việc tại Hà Nội, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.

Công cụ / hệ thống sử dụng trong công việc: phần mềm chấm công, Excel quản lý nhân sự, LinkedIn Recruiter, HRIS/HRM Software.

Vị trí Chuyên viên tuyển dụng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên tuyển dụng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên tuyển dụng.', 10000000, 18000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-15', 'Active', 1),
(22, 92, N'Hành chính nhân sự tổng hợp', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Hành chính nhân sự tổng hợp làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: HRIS/HRM Software, LinkedIn Recruiter, Excel quản lý nhân sự, phần mềm chấm công.

Vị trí Hành chính nhân sự tổng hợp sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Hành chính nhân sự tổng hợp hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 15.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Hành chính nhân sự tổng hợp.', 8000000, 15000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-30', 'Active', 0),
(23, 93, N'HR Manager (Trưởng phòng Nhân sự)', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí HR Manager (Trưởng phòng Nhân sự) làm việc tại Đà Nẵng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, Excel quản lý nhân sự, HRIS/HRM Software, phần mềm chấm công.

Vị trí HR Manager (Trưởng phòng Nhân sự) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí HR Manager (Trưởng phòng Nhân sự) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 35.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí HR Manager (Trưởng phòng Nhân sự).', 20000000, 35000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-09-10', 'Active', 0),
(24, 94, N'Chuyên viên đào tạo & phát triển', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Chuyên viên đào tạo & phát triển làm việc tại Hải Phòng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: HRIS/HRM Software, phần mềm chấm công, Excel quản lý nhân sự, LinkedIn Recruiter.

Vị trí Chuyên viên đào tạo & phát triển sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên đào tạo & phát triển hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên đào tạo & phát triển.', 12000000, 20000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-09-25', 'Closed', 0),
(25, 95, N'Chuyên viên C&B (Lương - Phúc lợi)', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Chuyên viên C&B (Lương - Phúc lợi) làm việc tại Cần Thơ, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.

Công cụ / hệ thống sử dụng trong công việc: Excel quản lý nhân sự, phần mềm chấm công, LinkedIn Recruiter, HRIS/HRM Software.

Vị trí Chuyên viên C&B (Lương - Phúc lợi) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên C&B (Lương - Phúc lợi) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên C&B (Lương - Phúc lợi).', 13000000, 22000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-10-05', 'Pending', 0),
(26, 96, N'Chuyên viên quan hệ lao động', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Chuyên viên quan hệ lao động làm việc tại Bình Dương, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: phần mềm chấm công, HRIS/HRM Software, LinkedIn Recruiter, Excel quản lý nhân sự.

Vị trí Chuyên viên quan hệ lao động sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên quan hệ lao động hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên quan hệ lao động.', 12000000, 20000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-10-20', 'Active', 0),
(27, 97, N'Giám đốc nhân sự (CHRO)', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí Giám đốc nhân sự (CHRO) làm việc tại Đồng Nai, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm chấm công, LinkedIn Recruiter, Excel quản lý nhân sự, HRIS/HRM Software.

Vị trí Giám đốc nhân sự (CHRO) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giám đốc nhân sự (CHRO) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 35.000.000 đ - 60.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám đốc nhân sự (CHRO).', 35000000, 60000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-11-01', 'Active', 0),
(28, 98, N'Nhân viên hành chính văn phòng', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Nhân viên hành chính văn phòng làm việc tại Nha Trang, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, Excel quản lý nhân sự, HRIS/HRM Software, phần mềm chấm công.

Vị trí Nhân viên hành chính văn phòng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên hành chính văn phòng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên hành chính văn phòng.', 7000000, 12000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-11-15', 'Active', 1),
(29, 99, N'Thư ký / Trợ lý giám đốc', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Thư ký / Trợ lý giám đốc làm việc tại Hà Nội, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: HRIS/HRM Software, LinkedIn Recruiter, Excel quản lý nhân sự, phần mềm chấm công.

Vị trí Thư ký / Trợ lý giám đốc sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Thư ký / Trợ lý giám đốc hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Thư ký / Trợ lý giám đốc.', 10000000, 18000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-30', 'Closed', 0),
(30, 100, N'Chuyên viên HRIS', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Chuyên viên HRIS làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.

Công cụ / hệ thống sử dụng trong công việc: Excel quản lý nhân sự, LinkedIn Recruiter, phần mềm chấm công, HRIS/HRM Software.

Vị trí Chuyên viên HRIS sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên HRIS hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên HRIS.', 13000000, 22000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-12-15', 'Pending', 0),
(1, 101, N'HR Business Partner', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí HR Business Partner làm việc tại Đà Nẵng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: phần mềm chấm công, Excel quản lý nhân sự, LinkedIn Recruiter, HRIS/HRM Software.

Vị trí HR Business Partner sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí HR Business Partner hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí HR Business Partner.', 18000000, 30000000, 0, 'Contract', N'Đà Nẵng', 'Middle', '2026-07-31', 'Active', 0),
(2, 102, N'Nhân viên lễ tân', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Nhân viên lễ tân làm việc tại Hải Phòng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, phần mềm chấm công, HRIS/HRM Software, Excel quản lý nhân sự.

Vị trí Nhân viên lễ tân sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên lễ tân hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 6.000.000 đ - 10.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên lễ tân.', 6000000, 10000000, 0, 'PartTime', N'Hải Phòng', 'Senior', '2026-08-20', 'Active', 0),
(3, 103, N'Chuyên viên văn thư lưu trữ', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Chuyên viên văn thư lưu trữ làm việc tại Cần Thơ, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: Excel quản lý nhân sự, LinkedIn Recruiter, phần mềm chấm công, HRIS/HRM Software.

Vị trí Chuyên viên văn thư lưu trữ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên văn thư lưu trữ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên văn thư lưu trữ.', 7000000, 12000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-09-05', 'Active', 0),
(4, 104, N'Quản lý tòa nhà', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Quản lý tòa nhà làm việc tại Bình Dương, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.

Công cụ / hệ thống sử dụng trong công việc: phần mềm chấm công, HRIS/HRM Software, LinkedIn Recruiter, Excel quản lý nhân sự.

Vị trí Quản lý tòa nhà sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý tòa nhà hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý tòa nhà.', 14000000, 22000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-09-20', 'Closed', 0),
(5, 105, N'Chuyên viên an toàn lao động', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Chuyên viên an toàn lao động làm việc tại Đồng Nai, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng và triển khai chính sách lương thưởng, phúc lợi cho nhân viên.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, HRIS/HRM Software, Excel quản lý nhân sự, phần mềm chấm công.

Vị trí Chuyên viên an toàn lao động sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên an toàn lao động hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên an toàn lao động.', 12000000, 20000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-10-10', 'Pending', 1),
(6, 106, N'Talent Acquisition Specialist', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Talent Acquisition Specialist làm việc tại Nha Trang, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, Excel quản lý nhân sự, HRIS/HRM Software, phần mềm chấm công.

Vị trí Talent Acquisition Specialist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Talent Acquisition Specialist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Talent Acquisition Specialist.', 14000000, 24000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-10-25', 'Active', 0),
(7, 107, N'OD Specialist (Phát triển tổ chức)', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí OD Specialist (Phát triển tổ chức) làm việc tại Hà Nội, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.

Công cụ / hệ thống sử dụng trong công việc: Excel quản lý nhân sự, phần mềm chấm công, LinkedIn Recruiter, HRIS/HRM Software.

Vị trí OD Specialist (Phát triển tổ chức) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí OD Specialist (Phát triển tổ chức) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Quản trị nhân lực, Luật, Kinh tế hoặc liên quan.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí OD Specialist (Phát triển tổ chức).', 15000000, 26000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-11-08', 'Active', 0),
(8, 108, N'Payroll Specialist', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Payroll Specialist làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.
- Quản lý hồ sơ nhân sự, hợp đồng lao động và các thủ tục hành chính liên quan.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, phần mềm chấm công, HRIS/HRM Software, Excel quản lý nhân sự.

Vị trí Payroll Specialist sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Payroll Specialist hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Payroll Specialist.', 13000000, 22000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-22', 'Active', 0),
(9, 109, N'Nhân viên bảo vệ', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Nhân viên bảo vệ làm việc tại Đà Nẵng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Đăng tin tuyển dụng, sàng lọc hồ sơ và tổ chức phỏng vấn ứng viên.

Công cụ / hệ thống sử dụng trong công việc: Excel quản lý nhân sự, HRIS/HRM Software, phần mềm chấm công, LinkedIn Recruiter.

Vị trí Nhân viên bảo vệ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên bảo vệ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Nắm vững Luật Lao động và các quy định liên quan đến BHXH, thuế TNCN.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 6.000.000 đ - 9.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên bảo vệ.', 6000000, 9000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-12-05', 'Closed', 0),
(10, 110, N'Chuyên viên phúc lợi nhân viên', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Chuyên viên phúc lợi nhân viên làm việc tại Hải Phòng, thuộc lĩnh vực Nhân sự - Hành chính. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập kế hoạch nhân sự, xây dựng lộ trình phát triển nghề nghiệp cho nhân viên.
- Giải quyết các vấn đề quan hệ lao động, đảm bảo tuân thủ luật lao động.
- Tổ chức đào tạo, đánh giá hiệu suất làm việc định kỳ (KPI/OKR)
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tổ chức các hoạt động gắn kết nội bộ, xây dựng văn hóa doanh nghiệp.

Công cụ / hệ thống sử dụng trong công việc: LinkedIn Recruiter, HRIS/HRM Software, Excel quản lý nhân sự, phần mềm chấm công.

Vị trí Chuyên viên phúc lợi nhân viên sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên phúc lợi nhân viên hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có kỹ năng giao tiếp, xử lý tình huống khéo léo, giữ bảo mật thông tin tốt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Cẩn thận, tỉ mỉ trong công tác lưu trữ hồ sơ và số liệu nhân sự.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường làm việc nhân văn, chú trọng phát triển con người.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia xây dựng văn hóa doanh nghiệp, tổ chức sự kiện nội bộ.
- Được đào tạo chuyên sâu về nghiệp vụ nhân sự hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên phúc lợi nhân viên.', 12000000, 20000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-12-20', 'Pending', 0),
(11, 111, N'Kỹ sư sản xuất', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Kỹ sư sản xuất làm việc tại Cần Thơ, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý sản xuất (MES/ERP), 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp, AutoCAD/SolidWorks.

Vị trí Kỹ sư sản xuất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư sản xuất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư sản xuất.', 14000000, 24000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-08-15', 'Active', 1),
(12, 112, N'Kỹ sư cơ khí', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Kỹ sư cơ khí làm việc tại Bình Dương, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/SolidWorks, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP), 5S/Kaizen/Lean Manufacturing.

Vị trí Kỹ sư cơ khí sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư cơ khí hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư cơ khí.', 13000000, 22000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-08-30', 'Active', 0),
(13, 113, N'Kỹ sư điện / Điện tử', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Kỹ sư điện / Điện tử làm việc tại Đồng Nai, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp, AutoCAD/SolidWorks.

Vị trí Kỹ sư điện / Điện tử sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư điện / Điện tử hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư điện / Điện tử.', 14000000, 24000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-09-10', 'Active', 0),
(14, 114, N'Kỹ sư chất lượng (QA/QC)', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Kỹ sư chất lượng (QA/QC) làm việc tại Nha Trang, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý sản xuất (MES/ERP), 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp, AutoCAD/SolidWorks.

Vị trí Kỹ sư chất lượng (QA/QC) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư chất lượng (QA/QC) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư chất lượng (QA/QC).', 13000000, 22000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-09-25', 'Closed', 0),
(15, 115, N'Kỹ sư vận hành nhà máy', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Kỹ sư vận hành nhà máy làm việc tại Hà Nội, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.

Công cụ / hệ thống sử dụng trong công việc: thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing.

Vị trí Kỹ sư vận hành nhà máy sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư vận hành nhà máy hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư vận hành nhà máy.', 14000000, 24000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-10-05', 'Pending', 0),
(16, 116, N'Kỹ thuật viên bảo trì', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Kỹ thuật viên bảo trì làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp.

Vị trí Kỹ thuật viên bảo trì sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ thuật viên bảo trì hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên bảo trì.', 9000000, 16000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-20', 'Active', 0),
(17, 117, N'Kỹ sư tự động hóa (PLC/SCADA)', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Kỹ sư tự động hóa (PLC/SCADA) làm việc tại Đà Nẵng, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing.

Vị trí Kỹ sư tự động hóa (PLC/SCADA) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư tự động hóa (PLC/SCADA) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư tự động hóa (PLC/SCADA).', 16000000, 28000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-11-01', 'Active', 0),
(18, 118, N'Công nhân kỹ thuật', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Công nhân kỹ thuật làm việc tại Hải Phòng, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP).

Vị trí Công nhân kỹ thuật sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Công nhân kỹ thuật hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 6.000.000 đ - 10.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Công nhân kỹ thuật.', 6000000, 10000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-11-15', 'Active', 1),
(19, 119, N'Trưởng ca sản xuất', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Trưởng ca sản xuất làm việc tại Cần Thơ, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP).

Vị trí Trưởng ca sản xuất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trưởng ca sản xuất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng ca sản xuất.', 14000000, 22000000, 0, 'FullTime', N'Cần Thơ', 'Senior', '2026-11-30', 'Closed', 0),
(20, 120, N'Kỹ sư công nghệ thực phẩm', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Kỹ sư công nghệ thực phẩm làm việc tại Bình Dương, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks.

Vị trí Kỹ sư công nghệ thực phẩm sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư công nghệ thực phẩm hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư công nghệ thực phẩm.', 13000000, 22000000, 0, 'Remote', N'Bình Dương', 'Junior', '2026-12-15', 'Pending', 0),
(21, 121, N'Kỹ sư hóa chất', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Kỹ sư hóa chất làm việc tại Đồng Nai, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP).

Vị trí Kỹ sư hóa chất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư hóa chất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư hóa chất.', 14000000, 24000000, 0, 'Contract', N'Đồng Nai', 'Middle', '2026-07-31', 'Active', 0),
(22, 122, N'Kỹ sư môi trường', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Kỹ sư môi trường làm việc tại Nha Trang, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp, AutoCAD/SolidWorks.

Vị trí Kỹ sư môi trường sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư môi trường hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư môi trường.', 13000000, 22000000, 0, 'PartTime', N'Nha Trang', 'Senior', '2026-08-20', 'Active', 0),
(23, 123, N'Giám sát sản xuất', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí Giám sát sản xuất làm việc tại Hà Nội, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp, hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks.

Vị trí Giám sát sản xuất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giám sát sản xuất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám sát sản xuất.', 14000000, 24000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-09-05', 'Active', 0),
(24, 124, N'Kỹ sư vật liệu', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Kỹ sư vật liệu làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.

Công cụ / hệ thống sử dụng trong công việc: thiết bị đo lường công nghiệp, 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks, hệ thống quản lý sản xuất (MES/ERP).

Vị trí Kỹ sư vật liệu sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư vật liệu hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư vật liệu.', 14000000, 24000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-20', 'Closed', 0),
(25, 125, N'Kỹ sư thiết kế cơ khí (CAD/CAM)', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Kỹ sư thiết kế cơ khí (CAD/CAM) làm việc tại Đà Nẵng, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing, hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp.

Vị trí Kỹ sư thiết kế cơ khí (CAD/CAM) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư thiết kế cơ khí (CAD/CAM) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư thiết kế cơ khí (CAD/CAM).', 14000000, 26000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-10-10', 'Pending', 1),
(26, 126, N'Quản lý nhà máy', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Quản lý nhà máy làm việc tại Hải Phòng, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing, hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp.

Vị trí Quản lý nhà máy sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Quản lý nhà máy hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 40.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý nhà máy.', 22000000, 40000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-10-25', 'Active', 0),
(27, 127, N'Kỹ sư hàn', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí Kỹ sư hàn làm việc tại Cần Thơ, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing, hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp.

Vị trí Kỹ sư hàn sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư hàn hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Tốt nghiệp chuyên ngành Cơ khí, Điện - Điện tử, Công nghệ kỹ thuật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư hàn.', 10000000, 18000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-11-08', 'Active', 0),
(28, 128, N'Kỹ sư R&D (Nghiên cứu & Phát triển)', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Kỹ sư R&D (Nghiên cứu & Phát triển) làm việc tại Bình Dương, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đề xuất cải tiến quy trình sản xuất nhằm giảm lãng phí, tăng năng suất.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.
- Đảm bảo tuân thủ quy định an toàn lao động (HSE) tại xưởng sản xuất.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý sản xuất (MES/ERP), thiết bị đo lường công nghiệp, 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks.

Vị trí Kỹ sư R&D (Nghiên cứu & Phát triển) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư R&D (Nghiên cứu & Phát triển) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư R&D (Nghiên cứu & Phát triển).', 16000000, 30000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-11-22', 'Active', 0),
(29, 129, N'Chuyên viên an toàn (HSE)', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Chuyên viên an toàn (HSE) làm việc tại Đồng Nai, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Kiểm soát chất lượng nguyên vật liệu đầu vào và thành phẩm đầu ra (QA/QC)
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập bản vẽ kỹ thuật, quy trình gia công theo yêu cầu sản phẩm.

Công cụ / hệ thống sử dụng trong công việc: thiết bị đo lường công nghiệp, 5S/Kaizen/Lean Manufacturing, AutoCAD/SolidWorks, hệ thống quản lý sản xuất (MES/ERP).

Vị trí Chuyên viên an toàn (HSE) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên an toàn (HSE) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên an toàn (HSE).', 13000000, 22000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-12-05', 'Closed', 0),
(30, 130, N'Kỹ sư dệt may / may mặc', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Kỹ sư dệt may / may mặc làm việc tại Nha Trang, thuộc lĩnh vực Sản xuất - Cơ khí. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo sản lượng, tỷ lệ lỗi và hiệu suất thiết bị (OEE) định kỳ.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Vận hành, giám sát dây chuyền sản xuất đảm bảo đúng tiến độ và chất lượng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Kiểm tra, bảo trì máy móc thiết bị định kỳ, xử lý sự cố kỹ thuật phát sinh.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý sản xuất (MES/ERP), AutoCAD/SolidWorks, 5S/Kaizen/Lean Manufacturing, thiết bị đo lường công nghiệp.

Vị trí Kỹ sư dệt may / may mặc sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư dệt may / may mặc hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, thông số kỹ thuật thiết bị.
- Có sức khỏe tốt, sẵn sàng làm việc theo ca tại nhà máy/xưởng sản xuất.
- Cẩn thận, có tinh thần trách nhiệm cao trong công việc, tuân thủ an toàn lao động.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Phụ cấp ca, phụ cấp độc hại (nếu có) theo quy định công ty.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Trang bị đầy đủ đồ bảo hộ lao động, khám sức khỏe định kỳ.
- Xe đưa đón nhân viên từ nội thành đến nhà máy (nếu có nhu cầu)
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư dệt may / may mặc.', 12000000, 20000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-12-20', 'Pending', 0),
(1, 131, N'Nhân viên logistics', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Nhân viên logistics làm việc tại Hà Nội, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), hệ thống quản lý kho (WMS), Excel theo dõi lô hàng, incoterms.

Vị trí Nhân viên logistics sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên logistics hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên logistics.', 10000000, 16000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-15', 'Active', 1),
(2, 132, N'Điều phối vận tải', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Điều phối vận tải làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)

Công cụ / hệ thống sử dụng trong công việc: incoterms, hệ thống quản lý kho (WMS), hệ thống khai báo hải quan điện tử, phần mềm quản lý vận tải (TMS).

Vị trí Điều phối vận tải sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Điều phối vận tải hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Điều phối vận tải.', 11000000, 18000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-30', 'Active', 0),
(3, 133, N'Nhân viên kho vận', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Nhân viên kho vận làm việc tại Đà Nẵng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), incoterms, hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS).

Vị trí Nhân viên kho vận sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên kho vận hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kho vận.', 8000000, 14000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-09-10', 'Active', 0),
(4, 134, N'Chuyên viên xuất nhập khẩu', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Chuyên viên xuất nhập khẩu làm việc tại Hải Phòng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý kho (WMS), incoterms, phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng.

Vị trí Chuyên viên xuất nhập khẩu sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên xuất nhập khẩu hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên xuất nhập khẩu.', 12000000, 20000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-09-25', 'Closed', 0),
(5, 135, N'Nhân viên hải quan', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Nhân viên hải quan làm việc tại Cần Thơ, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS), Excel theo dõi lô hàng, phần mềm quản lý vận tải (TMS).

Vị trí Nhân viên hải quan sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên hải quan hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên hải quan.', 11000000, 18000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-10-05', 'Pending', 0),
(6, 136, N'Lái xe tải / Tài xế', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Lái xe tải / Tài xế làm việc tại Bình Dương, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng, hệ thống quản lý kho (WMS), hệ thống khai báo hải quan điện tử.

Vị trí Lái xe tải / Tài xế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Lái xe tải / Tài xế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Lái xe tải / Tài xế.', 8000000, 14000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-10-20', 'Active', 0),
(7, 137, N'Quản lý kho', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Quản lý kho làm việc tại Đồng Nai, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), hệ thống quản lý kho (WMS), hệ thống khai báo hải quan điện tử, Excel theo dõi lô hàng.

Vị trí Quản lý kho sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Quản lý kho hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý kho.', 14000000, 22000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-11-01', 'Active', 0),
(8, 138, N'Freight Forwarder', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Freight Forwarder làm việc tại Nha Trang, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý kho (WMS), incoterms, phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng.

Vị trí Freight Forwarder sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Freight Forwarder hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Freight Forwarder.', 12000000, 22000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-11-15', 'Active', 1),
(9, 139, N'Chuyên viên chuỗi cung ứng', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Chuyên viên chuỗi cung ứng làm việc tại Hà Nội, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: hệ thống khai báo hải quan điện tử, phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng, incoterms.

Vị trí Chuyên viên chuỗi cung ứng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên chuỗi cung ứng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên chuỗi cung ứng.', 14000000, 24000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-30', 'Closed', 0),
(10, 140, N'Nhân viên giao nhận hàng hóa', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Nhân viên giao nhận hàng hóa làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.

Công cụ / hệ thống sử dụng trong công việc: Excel theo dõi lô hàng, incoterms, phần mềm quản lý vận tải (TMS), hệ thống quản lý kho (WMS).

Vị trí Nhân viên giao nhận hàng hóa sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên giao nhận hàng hóa hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên giao nhận hàng hóa.', 8000000, 14000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-12-15', 'Pending', 0),
(11, 141, N'Kỹ thuật viên xe', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Kỹ thuật viên xe làm việc tại Đà Nẵng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý kho (WMS), hệ thống khai báo hải quan điện tử, Excel theo dõi lô hàng, incoterms.

Vị trí Kỹ thuật viên xe sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ thuật viên xe hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên xe.', 8000000, 14000000, 0, 'Contract', N'Đà Nẵng', 'Middle', '2026-07-31', 'Active', 0),
(12, 142, N'Trưởng phòng logistics', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Trưởng phòng logistics làm việc tại Hải Phòng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.

Công cụ / hệ thống sử dụng trong công việc: Excel theo dõi lô hàng, incoterms, hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS).

Vị trí Trưởng phòng logistics sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trưởng phòng logistics hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 36.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng phòng logistics.', 20000000, 36000000, 0, 'PartTime', N'Hải Phòng', 'Senior', '2026-08-20', 'Active', 0),
(13, 143, N'Nhân viên chứng từ XNK', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Nhân viên chứng từ XNK làm việc tại Cần Thơ, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng, hệ thống quản lý kho (WMS), hệ thống khai báo hải quan điện tử.

Vị trí Nhân viên chứng từ XNK sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên chứng từ XNK hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 17.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên chứng từ XNK.', 10000000, 17000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-09-05', 'Active', 0),
(14, 144, N'Chuyên viên mua hàng', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Chuyên viên mua hàng làm việc tại Bình Dương, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.

Công cụ / hệ thống sử dụng trong công việc: hệ thống khai báo hải quan điện tử, phần mềm quản lý vận tải (TMS), Excel theo dõi lô hàng, incoterms.

Vị trí Chuyên viên mua hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên mua hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên mua hàng.', 12000000, 20000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-09-20', 'Closed', 0),
(15, 145, N'Nhân viên giao hàng', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Nhân viên giao hàng làm việc tại Đồng Nai, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: Excel theo dõi lô hàng, hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS), incoterms.

Vị trí Nhân viên giao hàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên giao hàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên giao hàng.', 7000000, 12000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-10-10', 'Pending', 1),
(16, 146, N'Giám sát kho', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Giám sát kho làm việc tại Nha Trang, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý kho (WMS), Excel theo dõi lô hàng, hệ thống khai báo hải quan điện tử, incoterms.

Vị trí Giám sát kho sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giám sát kho hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám sát kho.', 13000000, 20000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-10-25', 'Active', 0),
(17, 147, N'Nhân viên kiểm soát tồn kho', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Nhân viên kiểm soát tồn kho làm việc tại Hà Nội, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)

Công cụ / hệ thống sử dụng trong công việc: hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS), incoterms, phần mềm quản lý vận tải (TMS).

Vị trí Nhân viên kiểm soát tồn kho sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên kiểm soát tồn kho hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kiểm soát tồn kho.', 10000000, 16000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-11-08', 'Active', 0),
(18, 148, N'Chuyên viên phân tích logistics', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Chuyên viên phân tích logistics làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Quản lý kho bãi, sắp xếp hàng hóa khoa học, tối ưu diện tích lưu kho.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý vận tải (TMS), hệ thống quản lý kho (WMS), incoterms, Excel theo dõi lô hàng.

Vị trí Chuyên viên phân tích logistics sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên phân tích logistics hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Tốt nghiệp chuyên ngành Logistics, Kinh doanh quốc tế, Ngoại thương hoặc liên quan.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên phân tích logistics.', 13000000, 22000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-22', 'Active', 0),
(19, 149, N'Nhân viên vận hành bến bãi', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Nhân viên vận hành bến bãi làm việc tại Đà Nẵng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Xử lý sự cố phát sinh trong quá trình vận chuyển, khiếu nại với đối tác.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: hệ thống khai báo hải quan điện tử, Excel theo dõi lô hàng, hệ thống quản lý kho (WMS), phần mềm quản lý vận tải (TMS).

Vị trí Nhân viên vận hành bến bãi sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên vận hành bến bãi hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Am hiểu quy trình xuất nhập khẩu, thủ tục hải quan và Incoterms.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên vận hành bến bãi.', 10000000, 16000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-12-05', 'Closed', 0),
(20, 150, N'Quản lý vận tải quốc tế', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Quản lý vận tải quốc tế làm việc tại Hải Phòng, thuộc lĩnh vực Vận tải - Logistics. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với bộ phận kinh doanh để đảm bảo giao hàng đúng hẹn cho khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Điều phối, theo dõi tiến độ vận chuyển hàng hóa nội địa và quốc tế.
- Giám sát chi phí vận chuyển, đề xuất phương án tối ưu tuyến đường và cước phí.
- Lập chứng từ xuất nhập khẩu (invoice, packing list, bill of lading, C/O...)
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Làm việc với hãng tàu, hãng bay, đại lý hải quan để thông quan hàng hóa.

Công cụ / hệ thống sử dụng trong công việc: Excel theo dõi lô hàng, incoterms, hệ thống khai báo hải quan điện tử, hệ thống quản lý kho (WMS).

Vị trí Quản lý vận tải quốc tế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý vận tải quốc tế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc dưới áp lực thời gian giao hàng.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tiếng Anh giao tiếp tốt (đối với vị trí làm việc với đối tác nước ngoài)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 38.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng theo hiệu suất giao hàng đúng hạn, tối ưu chi phí.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Phụ cấp điện thoại, công tác phí khi làm việc tại cảng/kho ngoại quan.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cơ hội làm việc với đối tác quốc tế, mở rộng kiến thức ngoại thương.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý vận tải quốc tế.', 22000000, 38000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-12-20', 'Pending', 0),
(21, 151, N'Dược sĩ', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Dược sĩ làm việc tại Cần Thơ, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ bệnh án điện tử (EMR), thiết bị y tế chuyên khoa, tiêu chuẩn GMP/GSP/GLP, hệ thống quản lý bệnh viện (HIS).

Vị trí Dược sĩ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Dược sĩ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Dược sĩ.', 12000000, 20000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-08-15', 'Active', 1),
(22, 152, N'Bác sĩ đa khoa', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Bác sĩ đa khoa làm việc tại Bình Dương, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa.

Vị trí Bác sĩ đa khoa sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Bác sĩ đa khoa hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 35.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Bác sĩ đa khoa.', 18000000, 35000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-08-30', 'Active', 0),
(23, 153, N'Điều dưỡng viên', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí Điều dưỡng viên làm việc tại Đồng Nai, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, hệ thống quản lý bệnh viện (HIS).

Vị trí Điều dưỡng viên sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Điều dưỡng viên hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Điều dưỡng viên.', 10000000, 18000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-09-10', 'Active', 0),
(24, 154, N'Kỹ thuật viên xét nghiệm', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Kỹ thuật viên xét nghiệm làm việc tại Nha Trang, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ bệnh án điện tử (EMR), thiết bị y tế chuyên khoa, tiêu chuẩn GMP/GSP/GLP, hệ thống quản lý bệnh viện (HIS).

Vị trí Kỹ thuật viên xét nghiệm sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ thuật viên xét nghiệm hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên xét nghiệm.', 11000000, 18000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-09-25', 'Closed', 0),
(25, 155, N'Nhân viên kinh doanh dược', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Nhân viên kinh doanh dược làm việc tại Hà Nội, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.

Công cụ / hệ thống sử dụng trong công việc: tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR).

Vị trí Nhân viên kinh doanh dược sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên kinh doanh dược hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kinh doanh dược.', 11000000, 20000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-10-05', 'Pending', 0),
(26, 156, N'Chuyên viên nghiên cứu lâm sàng', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Chuyên viên nghiên cứu lâm sàng làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa.

Vị trí Chuyên viên nghiên cứu lâm sàng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên nghiên cứu lâm sàng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 25.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên nghiên cứu lâm sàng.', 14000000, 25000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-20', 'Active', 0),
(27, 157, N'Kỹ thuật viên hình ảnh (X-quang)', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí Kỹ thuật viên hình ảnh (X-quang) làm việc tại Đà Nẵng, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa.

Vị trí Kỹ thuật viên hình ảnh (X-quang) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ thuật viên hình ảnh (X-quang) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên hình ảnh (X-quang).', 11000000, 18000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-11-01', 'Active', 0),
(28, 158, N'Nhân viên y tế công ty', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Nhân viên y tế công ty làm việc tại Hải Phòng, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.

Công cụ / hệ thống sử dụng trong công việc: tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR).

Vị trí Nhân viên y tế công ty sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên y tế công ty hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 16.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên y tế công ty.', 10000000, 16000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-11-15', 'Active', 1),
(29, 159, N'Chuyên viên QA Dược phẩm', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Chuyên viên QA Dược phẩm làm việc tại Cần Thơ, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, hệ thống quản lý bệnh viện (HIS).

Vị trí Chuyên viên QA Dược phẩm sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên QA Dược phẩm hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên QA Dược phẩm.', 14000000, 24000000, 0, 'FullTime', N'Cần Thơ', 'Senior', '2026-11-30', 'Closed', 0),
(30, 160, N'Bác sĩ chuyên khoa', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Bác sĩ chuyên khoa làm việc tại Bình Dương, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR), hệ thống quản lý bệnh viện (HIS).

Vị trí Bác sĩ chuyên khoa sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Bác sĩ chuyên khoa hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 22.000.000 đ - 45.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Bác sĩ chuyên khoa.', 22000000, 45000000, 0, 'Remote', N'Bình Dương', 'Junior', '2026-12-15', 'Pending', 0),
(1, 161, N'Hộ lý / Điều dưỡng hỗ trợ', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Hộ lý / Điều dưỡng hỗ trợ làm việc tại Đồng Nai, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR), hệ thống quản lý bệnh viện (HIS).

Vị trí Hộ lý / Điều dưỡng hỗ trợ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Hộ lý / Điều dưỡng hỗ trợ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Hộ lý / Điều dưỡng hỗ trợ.', 7000000, 12000000, 0, 'Contract', N'Đồng Nai', 'Middle', '2026-07-31', 'Active', 0),
(2, 162, N'Trình dược viên (Medical Representative)', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Trình dược viên (Medical Representative) làm việc tại Nha Trang, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR), hệ thống quản lý bệnh viện (HIS).

Vị trí Trình dược viên (Medical Representative) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trình dược viên (Medical Representative) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trình dược viên (Medical Representative).', 12000000, 22000000, 0, 'PartTime', N'Nha Trang', 'Senior', '2026-08-20', 'Active', 0),
(3, 163, N'Quản lý nhà thuốc', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Quản lý nhà thuốc làm việc tại Hà Nội, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS), tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR).

Vị trí Quản lý nhà thuốc sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Quản lý nhà thuốc hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý nhà thuốc.', 14000000, 22000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-09-05', 'Active', 0),
(4, 164, N'Kỹ sư thiết bị y tế', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Kỹ sư thiết bị y tế làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa.

Vị trí Kỹ sư thiết bị y tế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư thiết bị y tế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư thiết bị y tế.', 14000000, 24000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-20', 'Closed', 0),
(5, 165, N'Chuyên viên dinh dưỡng', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Chuyên viên dinh dưỡng làm việc tại Đà Nẵng, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS).

Vị trí Chuyên viên dinh dưỡng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Chuyên viên dinh dưỡng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên dinh dưỡng.', 12000000, 20000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-10-10', 'Pending', 1),
(6, 166, N'Chuyên viên sức khỏe tâm thần', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Chuyên viên sức khỏe tâm thần làm việc tại Hải Phòng, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS), tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR).

Vị trí Chuyên viên sức khỏe tâm thần sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên sức khỏe tâm thần hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên sức khỏe tâm thần.', 14000000, 24000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-10-25', 'Active', 0),
(7, 167, N'Kỹ thuật viên vật lý trị liệu', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Kỹ thuật viên vật lý trị liệu làm việc tại Cần Thơ, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: tiêu chuẩn GMP/GSP/GLP, thiết bị y tế chuyên khoa, hệ thống quản lý bệnh viện (HIS), hồ sơ bệnh án điện tử (EMR).

Vị trí Kỹ thuật viên vật lý trị liệu sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ thuật viên vật lý trị liệu hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên vật lý trị liệu.', 11000000, 18000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-11-08', 'Active', 0),
(8, 168, N'Quản lý phòng khám', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Quản lý phòng khám làm việc tại Bình Dương, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Đảm bảo tuân thủ các quy định về an toàn, vệ sinh dịch tễ trong môi trường y tế.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), thiết bị y tế chuyên khoa, hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP.

Vị trí Quản lý phòng khám sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Quản lý phòng khám hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý phòng khám.', 16000000, 28000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-11-22', 'Active', 0),
(9, 169, N'Chuyên viên y tế dự phòng', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Chuyên viên y tế dự phòng làm việc tại Đồng Nai, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Thực hiện các quy trình kiểm soát chất lượng thuốc/sản phẩm theo tiêu chuẩn GMP.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với đội ngũ y bác sĩ, điều dưỡng trong quá trình chăm sóc bệnh nhân.
- Khám, chẩn đoán và điều trị cho bệnh nhân theo đúng chuyên môn, phác đồ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý bệnh viện (HIS), thiết bị y tế chuyên khoa, hồ sơ bệnh án điện tử (EMR), tiêu chuẩn GMP/GSP/GLP.

Vị trí Chuyên viên y tế dự phòng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên y tế dự phòng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên y tế dự phòng.', 12000000, 20000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-12-05', 'Closed', 0),
(10, 170, N'Nhân viên hành chính bệnh viện', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Nhân viên hành chính bệnh viện làm việc tại Nha Trang, thuộc lĩnh vực Y tế - Dược phẩm. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tư vấn, hướng dẫn sử dụng thuốc an toàn, hợp lý cho bệnh nhân.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Cập nhật hồ sơ bệnh án, báo cáo y tế theo quy định của Bộ Y tế.
- Tham gia nghiên cứu, thử nghiệm lâm sàng và đánh giá hiệu quả điều trị.

Công cụ / hệ thống sử dụng trong công việc: tiêu chuẩn GMP/GSP/GLP, hồ sơ bệnh án điện tử (EMR), hệ thống quản lý bệnh viện (HIS), thiết bị y tế chuyên khoa.

Vị trí Nhân viên hành chính bệnh viện sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên hành chính bệnh viện hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có tinh thần trách nhiệm cao, y đức tốt, tận tâm với người bệnh.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Y, Dược hoặc lĩnh vực liên quan theo đúng vị trí ứng tuyển.
- Khả năng làm việc theo ca, chịu được áp lực công việc trong môi trường y tế.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có chứng chỉ hành nghề theo quy định của Bộ Y tế (nếu vị trí yêu cầu)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Khám sức khỏe định kỳ miễn phí, ưu đãi khám chữa bệnh cho người thân.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường làm việc chuyên nghiệp, trang thiết bị y tế hiện đại.
- Được đào tạo cập nhật phác đồ điều trị mới, tham gia hội thảo y khoa.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên hành chính bệnh viện.', 8000000, 14000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-12-20', 'Pending', 0),
(11, 171, N'Giáo viên - Giảng viên', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Giáo viên - Giảng viên làm việc tại Hà Nội, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý học tập (LMS), Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, giáo trình chuẩn quốc tế.

Vị trí Giáo viên - Giảng viên sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giáo viên - Giảng viên hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giáo viên - Giảng viên.', 10000000, 18000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-15', 'Active', 1),
(12, 172, N'Giáo viên tiếng Anh', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Giáo viên tiếng Anh làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, hệ thống quản lý học tập (LMS), giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace.

Vị trí Giáo viên tiếng Anh sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Giáo viên tiếng Anh hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giáo viên tiếng Anh.', 9000000, 20000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-30', 'Active', 0),
(13, 173, N'Gia sư', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Gia sư làm việc tại Đà Nẵng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, giáo trình chuẩn quốc tế, hệ thống quản lý học tập (LMS).

Vị trí Gia sư sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Gia sư hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 5.000.000 đ - 9.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Gia sư.', 5000000, 9000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-09-10', 'Active', 0),
(14, 174, N'Chuyên viên đào tạo doanh nghiệp', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Chuyên viên đào tạo doanh nghiệp làm việc tại Hải Phòng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý học tập (LMS), Microsoft Office/Google Workspace, Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế.

Vị trí Chuyên viên đào tạo doanh nghiệp sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên đào tạo doanh nghiệp hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên đào tạo doanh nghiệp.', 13000000, 22000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-09-25', 'Closed', 0),
(15, 175, N'Quản lý trung tâm đào tạo', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Quản lý trung tâm đào tạo làm việc tại Cần Thơ, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Quản lý trung tâm đào tạo sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý trung tâm đào tạo hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý trung tâm đào tạo.', 16000000, 28000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-10-05', 'Pending', 0),
(16, 176, N'Nhân viên tư vấn tuyển sinh', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Nhân viên tư vấn tuyển sinh làm việc tại Bình Dương, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: Microsoft Office/Google Workspace, Zoom/Google Meet giảng dạy trực tuyến, hệ thống quản lý học tập (LMS), giáo trình chuẩn quốc tế.

Vị trí Nhân viên tư vấn tuyển sinh sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên tư vấn tuyển sinh hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên tư vấn tuyển sinh.', 8000000, 14000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-10-20', 'Active', 0),
(17, 177, N'Chuyên viên thiết kế chương trình học', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Chuyên viên thiết kế chương trình học làm việc tại Đồng Nai, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Chuyên viên thiết kế chương trình học sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên thiết kế chương trình học hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên thiết kế chương trình học.', 14000000, 24000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-11-01', 'Active', 0),
(18, 178, N'Giáo viên mầm non', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Giáo viên mầm non làm việc tại Nha Trang, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Giáo viên mầm non sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Giáo viên mầm non hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 14.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giáo viên mầm non.', 8000000, 14000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-11-15', 'Active', 1),
(19, 179, N'Nhân viên hỗ trợ học vụ', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Nhân viên hỗ trợ học vụ làm việc tại Hà Nội, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, Zoom/Google Meet giảng dạy trực tuyến, hệ thống quản lý học tập (LMS).

Vị trí Nhân viên hỗ trợ học vụ sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên hỗ trợ học vụ hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 12.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên hỗ trợ học vụ.', 7000000, 12000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-30', 'Closed', 0),
(20, 180, N'Chuyên viên E-learning', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Chuyên viên E-learning làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.

Công cụ / hệ thống sử dụng trong công việc: Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS), Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế.

Vị trí Chuyên viên E-learning sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên E-learning hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên E-learning.', 12000000, 20000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-12-15', 'Pending', 0),
(21, 181, N'Giáo viên âm nhạc / nghệ thuật', N'Công ty CP Công nghệ Di Chuyển Xanh đang tuyển dụng vị trí Giáo viên âm nhạc / nghệ thuật làm việc tại Đà Nẵng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý học tập (LMS), Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, giáo trình chuẩn quốc tế.

Vị trí Giáo viên âm nhạc / nghệ thuật sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Di Chuyển Xanh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Giáo viên âm nhạc / nghệ thuật hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 15.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Công nghệ Di Chuyển Xanh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giáo viên âm nhạc / nghệ thuật.', 8000000, 15000000, 0, 'Contract', N'Đà Nẵng', 'Middle', '2026-07-31', 'Active', 0),
(22, 182, N'Huấn luyện viên thể thao', N'Công ty CP Dược phẩm An Khang đang tuyển dụng vị trí Huấn luyện viên thể thao làm việc tại Hải Phòng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, giáo trình chuẩn quốc tế, hệ thống quản lý học tập (LMS).

Vị trí Huấn luyện viên thể thao sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Dược phẩm An Khang. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Huấn luyện viên thể thao hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Dược phẩm An Khang cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Huấn luyện viên thể thao.', 10000000, 18000000, 0, 'PartTime', N'Hải Phòng', 'Senior', '2026-08-20', 'Active', 0),
(23, 183, N'Chuyên viên tâm lý học đường', N'Công ty CP Giáo dục Trí Việt đang tuyển dụng vị trí Chuyên viên tâm lý học đường làm việc tại Cần Thơ, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Chuyên viên tâm lý học đường sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giáo dục Trí Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên tâm lý học đường hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Giáo dục Trí Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên tâm lý học đường.', 13000000, 22000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-09-05', 'Active', 0),
(24, 184, N'Trưởng phòng đào tạo', N'Công ty CP Xây dựng Thành Đô đang tuyển dụng vị trí Trưởng phòng đào tạo làm việc tại Bình Dương, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, giáo trình chuẩn quốc tế, hệ thống quản lý học tập (LMS).

Vị trí Trưởng phòng đào tạo sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Xây dựng Thành Đô. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Trưởng phòng đào tạo hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Xây dựng Thành Đô cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng phòng đào tạo.', 18000000, 32000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-09-20', 'Closed', 0),
(25, 185, N'Điều phối viên chương trình quốc tế', N'Công ty CP Logistics Miền Trung đang tuyển dụng vị trí Điều phối viên chương trình quốc tế làm việc tại Đồng Nai, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: Microsoft Office/Google Workspace, Zoom/Google Meet giảng dạy trực tuyến, hệ thống quản lý học tập (LMS), giáo trình chuẩn quốc tế.

Vị trí Điều phối viên chương trình quốc tế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Logistics Miền Trung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Điều phối viên chương trình quốc tế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Logistics Miền Trung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Điều phối viên chương trình quốc tế.', 12000000, 20000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-10-10', 'Pending', 1),
(26, 186, N'Giáo viên dạy nghề / STEM', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tuyển dụng vị trí Giáo viên dạy nghề / STEM làm việc tại Nha Trang, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.

Công cụ / hệ thống sử dụng trong công việc: Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS), Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế.

Vị trí Giáo viên dạy nghề / STEM sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bán lẻ Điện máy Phú Cường. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giáo viên dạy nghề / STEM hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 10.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty CP Bán lẻ Điện máy Phú Cường cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giáo viên dạy nghề / STEM.', 10000000, 18000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-10-25', 'Active', 0),
(27, 187, N'Chuyên viên kiểm định chất lượng GD', N'Công ty CP Truyền thông Sáng Tạo Việt đang tuyển dụng vị trí Chuyên viên kiểm định chất lượng GD làm việc tại Hà Nội, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý học tập (LMS), giáo trình chuẩn quốc tế, Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace.

Vị trí Chuyên viên kiểm định chất lượng GD sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Truyền thông Sáng Tạo Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên kiểm định chất lượng GD hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.

Công ty CP Truyền thông Sáng Tạo Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên kiểm định chất lượng GD.', 13000000, 22000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-11-08', 'Active', 0),
(28, 188, N'Nhân viên thư viện', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tuyển dụng vị trí Nhân viên thư viện làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Đánh giá năng lực, theo dõi tiến độ học tập và đưa ra phản hồi cho học viên.
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.

Công cụ / hệ thống sử dụng trong công việc: giáo trình chuẩn quốc tế, Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Nhân viên thư viện sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Bảo hiểm Niềm Tin Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên thư viện hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 7.000.000 đ - 11.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.

Công ty CP Bảo hiểm Niềm Tin Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên thư viện.', 7000000, 11000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-22', 'Active', 0),
(29, 189, N'Giám đốc học thuật', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tuyển dụng vị trí Giám đốc học thuật làm việc tại Đà Nẵng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tổ chức các hoạt động ngoại khóa, sự kiện giáo dục nhằm tăng trải nghiệm học tập.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: hệ thống quản lý học tập (LMS), giáo trình chuẩn quốc tế, Zoom/Google Meet giảng dạy trực tuyến, Microsoft Office/Google Workspace.

Vị trí Giám đốc học thuật sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Năng lượng Xanh Toàn Cầu. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Giám đốc học thuật hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng truyền đạt tốt, kiên nhẫn, yêu thích công việc giảng dạy.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 28.000.000 đ - 50.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.

Công ty CP Năng lượng Xanh Toàn Cầu cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám đốc học thuật.', 28000000, 50000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-12-05', 'Closed', 0),
(30, 190, N'Nhân viên hợp tác quốc tế', N'Công ty TNHH Thời trang Việt Xinh đang tuyển dụng vị trí Nhân viên hợp tác quốc tế làm việc tại Hải Phòng, thuộc lĩnh vực Giáo dục - Đào tạo. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp giảng dạy, truyền đạt kiến thức và kỹ năng theo chương trình đào tạo.
- Phối hợp với phụ huynh/học viên để nắm bắt nhu cầu và điều chỉnh phương pháp dạy.
- Tham gia biên soạn, cập nhật giáo trình, tài liệu giảng dạy nội bộ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Báo cáo kết quả giảng dạy, đề xuất cải tiến chương trình đào tạo.
- Xây dựng giáo án, kế hoạch giảng dạy phù hợp với từng đối tượng học viên.

Công cụ / hệ thống sử dụng trong công việc: Zoom/Google Meet giảng dạy trực tuyến, giáo trình chuẩn quốc tế, Microsoft Office/Google Workspace, hệ thống quản lý học tập (LMS).

Vị trí Nhân viên hợp tác quốc tế sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Thời trang Việt Xinh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Nhân viên hợp tác quốc tế hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng quản lý lớp học, xử lý tình huống sư phạm linh hoạt.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Sư phạm hoặc chuyên ngành liên quan đến môn giảng dạy.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có chứng chỉ nghiệp vụ sư phạm (đối với vị trí không tốt nghiệp Sư phạm)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được đào tạo phương pháp giảng dạy hiện đại, tham gia hội thảo giáo dục.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chế độ học phí ưu đãi cho con em cán bộ nhân viên.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Môi trường sư phạm thân thiện, cơ hội phát triển chuyên môn dài hạn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Thời trang Việt Xinh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên hợp tác quốc tế.', 12000000, 20000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-12-20', 'Pending', 0),
(1, 191, N'Kỹ sư xây dựng', N'Công ty CP Công nghệ Sao Việt đang tuyển dụng vị trí Kỹ sư xây dựng làm việc tại Cần Thơ, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, phần mềm quản lý dự án bất động sản, MS Project, hồ sơ pháp lý dự án.

Vị trí Kỹ sư xây dựng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Sao Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư xây dựng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Công nghệ Sao Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư xây dựng.', 14000000, 24000000, 0, 'FullTime', N'Cần Thơ', 'Junior', '2026-08-15', 'Active', 1),
(2, 192, N'Kiến trúc sư', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tuyển dụng vị trí Kiến trúc sư làm việc tại Bình Dương, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Xử lý các thủ tục pháp lý về đất đai, giấy phép xây dựng với cơ quan nhà nước.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý dự án bất động sản, hồ sơ pháp lý dự án, AutoCAD/Revit, MS Project.

Vị trí Kiến trúc sư sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Giải pháp Số Hưng Thịnh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kiến trúc sư hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 30.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.

Công ty TNHH Giải pháp Số Hưng Thịnh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kiến trúc sư.', 16000000, 30000000, 0, 'FullTime', N'Bình Dương', 'Middle', '2026-08-30', 'Active', 0),
(3, 193, N'Nhân viên kinh doanh bất động sản', N'Công ty CP Ví điện tử An Phát đang tuyển dụng vị trí Nhân viên kinh doanh bất động sản làm việc tại Đồng Nai, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý dự án bất động sản, AutoCAD/Revit, MS Project, hồ sơ pháp lý dự án.

Vị trí Nhân viên kinh doanh bất động sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ví điện tử An Phát. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên kinh doanh bất động sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 9.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Ví điện tử An Phát cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên kinh doanh bất động sản.', 9000000, 20000000, 0, 'FullTime', N'Đồng Nai', 'Senior', '2026-09-10', 'Active', 0),
(4, 194, N'Kỹ sư giám sát công trình', N'Công ty CP Thương mại Điện tử Việt Tiến đang tuyển dụng vị trí Kỹ sư giám sát công trình làm việc tại Nha Trang, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý dự án bất động sản, MS Project, AutoCAD/Revit, hồ sơ pháp lý dự án.

Vị trí Kỹ sư giám sát công trình sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thương mại Điện tử Việt Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư giám sát công trình hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Thương mại Điện tử Việt Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư giám sát công trình.', 15000000, 26000000, 0, 'Remote', N'Nha Trang', 'Junior', '2026-09-25', 'Closed', 0),
(5, 195, N'Quản lý dự án xây dựng', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tuyển dụng vị trí Quản lý dự án xây dựng làm việc tại Hà Nội, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.

Công cụ / hệ thống sử dụng trong công việc: MS Project, phần mềm quản lý dự án bất động sản, hồ sơ pháp lý dự án, AutoCAD/Revit.

Vị trí Quản lý dự án xây dựng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Bán lẻ Trực tuyến Minh Long. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Quản lý dự án xây dựng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 20.000.000 đ - 38.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Công ty TNHH Bán lẻ Trực tuyến Minh Long cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Quản lý dự án xây dựng.', 20000000, 38000000, 0, 'Contract', N'Hà Nội', 'Middle', '2026-10-05', 'Pending', 0),
(6, 196, N'Kỹ sư thiết kế kết cấu', N'Tổng Công ty Viễn thông Đông Á đang tuyển dụng vị trí Kỹ sư thiết kế kết cấu làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Xử lý các thủ tục pháp lý về đất đai, giấy phép xây dựng với cơ quan nhà nước.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.

Công cụ / hệ thống sử dụng trong công việc: MS Project, AutoCAD/Revit, hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản.

Vị trí Kỹ sư thiết kế kết cấu sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tổng Công ty Viễn thông Đông Á. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư thiết kế kết cấu hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Tổng Công ty Viễn thông Đông Á cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư thiết kế kết cấu.', 15000000, 26000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-20', 'Active', 0),
(7, 197, N'Nhân viên định giá bất động sản', N'Công ty CP Thực phẩm Sữa Phương Nam đang tuyển dụng vị trí Nhân viên định giá bất động sản làm việc tại Đà Nẵng, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.

Công cụ / hệ thống sử dụng trong công việc: MS Project, hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản, AutoCAD/Revit.

Vị trí Nhân viên định giá bất động sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Thực phẩm Sữa Phương Nam. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên định giá bất động sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Công ty CP Thực phẩm Sữa Phương Nam cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên định giá bất động sản.', 13000000, 22000000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-11-01', 'Active', 0),
(8, 198, N'Kỹ sư điện công trình', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tuyển dụng vị trí Kỹ sư điện công trình làm việc tại Hải Phòng, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, MS Project, phần mềm quản lý dự án bất động sản, hồ sơ pháp lý dự án.

Vị trí Kỹ sư điện công trình sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Kỹ Nghệ Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư điện công trình hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 14.000.000 đ - 24.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Ngân hàng TMCP Kỹ Nghệ Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư điện công trình.', 14000000, 24000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-11-15', 'Active', 1),
(9, 199, N'Kỹ sư kết cấu', N'Tập đoàn Bất động sản Hoàng Gia Land đang tuyển dụng vị trí Kỹ sư kết cấu làm việc tại Cần Thơ, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: MS Project, hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản, AutoCAD/Revit.

Vị trí Kỹ sư kết cấu sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Bất động sản Hoàng Gia Land. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Kỹ sư kết cấu hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Tập đoàn Bất động sản Hoàng Gia Land cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư kết cấu.', 15000000, 26000000, 0, 'FullTime', N'Cần Thơ', 'Senior', '2026-11-30', 'Closed', 0),
(10, 200, N'Nhân viên môi giới bất động sản', N'Công ty CP Công nghệ Vận tải Đi Chung đang tuyển dụng vị trí Nhân viên môi giới bất động sản làm việc tại Bình Dương, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Xử lý các thủ tục pháp lý về đất đai, giấy phép xây dựng với cơ quan nhà nước.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.

Công cụ / hệ thống sử dụng trong công việc: MS Project, hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản, AutoCAD/Revit.

Vị trí Nhân viên môi giới bất động sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Vận tải Đi Chung. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Nhân viên môi giới bất động sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 8.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.

Công ty CP Công nghệ Vận tải Đi Chung cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên môi giới bất động sản.', 8000000, 18000000, 0, 'Remote', N'Bình Dương', 'Junior', '2026-12-15', 'Pending', 0),
(11, 201, N'Kỹ sư cơ điện lạnh (MEP)', N'Tập đoàn Công nghệ Bình Minh đang tuyển dụng vị trí Kỹ sư cơ điện lạnh (MEP) làm việc tại Đồng Nai, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Xử lý các thủ tục pháp lý về đất đai, giấy phép xây dựng với cơ quan nhà nước.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản, MS Project, AutoCAD/Revit.

Vị trí Kỹ sư cơ điện lạnh (MEP) sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Tập đoàn Công nghệ Bình Minh. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư cơ điện lạnh (MEP) hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 16.000.000 đ - 28.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.

Tập đoàn Công nghệ Bình Minh cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư cơ điện lạnh (MEP).', 16000000, 28000000, 0, 'Contract', N'Đồng Nai', 'Middle', '2026-07-31', 'Active', 0),
(12, 202, N'Trưởng nhóm kinh doanh bất động sản', N'Công ty CP Hàng tiêu dùng Đại Dương đang tuyển dụng vị trí Trưởng nhóm kinh doanh bất động sản làm việc tại Nha Trang, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, hồ sơ pháp lý dự án, MS Project, phần mềm quản lý dự án bất động sản.

Vị trí Trưởng nhóm kinh doanh bất động sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng tiêu dùng Đại Dương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Trưởng nhóm kinh doanh bất động sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Hàng tiêu dùng Đại Dương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Trưởng nhóm kinh doanh bất động sản.', 18000000, 32000000, 0, 'PartTime', N'Nha Trang', 'Senior', '2026-08-20', 'Active', 0),
(13, 203, N'Chuyên viên pháp lý bất động sản', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tuyển dụng vị trí Chuyên viên pháp lý bất động sản làm việc tại Hà Nội, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý dự án bất động sản, AutoCAD/Revit, MS Project, hồ sơ pháp lý dự án.

Vị trí Chuyên viên pháp lý bất động sản sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Ngân hàng TMCP Thịnh Vượng Sài Gòn. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Chuyên viên pháp lý bất động sản hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.

Ngân hàng TMCP Thịnh Vượng Sài Gòn cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên pháp lý bất động sản.', 15000000, 26000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-09-05', 'Active', 0),
(14, 204, N'Kỹ sư địa kỹ thuật', N'Công ty CP Hàng không Cánh Việt đang tuyển dụng vị trí Kỹ sư địa kỹ thuật làm việc tại TP. Hồ Chí Minh, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, phần mềm quản lý dự án bất động sản, MS Project, hồ sơ pháp lý dự án.

Vị trí Kỹ sư địa kỹ thuật sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Hàng không Cánh Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Kỹ sư địa kỹ thuật hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 15.000.000 đ - 26.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.

Công ty CP Hàng không Cánh Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư địa kỹ thuật.', 15000000, 26000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-20', 'Closed', 0),
(15, 205, N'Nhân viên quản lý tòa nhà', N'Công ty TNHH Phần mềm Kim Cương đang tuyển dụng vị trí Nhân viên quản lý tòa nhà làm việc tại Đà Nẵng, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ pháp lý dự án, phần mềm quản lý dự án bất động sản, MS Project, AutoCAD/Revit.

Vị trí Nhân viên quản lý tòa nhà sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Kim Cương. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên quản lý tòa nhà hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 20.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.

Công ty TNHH Phần mềm Kim Cương cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên quản lý tòa nhà.', 12000000, 20000000, 0, 'FullTime', N'Đà Nẵng', 'Senior', '2026-10-10', 'Pending', 1),
(16, 206, N'Kỹ sư hoàn thiện nội thất', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tuyển dụng vị trí Kỹ sư hoàn thiện nội thất làm việc tại Hải Phòng, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Lập báo cáo kết quả công việc định kỳ và báo cáo trực tiếp cho quản lý phụ trách.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ pháp lý dự án, MS Project, phần mềm quản lý dự án bất động sản, AutoCAD/Revit.

Vị trí Kỹ sư hoàn thiện nội thất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Công nghệ Phương Đông. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ sư hoàn thiện nội thất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 13.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.

Công ty CP Giải pháp Công nghệ Phương Đông cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ sư hoàn thiện nội thất.', 13000000, 22000000, 0, 'Remote', N'Hải Phòng', 'Junior', '2026-10-25', 'Active', 0),
(17, 207, N'Chuyên viên phát triển dự án BĐS', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tuyển dụng vị trí Chuyên viên phát triển dự án BĐS làm việc tại Cần Thơ, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng công việc.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.

Công cụ / hệ thống sử dụng trong công việc: hồ sơ pháp lý dự án, MS Project, phần mềm quản lý dự án bất động sản, AutoCAD/Revit.

Vị trí Chuyên viên phát triển dự án BĐS sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty TNHH Phần mềm Toàn Cầu Việt. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Chuyên viên phát triển dự án BĐS hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 18.000.000 đ - 32.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.

Công ty TNHH Phần mềm Toàn Cầu Việt cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Chuyên viên phát triển dự án BĐS.', 18000000, 32000000, 0, 'Contract', N'Cần Thơ', 'Middle', '2026-11-08', 'Active', 0),
(18, 208, N'Nhân viên thiết kế nội thất', N'Công ty CP Công nghệ Tân Tiến đang tuyển dụng vị trí Nhân viên thiết kế nội thất làm việc tại Bình Dương, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Xử lý các thủ tục pháp lý về đất đai, giấy phép xây dựng với cơ quan nhà nước.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, MS Project, phần mềm quản lý dự án bất động sản, hồ sơ pháp lý dự án.

Vị trí Nhân viên thiết kế nội thất sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Công nghệ Tân Tiến. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 4-6 năm kinh nghiệm, có khả năng dẫn dắt các đầu việc phức tạp ở vị trí Nhân viên thiết kế nội thất hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 12.000.000 đ - 22.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.

Công ty CP Công nghệ Tân Tiến cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Nhân viên thiết kế nội thất.', 12000000, 22000000, 0, 'PartTime', N'Bình Dương', 'Senior', '2026-11-22', 'Active', 0),
(19, 209, N'Kỹ thuật viên khảo sát', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tuyển dụng vị trí Kỹ thuật viên khảo sát làm việc tại Đồng Nai, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả, tiết kiệm chi phí.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.

Công cụ / hệ thống sử dụng trong công việc: phần mềm quản lý dự án bất động sản, hồ sơ pháp lý dự án, AutoCAD/Revit, MS Project.

Vị trí Kỹ thuật viên khảo sát sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Giải pháp Phần mềm Kết Nối. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 1-2 năm kinh nghiệm ở vị trí Kỹ thuật viên khảo sát hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Có khả năng đọc hiểu bản vẽ kỹ thuật, dự toán công trình.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 11.000.000 đ - 18.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Cơ hội thăng tiến lên vị trí quản lý dự án/trưởng phòng kinh doanh.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Giải pháp Phần mềm Kết Nối cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Kỹ thuật viên khảo sát.', 11000000, 18000000, 0, 'FullTime', N'Đồng Nai', 'Junior', '2026-12-05', 'Closed', 0),
(20, 210, N'Giám đốc dự án xây dựng', N'Công ty CP Ô tô Điện Việt Phong đang tuyển dụng vị trí Giám đốc dự án xây dựng làm việc tại Nha Trang, thuộc lĩnh vực Bất động sản - Xây dựng. Đây là cơ hội để bạn được làm việc trong môi trường chuyên nghiệp, trực tiếp tham gia vào các dự án thực tế của công ty và phát triển chuyên môn lâu dài cùng đội ngũ giàu kinh nghiệm.

Mô tả công việc:
- Tư vấn, giới thiệu sản phẩm bất động sản phù hợp với nhu cầu khách hàng.
- Nghiên cứu thị trường bất động sản, phân tích tiềm năng và định giá dự án.
- Soạn thảo, rà soát hợp đồng mua bán, hồ sơ pháp lý liên quan đến dự án.
- Triển khai, giám sát tiến độ và chất lượng thi công dự án theo hồ sơ thiết kế.
- Lập dự toán, kiểm soát chi phí xây dựng và báo cáo tiến độ định kỳ.
- Phối hợp với các đơn vị thi công, tư vấn giám sát để đảm bảo tiến độ dự án.
- Tham gia các cuộc họp giao ban, cập nhật tiến độ dự án/công việc theo tuần.

Công cụ / hệ thống sử dụng trong công việc: AutoCAD/Revit, hồ sơ pháp lý dự án, MS Project, phần mềm quản lý dự án bất động sản.

Vị trí Giám đốc dự án xây dựng sẽ làm việc trực tiếp dưới sự hướng dẫn của quản lý bộ phận, tham gia vào các dự án đang triển khai tại Công ty CP Ô tô Điện Việt Phong. Khối lượng công việc và nhiệm vụ cụ thể có thể được điều chỉnh, bổ sung theo năng lực và định hướng phát triển của từng ứng viên trong quá trình làm việc.', N'Ứng viên cần từ 2-4 năm kinh nghiệm, có khả năng làm việc độc lập ở vị trí Giám đốc dự án xây dựng hoặc vị trí tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng đàm phán, tư vấn khách hàng tốt (đối với vị trí kinh doanh dự án)
- Am hiểu quy trình pháp lý dự án, Luật Đất đai, Luật Kinh doanh bất động sản.
- Có khả năng chịu áp lực công việc tốt và quản lý thời gian hiệu quả.
- Trung thực, có trách nhiệm và tinh thần cầu tiến trong công việc.
- Tốt nghiệp chuyên ngành Xây dựng, Kiến trúc, Bất động sản, Luật hoặc liên quan.
- Có khả năng làm việc độc lập và phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.

Ứng viên vui lòng chuẩn bị CV chi tiết, có thể kèm theo portfolio/hồ sơ năng lực liên quan (nếu có) để nhà tuyển dụng đánh giá chính xác hơn năng lực thực tế.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương từ 35.000.000 đ - 65.000.000 đ, thỏa thuận thêm theo năng lực thực tế khi phỏng vấn.
- Tham gia đầy đủ BHXH, BHYT, BHTN theo quy định của pháp luật Việt Nam.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được tham quan thực tế dự án, đào tạo kiến thức pháp lý bất động sản.
- Hoa hồng hấp dẫn theo giá trị giao dịch/dự án (đối với vị trí kinh doanh)
- Xét tăng lương định kỳ theo năng lực và kết quả đánh giá hàng năm.
- Nghỉ phép năm theo quy định, tổ chức du lịch công ty và team-building định kỳ.
- Chương trình đào tạo nội bộ, hỗ trợ chi phí học các khóa chuyên môn.

Công ty CP Ô tô Điện Việt Phong cam kết xây dựng môi trường làm việc công bằng, minh bạch, tạo điều kiện để nhân viên phát huy tối đa năng lực và gắn bó lâu dài cùng vị trí Giám đốc dự án xây dựng.', 35000000, 65000000, 0, 'FullTime', N'Nha Trang', 'Middle', '2026-12-20', 'Pending', 0);
UPDATE JobPosts SET JobCode = 'TD' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 6));
GO
INSERT INTO CvFiles (ProfileId, FileName, FilePath, FileSize, IsDefault) VALUES
(1, N'CV_ĐỗThịPhương_FrontendDeveloper.pdf', N'/uploads/cv/cv_1_2026.pdf', 158000, 1),
(2, N'CV_VũQuangHuy_BackendDeveloper.pdf', N'/uploads/cv/cv_2_2026.pdf', 166000, 1),
(3, N'CV_NgôThịLan_DataAnalyst.pdf', N'/uploads/cv/cv_3_2026.pdf', 174000, 1),
(4, N'CV_BùiVănKhoa_DevOpsEngineer.pdf', N'/uploads/cv/cv_4_2026.pdf', 182000, 1),
(5, N'CV_LýThịMai_UIUXDesigner.pdf', N'/uploads/cv/cv_5_2026.pdf', 190000, 1),
(6, N'CV_ĐinhVănNam_ProjectManager.pdf', N'/uploads/cv/cv_6_2026.pdf', 198000, 1),
(7, N'CV_PhanThịOanh_Kếtoántổnghợp.pdf', N'/uploads/cv/cv_7_2026.pdf', 206000, 1),
(8, N'CV_TôMinhPhúc_DigitalMarketingSpecialist.pdf', N'/uploads/cv/cv_8_2026.pdf', 214000, 1),
(9, N'CV_CaoThịQuỳnh_Nhânviênkinhdoanh.pdf', N'/uploads/cv/cv_9_2026.pdf', 222000, 1),
(10, N'CV_HàVănSơn_Full-stackDeveloper.pdf', N'/uploads/cv/cv_10_2026.pdf', 230000, 1),
(11, N'CV_LươngThịTrang_HRExecutive.pdf', N'/uploads/cv/cv_11_2026.pdf', 238000, 1),
(12, N'CV_MaiVănUy_MobileDeveloper.pdf', N'/uploads/cv/cv_12_2026.pdf', 246000, 1),
(13, N'CV_TrịnhThịVân_BusinessAnalyst.pdf', N'/uploads/cv/cv_13_2026.pdf', 254000, 1),
(14, N'CV_DươngVănXuân_QAQCEngineer.pdf', N'/uploads/cv/cv_14_2026.pdf', 262000, 1),
(15, N'CV_NguyễnThịYến_DataScientist.pdf', N'/uploads/cv/cv_15_2026.pdf', 270000, 1),
(16, N'CV_TrầnVănÁnh_SystemAdministrator.pdf', N'/uploads/cv/cv_16_2026.pdf', 278000, 1),
(17, N'CV_LêThịBích_ContentWriter.pdf', N'/uploads/cv/cv_17_2026.pdf', 286000, 1),
(18, N'CV_PhạmVănCảnh_CustomerSupportSpecialist.pdf', N'/uploads/cv/cv_18_2026.pdf', 294000, 1),
(19, N'CV_HoàngThịDuyên_ProductOwner.pdf', N'/uploads/cv/cv_19_2026.pdf', 302000, 1),
(20, N'CV_VũVănGiang_CloudEngineer.pdf', N'/uploads/cv/cv_20_2026.pdf', 310000, 1),
(21, N'CV_ĐặngThịHằng_Kỹsưxâydựng.pdf', N'/uploads/cv/cv_21_2026.pdf', 318000, 1),
(22, N'CV_BùiVănInh_Dượcsĩ.pdf', N'/uploads/cv/cv_22_2026.pdf', 326000, 1),
(23, N'CV_NgôThịKiều_GiáoviêntiếngAnh.pdf', N'/uploads/cv/cv_23_2026.pdf', 334000, 1),
(24, N'CV_ĐỗVănLâm_NhânviênLogistics.pdf', N'/uploads/cv/cv_24_2026.pdf', 342000, 1),
(25, N'CV_ĐinhThịMinh_Chuyênviêntuyểndụng.pdf', N'/uploads/cv/cv_25_2026.pdf', 350000, 1),
(26, N'CV_TrươngVănNghị_SEOSpecialist.pdf', N'/uploads/cv/cv_26_2026.pdf', 358000, 1),
(27, N'CV_LýThịOanh_Kếtoánthuế.pdf', N'/uploads/cv/cv_27_2026.pdf', 366000, 1),
(28, N'CV_PhanVănPhúc_Giaodịchviênngânhàng.pdf', N'/uploads/cv/cv_28_2026.pdf', 374000, 1),
(29, N'CV_TôThịQuý_Trưởngnhómkinhdoanh.pdf', N'/uploads/cv/cv_29_2026.pdf', 382000, 1),
(30, N'CV_CaoVănRạng_Chuyênviênphântíchtàichính.pdf', N'/uploads/cv/cv_30_2026.pdf', 390000, 1);
GO
INSERT INTO Applications (JobID, ProfileId, CoverLetter, Status) VALUES
(1, 1, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(2, 8, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(3, 15, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(4, 22, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(5, 29, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected'),
(6, 6, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(7, 13, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(8, 20, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(9, 27, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(10, 4, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected'),
(11, 11, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(12, 18, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(13, 25, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(14, 2, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(15, 9, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected'),
(16, 16, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(17, 23, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(18, 30, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(19, 7, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(20, 14, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected'),
(21, 21, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(22, 28, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(23, 5, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(24, 12, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(25, 19, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected'),
(26, 26, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Pending'),
(27, 3, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Reviewing'),
(28, 10, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Interview'),
(29, 17, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Approved'),
(30, 24, N'Tôi đã tìm hiểu kỹ về công ty và tin rằng kinh nghiệm của mình phù hợp với yêu cầu công việc này. Rất mong có cơ hội trao đổi thêm.', N'Rejected');
GO
INSERT INTO Interviews (AppID, InterviewDate, Location, Notes) VALUES
(1, '2026-07-02 10:00:00', N'Văn phòng công ty, Hà Nội', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(2, '2026-07-03 11:00:00', N'Văn phòng công ty, TP. Hồ Chí Minh', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(3, '2026-07-04 12:00:00', N'Văn phòng công ty, Đà Nẵng', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(4, '2026-07-05 13:00:00', N'Online - Microsoft Teams', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(5, '2026-07-06 14:00:00', N'Online - Google Meet', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(6, '2026-07-07 15:00:00', N'Văn phòng công ty, Hà Nội', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(7, '2026-07-08 16:00:00', N'Văn phòng công ty, TP. Hồ Chí Minh', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(8, '2026-07-09 09:00:00', N'Văn phòng công ty, Đà Nẵng', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(9, '2026-07-10 10:00:00', N'Online - Microsoft Teams', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(10, '2026-07-11 11:00:00', N'Online - Google Meet', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(11, '2026-07-12 12:00:00', N'Văn phòng công ty, Hà Nội', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(12, '2026-07-13 13:00:00', N'Văn phòng công ty, TP. Hồ Chí Minh', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(13, '2026-07-14 14:00:00', N'Văn phòng công ty, Đà Nẵng', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(14, '2026-07-15 15:00:00', N'Online - Microsoft Teams', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(15, '2026-07-16 16:00:00', N'Online - Google Meet', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(16, '2026-07-17 09:00:00', N'Văn phòng công ty, Hà Nội', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(17, '2026-07-18 10:00:00', N'Văn phòng công ty, TP. Hồ Chí Minh', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(18, '2026-07-19 11:00:00', N'Văn phòng công ty, Đà Nẵng', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(19, '2026-07-20 12:00:00', N'Online - Microsoft Teams', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.'),
(20, '2026-07-21 13:00:00', N'Online - Google Meet', N'Phỏng vấn trao đổi về kinh nghiệm làm việc, kỹ năng chuyên môn và định hướng phát triển nghề nghiệp.');
GO
INSERT INTO CandidateSkills (ProfileId, SkillID, ProficiencyLevel, YearsOfExperience) VALUES
(1, 4, 1, 0.5),
(2, 9, 2, 1.0),
(3, 14, 3, 1.5),
(4, 19, 4, 2.0),
(5, 24, 5, 2.5),
(6, 4, 1, 3.0),
(7, 9, 2, 3.5),
(8, 14, 3, 0.5),
(9, 19, 4, 1.0),
(10, 24, 5, 1.5),
(11, 4, 1, 2.0),
(12, 9, 2, 2.5),
(13, 14, 3, 3.0),
(14, 19, 4, 3.5),
(15, 24, 5, 0.5),
(16, 4, 1, 1.0),
(17, 9, 2, 1.5),
(18, 14, 3, 2.0),
(19, 19, 4, 2.5),
(20, 24, 5, 3.0),
(21, 4, 1, 3.5),
(22, 9, 2, 0.5),
(23, 14, 3, 1.0),
(24, 19, 4, 1.5),
(25, 24, 5, 2.0),
(26, 4, 1, 2.5),
(27, 9, 2, 3.0),
(28, 14, 3, 3.5),
(29, 19, 4, 0.5),
(30, 24, 5, 1.0);
GO
INSERT INTO SavedJobs (UserId, JobID) VALUES
(57, 2),
(58, 5),
(59, 8),
(60, 11),
(61, 14),
(62, 17),
(63, 20),
(64, 23),
(65, 26),
(66, 29),
(67, 32),
(68, 35),
(69, 38),
(70, 41),
(71, 44),
(72, 1),
(73, 4),
(74, 7),
(75, 10),
(76, 13),
(77, 16),
(78, 19),
(79, 22),
(80, 25),
(81, 28),
(82, 31),
(83, 34),
(84, 37),
(85, 40),
(86, 43);
GO
INSERT INTO CompanyFollows (UserId, EmployerId) VALUES
(57, 2),
(58, 4),
(59, 6),
(60, 8),
(61, 10),
(62, 12),
(63, 14),
(64, 16),
(65, 18),
(66, 20),
(67, 22),
(68, 24),
(69, 26),
(70, 28),
(71, 30),
(72, 2),
(73, 4),
(74, 6),
(75, 8),
(76, 10),
(77, 12),
(78, 14),
(79, 16),
(80, 18),
(81, 20),
(82, 22),
(83, 24),
(84, 26),
(85, 28),
(86, 30);
GO
INSERT INTO Messages (SenderID, ReceiverID, Content, JobID) VALUES
(27, 57, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 1),
(58, 28, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 2),
(29, 59, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 3),
(60, 30, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 4),
(31, 61, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 5),
(62, 32, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 6),
(33, 63, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 7),
(64, 34, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 8),
(35, 65, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 9),
(66, 36, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 10),
(37, 67, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 11),
(68, 38, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 12),
(39, 69, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 13),
(70, 40, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 14),
(41, 71, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 15),
(72, 42, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 16),
(43, 73, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 17),
(74, 44, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 18),
(45, 75, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 19),
(76, 46, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 20),
(47, 77, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 21),
(78, 48, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 22),
(49, 79, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 23),
(80, 50, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 24),
(51, 81, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 25),
(82, 52, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 26),
(53, 83, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 27),
(84, 54, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 28),
(55, 85, N'Chào bạn, chúng tôi đã xem hồ sơ và muốn mời bạn tham gia phỏng vấn cho vị trí đang ứng tuyển.', 29),
(86, 56, N'Dạ, cảm ơn anh/chị đã phản hồi. Em rất vui khi nhận được lời mời và sẵn sàng sắp xếp thời gian phỏng vấn.', 30);
GO
INSERT INTO Notifications (UserId, Title, Content, Type, IsRead) VALUES
(57, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 1),
(28, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 0),
(59, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 1),
(30, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 0),
(61, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 1),
(32, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 0),
(63, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 1),
(34, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 0),
(65, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 1),
(36, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 0),
(67, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 1),
(38, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 0),
(69, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 1),
(40, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 0),
(71, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 1),
(42, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 0),
(73, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 1),
(44, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 0),
(75, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 1),
(46, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 0),
(77, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 1),
(48, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 0),
(79, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 1),
(50, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 0),
(81, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 1),
(52, N'Thông báo: Interview', N'Bạn có một lịch phỏng vấn mới được nhà tuyển dụng sắp xếp, vui lòng kiểm tra chi tiết thời gian và địa điểm.', N'Interview', 0),
(83, N'Thông báo: Application', N'Hồ sơ ứng tuyển của bạn vừa được cập nhật trạng thái, hãy vào mục Ứng tuyển để xem chi tiết.', N'Application', 1),
(54, N'Thông báo: Message', N'Bạn vừa nhận được một tin nhắn mới từ nhà tuyển dụng, hãy kiểm tra hộp thư để phản hồi kịp thời.', N'Message', 0),
(85, N'Thông báo: System', N'Hệ thống JobConnect vừa có bản cập nhật mới nhằm cải thiện trải nghiệm tìm việc của bạn.', N'System', 1),
(56, N'Thông báo: NewApplication', N'Có một ứng viên mới vừa nộp hồ sơ ứng tuyển vào tin tuyển dụng của công ty bạn.', N'NewApplication', 0);
GO
INSERT INTO BlogPosts (AuthorID, Title, Slug, Excerpt, Content, IsPublished, PublishedAt, Status) VALUES
(1, N'Top 10 kỹ năng công nghệ được nhà tuyển dụng săn đón năm 2026', N'top-10-kỹ-năng-công-nghệ-được-nhà-tuyển-dụng-săn-đón-năm-2026', N'Các doanh nghiệp Việt Nam đang ưu tiên tuyển dụng nhân sự thành thạo điện toán đám mây, phân tích dữ liệu và bảo mật hệ thống. Bên cạnh kỹ năng chuyên...', N'Các doanh nghiệp Việt Nam đang ưu tiên tuyển dụng nhân sự thành thạo điện toán đám mây, phân tích dữ liệu và bảo mật hệ thống. Bên cạnh kỹ năng chuyên môn, khả năng làm việc với các công cụ tự động hóa và tư duy giải quyết vấn đề cũng ngày càng được đánh giá cao. Ứng viên nên chủ động cập nhật kiến thức qua các khóa học ngắn hạn, dự án cá nhân và chứng chỉ quốc tế để tăng khả năng cạnh tranh trên thị trường lao động.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "top 10 kỹ năng công nghệ được nhà tuyển dụng săn đón năm 2026" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-01-03', 'Published'),
(1, N'Cách viết CV xin việc gây ấn tượng với nhà tuyển dụng', N'cách-viết-cv-xin-việc-gây-ấn-tượng-với-nhà-tuyển-dụng', N'Một CV tốt cần trình bày rõ ràng, ngắn gọn và tập trung vào kết quả công việc thay vì chỉ liệt kê nhiệm vụ. Ứng viên nên sử dụng số liệu cụ thể để chứ...', N'Một CV tốt cần trình bày rõ ràng, ngắn gọn và tập trung vào kết quả công việc thay vì chỉ liệt kê nhiệm vụ. Ứng viên nên sử dụng số liệu cụ thể để chứng minh hiệu quả công việc, đồng thời điều chỉnh nội dung CV phù hợp với từng vị trí ứng tuyển. Tránh các lỗi chính tả, định dạng lộn xộn và thông tin không liên quan để tạo thiện cảm ngay từ cái nhìn đầu tiên.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "cách viết cv xin việc gây ấn tượng với nhà tuyển dụng" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Số liệu từ các nền tảng tuyển dụng cho thấy tin đăng liên quan đến chủ đề này nhận được lượng ứng tuyển cao hơn trung bình khoảng 20-30% so với các tin thông thường.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-02-05', 'Published'),
(1, N'Báo cáo mức lương ngành công nghệ thông tin tại Việt Nam', N'báo-cáo-mức-lương-ngành-công-nghệ-thông-tin-tại-việt-nam', N'Theo khảo sát từ nhiều nguồn tuyển dụng, mức lương của lập trình viên tại Việt Nam tiếp tục tăng trưởng, đặc biệt ở các vị trí liên quan đến điện toán...', N'Theo khảo sát từ nhiều nguồn tuyển dụng, mức lương của lập trình viên tại Việt Nam tiếp tục tăng trưởng, đặc biệt ở các vị trí liên quan đến điện toán đám mây và trí tuệ nhân tạo. Nhân sự có kinh nghiệm từ 3-5 năm thường có mức thu nhập cao hơn đáng kể so với nhóm mới ra trường, và các thành phố lớn như Hà Nội, TP. Hồ Chí Minh vẫn là nơi tập trung nhiều cơ hội việc làm với mức đãi ngộ tốt nhất.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "báo cáo mức lương ngành công nghệ thông tin tại việt nam" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-03-07', 'Published'),
(1, N'Bí quyết phỏng vấn thành công dành cho ứng viên mới ra trường', N'bí-quyết-phỏng-vấn-thành-công-dành-cho-ứng-viên-mới-ra-trường', N'Ứng viên mới ra trường nên chuẩn bị kỹ về thông tin công ty, vị trí ứng tuyển và luyện tập trả lời các câu hỏi phỏng vấn phổ biến. Thái độ tự tin, tru...', N'Ứng viên mới ra trường nên chuẩn bị kỹ về thông tin công ty, vị trí ứng tuyển và luyện tập trả lời các câu hỏi phỏng vấn phổ biến. Thái độ tự tin, trung thực và tinh thần cầu tiến thường được nhà tuyển dụng đánh giá cao hơn là kinh nghiệm làm việc chưa nhiều. Đặt câu hỏi ngược lại cho nhà tuyển dụng cũng là cách thể hiện sự quan tâm nghiêm túc đến công việc.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "bí quyết phỏng vấn thành công dành cho ứng viên mới ra trường" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-04-09', 'Published'),
(1, N'Xu hướng làm việc từ xa và mô hình hybrid tại doanh nghiệp Việt', N'xu-hướng-làm-việc-từ-xa-và-mô-hình-hybrid-tại-doanh-nghiệp-việt', N'Nhiều doanh nghiệp tại Việt Nam đã áp dụng mô hình làm việc kết hợp giữa văn phòng và từ xa nhằm tăng tính linh hoạt cho nhân viên. Mô hình này giúp t...', N'Nhiều doanh nghiệp tại Việt Nam đã áp dụng mô hình làm việc kết hợp giữa văn phòng và từ xa nhằm tăng tính linh hoạt cho nhân viên. Mô hình này giúp tiết kiệm chi phí vận hành, đồng thời đòi hỏi nhân sự có kỹ năng quản lý thời gian và giao tiếp trực tuyến tốt hơn. Xu hướng này được dự đoán sẽ tiếp tục phổ biến trong các ngành công nghệ, marketing và dịch vụ khách hàng.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xu hướng làm việc từ xa và mô hình hybrid tại doanh nghiệp việt" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Theo khảo sát thị trường lao động gần đây, hơn 60% nhà tuyển dụng tại Việt Nam cho biết đây là một trong những yếu tố họ cân nhắc hàng đầu khi đánh giá ứng viên.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-05-11', 'Published'),
(1, N'Xây dựng thương hiệu cá nhân trên mạng xã hội nghề nghiệp', N'xây-dựng-thương-hiệu-cá-nhân-trên-mạng-xã-hội-nghề-nghiệp', N'Việc xây dựng hồ sơ chuyên nghiệp trên các nền tảng mạng xã hội nghề nghiệp giúp ứng viên tăng cơ hội được nhà tuyển dụng chủ động liên hệ. Chia sẻ ki...', N'Việc xây dựng hồ sơ chuyên nghiệp trên các nền tảng mạng xã hội nghề nghiệp giúp ứng viên tăng cơ hội được nhà tuyển dụng chủ động liên hệ. Chia sẻ kiến thức chuyên môn, tham gia thảo luận trong cộng đồng ngành nghề và cập nhật thành tích công việc thường xuyên là những cách hiệu quả để xây dựng uy tín cá nhân trong lĩnh vực đang theo đuổi.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xây dựng thương hiệu cá nhân trên mạng xã hội nghề nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-06-13', 'Published'),
(1, N'Những kỹ năng mềm quan trọng đối với nhân sự ngành công nghệ', N'những-kỹ-năng-mềm-quan-trọng-đối-với-nhân-sự-ngành-công-nghệ', N'Ngoài kiến thức chuyên môn, kỹ năng giao tiếp, làm việc nhóm và quản lý thời gian đóng vai trò quan trọng trong sự phát triển sự nghiệp của nhân sự cô...', N'Ngoài kiến thức chuyên môn, kỹ năng giao tiếp, làm việc nhóm và quản lý thời gian đóng vai trò quan trọng trong sự phát triển sự nghiệp của nhân sự công nghệ. Khả năng trình bày ý tưởng rõ ràng trước đội nhóm và đối tác cũng giúp nhân viên dễ dàng đảm nhận các vị trí quản lý trong tương lai.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những kỹ năng mềm quan trọng đối với nhân sự ngành công nghệ" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-07-15', 'Published'),
(1, N'So sánh mức lương giữa các ngành nghề phổ biến hiện nay', N'so-sánh-mức-lương-giữa-các-ngành-nghề-phổ-biến-hiện-nay', N'Mức lương giữa các ngành nghề tại Việt Nam có sự chênh lệch đáng kể, trong đó công nghệ thông tin, tài chính ngân hàng và một số ngành kỹ thuật cao th...', N'Mức lương giữa các ngành nghề tại Việt Nam có sự chênh lệch đáng kể, trong đó công nghệ thông tin, tài chính ngân hàng và một số ngành kỹ thuật cao thường có mức đãi ngộ tốt hơn mặt bằng chung. Tuy nhiên, mức lương thực tế còn phụ thuộc vào kinh nghiệm, vị trí địa lý và quy mô doanh nghiệp tuyển dụng.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "so sánh mức lương giữa các ngành nghề phổ biến hiện nay" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Số liệu từ các nền tảng tuyển dụng cho thấy tin đăng liên quan đến chủ đề này nhận được lượng ứng tuyển cao hơn trung bình khoảng 20-30% so với các tin thông thường.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-08-17', 'Published'),
(1, N'Kinh nghiệm đàm phán lương khi nhận được lời mời làm việc mới', N'kinh-nghiệm-đàm-phán-lương-khi-nhận-được-lời-mời-làm-việc-mới', N'Trước khi đàm phán lương, ứng viên nên tìm hiểu mặt bằng lương chung của vị trí tương đương trên thị trường để có cơ sở thương lượng hợp lý. Việc trìn...', N'Trước khi đàm phán lương, ứng viên nên tìm hiểu mặt bằng lương chung của vị trí tương đương trên thị trường để có cơ sở thương lượng hợp lý. Việc trình bày rõ giá trị bản thân có thể mang lại cho công ty, kết hợp với thái độ chuyên nghiệp, sẽ giúp quá trình đàm phán diễn ra thuận lợi hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kinh nghiệm đàm phán lương khi nhận được lời mời làm việc mới" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Theo khảo sát thị trường lao động gần đây, hơn 60% nhà tuyển dụng tại Việt Nam cho biết đây là một trong những yếu tố họ cân nhắc hàng đầu khi đánh giá ứng viên.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-09-19', 'Published'),
(1, N'Chuyển ngành sang công nghệ thông tin nên bắt đầu từ đâu', N'chuyển-ngành-sang-công-nghệ-thông-tin-nên-bắt-đầu-từ-đâu', N'Người muốn chuyển ngành sang công nghệ thông tin có thể bắt đầu bằng việc học các ngôn ngữ lập trình phổ biến, tham gia khóa học trực tuyến và xây dựn...', N'Người muốn chuyển ngành sang công nghệ thông tin có thể bắt đầu bằng việc học các ngôn ngữ lập trình phổ biến, tham gia khóa học trực tuyến và xây dựng dự án cá nhân để làm portfolio. Kiên trì luyện tập và tham gia cộng đồng lập trình viên sẽ giúp quá trình chuyển ngành diễn ra nhanh và hiệu quả hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "chuyển ngành sang công nghệ thông tin nên bắt đầu từ đâu" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Theo khảo sát thị trường lao động gần đây, hơn 60% nhà tuyển dụng tại Việt Nam cho biết đây là một trong những yếu tố họ cân nhắc hàng đầu khi đánh giá ứng viên.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-10-21', 'Published'),
(1, N'Khoa học dữ liệu - lĩnh vực được nhiều bạn trẻ quan tâm', N'khoa-học-dữ-liệu-lĩnh-vực-được-nhiều-bạn-trẻ-quan-tâm', N'Khoa học dữ liệu đang trở thành một trong những lĩnh vực có nhu cầu tuyển dụng cao tại Việt Nam nhờ vào sự phát triển của các doanh nghiệp ứng dụng dữ...', N'Khoa học dữ liệu đang trở thành một trong những lĩnh vực có nhu cầu tuyển dụng cao tại Việt Nam nhờ vào sự phát triển của các doanh nghiệp ứng dụng dữ liệu lớn và trí tuệ nhân tạo. Người theo đuổi lĩnh vực này cần trang bị kiến thức về thống kê, lập trình và tư duy phân tích vấn đề.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "khoa học dữ liệu - lĩnh vực được nhiều bạn trẻ quan tâm" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-11-23', 'Published'),
(1, N'Những sai lầm phổ biến khi tìm việc mà ứng viên thường gặp', N'những-sai-lầm-phổ-biến-khi-tìm-việc-mà-ứng-viên-thường-gặp', N'Nhiều ứng viên mắc lỗi nộp hồ sơ hàng loạt mà không tìm hiểu kỹ về công ty, dẫn đến tỷ lệ phản hồi thấp. Việc chuẩn bị CV chung chung, không nêu bật t...', N'Nhiều ứng viên mắc lỗi nộp hồ sơ hàng loạt mà không tìm hiểu kỹ về công ty, dẫn đến tỷ lệ phản hồi thấp. Việc chuẩn bị CV chung chung, không nêu bật thế mạnh cá nhân cũng khiến hồ sơ khó nổi bật giữa hàng trăm ứng viên khác.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những sai lầm phổ biến khi tìm việc mà ứng viên thường gặp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-12-25', 'Published'),
(1, N'Cách tối ưu hồ sơ trên các nền tảng tuyển dụng trực tuyến', N'cách-tối-ưu-hồ-sơ-trên-các-nền-tảng-tuyển-dụng-trực-tuyến', N'Ứng viên nên cập nhật đầy đủ thông tin, sử dụng từ khóa liên quan đến ngành nghề và bổ sung portfolio nếu có để tăng khả năng được nhà tuyển dụng tìm ...', N'Ứng viên nên cập nhật đầy đủ thông tin, sử dụng từ khóa liên quan đến ngành nghề và bổ sung portfolio nếu có để tăng khả năng được nhà tuyển dụng tìm thấy. Việc thường xuyên làm mới hồ sơ cũng giúp tăng thứ hạng hiển thị trên các nền tảng tìm việc.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "cách tối ưu hồ sơ trên các nền tảng tuyển dụng trực tuyến" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Theo khảo sát thị trường lao động gần đây, hơn 60% nhà tuyển dụng tại Việt Nam cho biết đây là một trong những yếu tố họ cân nhắc hàng đầu khi đánh giá ứng viên.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-01-27', 'Published'),
(1, N'Trí tuệ nhân tạo đang thay đổi thị trường tuyển dụng như thế nào', N'trí-tuệ-nhân-tạo-đang-thay-đổi-thị-trường-tuyển-dụng-như-thế-nào', N'Nhiều doanh nghiệp đã ứng dụng công nghệ AI để sàng lọc hồ sơ, phân tích năng lực ứng viên và tối ưu quy trình tuyển dụng. Điều này đòi hỏi ứng viên c...', N'Nhiều doanh nghiệp đã ứng dụng công nghệ AI để sàng lọc hồ sơ, phân tích năng lực ứng viên và tối ưu quy trình tuyển dụng. Điều này đòi hỏi ứng viên cần chuẩn bị hồ sơ rõ ràng, đúng trọng tâm để dễ dàng vượt qua các vòng sàng lọc tự động.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "trí tuệ nhân tạo đang thay đổi thị trường tuyển dụng như thế nào" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-02-02', 'Published'),
(1, N'Kinh nghiệm phỏng vấn tại các tập đoàn lớn', N'kinh-nghiệm-phỏng-vấn-tại-các-tập-đoàn-lớn', N'Quy trình phỏng vấn tại các tập đoàn lớn thường gồm nhiều vòng, từ kiểm tra kiến thức chuyên môn đến đánh giá tư duy giải quyết vấn đề và mức độ phù h...', N'Quy trình phỏng vấn tại các tập đoàn lớn thường gồm nhiều vòng, từ kiểm tra kiến thức chuyên môn đến đánh giá tư duy giải quyết vấn đề và mức độ phù hợp văn hóa doanh nghiệp. Ứng viên nên tìm hiểu kỹ văn hóa công ty và chuẩn bị ví dụ thực tế cho từng vòng phỏng vấn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kinh nghiệm phỏng vấn tại các tập đoàn lớn" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Theo khảo sát thị trường lao động gần đây, hơn 60% nhà tuyển dụng tại Việt Nam cho biết đây là một trong những yếu tố họ cân nhắc hàng đầu khi đánh giá ứng viên.

Dưới đây là một số bước cụ thể mà ứng viên/nhân sự có thể thực hiện ngay để cải thiện tình hình:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Tóm lại, việc chủ động nắm bắt và thích ứng với những thay đổi của thị trường lao động sẽ giúp bạn có lợi thế cạnh tranh rõ rệt, dù bạn đang là người tìm việc hay nhà tuyển dụng. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-03-04', 'Published'),
(1, N'Làm sao để thăng tiến nhanh trong sự nghiệp', N'làm-sao-để-thăng-tiến-nhanh-trong-sự-nghiệp', N'Để thăng tiến nhanh, nhân sự cần chủ động nhận thêm trách nhiệm, không ngừng học hỏi kỹ năng mới và xây dựng mối quan hệ tốt với đồng nghiệp, cấp trên...', N'Để thăng tiến nhanh, nhân sự cần chủ động nhận thêm trách nhiệm, không ngừng học hỏi kỹ năng mới và xây dựng mối quan hệ tốt với đồng nghiệp, cấp trên. Đặt mục tiêu nghề nghiệp rõ ràng theo từng giai đoạn cũng giúp định hướng phát triển sự nghiệp hiệu quả hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "làm sao để thăng tiến nhanh trong sự nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-04-06', 'Published'),
(1, N'Xây dựng lộ trình học tập cho người mới bắt đầu sự nghiệp', N'xây-dựng-lộ-trình-học-tập-cho-người-mới-bắt-đầu-sự-nghiệp', N'Người mới bắt đầu sự nghiệp nên xác định rõ mục tiêu nghề nghiệp, sau đó xây dựng lộ trình học tập theo từng giai đoạn ngắn hạn và dài hạn. Kết hợp gi...', N'Người mới bắt đầu sự nghiệp nên xác định rõ mục tiêu nghề nghiệp, sau đó xây dựng lộ trình học tập theo từng giai đoạn ngắn hạn và dài hạn. Kết hợp giữa học lý thuyết và thực hành dự án thực tế sẽ giúp tích lũy kinh nghiệm nhanh hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xây dựng lộ trình học tập cho người mới bắt đầu sự nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-05-08', 'Published'),
(1, N'Bí quyết cân bằng giữa công việc và cuộc sống cá nhân', N'bí-quyết-cân-bằng-giữa-công-việc-và-cuộc-sống-cá-nhân', N'Việc thiết lập ranh giới rõ ràng giữa thời gian làm việc và thời gian cá nhân giúp nhân sự duy trì hiệu suất làm việc lâu dài mà không bị kiệt sức. Sắ...', N'Việc thiết lập ranh giới rõ ràng giữa thời gian làm việc và thời gian cá nhân giúp nhân sự duy trì hiệu suất làm việc lâu dài mà không bị kiệt sức. Sắp xếp công việc theo mức độ ưu tiên và dành thời gian nghỉ ngơi hợp lý là yếu tố quan trọng để cân bằng cuộc sống.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "bí quyết cân bằng giữa công việc và cuộc sống cá nhân" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-06-10', 'Published'),
(1, N'Những chứng chỉ nghề nghiệp giá trị nên cân nhắc', N'những-chứng-chỉ-nghề-nghiệp-giá-trị-nên-cân-nhắc', N'Các chứng chỉ liên quan đến điện toán đám mây, quản lý dự án và phân tích dữ liệu đang được nhiều nhà tuyển dụng đánh giá cao. Việc lựa chọn chứng chỉ...', N'Các chứng chỉ liên quan đến điện toán đám mây, quản lý dự án và phân tích dữ liệu đang được nhiều nhà tuyển dụng đánh giá cao. Việc lựa chọn chứng chỉ phù hợp với định hướng nghề nghiệp sẽ giúp tăng giá trị hồ sơ ứng tuyển.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những chứng chỉ nghề nghiệp giá trị nên cân nhắc" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-07-12', 'Published'),
(1, N'Chuẩn bị hồ sơ ứng tuyển vị trí làm việc từ xa cho công ty quốc tế', N'chuẩn-bị-hồ-sơ-ứng-tuyển-vị-trí-làm-việc-từ-xa-cho-công-ty-quốc-tế', N'Ứng viên muốn làm việc từ xa cho công ty quốc tế cần chuẩn bị hồ sơ bằng tiếng Anh chuyên nghiệp, thể hiện rõ khả năng làm việc độc lập và giao tiếp q...', N'Ứng viên muốn làm việc từ xa cho công ty quốc tế cần chuẩn bị hồ sơ bằng tiếng Anh chuyên nghiệp, thể hiện rõ khả năng làm việc độc lập và giao tiếp qua các công cụ trực tuyến. Portfolio dự án thực tế cũng là yếu tố giúp tăng độ tin cậy với nhà tuyển dụng nước ngoài.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "chuẩn bị hồ sơ ứng tuyển vị trí làm việc từ xa cho công ty quốc tế" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-08-14', 'Published'),
(1, N'Ngành logistics và cơ hội việc làm trong bối cảnh thương mại điện tử phát triển', N'ngành-logistics-và-cơ-hội-việc-làm-trong-bối-cảnh-thương-mại-điện-tử-phát-triển', N'Sự phát triển mạnh mẽ của thương mại điện tử kéo theo nhu cầu nhân sự ngành logistics tăng cao, đặc biệt ở các vị trí điều phối vận tải và quản lý kho...', N'Sự phát triển mạnh mẽ của thương mại điện tử kéo theo nhu cầu nhân sự ngành logistics tăng cao, đặc biệt ở các vị trí điều phối vận tải và quản lý kho vận. Đây là lĩnh vực được đánh giá có nhiều tiềm năng phát triển trong những năm tới.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "ngành logistics và cơ hội việc làm trong bối cảnh thương mại điện tử phát triển" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Không ít doanh nghiệp đã điều chỉnh chính sách nhân sự, quy trình tuyển dụng để bắt kịp với thay đổi của thị trường lao động hiện nay.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.
Bước 5: Theo dõi sát các tin tuyển dụng, xu hướng thị trường để kịp thời điều chỉnh định hướng nghề nghiệp phù hợp.
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-09-16', 'Published'),
(1, N'Kỹ năng quản lý dự án cần thiết cho nhân sự công nghệ', N'kỹ-năng-quản-lý-dự-án-cần-thiết-cho-nhân-sự-công-nghệ', N'Kỹ năng lập kế hoạch, phân bổ nguồn lực và quản lý rủi ro là những yếu tố quan trọng giúp nhân sự công nghệ đảm nhận tốt vai trò quản lý dự án. Việc s...', N'Kỹ năng lập kế hoạch, phân bổ nguồn lực và quản lý rủi ro là những yếu tố quan trọng giúp nhân sự công nghệ đảm nhận tốt vai trò quản lý dự án. Việc sử dụng thành thạo các công cụ quản lý công việc cũng góp phần nâng cao hiệu quả phối hợp trong đội nhóm.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kỹ năng quản lý dự án cần thiết cho nhân sự công nghệ" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.

Nhiều chuyên gia nhân sự nhận định rằng xu hướng này sẽ còn tiếp tục phát triển mạnh trong 2-3 năm tới, đặc biệt tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh, Đà Nẵng.

Để áp dụng hiệu quả vào thực tế công việc và định hướng nghề nghiệp, bạn có thể tham khảo lộ trình từng bước sau đây:
Bước 2: Lập kế hoạch học tập, trau dồi kỹ năng theo lộ trình cụ thể, ưu tiên những kỹ năng có tính ứng dụng cao và được nhiều nhà tuyển dụng tìm kiếm.
Bước 1: Đánh giá lại năng lực hiện tại của bản thân, xác định rõ điểm mạnh, điểm cần cải thiện so với yêu cầu thực tế của thị trường.
Bước 3: Chủ động tham gia các dự án thực tế, khóa học ngắn hạn hoặc chương trình thực tập để tích lũy kinh nghiệm và minh chứng cụ thể cho CV.
Bước 4: Xây dựng mạng lưới quan hệ (networking) với đồng nghiệp, chuyên gia trong ngành để cập nhật thông tin và cơ hội việc làm mới nhất.

Nhìn chung, đây là xu hướng tất yếu mà cả người lao động và doanh nghiệp đều cần quan tâm để xây dựng chiến lược phát triển nhân sự bền vững trong dài hạn. JobConnect hy vọng những chia sẻ trên sẽ giúp ích cho bạn trong hành trình phát triển sự nghiệp. Đừng quên theo dõi thêm các bài viết khác trên chuyên mục Blog để cập nhật thông tin mới nhất về thị trường tuyển dụng tại Việt Nam.', 1, '2026-10-18', 'Published');

GO
UPDATE BlogPosts SET BlogCode = 'BL' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 6));
GO
INSERT INTO CompanyHighlight (Icon, Title, Description, IsHighlighted, EmployerId) VALUES
(N'🏆', N'Môi trường làm việc chuyên nghiệp', N'Đầu tư mạnh vào đào tạo và phát triển nhân sự nội bộ', 1, 1),
(N'🌍', N'Đối tác khách hàng đa dạng', N'Hợp tác với nhiều khách hàng trong và ngoài nước', 1, 2),
(N'🚀', N'Tăng trưởng nhanh', N'Quy mô nhân sự và doanh thu tăng trưởng ổn định qua các năm', 1, 3),
(N'💳', N'Nền tảng công nghệ hiện đại', N'Đầu tư hệ thống công nghệ phục vụ hàng triệu người dùng', 1, 4),
(N'💰', N'Tài chính ổn định', N'Có nền tảng tài chính vững chắc, đảm bảo quyền lợi nhân viên', 1, 5),
(N'🎯', N'Văn hóa doanh nghiệp gắn kết', N'Xây dựng môi trường làm việc cởi mở, tôn trọng sự khác biệt', 1, 6),
(N'📈', N'Lộ trình thăng tiến rõ ràng', N'Có chính sách đánh giá và thăng tiến minh bạch theo năng lực', 1, 7),
(N'🎓', N'Chương trình đào tạo bài bản', N'Tổ chức đào tạo định kỳ cho nhân viên mới và nhân viên hiện tại', 1, 8),
(N'🏥', N'Phúc lợi toàn diện', N'Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân', 1, 9),
(N'🌟', N'Quan hệ đối tác chiến lược', N'Hợp tác lâu dài với các đối tác uy tín trong ngành', 1, 10),
(N'🏆', N'Môi trường làm việc chuyên nghiệp', N'Đầu tư mạnh vào đào tạo và phát triển nhân sự nội bộ', 1, 11),
(N'🌍', N'Đối tác khách hàng đa dạng', N'Hợp tác với nhiều khách hàng trong và ngoài nước', 1, 12),
(N'🚀', N'Tăng trưởng nhanh', N'Quy mô nhân sự và doanh thu tăng trưởng ổn định qua các năm', 1, 13),
(N'💳', N'Nền tảng công nghệ hiện đại', N'Đầu tư hệ thống công nghệ phục vụ hàng triệu người dùng', 1, 14),
(N'💰', N'Tài chính ổn định', N'Có nền tảng tài chính vững chắc, đảm bảo quyền lợi nhân viên', 1, 15),
(N'🎯', N'Văn hóa doanh nghiệp gắn kết', N'Xây dựng môi trường làm việc cởi mở, tôn trọng sự khác biệt', 1, 16),
(N'📈', N'Lộ trình thăng tiến rõ ràng', N'Có chính sách đánh giá và thăng tiến minh bạch theo năng lực', 1, 17),
(N'🎓', N'Chương trình đào tạo bài bản', N'Tổ chức đào tạo định kỳ cho nhân viên mới và nhân viên hiện tại', 1, 18),
(N'🏥', N'Phúc lợi toàn diện', N'Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân', 1, 19),
(N'🌟', N'Quan hệ đối tác chiến lược', N'Hợp tác lâu dài với các đối tác uy tín trong ngành', 1, 20),
(N'🏆', N'Môi trường làm việc chuyên nghiệp', N'Đầu tư mạnh vào đào tạo và phát triển nhân sự nội bộ', 1, 21),
(N'🌍', N'Đối tác khách hàng đa dạng', N'Hợp tác với nhiều khách hàng trong và ngoài nước', 1, 22),
(N'🚀', N'Tăng trưởng nhanh', N'Quy mô nhân sự và doanh thu tăng trưởng ổn định qua các năm', 1, 23),
(N'💳', N'Nền tảng công nghệ hiện đại', N'Đầu tư hệ thống công nghệ phục vụ hàng triệu người dùng', 1, 24),
(N'💰', N'Tài chính ổn định', N'Có nền tảng tài chính vững chắc, đảm bảo quyền lợi nhân viên', 1, 25),
(N'🎯', N'Văn hóa doanh nghiệp gắn kết', N'Xây dựng môi trường làm việc cởi mở, tôn trọng sự khác biệt', 1, 26),
(N'📈', N'Lộ trình thăng tiến rõ ràng', N'Có chính sách đánh giá và thăng tiến minh bạch theo năng lực', 1, 27),
(N'🎓', N'Chương trình đào tạo bài bản', N'Tổ chức đào tạo định kỳ cho nhân viên mới và nhân viên hiện tại', 1, 28),
(N'🏥', N'Phúc lợi toàn diện', N'Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân', 1, 29),
(N'🌟', N'Quan hệ đối tác chiến lược', N'Hợp tác lâu dài với các đối tác uy tín trong ngành', 1, 30);
GO
INSERT INTO SupportTickets (UserId, Type, Subject, Message, Status, AssignedToStaffId, Priority, StaffResponse, AssignedAt, ResolvedAt) VALUES
(28, 1, N'Không đăng nhập được tài khoản', N'Chi tiết yêu cầu hỗ trợ số 1: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không đăng nhập được tài khoản''.', 1, 2, 1, NULL, '2026-06-02 09:00:00', NULL),
(59, 2, N'Tin tuyển dụng bị từ chối duyệt', N'Chi tiết yêu cầu hỗ trợ số 2: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Tin tuyển dụng bị từ chối duyệt''.', 2, 3, 2, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-03 09:00:00', '2026-06-03 11:00:00'),
(30, 3, N'Yêu cầu xóa tài khoản', N'Chi tiết yêu cầu hỗ trợ số 3: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu xóa tài khoản''.', 0, NULL, 3, NULL, NULL, NULL),
(61, 0, N'Không thể nâng cấp gói dịch vụ', N'Chi tiết yêu cầu hỗ trợ số 4: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không thể nâng cấp gói dịch vụ''.', 1, 5, 0, NULL, '2026-06-05 09:00:00', NULL),
(32, 1, N'Không nhận được thông báo phỏng vấn', N'Chi tiết yêu cầu hỗ trợ số 5: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không nhận được thông báo phỏng vấn''.', 2, 6, 1, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-06 09:00:00', '2026-06-06 11:00:00'),
(63, 2, N'Lỗi khi tải CV lên hệ thống', N'Chi tiết yêu cầu hỗ trợ số 6: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Lỗi khi tải CV lên hệ thống''.', 0, NULL, 2, NULL, NULL, NULL),
(34, 3, N'Thắc mắc về chính sách hoàn tiền', N'Chi tiết yêu cầu hỗ trợ số 7: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Thắc mắc về chính sách hoàn tiền''.', 1, 8, 3, NULL, '2026-06-08 09:00:00', NULL),
(65, 0, N'Yêu cầu hỗ trợ xác minh doanh nghiệp', N'Chi tiết yêu cầu hỗ trợ số 8: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu hỗ trợ xác minh doanh nghiệp''.', 2, 9, 0, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-09 09:00:00', '2026-06-09 11:00:00'),
(36, 1, N'Không đăng nhập được tài khoản', N'Chi tiết yêu cầu hỗ trợ số 9: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không đăng nhập được tài khoản''.', 0, NULL, 1, NULL, NULL, NULL),
(67, 2, N'Tin tuyển dụng bị từ chối duyệt', N'Chi tiết yêu cầu hỗ trợ số 10: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Tin tuyển dụng bị từ chối duyệt''.', 1, 11, 2, NULL, '2026-06-11 09:00:00', NULL),
(38, 3, N'Yêu cầu xóa tài khoản', N'Chi tiết yêu cầu hỗ trợ số 11: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu xóa tài khoản''.', 2, 12, 3, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-12 09:00:00', '2026-06-12 11:00:00'),
(69, 0, N'Không thể nâng cấp gói dịch vụ', N'Chi tiết yêu cầu hỗ trợ số 12: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không thể nâng cấp gói dịch vụ''.', 0, NULL, 0, NULL, NULL, NULL),
(40, 1, N'Không nhận được thông báo phỏng vấn', N'Chi tiết yêu cầu hỗ trợ số 13: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không nhận được thông báo phỏng vấn''.', 1, 14, 1, NULL, '2026-06-14 09:00:00', NULL),
(71, 2, N'Lỗi khi tải CV lên hệ thống', N'Chi tiết yêu cầu hỗ trợ số 14: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Lỗi khi tải CV lên hệ thống''.', 2, 15, 2, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-15 09:00:00', '2026-06-15 11:00:00'),
(42, 3, N'Thắc mắc về chính sách hoàn tiền', N'Chi tiết yêu cầu hỗ trợ số 15: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Thắc mắc về chính sách hoàn tiền''.', 0, NULL, 3, NULL, NULL, NULL),
(73, 0, N'Yêu cầu hỗ trợ xác minh doanh nghiệp', N'Chi tiết yêu cầu hỗ trợ số 16: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu hỗ trợ xác minh doanh nghiệp''.', 1, 17, 0, NULL, '2026-06-17 09:00:00', NULL),
(44, 1, N'Không đăng nhập được tài khoản', N'Chi tiết yêu cầu hỗ trợ số 17: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không đăng nhập được tài khoản''.', 2, 18, 1, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-18 09:00:00', '2026-06-18 11:00:00'),
(75, 2, N'Tin tuyển dụng bị từ chối duyệt', N'Chi tiết yêu cầu hỗ trợ số 18: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Tin tuyển dụng bị từ chối duyệt''.', 0, NULL, 2, NULL, NULL, NULL),
(46, 3, N'Yêu cầu xóa tài khoản', N'Chi tiết yêu cầu hỗ trợ số 19: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu xóa tài khoản''.', 1, 20, 3, NULL, '2026-06-20 09:00:00', NULL),
(77, 0, N'Không thể nâng cấp gói dịch vụ', N'Chi tiết yêu cầu hỗ trợ số 20: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không thể nâng cấp gói dịch vụ''.', 2, 21, 0, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-21 09:00:00', '2026-06-21 11:00:00'),
(48, 1, N'Không nhận được thông báo phỏng vấn', N'Chi tiết yêu cầu hỗ trợ số 21: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không nhận được thông báo phỏng vấn''.', 0, NULL, 1, NULL, NULL, NULL),
(79, 2, N'Lỗi khi tải CV lên hệ thống', N'Chi tiết yêu cầu hỗ trợ số 22: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Lỗi khi tải CV lên hệ thống''.', 1, 23, 2, NULL, '2026-06-23 09:00:00', NULL),
(50, 3, N'Thắc mắc về chính sách hoàn tiền', N'Chi tiết yêu cầu hỗ trợ số 23: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Thắc mắc về chính sách hoàn tiền''.', 2, 24, 3, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-24 09:00:00', '2026-06-24 11:00:00'),
(81, 0, N'Yêu cầu hỗ trợ xác minh doanh nghiệp', N'Chi tiết yêu cầu hỗ trợ số 24: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu hỗ trợ xác minh doanh nghiệp''.', 0, NULL, 0, NULL, NULL, NULL),
(52, 1, N'Không đăng nhập được tài khoản', N'Chi tiết yêu cầu hỗ trợ số 25: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không đăng nhập được tài khoản''.', 1, 1, 1, NULL, '2026-06-26 09:00:00', NULL),
(83, 2, N'Tin tuyển dụng bị từ chối duyệt', N'Chi tiết yêu cầu hỗ trợ số 26: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Tin tuyển dụng bị từ chối duyệt''.', 2, 2, 2, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-27 09:00:00', '2026-06-27 11:00:00'),
(54, 3, N'Yêu cầu xóa tài khoản', N'Chi tiết yêu cầu hỗ trợ số 27: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Yêu cầu xóa tài khoản''.', 0, NULL, 3, NULL, NULL, NULL),
(85, 0, N'Không thể nâng cấp gói dịch vụ', N'Chi tiết yêu cầu hỗ trợ số 28: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không thể nâng cấp gói dịch vụ''.', 1, 4, 0, NULL, '2026-06-02 09:00:00', NULL),
(56, 1, N'Không nhận được thông báo phỏng vấn', N'Chi tiết yêu cầu hỗ trợ số 29: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Không nhận được thông báo phỏng vấn''.', 2, 5, 1, N'Yêu cầu của bạn đã được đội ngũ hỗ trợ xử lý thành công, cảm ơn bạn đã phản hồi.', '2026-06-03 09:00:00', '2026-06-03 11:00:00'),
(57, 2, N'Lỗi khi tải CV lên hệ thống', N'Chi tiết yêu cầu hỗ trợ số 30: người dùng cần được giải đáp và xử lý vấn đề liên quan đến ''Lỗi khi tải CV lên hệ thống''.', 0, NULL, 2, NULL, NULL, NULL);
GO
INSERT INTO Reports (ReporterId, ReporterType, ReportType, JobPostId, CompanyId, ReportedEntityName, Reason, Description, Status, ProcessedByStaffId, ProcessNote, ProcessedAt) VALUES
(28, 2, 2, NULL, 2, N'Công ty TNHH Giải pháp Số Hưng Thịnh', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 1.', 1, 2, NULL, NULL),
(59, 1, 3, NULL, NULL, N'candidate03@gmail.com', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 2.', 2, 3, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-03 15:00:00'),
(30, 2, 1, 4, NULL, N'Tin tuyển dụng #4', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 3.', 0, NULL, NULL, NULL),
(61, 1, 2, NULL, 5, N'Công ty TNHH Bán lẻ Trực tuyến Minh Long', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 4.', 1, 5, NULL, NULL),
(32, 2, 3, NULL, NULL, N'candidate06@gmail.com', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 5.', 2, 6, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-06 15:00:00'),
(63, 1, 1, 7, NULL, N'Tin tuyển dụng #7', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 6.', 0, NULL, NULL, NULL),
(34, 2, 2, NULL, 8, N'Ngân hàng TMCP Kỹ Nghệ Việt', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 7.', 1, 8, NULL, NULL),
(65, 1, 3, NULL, NULL, N'candidate09@gmail.com', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 8.', 2, 9, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-09 15:00:00'),
(36, 2, 1, 10, NULL, N'Tin tuyển dụng #10', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 9.', 0, NULL, NULL, NULL),
(67, 1, 2, NULL, 11, N'Tập đoàn Công nghệ Bình Minh', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 10.', 1, 11, NULL, NULL),
(38, 2, 3, NULL, NULL, N'candidate12@gmail.com', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 11.', 2, 12, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-12 15:00:00'),
(69, 1, 1, 13, NULL, N'Tin tuyển dụng #13', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 12.', 0, NULL, NULL, NULL),
(40, 2, 2, NULL, 14, N'Công ty CP Hàng không Cánh Việt', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 13.', 1, 14, NULL, NULL),
(71, 1, 3, NULL, NULL, N'candidate15@gmail.com', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 14.', 2, 15, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-15 15:00:00'),
(42, 2, 1, 16, NULL, N'Tin tuyển dụng #16', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 15.', 0, NULL, NULL, NULL),
(73, 1, 2, NULL, 17, N'Công ty TNHH Phần mềm Toàn Cầu Việt', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 16.', 1, 17, NULL, NULL),
(44, 2, 3, NULL, NULL, N'candidate18@gmail.com', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 17.', 2, 18, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-18 15:00:00'),
(75, 1, 1, 19, NULL, N'Tin tuyển dụng #19', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 18.', 0, NULL, NULL, NULL),
(46, 2, 2, NULL, 20, N'Công ty CP Ô tô Điện Việt Phong', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 19.', 1, 20, NULL, NULL),
(77, 1, 3, NULL, NULL, N'candidate21@gmail.com', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 20.', 2, 21, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-21 15:00:00'),
(48, 2, 1, 22, NULL, N'Tin tuyển dụng #22', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 21.', 0, NULL, NULL, NULL),
(79, 1, 2, NULL, 23, N'Công ty CP Giáo dục Trí Việt', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 22.', 1, 23, NULL, NULL),
(50, 2, 3, NULL, NULL, N'candidate24@gmail.com', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 23.', 2, 24, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-24 15:00:00'),
(81, 1, 1, 25, NULL, N'Tin tuyển dụng #25', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 24.', 0, NULL, NULL, NULL),
(52, 2, 2, NULL, 26, N'Công ty CP Bán lẻ Điện máy Phú Cường', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 25.', 1, 1, NULL, NULL),
(83, 1, 3, NULL, NULL, N'candidate27@gmail.com', N'Tin đăng có dấu hiệu lừa đảo', N'Mô tả chi tiết báo cáo số 26.', 2, 2, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-27 15:00:00'),
(54, 2, 1, 28, NULL, N'Tin tuyển dụng #28', N'Thông tin công ty không chính xác', N'Mô tả chi tiết báo cáo số 27.', 0, NULL, NULL, NULL),
(85, 1, 2, NULL, 29, N'Công ty CP Năng lượng Xanh Toàn Cầu', N'Mô tả công việc gây hiểu lầm', N'Mô tả chi tiết báo cáo số 28.', 1, 4, NULL, NULL),
(56, 2, 3, NULL, NULL, N'candidate30@gmail.com', N'Ứng viên cung cấp CV giả mạo', N'Mô tả chi tiết báo cáo số 29.', 2, 5, N'Đã xác minh và xử lý báo cáo theo quy trình nội bộ.', '2026-06-03 15:00:00'),
(57, 1, 1, 31, NULL, N'Tin tuyển dụng #31', N'Nội dung vi phạm chính sách nền tảng', N'Mô tả chi tiết báo cáo số 30.', 0, NULL, NULL, NULL);
GO
INSERT INTO ActivityLogs (StaffId, Action, Description, IpAddress, UserAgent) VALUES
(1, N'Xử lý báo cáo', N'Nhân viên thực hiện thao tác: Xử lý báo cáo (bản ghi số 1).', '192.168.1.10', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(2, N'Duyệt tin tuyển dụng', N'Nhân viên thực hiện thao tác: Duyệt tin tuyển dụng (bản ghi số 2).', '192.168.1.11', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(3, N'Xử lý ticket hỗ trợ', N'Nhân viên thực hiện thao tác: Xử lý ticket hỗ trợ (bản ghi số 3).', '192.168.1.12', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(4, N'Xác minh doanh nghiệp', N'Nhân viên thực hiện thao tác: Xác minh doanh nghiệp (bản ghi số 4).', '192.168.1.13', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(5, N'Khóa tài khoản vi phạm', N'Nhân viên thực hiện thao tác: Khóa tài khoản vi phạm (bản ghi số 5).', '192.168.1.14', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(6, N'Xử lý báo cáo', N'Nhân viên thực hiện thao tác: Xử lý báo cáo (bản ghi số 6).', '192.168.1.15', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(7, N'Duyệt tin tuyển dụng', N'Nhân viên thực hiện thao tác: Duyệt tin tuyển dụng (bản ghi số 7).', '192.168.1.16', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(8, N'Xử lý ticket hỗ trợ', N'Nhân viên thực hiện thao tác: Xử lý ticket hỗ trợ (bản ghi số 8).', '192.168.1.17', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(9, N'Xác minh doanh nghiệp', N'Nhân viên thực hiện thao tác: Xác minh doanh nghiệp (bản ghi số 9).', '192.168.1.18', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(10, N'Khóa tài khoản vi phạm', N'Nhân viên thực hiện thao tác: Khóa tài khoản vi phạm (bản ghi số 10).', '192.168.1.19', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(11, N'Xử lý báo cáo', N'Nhân viên thực hiện thao tác: Xử lý báo cáo (bản ghi số 11).', '192.168.1.20', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(12, N'Duyệt tin tuyển dụng', N'Nhân viên thực hiện thao tác: Duyệt tin tuyển dụng (bản ghi số 12).', '192.168.1.21', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(13, N'Xử lý ticket hỗ trợ', N'Nhân viên thực hiện thao tác: Xử lý ticket hỗ trợ (bản ghi số 13).', '192.168.1.22', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(14, N'Xác minh doanh nghiệp', N'Nhân viên thực hiện thao tác: Xác minh doanh nghiệp (bản ghi số 14).', '192.168.1.23', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(15, N'Khóa tài khoản vi phạm', N'Nhân viên thực hiện thao tác: Khóa tài khoản vi phạm (bản ghi số 15).', '192.168.1.24', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(16, N'Xử lý báo cáo', N'Nhân viên thực hiện thao tác: Xử lý báo cáo (bản ghi số 16).', '192.168.1.25', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(17, N'Duyệt tin tuyển dụng', N'Nhân viên thực hiện thao tác: Duyệt tin tuyển dụng (bản ghi số 17).', '192.168.1.26', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(18, N'Xử lý ticket hỗ trợ', N'Nhân viên thực hiện thao tác: Xử lý ticket hỗ trợ (bản ghi số 18).', '192.168.1.27', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(19, N'Xác minh doanh nghiệp', N'Nhân viên thực hiện thao tác: Xác minh doanh nghiệp (bản ghi số 19).', '192.168.1.28', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(20, N'Khóa tài khoản vi phạm', N'Nhân viên thực hiện thao tác: Khóa tài khoản vi phạm (bản ghi số 20).', '192.168.1.29', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(21, N'Xử lý báo cáo', N'Nhân viên thực hiện thao tác: Xử lý báo cáo (bản ghi số 21).', '192.168.1.30', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(22, N'Duyệt tin tuyển dụng', N'Nhân viên thực hiện thao tác: Duyệt tin tuyển dụng (bản ghi số 22).', '192.168.1.31', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(23, N'Xử lý ticket hỗ trợ', N'Nhân viên thực hiện thao tác: Xử lý ticket hỗ trợ (bản ghi số 23).', '192.168.1.32', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(24, N'Xác minh doanh nghiệp', N'Nhân viên thực hiện thao tác: Xác minh doanh nghiệp (bản ghi số 24).', '192.168.1.33', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)'),
(25, N'Khóa tài khoản vi phạm', N'Nhân viên thực hiện thao tác: Khóa tài khoản vi phạm (bản ghi số 25).', '192.168.1.34', N'Mozilla/5.0 (compatible; JobConnectStaffClient/1.0)');
GO
INSERT INTO SystemLogs (UserId, Action, IPAddress, Detail) VALUES
(1, 'Admin_Login', '113.161.1.7', N'Sự kiện hệ thống ghi nhận: Admin_Login (log #1).'),
(2, 'Staff_Login', '113.161.2.14', N'Sự kiện hệ thống ghi nhận: Staff_Login (log #2).'),
(3, 'Employer_PostJob', '113.161.3.21', N'Sự kiện hệ thống ghi nhận: Employer_PostJob (log #3).'),
(4, 'Candidate_Apply', '113.161.4.28', N'Sự kiện hệ thống ghi nhận: Candidate_Apply (log #4).'),
(5, 'Employer_Login', '113.161.5.35', N'Sự kiện hệ thống ghi nhận: Employer_Login (log #5).'),
(6, 'Candidate_Login', '113.161.6.42', N'Sự kiện hệ thống ghi nhận: Candidate_Login (log #6).'),
(7, 'Admin_Login', '113.161.7.49', N'Sự kiện hệ thống ghi nhận: Admin_Login (log #7).'),
(8, 'Staff_Login', '113.161.8.56', N'Sự kiện hệ thống ghi nhận: Staff_Login (log #8).'),
(9, 'Employer_PostJob', '113.161.9.63', N'Sự kiện hệ thống ghi nhận: Employer_PostJob (log #9).'),
(10, 'Candidate_Apply', '113.161.10.70', N'Sự kiện hệ thống ghi nhận: Candidate_Apply (log #10).'),
(11, 'Employer_Login', '113.161.11.77', N'Sự kiện hệ thống ghi nhận: Employer_Login (log #11).'),
(12, 'Candidate_Login', '113.161.12.84', N'Sự kiện hệ thống ghi nhận: Candidate_Login (log #12).'),
(13, 'Admin_Login', '113.161.13.91', N'Sự kiện hệ thống ghi nhận: Admin_Login (log #13).'),
(14, 'Staff_Login', '113.161.14.98', N'Sự kiện hệ thống ghi nhận: Staff_Login (log #14).'),
(15, 'Employer_PostJob', '113.161.15.105', N'Sự kiện hệ thống ghi nhận: Employer_PostJob (log #15).'),
(16, 'Candidate_Apply', '113.161.16.112', N'Sự kiện hệ thống ghi nhận: Candidate_Apply (log #16).'),
(17, 'Employer_Login', '113.161.17.119', N'Sự kiện hệ thống ghi nhận: Employer_Login (log #17).'),
(18, 'Candidate_Login', '113.161.18.126', N'Sự kiện hệ thống ghi nhận: Candidate_Login (log #18).'),
(19, 'Admin_Login', '113.161.19.133', N'Sự kiện hệ thống ghi nhận: Admin_Login (log #19).'),
(20, 'Staff_Login', '113.161.0.140', N'Sự kiện hệ thống ghi nhận: Staff_Login (log #20).'),
(21, 'Employer_PostJob', '113.161.1.147', N'Sự kiện hệ thống ghi nhận: Employer_PostJob (log #21).'),
(22, 'Candidate_Apply', '113.161.2.154', N'Sự kiện hệ thống ghi nhận: Candidate_Apply (log #22).'),
(23, 'Employer_Login', '113.161.3.161', N'Sự kiện hệ thống ghi nhận: Employer_Login (log #23).'),
(24, 'Candidate_Login', '113.161.4.168', N'Sự kiện hệ thống ghi nhận: Candidate_Login (log #24).'),
(25, 'Admin_Login', '113.161.5.175', N'Sự kiện hệ thống ghi nhận: Admin_Login (log #25).'),
(26, 'Staff_Login', '113.161.6.182', N'Sự kiện hệ thống ghi nhận: Staff_Login (log #26).'),
(27, 'Employer_PostJob', '113.161.7.189', N'Sự kiện hệ thống ghi nhận: Employer_PostJob (log #27).'),
(28, 'Candidate_Apply', '113.161.8.196', N'Sự kiện hệ thống ghi nhận: Candidate_Apply (log #28).'),
(29, 'Employer_Login', '113.161.9.203', N'Sự kiện hệ thống ghi nhận: Employer_Login (log #29).'),
(30, 'Candidate_Login', '113.161.10.210', N'Sự kiện hệ thống ghi nhận: Candidate_Login (log #30).');
GO
INSERT INTO PasswordResetTokens (Email, Code, ExpiresAt, IsUsed) VALUES
(N'candidate01@gmail.com', '104321', '2026-07-02 09:11:00', 1),
(N'candidate02@gmail.com', '108642', '2026-07-03 09:12:00', 0),
(N'candidate03@gmail.com', '112963', '2026-07-04 09:13:00', 1),
(N'candidate04@gmail.com', '117284', '2026-07-05 09:14:00', 0),
(N'candidate05@gmail.com', '121605', '2026-07-06 09:15:00', 1),
(N'candidate06@gmail.com', '125926', '2026-07-07 09:16:00', 0),
(N'candidate07@gmail.com', '130247', '2026-07-08 09:17:00', 1),
(N'candidate08@gmail.com', '134568', '2026-07-09 09:18:00', 0),
(N'candidate09@gmail.com', '138889', '2026-07-10 09:19:00', 1),
(N'candidate10@gmail.com', '143210', '2026-07-11 09:20:00', 0),
(N'candidate11@gmail.com', '147531', '2026-07-12 09:21:00', 1),
(N'candidate12@gmail.com', '151852', '2026-07-13 09:22:00', 0),
(N'candidate13@gmail.com', '156173', '2026-07-14 09:23:00', 1),
(N'candidate14@gmail.com', '160494', '2026-07-15 09:24:00', 0),
(N'candidate15@gmail.com', '164815', '2026-07-16 09:25:00', 1),
(N'candidate16@gmail.com', '169136', '2026-07-17 09:26:00', 0),
(N'candidate17@gmail.com', '173457', '2026-07-18 09:27:00', 1),
(N'candidate18@gmail.com', '177778', '2026-07-19 09:28:00', 0),
(N'candidate19@gmail.com', '182099', '2026-07-20 09:29:00', 1),
(N'candidate20@gmail.com', '186420', '2026-07-21 09:30:00', 0),
(N'candidate21@gmail.com', '190741', '2026-07-22 09:31:00', 1),
(N'candidate22@gmail.com', '195062', '2026-07-23 09:32:00', 0),
(N'candidate23@gmail.com', '199383', '2026-07-24 09:33:00', 1),
(N'candidate24@gmail.com', '203704', '2026-07-25 09:34:00', 0),
(N'candidate25@gmail.com', '208025', '2026-07-26 09:35:00', 1),
(N'candidate26@gmail.com', '212346', '2026-07-27 09:36:00', 0),
(N'candidate27@gmail.com', '216667', '2026-07-01 09:37:00', 1),
(N'candidate28@gmail.com', '220988', '2026-07-02 09:38:00', 0),
(N'candidate29@gmail.com', '225309', '2026-07-03 09:39:00', 1),
(N'candidate30@gmail.com', '229630', '2026-07-04 09:40:00', 0);
GO