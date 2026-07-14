/* =========================================================
   JobConnectDB13 - XOA VA TAO LAI HOAN TOAN TU DAU
   CANH BAO: Script nay se XOA SACH du lieu cu trong JobConnectDB13
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

IF DB_ID('JobConnectDB21') IS NOT NULL
BEGIN
    ALTER DATABASE JobConnectDB21 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JobConnectDB21;
END
GO

CREATE DATABASE JobConnectDB21;
GO

USE JobConnectDB21;
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

/* ================= SERVICE PACKAGES ================= */
CREATE TABLE ServicePackages (
    PackageID       INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(150) NOT NULL,
    Price           DECIMAL(15,0) NOT NULL,
    DurationDays    INT NOT NULL,
    MaxJobPosts     INT NOT NULL,
    MaxFeatured     INT NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    IsActive        BIT NOT NULL DEFAULT 1
);
GO

/* ================= TRANSACTIONS ================= */
CREATE TABLE Transactions (
    TransID         INT IDENTITY(1,1) PRIMARY KEY,
    EmployerId      INT NOT NULL,
    PackageID       INT NOT NULL,
    Amount          DECIMAL(15,0) NOT NULL,
    PaymentMethod   NVARCHAR(50) NOT NULL,
    Status          NVARCHAR(50) NOT NULL,
    ExpiredAt       DATETIME2 NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Transactions_Employer FOREIGN KEY (EmployerId) REFERENCES Employers(EmployerId),
    CONSTRAINT FK_Transactions_Package FOREIGN KEY (PackageID) REFERENCES ServicePackages(PackageID)
);
CREATE INDEX IX_Transactions_EmployerId ON Transactions(EmployerId);
CREATE INDEX IX_Transactions_PackageID ON Transactions(PackageID);
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

