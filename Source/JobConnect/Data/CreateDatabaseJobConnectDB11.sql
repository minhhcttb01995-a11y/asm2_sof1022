/* =========================================================
   JobConnectDB11 - XOA VA TAO LAI HOAN TOAN TU DAU
   CANH BAO: Script nay se XOA SACH du lieu cu trong JobConnectDB11
   Chi chay khi ban chac chan muon lam lai tu dau.
   ========================================================= */
 
USE master;
GO
 
-- Ngat moi ket noi dang mo toi DB nay truoc khi xoa
IF DB_ID('JobConnectDB11') IS NOT NULL
BEGIN
    ALTER DATABASE JobConnectDB11 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JobConnectDB11;
END
GO
 
CREATE DATABASE JobConnectDB11;
GO
 
USE JobConnectDB11;
GO
 
/* ================= USERS ================= */
CREATE TABLE Users (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
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
    UserId          INT NOT NULL,
    CompanyName     NVARCHAR(200) NOT NULL,
    TaxCode         NVARCHAR(50)  NULL,
    Industry        NVARCHAR(100) NULL,
    CompanySize     NVARCHAR(50)  NULL,
    Address         NVARCHAR(300) NULL,
    Website         NVARCHAR(300) NULL,
    LogoURL         NVARCHAR(500) NULL,
    CoverURL        NVARCHAR(500) NULL,
    IsVerified      BIT NOT NULL DEFAULT 0,
    IsLocked        BIT NOT NULL DEFAULT 0,
    Description     NVARCHAR(MAX) NULL,
    WhyWorkHereJson NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,
    CONSTRAINT UQ_Employers_UserId UNIQUE (UserId),
    CONSTRAINT FK_Employers_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
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
    Status              INT NOT NULL DEFAULT 1,
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
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    ColorClass NVARCHAR(50) NULL,
    SortOrder INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    IsSystem BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT UQ_StatusCatalog_EntityType_Code UNIQUE (EntityType, Code)
);
GO

CREATE INDEX IX_StatusCatalog_EntityType ON StatusCatalog(EntityType);
GO
 
-- Dua DB ve che do multi-user binh thuong
ALTER DATABASE JobConnectDB11 SET MULTI_USER;
GO
 
-- Kiem tra ket qua
SELECT 'Users.DeletedAt' AS CheckItem,
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'DeletedAt')
            THEN 'OK' ELSE 'MISSING' END AS Status
UNION ALL
SELECT 'BlogPosts.Status',
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('BlogPosts') AND name = 'Status')
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'BlogPosts.UpdatedAt',
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('BlogPosts') AND name = 'UpdatedAt' AND is_nullable = 1)
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'Employers.UpdatedAt',
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Employers') AND name = 'UpdatedAt')
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'Staff.CCCD',
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Staff') AND name = 'CCCD')
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'Staff.Gender',
       CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Staff') AND name = 'Gender')
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'CompanyHighlight table',
       CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyHighlight')
            THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'StatusCatalog table',
       CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = 'StatusCatalog')
            THEN 'OK' ELSE 'MISSING' END;
GO