ALTER DATABASE JobConnectDB13 SET MULTI_USER;
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
(1, N'Backend Developer', 'JobType', N'backend-developer', N'Lập trình viên backend'),
(1, N'Frontend Developer', 'JobType', N'frontend-developer', N'Lập trình viên frontend'),
(1, N'DevOps / Cloud Engineer', 'JobType', N'devops-cloud-engineer', N'DevOps, Cloud engineer'),
(1, N'Mobile Developer', 'JobType', N'mobile-developer', N'Lập trình viên di động'),
(1, N'Data Engineer / Analyst', 'JobType', N'data-engineer-analyst', N'Kỹ sư/Chuyên viên dữ liệu'),
(1, N'QA/QC Engineer', 'JobType', N'qa-qc-engineer', N'Kiểm thử phần mềm'),
(2, N'Kế toán tổng hợp', 'JobType', N'ke-toan-tong-hop', N'Kế toán tổng hợp'),
(2, N'Chuyên viên tài chính', 'JobType', N'chuyen-vien-tai-chinh', N'Phân tích tài chính'),
(2, N'Giao dịch viên ngân hàng', 'JobType', N'giao-dich-vien-ngan-hang', N'Giao dịch viên'),
(3, N'Digital Marketing', 'JobType', N'digital-marketing', N'Digital Marketing specialist'),
(3, N'Content Creator', 'JobType', N'content-creator', N'Sáng tạo nội dung'),
(3, N'SEO Specialist', 'JobType', N'seo-specialist', N'Chuyên viên SEO'),
(4, N'Nhân viên kinh doanh', 'JobType', N'nhan-vien-kinh-doanh', N'Sales, kinh doanh'),
(4, N'Quản lý cửa hàng', 'JobType', N'quan-ly-cua-hang', N'Quản lý bán lẻ'),
(5, N'Chuyên viên tuyển dụng', 'JobType', N'chuyen-vien-tuyen-dung', N'Tuyển dụng nhân sự'),
(5, N'Hành chính nhân sự', 'JobType', N'hanh-chinh-nhan-su', N'Hành chính - Nhân sự tổng hợp'),
(7, N'Nhân viên logistics', 'JobType', N'nhan-vien-logistics', N'Điều phối vận tải, kho vận'),
(8, N'Dược sĩ', 'JobType', N'duoc-si', N'Dược sĩ nhà thuốc, bệnh viện'),
(9, N'Giáo viên - Giảng viên', 'JobType', N'giao-vien-giang-vien', N'Giảng dạy, đào tạo'),
(10, N'Kỹ sư xây dựng', 'JobType', N'ky-su-xay-dung', N'Kỹ sư giám sát công trình');
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
(N'Kubernetes', N'Điều phối container', 1, 1),
(N'Node.js', N'Môi trường chạy JS phía server', 1, 1),
(N'AWS', N'Điện toán đám mây Amazon', 1, 1),
(N'Excel nâng cao', N'Kỹ năng Excel nâng cao', 2, 1),
(N'Phân tích tài chính', N'Phân tích báo cáo tài chính', 2, 1),
(N'Kế toán thuế', N'Nghiệp vụ kế toán thuế', 2, 1),
(N'Google Ads', N'Quảng cáo Google Ads', 3, 1),
(N'SEO', N'Tối ưu công cụ tìm kiếm', 3, 1),
(N'Facebook Ads', N'Quảng cáo Facebook Ads', 3, 1),
(N'Content Marketing', N'Xây dựng nội dung marketing', 3, 1),
(N'Đàm phán', N'Kỹ năng đàm phán kinh doanh', 4, 1),
(N'Chăm sóc khách hàng', N'Kỹ năng CSKH', 4, 1),
(N'Tuyển dụng', N'Kỹ năng tuyển dụng nhân sự', 5, 1),
(N'Quản lý dự án', N'Kỹ năng quản lý dự án', 1, 1),
(N'Kiểm thử phần mềm', N'Kiểm thử QA/QC', 1, 1),
(N'Logistics', N'Điều phối vận tải kho vận', 7, 1),
(N'Dược lâm sàng', N'Kiến thức dược lâm sàng', 8, 1),
(N'Thiết kế UI/UX', N'Thiết kế trải nghiệm người dùng', 1, 1);
GO
INSERT INTO Employers (UserId, CompanyName, TaxCode, Industry, CompanySize, Address, Website, IsVerified, Status, Description, WhyWorkHereJson) VALUES
(27, N'Công ty CP Công nghệ Sao Việt', N'90000001', N'Công nghệ thông tin', N'500-1000', N'Số 17 đường Nguyễn Trãi, Quận 1, Hà Nội', N'https://côngtycpcôngnghệsa.vn', 1, N'Active', N'Phát triển phần mềm và giải pháp doanh nghiệp cho khách hàng trong và ngoài nước, tập trung vào các dự án outsourcing và sản phẩm SaaS.

Được thành lập từ năm 2006 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(28, N'Công ty TNHH Giải pháp Số Hưng Thịnh', N'90000002', N'Công nghệ thông tin', N'100-500', N'Số 24 đường Lê Lợi, Quận 3, TP. Hồ Chí Minh', N'https://côngtytnhhgiảipháp.vn', 1, N'Active', N'Chuyên cung cấp dịch vụ chuyển đổi số, tư vấn giải pháp ERP và phát triển ứng dụng di động cho doanh nghiệp vừa và nhỏ.

Được thành lập từ năm 2007 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(29, N'Công ty CP Ví điện tử An Phát', N'90000003', N'Fintech', N'500-1000', N'Số 31 đường Trần Hưng Đạo, Quận 7, TP. Hồ Chí Minh', N'https://côngtycpvíđiệntửan.vn', 1, N'Active', N'Cung cấp dịch vụ ví điện tử, thanh toán trực tuyến và các giải pháp tài chính số cho hàng triệu người dùng.

Được thành lập từ năm 2008 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực fintech với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành fintech.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực fintech","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(30, N'Công ty CP Thương mại Điện tử Việt Tiến', N'90000004', N'Thương mại điện tử', N'500-1000', N'Số 38 đường Hai Bà Trưng, Quận 10, TP. Hồ Chí Minh', N'https://côngtycpthươngmạiđ.vn', 1, N'Active', N'Vận hành sàn thương mại điện tử với danh mục hàng trăm nghìn sản phẩm, phục vụ người tiêu dùng trên toàn quốc.

Được thành lập từ năm 2009 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thương mại điện tử với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thương mại điện tử.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thương mại điện tử","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(31, N'Công ty TNHH Bán lẻ Trực tuyến Minh Long', N'90000005', N'Thương mại điện tử', N'1000+', N'Số 45 đường Nguyễn Văn Linh, Cầu Giấy, TP. Hồ Chí Minh', N'https://côngtytnhhbánlẻtrự.vn', 1, N'Active', N'Nền tảng bán lẻ trực tuyến kết nối nhà bán hàng và người tiêu dùng, phát triển hệ thống logistics riêng.

Được thành lập từ năm 2010 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thương mại điện tử với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thương mại điện tử.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thương mại điện tử","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(32, N'Tổng Công ty Viễn thông Đông Á', N'90000006', N'Viễn thông', N'1000+', N'Số 52 đường Phạm Văn Đồng, Đống Đa, Hà Nội', N'https://tổngcôngtyviễnthôn.vn', 1, N'Active', N'Cung cấp dịch vụ viễn thông, internet băng rộng và hạ tầng mạng cho khách hàng cá nhân và doanh nghiệp.

Được thành lập từ năm 2011 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực viễn thông với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành viễn thông.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực viễn thông","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(33, N'Công ty CP Thực phẩm Sữa Phương Nam', N'90000007', N'Thực phẩm - Đồ uống', N'1000+', N'Số 59 đường Điện Biên Phủ, Hai Bà Trưng, TP. Hồ Chí Minh', N'https://côngtycpthựcphẩmsữ.vn', 1, N'Active', N'Sản xuất và phân phối các sản phẩm sữa, đồ uống dinh dưỡng với hệ thống nhà máy đạt chuẩn quốc tế.

Được thành lập từ năm 2012 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực thực phẩm - đồ uống với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành thực phẩm - đồ uống.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực thực phẩm - đồ uống","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(34, N'Ngân hàng TMCP Kỹ Nghệ Việt', N'90000008', N'Ngân hàng - Tài chính', N'1000+', N'Số 66 đường Cách Mạng Tháng Tám, Thanh Xuân, Hà Nội', N'https://ngânhàngtmcpkỹnghệ.vn', 1, N'Active', N'Cung cấp dịch vụ ngân hàng bán lẻ, doanh nghiệp và ngân hàng số cho khách hàng trên cả nước.

Được thành lập từ năm 2013 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(35, N'Tập đoàn Bất động sản Hoàng Gia Land', N'90000009', N'Bất động sản', N'1000+', N'Số 73 đường Nguyễn Huệ, Long Biên, Hà Nội', N'https://tậpđoànbấtđộngsảnh.vn', 1, N'Active', N'Phát triển các dự án khu đô thị, nhà ở và bất động sản nghỉ dưỡng quy mô lớn.

Được thành lập từ năm 2014 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực bất động sản với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành bất động sản.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực bất động sản","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(36, N'Công ty CP Công nghệ Vận tải Đi Chung', N'90000010', N'Công nghệ - Vận tải', N'500-1000', N'Số 80 đường Võ Văn Kiệt, Hải Châu, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệvậ.vn', 1, N'Active', N'Nền tảng gọi xe công nghệ và giao hàng, kết nối tài xế và khách hàng qua ứng dụng di động.

Được thành lập từ năm 2015 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ - vận tải với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ - vận tải.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ - vận tải","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(37, N'Tập đoàn Công nghệ Bình Minh', N'90000011', N'Công nghệ thông tin', N'500-1000', N'Số 87 đường Láng Hạ, Ninh Kiều, Hà Nội', N'https://tậpđoàncôngnghệbìn.vn', 1, N'Active', N'Đầu tư và phát triển các công ty con trong lĩnh vực công nghệ, an ninh mạng và trí tuệ nhân tạo.

Được thành lập từ năm 2016 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(38, N'Công ty CP Hàng tiêu dùng Đại Dương', N'90000012', N'Hàng tiêu dùng', N'1000+', N'Số 94 đường Trường Chinh, Sơn Trà, TP. Hồ Chí Minh', N'https://côngtycphàngtiêudù.vn', 1, N'Active', N'Sản xuất và phân phối các mặt hàng tiêu dùng nhanh (FMCG) với hệ thống phân phối rộng khắp cả nước.

Được thành lập từ năm 2017 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực hàng tiêu dùng với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành hàng tiêu dùng.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực hàng tiêu dùng","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(39, N'Ngân hàng TMCP Thịnh Vượng Sài Gòn', N'90000013', N'Ngân hàng - Tài chính', N'1000+', N'Số 101 đường Kim Mã, Quận 1, TP. Hồ Chí Minh', N'https://ngânhàngtmcpthịnhv.vn', 1, N'Active', N'Cung cấp các sản phẩm tín dụng, tiết kiệm và dịch vụ ngân hàng số cho khách hàng cá nhân và SME.

Được thành lập từ năm 2018 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(40, N'Công ty CP Hàng không Cánh Việt', N'90000014', N'Hàng không', N'500-1000', N'Số 108 đường Xuân Thủy, Quận 3, TP. Hồ Chí Minh', N'https://côngtycphàngkhôngc.vn', 1, N'Active', N'Khai thác các đường bay nội địa và quốc tế, cung cấp dịch vụ vận chuyển hành khách và hàng hóa.

Được thành lập từ năm 2019 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực hàng không với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành hàng không.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực hàng không","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(41, N'Công ty TNHH Phần mềm Kim Cương', N'90000015', N'Công nghệ thông tin', N'500-1000', N'Số 115 đường Tôn Đức Thắng, Quận 7, Hà Nội', N'https://côngtytnhhphầnmềmk.vn', 1, N'Active', N'Gia công phần mềm cho thị trường Nhật Bản, Mỹ và châu Âu, tập trung vào các dự án ngân hàng và bảo hiểm.

Được thành lập từ năm 2020 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(42, N'Công ty CP Giải pháp Công nghệ Phương Đông', N'90000016', N'Công nghệ thông tin', N'100-500', N'Số 122 đường Nguyễn Trãi, Quận 10, TP. Hồ Chí Minh', N'https://côngtycpgiảiphápcô.vn', 1, N'Active', N'Phát triển sản phẩm phần mềm quản lý doanh nghiệp và tư vấn chuyển đổi số cho khách hàng SME.

Được thành lập từ năm 2005 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(43, N'Công ty TNHH Phần mềm Toàn Cầu Việt', N'90000017', N'Công nghệ thông tin', N'100-500', N'Số 129 đường Lê Lợi, Cầu Giấy, TP. Hồ Chí Minh', N'https://côngtytnhhphầnmềmt.vn', 1, N'Active', N'Cung cấp dịch vụ phát triển phần mềm theo yêu cầu và giải pháp kiểm thử tự động cho đối tác nước ngoài.

Được thành lập từ năm 2006 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(44, N'Công ty CP Công nghệ Tân Tiến', N'90000018', N'Công nghệ thông tin', N'100-500', N'Số 136 đường Trần Hưng Đạo, Đống Đa, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệtâ.vn', 0, N'Pending', N'Xây dựng nền tảng phần mềm cho lĩnh vực bán lẻ và chuỗi cung ứng, đang trong quá trình xác minh thông tin doanh nghiệp.

Được thành lập từ năm 2007 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(45, N'Công ty CP Giải pháp Phần mềm Kết Nối', N'90000019', N'Công nghệ thông tin', N'1000+', N'Số 143 đường Hai Bà Trưng, Hai Bà Trưng, TP. Hồ Chí Minh', N'https://côngtycpgiảiphápph.vn', 0, N'Pending', N'Gia công phần mềm quy mô lớn cho khách hàng quốc tế, đang chờ xác minh hồ sơ pháp lý trên hệ thống.

Được thành lập từ năm 2008 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ thông tin với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ thông tin.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ thông tin","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(46, N'Công ty CP Ô tô Điện Việt Phong', N'90000020', N'Sản xuất ô tô', N'1000+', N'Số 150 đường Nguyễn Văn Linh, Thanh Xuân, Hải Phòng', N'https://côngtycpôtôđiệnviệ.vn', 0, N'Pending', N'Sản xuất và lắp ráp ô tô điện, đầu tư nhà máy công nghệ cao, hiện đang hoàn thiện hồ sơ xác minh doanh nghiệp.

Được thành lập từ năm 2009 và có trụ sở chính tại Hải Phòng, công ty hoạt động trong lĩnh vực sản xuất ô tô với quy mô tập đoàn với hàng nghìn nhân sự trên toàn quốc. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành sản xuất ô tô.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực sản xuất ô tô","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(47, N'Công ty CP Công nghệ Di Chuyển Xanh', N'90000021', N'Công nghệ - Vận tải', N'500-1000', N'Số 157 đường Phạm Văn Đồng, Long Biên, TP. Hồ Chí Minh', N'https://côngtycpcôngnghệdi.vn', 1, N'Active', N'Nền tảng gọi xe công nghệ tập trung vào phương tiện thân thiện môi trường.

Được thành lập từ năm 2010 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực công nghệ - vận tải với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành công nghệ - vận tải.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực công nghệ - vận tải","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(48, N'Công ty CP Dược phẩm An Khang', N'90000022', N'Y tế - Dược phẩm', N'500-1000', N'Số 164 đường Điện Biên Phủ, Hải Châu, Hà Nội', N'https://côngtycpdượcphẩman.vn', 1, N'Active', N'Sản xuất và phân phối dược phẩm, thực phẩm chức năng, vận hành chuỗi nhà thuốc trên toàn quốc.

Được thành lập từ năm 2011 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực y tế - dược phẩm với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành y tế - dược phẩm.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực y tế - dược phẩm","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(49, N'Công ty CP Giáo dục Trí Việt', N'90000023', N'Giáo dục - Đào tạo', N'100-500', N'Số 171 đường Cách Mạng Tháng Tám, Ninh Kiều, TP. Hồ Chí Minh', N'https://côngtycpgiáodụctrí.vn', 1, N'Active', N'Cung cấp chương trình đào tạo kỹ năng, ngoại ngữ và luyện thi trực tuyến.

Được thành lập từ năm 2012 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực giáo dục - đào tạo với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành giáo dục - đào tạo.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực giáo dục - đào tạo","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(50, N'Công ty CP Xây dựng Thành Đô', N'90000024', N'Bất động sản - Xây dựng', N'500-1000', N'Số 178 đường Nguyễn Huệ, Sơn Trà, Hà Nội', N'https://côngtycpxâydựngthà.vn', 1, N'Active', N'Thi công các công trình dân dụng, công nghiệp và hạ tầng giao thông.

Được thành lập từ năm 2013 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực bất động sản - xây dựng với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành bất động sản - xây dựng.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực bất động sản - xây dựng","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(51, N'Công ty CP Logistics Miền Trung', N'90000025', N'Vận tải - Logistics', N'100-500', N'Số 185 đường Võ Văn Kiệt, Quận 1, Đà Nẵng', N'https://côngtycplogisticsm.vn', 1, N'Active', N'Cung cấp dịch vụ vận chuyển hàng hóa, kho bãi và giao nhận cho khu vực miền Trung.

Được thành lập từ năm 2014 và có trụ sở chính tại Đà Nẵng, công ty hoạt động trong lĩnh vực vận tải - logistics với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành vận tải - logistics.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực vận tải - logistics","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(52, N'Công ty CP Bán lẻ Điện máy Phú Cường', N'90000026', N'Kinh doanh - Bán lẻ', N'500-1000', N'Số 192 đường Láng Hạ, Quận 3, Hà Nội', N'https://côngtycpbánlẻđiệnm.vn', 1, N'Active', N'Vận hành hệ thống siêu thị điện máy và đồ gia dụng trên toàn quốc.

Được thành lập từ năm 2015 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực kinh doanh - bán lẻ với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành kinh doanh - bán lẻ.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực kinh doanh - bán lẻ","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(53, N'Công ty CP Truyền thông Sáng Tạo Việt', N'90000027', N'Marketing - Truyền thông', N'100-500', N'Số 199 đường Trường Chinh, Quận 7, TP. Hồ Chí Minh', N'https://côngtycptruyềnthôn.vn', 1, N'Active', N'Cung cấp dịch vụ truyền thông, sản xuất nội dung số và quảng cáo cho các nhãn hàng.

Được thành lập từ năm 2016 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực marketing - truyền thông với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành marketing - truyền thông.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực marketing - truyền thông","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(54, N'Công ty CP Bảo hiểm Niềm Tin Việt', N'90000028', N'Ngân hàng - Tài chính', N'500-1000', N'Số 16 đường Kim Mã, Quận 10, Hà Nội', N'https://côngtycpbảohiểmniề.vn', 1, N'Active', N'Cung cấp các sản phẩm bảo hiểm nhân thọ và phi nhân thọ cho khách hàng cá nhân, doanh nghiệp.

Được thành lập từ năm 2017 và có trụ sở chính tại Hà Nội, công ty hoạt động trong lĩnh vực ngân hàng - tài chính với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành ngân hàng - tài chính.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực ngân hàng - tài chính","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(55, N'Công ty CP Năng lượng Xanh Toàn Cầu', N'90000029', N'Sản xuất - Cơ khí', N'500-1000', N'Số 23 đường Xuân Thủy, Cầu Giấy, Đồng Nai', N'https://côngtycpnănglượngx.vn', 1, N'Active', N'Đầu tư và vận hành các nhà máy năng lượng tái tạo, sản xuất thiết bị cơ điện.

Được thành lập từ năm 2018 và có trụ sở chính tại Đồng Nai, công ty hoạt động trong lĩnh vực sản xuất - cơ khí với quy mô lớn với hệ thống vận hành chuyên nghiệp. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành sản xuất - cơ khí.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực sản xuất - cơ khí","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]'),
(56, N'Công ty TNHH Thời trang Việt Xinh', N'90000030', N'Kinh doanh - Bán lẻ', N'100-500', N'Số 30 đường Tôn Đức Thắng, Đống Đa, TP. Hồ Chí Minh', N'https://côngtytnhhthờitran.vn', 1, N'Active', N'Thiết kế, sản xuất và phân phối thời trang nội địa qua hệ thống cửa hàng và kênh online.

Được thành lập từ năm 2019 và có trụ sở chính tại TP. Hồ Chí Minh, công ty hoạt động trong lĩnh vực kinh doanh - bán lẻ với quy mô vừa với đội ngũ nhân sự trẻ, năng động. Trải qua nhiều năm phát triển, doanh nghiệp đã xây dựng được mạng lưới khách hàng và đối tác ổn định, không ngừng đầu tư vào con người và công nghệ để nâng cao chất lượng sản phẩm, dịch vụ.

Với định hướng phát triển bền vững, công ty chú trọng xây dựng môi trường làm việc chuyên nghiệp, khuyến khích nhân viên chủ động sáng tạo và đóng góp ý tưởng cải tiến quy trình. Chính sách phúc lợi, lộ trình đào tạo và cơ hội thăng tiến rõ ràng là những yếu tố được công ty đặc biệt quan tâm nhằm thu hút và giữ chân nhân tài trong ngành kinh doanh - bán lẻ.', N'["Môi trường làm việc chuyên nghiệp, cởi mở trong lĩnh vực kinh doanh - bán lẻ","Lương thưởng cạnh tranh, đánh giá hiệu suất minh bạch theo quý","Chế độ bảo hiểm sức khỏe mở rộng cho nhân viên và người thân","Lộ trình đào tạo nội bộ và tài trợ chứng chỉ chuyên môn","Cơ hội thăng tiến rõ ràng, được trao quyền chủ động trong công việc"]');
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
INSERT INTO ServicePackages (Name, Price, DurationDays, MaxJobPosts, MaxFeatured, Description, IsActive) VALUES
(N'Gói Khởi Đầu S1', 500000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S1, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M1', 1500000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M1, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L1', 2500000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L1, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S2', 700000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S2, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M2', 1700000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M2, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L2', 2700000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L2, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S3', 900000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S3, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M3', 1900000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M3, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L3', 2900000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L3, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S4', 1100000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S4, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M4', 2100000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M4, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L4', 3100000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L4, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S5', 1300000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S5, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M5', 2300000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M5, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L5', 3300000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L5, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S6', 1500000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S6, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M6', 2500000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M6, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L6', 3500000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L6, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1),
(N'Gói Khởi Đầu S7', 1700000, 30, 5, 1, N'Gói dịch vụ đăng tuyển mức Gói Khởi Đầu S7, phù hợp cho doanh nghiệp cần đăng tối đa 5 tin trong 30 ngày.', 1),
(N'Gói Tăng Trưởng M7', 2700000, 45, 20, 5, N'Gói dịch vụ đăng tuyển mức Gói Tăng Trưởng M7, phù hợp cho doanh nghiệp cần đăng tối đa 20 tin trong 45 ngày.', 1),
(N'Gói Doanh Nghiệp L7', 3700000, 60, 999, 20, N'Gói dịch vụ đăng tuyển mức Gói Doanh Nghiệp L7, phù hợp cho doanh nghiệp cần đăng tối đa không giới hạn tin trong 60 ngày.', 1);
GO
INSERT INTO JobPosts (EmployerId, CategoryID, Title, Description, Requirements, Benefits, SalaryMin, SalaryMax, SalaryNegotiable, JobType, Location, ExperienceLevel, Deadline, Status, IsFeatured) VALUES
(1, 11, N'Backend Developer (.NET / Java) tại Công ty CP Công nghệ Sao Việt', N'Công ty CP Công nghệ Sao Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (.NET / Java), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Backend Developer (.NET / Java) hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.', 15000000, 25000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-09-04', 'Active', 1),
(1, 13, N'DevOps Engineer tại Công ty CP Công nghệ Sao Việt', N'Công ty CP Công nghệ Sao Việt đang tìm kiếm ứng viên tiềm năng cho vị trí DevOps Engineer, làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí DevOps Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 20000000, 35000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-10-07', 'Active', 0),
(2, 12, N'Frontend Developer (ReactJS) tại Công ty TNHH Giải pháp Số Hưng Thịnh', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tìm kiếm ứng viên tiềm năng cho vị trí Frontend Developer (ReactJS), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Frontend Developer (ReactJS) hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 10000000, 18000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Junior', '2026-11-10', 'Pending', 0),
(2, 26, N'Business Analyst tại Công ty TNHH Giải pháp Số Hưng Thịnh', N'Công ty TNHH Giải pháp Số Hưng Thịnh đang tìm kiếm ứng viên tiềm năng cho vị trí Business Analyst, làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Business Analyst hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 16000000, 26000000, 0, 'Hybrid', N'TP. Hồ Chí Minh', 'Middle', '2026-08-13', 'Active', 0),
(3, 11, N'Backend Developer (Fintech) tại Công ty CP Ví điện tử An Phát', N'Công ty CP Ví điện tử An Phát đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Fintech), làm việc trực tiếp trong lĩnh vực fintech. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Backend Developer (Fintech) hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.', 22000000, 38000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Senior', '2026-09-16', 'Active', 1),
(3, 16, N'QA/QC Engineer tại Công ty CP Ví điện tử An Phát', N'Công ty CP Ví điện tử An Phát đang tìm kiếm ứng viên tiềm năng cho vị trí QA/QC Engineer, làm việc trực tiếp trong lĩnh vực fintech. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí QA/QC Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 14000000, 22000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-10-19', 'Rejected', 0),
(4, 15, N'Data Analyst tại Công ty CP Thương mại Điện tử Việt Tiến', N'Công ty CP Thương mại Điện tử Việt Tiến đang tìm kiếm ứng viên tiềm năng cho vị trí Data Analyst, làm việc trực tiếp trong lĩnh vực thương mại điện tử. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Data Analyst hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 15000000, 24000000, 0, 'Hybrid', N'TP. Hồ Chí Minh', 'Middle', '2026-11-22', 'Active', 0),
(4, 23, N'Nhân viên kinh doanh (E-commerce) tại Công ty CP Thương mại Điện tử Việt Tiến', N'Công ty CP Thương mại Điện tử Việt Tiến đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên kinh doanh (E-commerce), làm việc trực tiếp trong lĩnh vực thương mại điện tử. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên kinh doanh (E-commerce) hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.', 9000000, 15000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-08-25', 'Pending', 0),
(5, 27, N'Nhân viên Logistics tại Công ty TNHH Bán lẻ Trực tuyến Minh Long', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên Logistics, làm việc trực tiếp trong lĩnh vực thương mại điện tử. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên Logistics hoặc tương đương.

Yêu cầu ứng viên:
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.', 9500000, 14000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-09-01', 'Active', 0),
(5, 24, N'Quản lý cửa hàng tại Công ty TNHH Bán lẻ Trực tuyến Minh Long', N'Công ty TNHH Bán lẻ Trực tuyến Minh Long đang tìm kiếm ứng viên tiềm năng cho vị trí Quản lý cửa hàng, làm việc trực tiếp trong lĩnh vực thương mại điện tử. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Quản lý cửa hàng hoặc tương đương.

Yêu cầu ứng viên:
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.', 15000000, 22000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-04', 'Active', 0),
(6, 13, N'Cloud Engineer tại Tổng Công ty Viễn thông Đông Á', N'Tổng Công ty Viễn thông Đông Á đang tìm kiếm ứng viên tiềm năng cho vị trí Cloud Engineer, làm việc trực tiếp trong lĩnh vực viễn thông. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Cloud Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.', 25000000, 40000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-11-07', 'Active', 1),
(6, 25, N'Hành chính nhân sự tại Tổng Công ty Viễn thông Đông Á', N'Tổng Công ty Viễn thông Đông Á đang tìm kiếm ứng viên tiềm năng cho vị trí Hành chính nhân sự, làm việc trực tiếp trong lĩnh vực viễn thông. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Hành chính nhân sự hoặc tương đương.

Yêu cầu ứng viên:
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.', 9000000, 13000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-10', 'Draft', 0),
(7, 17, N'Kế toán tổng hợp tại Công ty CP Thực phẩm Sữa Phương Nam', N'Công ty CP Thực phẩm Sữa Phương Nam đang tìm kiếm ứng viên tiềm năng cho vị trí Kế toán tổng hợp, làm việc trực tiếp trong lĩnh vực thực phẩm - đồ uống. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Kế toán tổng hợp hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 12000000, 18000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-13', 'Active', 0),
(7, 19, N'Giao dịch viên ngân hàng tại Công ty CP Thực phẩm Sữa Phương Nam', N'Công ty CP Thực phẩm Sữa Phương Nam đang tìm kiếm ứng viên tiềm năng cho vị trí Giao dịch viên ngân hàng, làm việc trực tiếp trong lĩnh vực thực phẩm - đồ uống. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Giao dịch viên ngân hàng hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.', N'Quyền lợi khi làm việc tại công ty:
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 9000000, 13000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-10-16', 'Pending', 0),
(8, 18, N'Chuyên viên tài chính tại Ngân hàng TMCP Kỹ Nghệ Việt', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Chuyên viên tài chính, làm việc trực tiếp trong lĩnh vực ngân hàng - tài chính. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Chuyên viên tài chính hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 16000000, 24000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-11-19', 'Active', 0),
(8, 19, N'Giao dịch viên ngân hàng tại Ngân hàng TMCP Kỹ Nghệ Việt', N'Ngân hàng TMCP Kỹ Nghệ Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Giao dịch viên ngân hàng, làm việc trực tiếp trong lĩnh vực ngân hàng - tài chính. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Giao dịch viên ngân hàng hoặc tương đương.

Yêu cầu ứng viên:
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.', N'Quyền lợi khi làm việc tại công ty:
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.', 9500000, 13500000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-08-22', 'Active', 0),
(9, 30, N'Kỹ sư xây dựng tại Tập đoàn Bất động sản Hoàng Gia Land', N'Tập đoàn Bất động sản Hoàng Gia Land đang tìm kiếm ứng viên tiềm năng cho vị trí Kỹ sư xây dựng, làm việc trực tiếp trong lĩnh vực bất động sản. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Kỹ sư xây dựng hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.', 15000000, 23000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-09-25', 'Active', 0),
(9, 14, N'Mobile Developer tại Tập đoàn Bất động sản Hoàng Gia Land', N'Tập đoàn Bất động sản Hoàng Gia Land đang tìm kiếm ứng viên tiềm năng cho vị trí Mobile Developer, làm việc trực tiếp trong lĩnh vực bất động sản. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Mobile Developer hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 16000000, 26000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-10-01', 'Banned', 0),
(10, 13, N'DevOps / Site Reliability Engineer tại Công ty CP Công nghệ Vận tải Đi Chung', N'Công ty CP Công nghệ Vận tải Đi Chung đang tìm kiếm ứng viên tiềm năng cho vị trí DevOps / Site Reliability Engineer, làm việc trực tiếp trong lĩnh vực công nghệ - vận tải. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí DevOps / Site Reliability Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.', 24000000, 38000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Senior', '2026-11-04', 'Active', 1),
(10, 11, N'Backend Developer (Node.js) tại Công ty CP Công nghệ Vận tải Đi Chung', N'Công ty CP Công nghệ Vận tải Đi Chung đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Node.js), làm việc trực tiếp trong lĩnh vực công nghệ - vận tải. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Backend Developer (Node.js) hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.', 16000000, 27000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Middle', '2026-08-07', 'Active', 0),
(11, 11, N'Backend Developer (Java) tại Tập đoàn Công nghệ Bình Minh', N'Tập đoàn Công nghệ Bình Minh đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Java), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Backend Developer (Java) hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 20000000, 32000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-09-10', 'Active', 0),
(11, 12, N'Frontend Developer (Angular) tại Tập đoàn Công nghệ Bình Minh', N'Tập đoàn Công nghệ Bình Minh đang tìm kiếm ứng viên tiềm năng cho vị trí Frontend Developer (Angular), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Frontend Developer (Angular) hoặc tương đương.

Yêu cầu ứng viên:
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.', N'Quyền lợi khi làm việc tại công ty:
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.', 14000000, 22000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-10-13', 'Pending', 0),
(12, 23, N'Nhân viên kinh doanh FMCG tại Công ty CP Hàng tiêu dùng Đại Dương', N'Công ty CP Hàng tiêu dùng Đại Dương đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên kinh doanh FMCG, làm việc trực tiếp trong lĩnh vực hàng tiêu dùng. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên kinh doanh FMCG hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 9000000, 15000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-11-16', 'Active', 0),
(12, 20, N'Digital Marketing Executive tại Công ty CP Hàng tiêu dùng Đại Dương', N'Công ty CP Hàng tiêu dùng Đại Dương đang tìm kiếm ứng viên tiềm năng cho vị trí Digital Marketing Executive, làm việc trực tiếp trong lĩnh vực hàng tiêu dùng. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Digital Marketing Executive hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 12000000, 18000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-19', 'Rejected', 0),
(13, 19, N'Giao dịch viên ngân hàng tại Ngân hàng TMCP Thịnh Vượng Sài Gòn', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tìm kiếm ứng viên tiềm năng cho vị trí Giao dịch viên ngân hàng, làm việc trực tiếp trong lĩnh vực ngân hàng - tài chính. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Giao dịch viên ngân hàng hoặc tương đương.

Yêu cầu ứng viên:
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.', 9000000, 13000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-09-22', 'Active', 0),
(13, 18, N'Chuyên viên tài chính doanh nghiệp tại Ngân hàng TMCP Thịnh Vượng Sài Gòn', N'Ngân hàng TMCP Thịnh Vượng Sài Gòn đang tìm kiếm ứng viên tiềm năng cho vị trí Chuyên viên tài chính doanh nghiệp, làm việc trực tiếp trong lĩnh vực ngân hàng - tài chính. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Chuyên viên tài chính doanh nghiệp hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.', 22000000, 34000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Senior', '2026-10-25', 'Active', 1),
(14, 24, N'Quản lý cửa hàng tại Công ty CP Hàng không Cánh Việt', N'Công ty CP Hàng không Cánh Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Quản lý cửa hàng, làm việc trực tiếp trong lĩnh vực hàng không. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Quản lý cửa hàng hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 14000000, 20000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-11-01', 'Banned', 0),
(14, 28, N'Nhân viên chăm sóc khách hàng (hàng không) tại Công ty CP Hàng không Cánh Việt', N'Công ty CP Hàng không Cánh Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên chăm sóc khách hàng (hàng không), làm việc trực tiếp trong lĩnh vực hàng không. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên chăm sóc khách hàng (hàng không) hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.', N'Quyền lợi khi làm việc tại công ty:
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 9000000, 14000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-08-04', 'Active', 0),
(15, 11, N'Backend Developer (Ngân hàng - Bảo hiểm) tại Công ty TNHH Phần mềm Kim Cương', N'Công ty TNHH Phần mềm Kim Cương đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Ngân hàng - Bảo hiểm), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Backend Developer (Ngân hàng - Bảo hiểm) hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.', 22000000, 36000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-09-07', 'Active', 0),
(15, 16, N'QA/QC Automation Engineer tại Công ty TNHH Phần mềm Kim Cương', N'Công ty TNHH Phần mềm Kim Cương đang tìm kiếm ứng viên tiềm năng cho vị trí QA/QC Automation Engineer, làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí QA/QC Automation Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.', 15000000, 24000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-10-10', 'Draft', 0),
(16, 12, N'Frontend Developer (ReactJS) tại Công ty CP Giải pháp Công nghệ Phương Đông', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tìm kiếm ứng viên tiềm năng cho vị trí Frontend Developer (ReactJS), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Frontend Developer (ReactJS) hoặc tương đương.

Yêu cầu ứng viên:
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.', 11000000, 17000000, 0, 'Hybrid', N'TP. Hồ Chí Minh', 'Junior', '2026-11-13', 'Pending', 0),
(16, 31, N'Chuyên viên tuyển dụng tại Công ty CP Giải pháp Công nghệ Phương Đông', N'Công ty CP Giải pháp Công nghệ Phương Đông đang tìm kiếm ứng viên tiềm năng cho vị trí Chuyên viên tuyển dụng, làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Chuyên viên tuyển dụng hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 12000000, 18000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-08-16', 'Active', 0),
(17, 11, N'Backend Developer (Automation Testing) tại Công ty TNHH Phần mềm Toàn Cầu Việt', N'Công ty TNHH Phần mềm Toàn Cầu Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Automation Testing), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Backend Developer (Automation Testing) hoặc tương đương.

Yêu cầu ứng viên:
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 15000000, 23000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-09-19', 'Rejected', 0),
(18, 15, N'Data Engineer tại Công ty CP Công nghệ Tân Tiến', N'Công ty CP Công nghệ Tân Tiến đang tìm kiếm ứng viên tiềm năng cho vị trí Data Engineer, làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Data Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.', 18000000, 28000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Middle', '2026-10-22', 'Pending', 1),
(19, 11, N'Backend Developer (Outsourcing) tại Công ty CP Giải pháp Phần mềm Kết Nối', N'Công ty CP Giải pháp Phần mềm Kết Nối đang tìm kiếm ứng viên tiềm năng cho vị trí Backend Developer (Outsourcing), làm việc trực tiếp trong lĩnh vực công nghệ thông tin. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Backend Developer (Outsourcing) hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 20000000, 32000000, 0, 'Remote', N'TP. Hồ Chí Minh', 'Senior', '2026-11-25', 'Banned', 0),
(20, 14, N'Embedded Software Engineer tại Công ty CP Ô tô Điện Việt Phong', N'Công ty CP Ô tô Điện Việt Phong đang tìm kiếm ứng viên tiềm năng cho vị trí Embedded Software Engineer, làm việc trực tiếp trong lĩnh vực sản xuất ô tô. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Embedded Software Engineer hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.', 16000000, 25000000, 0, 'FullTime', N'Hải Phòng', 'Middle', '2026-08-01', 'Pending', 0),
(21, 19, N'Chuyên viên vận hành gọi xe công nghệ tại Công ty CP Công nghệ Di Chuyển Xanh', N'Công ty CP Công nghệ Di Chuyển Xanh đang tìm kiếm ứng viên tiềm năng cho vị trí Chuyên viên vận hành gọi xe công nghệ, làm việc trực tiếp trong lĩnh vực công nghệ - vận tải. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Chuyên viên vận hành gọi xe công nghệ hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.', N'Quyền lợi khi làm việc tại công ty:
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 9000000, 14000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-09-04', 'Active', 0),
(22, 33, N'Trình dược viên tại Công ty CP Dược phẩm An Khang', N'Công ty CP Dược phẩm An Khang đang tìm kiếm ứng viên tiềm năng cho vị trí Trình dược viên, làm việc trực tiếp trong lĩnh vực y tế - dược phẩm. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Trình dược viên hoặc tương đương.

Yêu cầu ứng viên:
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.', 9500000, 15000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-10-07', 'Active', 0),
(23, 34, N'Giáo viên tiếng Anh tại Công ty CP Giáo dục Trí Việt', N'Công ty CP Giáo dục Trí Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Giáo viên tiếng Anh, làm việc trực tiếp trong lĩnh vực giáo dục - đào tạo. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Giáo viên tiếng Anh hoặc tương đương.

Yêu cầu ứng viên:
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 12000000, 20000000, 0, 'PartTime', N'TP. Hồ Chí Minh', 'Middle', '2026-11-10', 'Active', 0),
(24, 30, N'Kỹ sư giám sát công trình tại Công ty CP Xây dựng Thành Đô', N'Công ty CP Xây dựng Thành Đô đang tìm kiếm ứng viên tiềm năng cho vị trí Kỹ sư giám sát công trình, làm việc trực tiếp trong lĩnh vực bất động sản - xây dựng. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có trên 5 năm kinh nghiệm và có khả năng dẫn dắt đội nhóm ở vị trí Kỹ sư giám sát công trình hoặc tương đương.

Yêu cầu ứng viên:
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.', 18000000, 28000000, 0, 'FullTime', N'Hà Nội', 'Senior', '2026-08-13', 'Active', 0),
(25, 27, N'Điều phối viên Logistics tại Công ty CP Logistics Miền Trung', N'Công ty CP Logistics Miền Trung đang tìm kiếm ứng viên tiềm năng cho vị trí Điều phối viên Logistics, làm việc trực tiếp trong lĩnh vực vận tải - logistics. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Điều phối viên Logistics hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.', 9500000, 14500000, 0, 'FullTime', N'Đà Nẵng', 'Junior', '2026-09-16', 'Active', 0),
(26, 24, N'Nhân viên bán hàng điện máy tại Công ty CP Bán lẻ Điện máy Phú Cường', N'Công ty CP Bán lẻ Điện máy Phú Cường đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên bán hàng điện máy, làm việc trực tiếp trong lĩnh vực kinh doanh - bán lẻ. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên bán hàng điện máy hoặc tương đương.

Yêu cầu ứng viên:
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 8500000, 13000000, 0, 'FullTime', N'Hà Nội', 'Junior', '2026-10-19', 'Active', 0),
(27, 21, N'Content Creator tại Công ty CP Truyền thông Sáng Tạo Việt', N'Công ty CP Truyền thông Sáng Tạo Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Content Creator, làm việc trực tiếp trong lĩnh vực marketing - truyền thông. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Hỗ trợ đào tạo, hướng dẫn nhân viên mới hoặc thực tập sinh trong phạm vi công việc được phân công.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Content Creator hoặc tương đương.

Yêu cầu ứng viên:
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.', 9000000, 16000000, 0, 'Hybrid', N'TP. Hồ Chí Minh', 'Junior', '2026-11-22', 'Active', 0),
(28, 18, N'Chuyên viên tư vấn bảo hiểm tại Công ty CP Bảo hiểm Niềm Tin Việt', N'Công ty CP Bảo hiểm Niềm Tin Việt đang tìm kiếm ứng viên tiềm năng cho vị trí Chuyên viên tư vấn bảo hiểm, làm việc trực tiếp trong lĩnh vực ngân hàng - tài chính. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Chuyên viên tư vấn bảo hiểm hoặc tương đương.

Yêu cầu ứng viên:
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Có khả năng làm việc độc lập cũng như phối hợp hiệu quả trong môi trường nhóm.
- Kỹ năng giao tiếp tốt, tư duy logic và khả năng giải quyết vấn đề linh hoạt.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.', N'Quyền lợi khi làm việc tại công ty:
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.', 12000000, 20000000, 0, 'FullTime', N'Hà Nội', 'Middle', '2026-08-25', 'Active', 0),
(29, 16, N'Kỹ sư vận hành nhà máy tại Công ty CP Năng lượng Xanh Toàn Cầu', N'Công ty CP Năng lượng Xanh Toàn Cầu đang tìm kiếm ứng viên tiềm năng cho vị trí Kỹ sư vận hành nhà máy, làm việc trực tiếp trong lĩnh vực sản xuất - cơ khí. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Cập nhật kiến thức chuyên môn, công cụ và xu hướng mới của ngành để áp dụng vào công việc thực tế.
- Chủ động đề xuất cải tiến quy trình làm việc nhằm nâng cao hiệu quả và tiết kiệm thời gian, chi phí.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có từ 2-4 năm kinh nghiệm thực tế ở vị trí Kỹ sư vận hành nhà máy hoặc tương đương.

Yêu cầu ứng viên:
- Chủ động học hỏi, cập nhật kiến thức mới và thích nghi nhanh với thay đổi.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.', N'Quyền lợi khi làm việc tại công ty:
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Mức lương thỏa thuận theo năng lực, xét tăng lương định kỳ mỗi năm.
- Chương trình đào tạo nội bộ, tài trợ chi phí học chứng chỉ chuyên môn.
- Thưởng hiệu suất (KPI) hằng quý, thưởng Tết và các dịp lễ trong năm.', 15000000, 24000000, 0, 'FullTime', N'Đồng Nai', 'Middle', '2026-09-01', 'Active', 0),
(30, 23, N'Nhân viên bán hàng thời trang tại Công ty TNHH Thời trang Việt Xinh', N'Công ty TNHH Thời trang Việt Xinh đang tìm kiếm ứng viên tiềm năng cho vị trí Nhân viên bán hàng thời trang, làm việc trực tiếp trong lĩnh vực kinh doanh - bán lẻ. Đây là cơ hội để bạn phát huy năng lực chuyên môn, tích lũy kinh nghiệm thực tế và đồng hành cùng sự phát triển của công ty.

Mô tả công việc:
- Phối hợp chặt chẽ với các phòng ban liên quan để triển khai công việc thông suốt, kịp thời xử lý phát sinh.
- Lập báo cáo kết quả công việc định kỳ (tuần/tháng/quý) và báo cáo trực tiếp cho quản lý phụ trách.
- Trực tiếp thực hiện các nghiệp vụ chuyên môn hằng ngày, đảm bảo tiến độ và chất lượng theo kế hoạch được giao.
- Tham gia các cuộc họp chuyên môn, đóng góp ý kiến xây dựng cho các dự án của bộ phận.
- Đảm bảo tuân thủ đầy đủ các quy định, chính sách nội bộ và tiêu chuẩn chất lượng của công ty.

Ngoài các đầu việc trên, vị trí này có thể được điều chỉnh, bổ sung nhiệm vụ phù hợp với năng lực và định hướng phát triển của ứng viên trong quá trình làm việc, đảm bảo tính linh hoạt và cơ hội học hỏi liên tục.', N'Ứng viên cần có dưới 1 năm kinh nghiệm (hoặc chấp nhận sinh viên mới ra trường) ở vị trí Nhân viên bán hàng thời trang hoặc tương đương.

Yêu cầu ứng viên:
- Thành thạo tin học văn phòng và các công cụ hỗ trợ công việc liên quan đến chuyên môn.
- Cẩn thận, trung thực, có tinh thần trách nhiệm cao với công việc được giao.
- Ưu tiên ứng viên có khả năng chịu áp lực tốt và quản lý thời gian hiệu quả.
- Tốt nghiệp Cao đẳng/Đại học chuyên ngành phù hợp với vị trí ứng tuyển.', N'Quyền lợi khi làm việc tại công ty:
- Môi trường làm việc năng động, đồng nghiệp thân thiện, cơ hội thăng tiến rõ ràng.
- Nghỉ phép năm theo quy định, du lịch công ty và các hoạt động team-building định kỳ.
- Tham gia đầy đủ Bảo hiểm xã hội, Bảo hiểm y tế, Bảo hiểm thất nghiệp theo quy định.
- Được cấp trang thiết bị làm việc đầy đủ, phù hợp với tính chất công việc.
- Khám sức khỏe định kỳ hằng năm cho toàn thể nhân viên.', 8000000, 12000000, 0, 'FullTime', N'TP. Hồ Chí Minh', 'Junior', '2026-10-04', 'Active', 0);
GO
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

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-01-03', 'Published'),
(1, N'Cách viết CV xin việc gây ấn tượng với nhà tuyển dụng', N'cách-viết-cv-xin-việc-gây-ấn-tượng-với-nhà-tuyển-dụng', N'Một CV tốt cần trình bày rõ ràng, ngắn gọn và tập trung vào kết quả công việc thay vì chỉ liệt kê nhiệm vụ. Ứng viên nên sử dụng số liệu cụ thể để chứ...', N'Một CV tốt cần trình bày rõ ràng, ngắn gọn và tập trung vào kết quả công việc thay vì chỉ liệt kê nhiệm vụ. Ứng viên nên sử dụng số liệu cụ thể để chứng minh hiệu quả công việc, đồng thời điều chỉnh nội dung CV phù hợp với từng vị trí ứng tuyển. Tránh các lỗi chính tả, định dạng lộn xộn và thông tin không liên quan để tạo thiện cảm ngay từ cái nhìn đầu tiên.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "cách viết cv xin việc gây ấn tượng với nhà tuyển dụng" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-02-05', 'Published'),
(1, N'Báo cáo mức lương ngành công nghệ thông tin tại Việt Nam', N'báo-cáo-mức-lương-ngành-công-nghệ-thông-tin-tại-việt-nam', N'Theo khảo sát từ nhiều nguồn tuyển dụng, mức lương của lập trình viên tại Việt Nam tiếp tục tăng trưởng, đặc biệt ở các vị trí liên quan đến điện toán...', N'Theo khảo sát từ nhiều nguồn tuyển dụng, mức lương của lập trình viên tại Việt Nam tiếp tục tăng trưởng, đặc biệt ở các vị trí liên quan đến điện toán đám mây và trí tuệ nhân tạo. Nhân sự có kinh nghiệm từ 3-5 năm thường có mức thu nhập cao hơn đáng kể so với nhóm mới ra trường, và các thành phố lớn như Hà Nội, TP. Hồ Chí Minh vẫn là nơi tập trung nhiều cơ hội việc làm với mức đãi ngộ tốt nhất.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "báo cáo mức lương ngành công nghệ thông tin tại việt nam" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-03-07', 'Published'),
(1, N'Bí quyết phỏng vấn thành công dành cho ứng viên mới ra trường', N'bí-quyết-phỏng-vấn-thành-công-dành-cho-ứng-viên-mới-ra-trường', N'Ứng viên mới ra trường nên chuẩn bị kỹ về thông tin công ty, vị trí ứng tuyển và luyện tập trả lời các câu hỏi phỏng vấn phổ biến. Thái độ tự tin, tru...', N'Ứng viên mới ra trường nên chuẩn bị kỹ về thông tin công ty, vị trí ứng tuyển và luyện tập trả lời các câu hỏi phỏng vấn phổ biến. Thái độ tự tin, trung thực và tinh thần cầu tiến thường được nhà tuyển dụng đánh giá cao hơn là kinh nghiệm làm việc chưa nhiều. Đặt câu hỏi ngược lại cho nhà tuyển dụng cũng là cách thể hiện sự quan tâm nghiêm túc đến công việc.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "bí quyết phỏng vấn thành công dành cho ứng viên mới ra trường" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-04-09', 'Published'),
(1, N'Xu hướng làm việc từ xa và mô hình hybrid tại doanh nghiệp Việt', N'xu-hướng-làm-việc-từ-xa-và-mô-hình-hybrid-tại-doanh-nghiệp-việt', N'Nhiều doanh nghiệp tại Việt Nam đã áp dụng mô hình làm việc kết hợp giữa văn phòng và từ xa nhằm tăng tính linh hoạt cho nhân viên. Mô hình này giúp t...', N'Nhiều doanh nghiệp tại Việt Nam đã áp dụng mô hình làm việc kết hợp giữa văn phòng và từ xa nhằm tăng tính linh hoạt cho nhân viên. Mô hình này giúp tiết kiệm chi phí vận hành, đồng thời đòi hỏi nhân sự có kỹ năng quản lý thời gian và giao tiếp trực tuyến tốt hơn. Xu hướng này được dự đoán sẽ tiếp tục phổ biến trong các ngành công nghệ, marketing và dịch vụ khách hàng.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xu hướng làm việc từ xa và mô hình hybrid tại doanh nghiệp việt" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-05-11', 'Published'),
(1, N'Xây dựng thương hiệu cá nhân trên mạng xã hội nghề nghiệp', N'xây-dựng-thương-hiệu-cá-nhân-trên-mạng-xã-hội-nghề-nghiệp', N'Việc xây dựng hồ sơ chuyên nghiệp trên các nền tảng mạng xã hội nghề nghiệp giúp ứng viên tăng cơ hội được nhà tuyển dụng chủ động liên hệ. Chia sẻ ki...', N'Việc xây dựng hồ sơ chuyên nghiệp trên các nền tảng mạng xã hội nghề nghiệp giúp ứng viên tăng cơ hội được nhà tuyển dụng chủ động liên hệ. Chia sẻ kiến thức chuyên môn, tham gia thảo luận trong cộng đồng ngành nghề và cập nhật thành tích công việc thường xuyên là những cách hiệu quả để xây dựng uy tín cá nhân trong lĩnh vực đang theo đuổi.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xây dựng thương hiệu cá nhân trên mạng xã hội nghề nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-06-13', 'Published'),
(1, N'Những kỹ năng mềm quan trọng đối với nhân sự ngành công nghệ', N'những-kỹ-năng-mềm-quan-trọng-đối-với-nhân-sự-ngành-công-nghệ', N'Ngoài kiến thức chuyên môn, kỹ năng giao tiếp, làm việc nhóm và quản lý thời gian đóng vai trò quan trọng trong sự phát triển sự nghiệp của nhân sự cô...', N'Ngoài kiến thức chuyên môn, kỹ năng giao tiếp, làm việc nhóm và quản lý thời gian đóng vai trò quan trọng trong sự phát triển sự nghiệp của nhân sự công nghệ. Khả năng trình bày ý tưởng rõ ràng trước đội nhóm và đối tác cũng giúp nhân viên dễ dàng đảm nhận các vị trí quản lý trong tương lai.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những kỹ năng mềm quan trọng đối với nhân sự ngành công nghệ" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-07-15', 'Published'),
(1, N'So sánh mức lương giữa các ngành nghề phổ biến hiện nay', N'so-sánh-mức-lương-giữa-các-ngành-nghề-phổ-biến-hiện-nay', N'Mức lương giữa các ngành nghề tại Việt Nam có sự chênh lệch đáng kể, trong đó công nghệ thông tin, tài chính ngân hàng và một số ngành kỹ thuật cao th...', N'Mức lương giữa các ngành nghề tại Việt Nam có sự chênh lệch đáng kể, trong đó công nghệ thông tin, tài chính ngân hàng và một số ngành kỹ thuật cao thường có mức đãi ngộ tốt hơn mặt bằng chung. Tuy nhiên, mức lương thực tế còn phụ thuộc vào kinh nghiệm, vị trí địa lý và quy mô doanh nghiệp tuyển dụng.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "so sánh mức lương giữa các ngành nghề phổ biến hiện nay" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-08-17', 'Published'),
(1, N'Kinh nghiệm đàm phán lương khi nhận được lời mời làm việc mới', N'kinh-nghiệm-đàm-phán-lương-khi-nhận-được-lời-mời-làm-việc-mới', N'Trước khi đàm phán lương, ứng viên nên tìm hiểu mặt bằng lương chung của vị trí tương đương trên thị trường để có cơ sở thương lượng hợp lý. Việc trìn...', N'Trước khi đàm phán lương, ứng viên nên tìm hiểu mặt bằng lương chung của vị trí tương đương trên thị trường để có cơ sở thương lượng hợp lý. Việc trình bày rõ giá trị bản thân có thể mang lại cho công ty, kết hợp với thái độ chuyên nghiệp, sẽ giúp quá trình đàm phán diễn ra thuận lợi hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kinh nghiệm đàm phán lương khi nhận được lời mời làm việc mới" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-09-19', 'Published'),
(1, N'Chuyển ngành sang công nghệ thông tin nên bắt đầu từ đâu', N'chuyển-ngành-sang-công-nghệ-thông-tin-nên-bắt-đầu-từ-đâu', N'Người muốn chuyển ngành sang công nghệ thông tin có thể bắt đầu bằng việc học các ngôn ngữ lập trình phổ biến, tham gia khóa học trực tuyến và xây dựn...', N'Người muốn chuyển ngành sang công nghệ thông tin có thể bắt đầu bằng việc học các ngôn ngữ lập trình phổ biến, tham gia khóa học trực tuyến và xây dựng dự án cá nhân để làm portfolio. Kiên trì luyện tập và tham gia cộng đồng lập trình viên sẽ giúp quá trình chuyển ngành diễn ra nhanh và hiệu quả hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "chuyển ngành sang công nghệ thông tin nên bắt đầu từ đâu" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-10-21', 'Published'),
(1, N'Khoa học dữ liệu - lĩnh vực được nhiều bạn trẻ quan tâm', N'khoa-học-dữ-liệu-lĩnh-vực-được-nhiều-bạn-trẻ-quan-tâm', N'Khoa học dữ liệu đang trở thành một trong những lĩnh vực có nhu cầu tuyển dụng cao tại Việt Nam nhờ vào sự phát triển của các doanh nghiệp ứng dụng dữ...', N'Khoa học dữ liệu đang trở thành một trong những lĩnh vực có nhu cầu tuyển dụng cao tại Việt Nam nhờ vào sự phát triển của các doanh nghiệp ứng dụng dữ liệu lớn và trí tuệ nhân tạo. Người theo đuổi lĩnh vực này cần trang bị kiến thức về thống kê, lập trình và tư duy phân tích vấn đề.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "khoa học dữ liệu - lĩnh vực được nhiều bạn trẻ quan tâm" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-11-23', 'Published'),
(1, N'Những sai lầm phổ biến khi tìm việc mà ứng viên thường gặp', N'những-sai-lầm-phổ-biến-khi-tìm-việc-mà-ứng-viên-thường-gặp', N'Nhiều ứng viên mắc lỗi nộp hồ sơ hàng loạt mà không tìm hiểu kỹ về công ty, dẫn đến tỷ lệ phản hồi thấp. Việc chuẩn bị CV chung chung, không nêu bật t...', N'Nhiều ứng viên mắc lỗi nộp hồ sơ hàng loạt mà không tìm hiểu kỹ về công ty, dẫn đến tỷ lệ phản hồi thấp. Việc chuẩn bị CV chung chung, không nêu bật thế mạnh cá nhân cũng khiến hồ sơ khó nổi bật giữa hàng trăm ứng viên khác.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những sai lầm phổ biến khi tìm việc mà ứng viên thường gặp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-12-25', 'Published'),
(1, N'Cách tối ưu hồ sơ trên các nền tảng tuyển dụng trực tuyến', N'cách-tối-ưu-hồ-sơ-trên-các-nền-tảng-tuyển-dụng-trực-tuyến', N'Ứng viên nên cập nhật đầy đủ thông tin, sử dụng từ khóa liên quan đến ngành nghề và bổ sung portfolio nếu có để tăng khả năng được nhà tuyển dụng tìm ...', N'Ứng viên nên cập nhật đầy đủ thông tin, sử dụng từ khóa liên quan đến ngành nghề và bổ sung portfolio nếu có để tăng khả năng được nhà tuyển dụng tìm thấy. Việc thường xuyên làm mới hồ sơ cũng giúp tăng thứ hạng hiển thị trên các nền tảng tìm việc.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "cách tối ưu hồ sơ trên các nền tảng tuyển dụng trực tuyến" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-01-27', 'Published'),
(1, N'Trí tuệ nhân tạo đang thay đổi thị trường tuyển dụng như thế nào', N'trí-tuệ-nhân-tạo-đang-thay-đổi-thị-trường-tuyển-dụng-như-thế-nào', N'Nhiều doanh nghiệp đã ứng dụng công nghệ AI để sàng lọc hồ sơ, phân tích năng lực ứng viên và tối ưu quy trình tuyển dụng. Điều này đòi hỏi ứng viên c...', N'Nhiều doanh nghiệp đã ứng dụng công nghệ AI để sàng lọc hồ sơ, phân tích năng lực ứng viên và tối ưu quy trình tuyển dụng. Điều này đòi hỏi ứng viên cần chuẩn bị hồ sơ rõ ràng, đúng trọng tâm để dễ dàng vượt qua các vòng sàng lọc tự động.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "trí tuệ nhân tạo đang thay đổi thị trường tuyển dụng như thế nào" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-02-02', 'Published'),
(1, N'Kinh nghiệm phỏng vấn tại các tập đoàn lớn', N'kinh-nghiệm-phỏng-vấn-tại-các-tập-đoàn-lớn', N'Quy trình phỏng vấn tại các tập đoàn lớn thường gồm nhiều vòng, từ kiểm tra kiến thức chuyên môn đến đánh giá tư duy giải quyết vấn đề và mức độ phù h...', N'Quy trình phỏng vấn tại các tập đoàn lớn thường gồm nhiều vòng, từ kiểm tra kiến thức chuyên môn đến đánh giá tư duy giải quyết vấn đề và mức độ phù hợp văn hóa doanh nghiệp. Ứng viên nên tìm hiểu kỹ văn hóa công ty và chuẩn bị ví dụ thực tế cho từng vòng phỏng vấn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kinh nghiệm phỏng vấn tại các tập đoàn lớn" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-03-04', 'Published'),
(1, N'Làm sao để thăng tiến nhanh trong sự nghiệp', N'làm-sao-để-thăng-tiến-nhanh-trong-sự-nghiệp', N'Để thăng tiến nhanh, nhân sự cần chủ động nhận thêm trách nhiệm, không ngừng học hỏi kỹ năng mới và xây dựng mối quan hệ tốt với đồng nghiệp, cấp trên...', N'Để thăng tiến nhanh, nhân sự cần chủ động nhận thêm trách nhiệm, không ngừng học hỏi kỹ năng mới và xây dựng mối quan hệ tốt với đồng nghiệp, cấp trên. Đặt mục tiêu nghề nghiệp rõ ràng theo từng giai đoạn cũng giúp định hướng phát triển sự nghiệp hiệu quả hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "làm sao để thăng tiến nhanh trong sự nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-04-06', 'Published'),
(1, N'Xây dựng lộ trình học tập cho người mới bắt đầu sự nghiệp', N'xây-dựng-lộ-trình-học-tập-cho-người-mới-bắt-đầu-sự-nghiệp', N'Người mới bắt đầu sự nghiệp nên xác định rõ mục tiêu nghề nghiệp, sau đó xây dựng lộ trình học tập theo từng giai đoạn ngắn hạn và dài hạn. Kết hợp gi...', N'Người mới bắt đầu sự nghiệp nên xác định rõ mục tiêu nghề nghiệp, sau đó xây dựng lộ trình học tập theo từng giai đoạn ngắn hạn và dài hạn. Kết hợp giữa học lý thuyết và thực hành dự án thực tế sẽ giúp tích lũy kinh nghiệm nhanh hơn.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "xây dựng lộ trình học tập cho người mới bắt đầu sự nghiệp" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-05-08', 'Published'),
(1, N'Bí quyết cân bằng giữa công việc và cuộc sống cá nhân', N'bí-quyết-cân-bằng-giữa-công-việc-và-cuộc-sống-cá-nhân', N'Việc thiết lập ranh giới rõ ràng giữa thời gian làm việc và thời gian cá nhân giúp nhân sự duy trì hiệu suất làm việc lâu dài mà không bị kiệt sức. Sắ...', N'Việc thiết lập ranh giới rõ ràng giữa thời gian làm việc và thời gian cá nhân giúp nhân sự duy trì hiệu suất làm việc lâu dài mà không bị kiệt sức. Sắp xếp công việc theo mức độ ưu tiên và dành thời gian nghỉ ngơi hợp lý là yếu tố quan trọng để cân bằng cuộc sống.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "bí quyết cân bằng giữa công việc và cuộc sống cá nhân" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-06-10', 'Published'),
(1, N'Những chứng chỉ nghề nghiệp giá trị nên cân nhắc', N'những-chứng-chỉ-nghề-nghiệp-giá-trị-nên-cân-nhắc', N'Các chứng chỉ liên quan đến điện toán đám mây, quản lý dự án và phân tích dữ liệu đang được nhiều nhà tuyển dụng đánh giá cao. Việc lựa chọn chứng chỉ...', N'Các chứng chỉ liên quan đến điện toán đám mây, quản lý dự án và phân tích dữ liệu đang được nhiều nhà tuyển dụng đánh giá cao. Việc lựa chọn chứng chỉ phù hợp với định hướng nghề nghiệp sẽ giúp tăng giá trị hồ sơ ứng tuyển.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "những chứng chỉ nghề nghiệp giá trị nên cân nhắc" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Dành thời gian tìm hiểu kỹ thông tin công ty, sản phẩm và văn hóa doanh nghiệp trước khi quyết định ứng tuyển hoặc phỏng vấn.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-07-12', 'Published'),
(1, N'Chuẩn bị hồ sơ ứng tuyển vị trí làm việc từ xa cho công ty quốc tế', N'chuẩn-bị-hồ-sơ-ứng-tuyển-vị-trí-làm-việc-từ-xa-cho-công-ty-quốc-tế', N'Ứng viên muốn làm việc từ xa cho công ty quốc tế cần chuẩn bị hồ sơ bằng tiếng Anh chuyên nghiệp, thể hiện rõ khả năng làm việc độc lập và giao tiếp q...', N'Ứng viên muốn làm việc từ xa cho công ty quốc tế cần chuẩn bị hồ sơ bằng tiếng Anh chuyên nghiệp, thể hiện rõ khả năng làm việc độc lập và giao tiếp qua các công cụ trực tuyến. Portfolio dự án thực tế cũng là yếu tố giúp tăng độ tin cậy với nhà tuyển dụng nước ngoài.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "chuẩn bị hồ sơ ứng tuyển vị trí làm việc từ xa cho công ty quốc tế" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Ghi lại nhật ký công việc hằng ngày để tự đánh giá tiến độ, kịp thời điều chỉnh phương pháp làm việc phù hợp hơn.
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-08-14', 'Published'),
(1, N'Ngành logistics và cơ hội việc làm trong bối cảnh thương mại điện tử phát triển', N'ngành-logistics-và-cơ-hội-việc-làm-trong-bối-cảnh-thương-mại-điện-tử-phát-triển', N'Sự phát triển mạnh mẽ của thương mại điện tử kéo theo nhu cầu nhân sự ngành logistics tăng cao, đặc biệt ở các vị trí điều phối vận tải và quản lý kho...', N'Sự phát triển mạnh mẽ của thương mại điện tử kéo theo nhu cầu nhân sự ngành logistics tăng cao, đặc biệt ở các vị trí điều phối vận tải và quản lý kho vận. Đây là lĩnh vực được đánh giá có nhiều tiềm năng phát triển trong những năm tới.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "ngành logistics và cơ hội việc làm trong bối cảnh thương mại điện tử phát triển" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Thường xuyên cập nhật hồ sơ cá nhân, portfolio để phản ánh đúng năng lực và kinh nghiệm hiện tại.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-09-16', 'Published'),
(1, N'Kỹ năng quản lý dự án cần thiết cho nhân sự công nghệ', N'kỹ-năng-quản-lý-dự-án-cần-thiết-cho-nhân-sự-công-nghệ', N'Kỹ năng lập kế hoạch, phân bổ nguồn lực và quản lý rủi ro là những yếu tố quan trọng giúp nhân sự công nghệ đảm nhận tốt vai trò quản lý dự án. Việc s...', N'Kỹ năng lập kế hoạch, phân bổ nguồn lực và quản lý rủi ro là những yếu tố quan trọng giúp nhân sự công nghệ đảm nhận tốt vai trò quản lý dự án. Việc sử dụng thành thạo các công cụ quản lý công việc cũng góp phần nâng cao hiệu quả phối hợp trong đội nhóm.

Trên thực tế, đây là vấn đề được nhiều người lao động và nhà tuyển dụng tại Việt Nam quan tâm trong bối cảnh thị trường việc làm liên tục thay đổi. Việc hiểu rõ bản chất của chủ đề "kỹ năng quản lý dự án cần thiết cho nhân sự công nghệ" giúp mỗi người có cái nhìn thực tế hơn, từ đó đưa ra quyết định phù hợp với định hướng nghề nghiệp của bản thân, dù đang ở giai đoạn tìm việc, chuyển việc hay phát triển sự nghiệp lâu dài.

Một số gợi ý thực tế bạn có thể tham khảo:
- Rèn luyện kỹ năng trình bày, thuyết trình để tự tin chia sẻ ý tưởng trước đội nhóm và cấp quản lý.
- Xây dựng thói quen học tập liên tục thông qua sách chuyên ngành, khóa học trực tuyến và các buổi chia sẻ kinh nghiệm thực tế.
- Chủ động kết nối với những người đi trước trong ngành để xin lời khuyên và mở rộng cơ hội nghề nghiệp.

Nhìn chung, không có công thức chung áp dụng cho tất cả mọi người, bởi mỗi cá nhân có xuất phát điểm, mục tiêu và hoàn cảnh khác nhau. Điều quan trọng là duy trì tinh thần chủ động học hỏi, kiên trì với lộ trình đã đặt ra và sẵn sàng điều chỉnh khi cần thiết. JobConnect hy vọng những chia sẻ trên sẽ giúp bạn có thêm góc nhìn hữu ích trên hành trình phát triển sự nghiệp của mình.', 1, '2026-10-18', 'Published');
GO
UPDATE BlogPosts SET BlogCode = 'BL' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 6));
GO
INSERT INTO Transactions (EmployerId, PackageID, Amount, PaymentMethod, Status, ExpiredAt) VALUES
(1, 1, 800000, 'BankTransfer', 'Completed', '2026-02-28'),
(2, 2, 1100000, 'VNPay', 'Completed', '2026-03-28'),
(3, 3, 1400000, 'MoMo', 'Completed', '2026-04-28'),
(4, 4, 1700000, 'ZaloPay', 'Pending', '2026-05-28'),
(5, 5, 2000000, 'BankTransfer', 'Failed', '2026-06-28'),
(6, 6, 2300000, 'VNPay', 'Completed', '2026-07-28'),
(7, 7, 500000, 'MoMo', 'Completed', '2026-08-28'),
(8, 8, 800000, 'ZaloPay', 'Completed', '2026-09-28'),
(9, 9, 1100000, 'BankTransfer', 'Pending', '2026-10-28'),
(10, 10, 1400000, 'VNPay', 'Failed', '2026-11-28'),
(11, 11, 1700000, 'MoMo', 'Completed', '2026-12-28'),
(12, 12, 2000000, 'ZaloPay', 'Completed', '2026-01-28'),
(13, 13, 2300000, 'BankTransfer', 'Completed', '2026-02-28'),
(14, 14, 500000, 'VNPay', 'Pending', '2026-03-28'),
(15, 15, 800000, 'MoMo', 'Failed', '2026-04-28'),
(16, 16, 1100000, 'ZaloPay', 'Completed', '2026-05-28'),
(17, 17, 1400000, 'BankTransfer', 'Completed', '2026-06-28'),
(18, 18, 1700000, 'VNPay', 'Completed', '2026-07-28'),
(19, 19, 2000000, 'MoMo', 'Pending', '2026-08-28'),
(20, 20, 2300000, 'ZaloPay', 'Failed', '2026-09-28'),
(21, 21, 500000, 'BankTransfer', 'Completed', '2026-10-28'),
(22, 1, 800000, 'VNPay', 'Completed', '2026-11-28'),
(23, 2, 1100000, 'MoMo', 'Completed', '2026-12-28'),
(24, 3, 1400000, 'ZaloPay', 'Pending', '2026-01-28'),
(25, 4, 1700000, 'BankTransfer', 'Failed', '2026-02-28'),
(26, 5, 2000000, 'VNPay', 'Completed', '2026-03-28'),
(27, 6, 2300000, 'MoMo', 'Completed', '2026-04-28'),
(28, 7, 500000, 'ZaloPay', 'Completed', '2026-05-28'),
(29, 8, 800000, 'BankTransfer', 'Pending', '2026-06-28'),
(30, 9, 1100000, 'VNPay', 'Failed', '2026-07-28');
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