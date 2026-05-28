-- ============================================================
--  TẠO DATABASE JOBCONNECT
-- ============================================================
CREATE DATABASE JobConnectDB;
GO
USE JobConnectDB;
GO

-- BẢNG 1: USERS
CREATE TABLE Users (
    UserID      INT IDENTITY(1,1) PRIMARY KEY,
    Email       NVARCHAR(150)  NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role        NVARCHAR(20)   NOT NULL DEFAULT 'Candidate',
    FullName    NVARCHAR(100)  NOT NULL,
    PhoneNumber NVARCHAR(15)   NULL,
    AvatarURL   NVARCHAR(300)  NULL,
    Status      NVARCHAR(20)   NOT NULL DEFAULT 'Active',
    CreatedAt   DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt   DATETIME       NULL
);

-- BẢNG 2: CANDIDATE_PROFILES
CREATE TABLE CandidateProfiles (
    ProfileID       INT IDENTITY(1,1) PRIMARY KEY,
    UserID          INT           NOT NULL UNIQUE,
    DateOfBirth     DATE          NULL,
    Gender          NVARCHAR(10)  NULL,
    Address         NVARCHAR(200) NULL,
    Summary         NVARCHAR(MAX) NULL,
    ExperienceYears INT           NOT NULL DEFAULT 0,
    DesiredSalary   DECIMAL(15,0) NULL,
    IsOpenToWork    BIT           NOT NULL DEFAULT 1,
    CONSTRAINT FK_CandidateProfiles_Users FOREIGN KEY (UserID)
        REFERENCES Users(UserID) ON DELETE CASCADE
);

-- BẢNG 3: CV_FILES
CREATE TABLE CvFiles (
    CVID        INT IDENTITY(1,1) PRIMARY KEY,
    ProfileID   INT           NOT NULL,
    FileName    NVARCHAR(200) NOT NULL,
    FilePath    NVARCHAR(500) NOT NULL,
    FileSize    INT           NULL,
    IsDefault   BIT           NOT NULL DEFAULT 0,
    UploadedAt  DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CvFiles_Profile FOREIGN KEY (ProfileID)
        REFERENCES CandidateProfiles(ProfileID) ON DELETE CASCADE
);

-- BẢNG 4: CATEGORIES
CREATE TABLE Categories (
    CategoryID  INT IDENTITY(1,1) PRIMARY KEY,
    ParentID    INT           NULL,
    Name        NVARCHAR(100) NOT NULL,
    Type        NVARCHAR(30)  NOT NULL,
    Slug        NVARCHAR(120) NOT NULL UNIQUE,
    Description NVARCHAR(300) NULL
);

-- BẢNG 5: SKILLS
CREATE TABLE Skills (
    SkillID     INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(300) NULL
);

-- BẢNG 6: CANDIDATE_SKILLS
CREATE TABLE CandidateSkills (
    ProfileID   INT          NOT NULL,
    SkillID     INT          NOT NULL,
    Level       NVARCHAR(20) NOT NULL DEFAULT 'Intermediate',
    YearsOfExp  DECIMAL(4,1) NULL,
    PRIMARY KEY (ProfileID, SkillID),
    CONSTRAINT FK_CS_Profile FOREIGN KEY (ProfileID)
        REFERENCES CandidateProfiles(ProfileID) ON DELETE CASCADE,
    CONSTRAINT FK_CS_Skill   FOREIGN KEY (SkillID)
        REFERENCES Skills(SkillID)
);

-- BẢNG 7: EMPLOYERS
CREATE TABLE Employers (
    EmployerID  INT IDENTITY(1,1) PRIMARY KEY,
    UserID      INT           NOT NULL UNIQUE,
    CompanyName NVARCHAR(200) NOT NULL,
    TaxCode     NVARCHAR(20)  NULL,
    Industry    NVARCHAR(100) NULL,
    CompanySize NVARCHAR(50)  NULL,
    Address     NVARCHAR(300) NULL,
    Website     NVARCHAR(200) NULL,
    LogoURL     NVARCHAR(300) NULL,
    CoverURL    NVARCHAR(300) NULL,
    IsVerified  BIT           NOT NULL DEFAULT 0,
    Description NVARCHAR(MAX) NULL,
    CreatedAt   DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Employers_Users FOREIGN KEY (UserID)
        REFERENCES Users(UserID) ON DELETE CASCADE
);

-- BẢNG 8: JOB_POSTS
CREATE TABLE JobPosts (
    JobID            INT IDENTITY(1,1) PRIMARY KEY,
    EmployerID       INT           NOT NULL,
    CategoryID       INT           NULL,
    Title            NVARCHAR(200) NOT NULL,
    Description      NVARCHAR(MAX) NULL,
    Requirements     NVARCHAR(MAX) NULL,
    Benefits         NVARCHAR(MAX) NULL,
    SalaryMin        DECIMAL(15,0) NULL,
    SalaryMax        DECIMAL(15,0) NULL,
    SalaryNegotiable BIT           NOT NULL DEFAULT 0,
    JobType          NVARCHAR(30)  NOT NULL DEFAULT 'FullTime',
    Location         NVARCHAR(200) NULL,
    ExperienceLevel  NVARCHAR(30)  NULL,
    Deadline         DATE          NULL,
    Status           NVARCHAR(20)  NOT NULL DEFAULT 'Pending',
    ViewCount        INT           NOT NULL DEFAULT 0,
    IsFeatured       BIT           NOT NULL DEFAULT 0,
    CreatedAt        DATETIME      NOT NULL DEFAULT GETDATE(),
    UpdatedAt        DATETIME      NULL,
    CONSTRAINT FK_JobPosts_Employer FOREIGN KEY (EmployerID)
        REFERENCES Employers(EmployerID),
    CONSTRAINT FK_JobPosts_Category FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);

-- BẢNG 9: APPLICATIONS
CREATE TABLE Applications (
    AppID       INT IDENTITY(1,1) PRIMARY KEY,
    JobID       INT           NOT NULL,
    ProfileID   INT           NOT NULL,
    CVID        INT           NULL,
    CoverLetter NVARCHAR(MAX) NULL,
    Status      NVARCHAR(20)  NOT NULL DEFAULT 'Pending',
    AppliedAt   DATETIME      NOT NULL DEFAULT GETDATE(),
    UpdatedAt   DATETIME      NULL,
    CONSTRAINT FK_App_Job     FOREIGN KEY (JobID)     REFERENCES JobPosts(JobID),
    CONSTRAINT FK_App_Profile FOREIGN KEY (ProfileID) REFERENCES CandidateProfiles(ProfileID),
    CONSTRAINT FK_App_CV      FOREIGN KEY (CVID)      REFERENCES CvFiles(CVID),
    CONSTRAINT UQ_App         UNIQUE (JobID, ProfileID)
);

-- BẢNG 10: SAVED_JOBS
CREATE TABLE SavedJobs (
    SaveID  INT IDENTITY(1,1) PRIMARY KEY,
    UserID  INT      NOT NULL,
    JobID   INT      NOT NULL,
    SavedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_SJ_User FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT FK_SJ_Job  FOREIGN KEY (JobID)  REFERENCES JobPosts(JobID) ON DELETE CASCADE,
    CONSTRAINT UQ_SavedJob UNIQUE (UserID, JobID)
);

-- BẢNG 11: NOTIFICATIONS
CREATE TABLE Notifications (
    NotifID   INT IDENTITY(1,1) PRIMARY KEY,
    UserID    INT           NOT NULL,
    Title     NVARCHAR(200) NOT NULL,
    Content   NVARCHAR(MAX) NULL,
    Type      NVARCHAR(30)  NOT NULL DEFAULT 'System',
    IsRead    BIT           NOT NULL DEFAULT 0,
    RelatedID INT           NULL,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Notif_User FOREIGN KEY (UserID)
        REFERENCES Users(UserID) ON DELETE CASCADE
);

-- BẢNG 12: SERVICE_PACKAGES
CREATE TABLE ServicePackages (
    PackageID    INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(100) NOT NULL,
    Price        DECIMAL(15,0) NOT NULL,
    DurationDays INT           NOT NULL,
    MaxJobPosts  INT           NOT NULL,
    MaxFeatured  INT           NOT NULL DEFAULT 0,
    Description  NVARCHAR(MAX) NULL,
    IsActive     BIT           NOT NULL DEFAULT 1
);

-- BẢNG 13: TRANSACTIONS
CREATE TABLE Transactions (
    TransID       INT IDENTITY(1,1) PRIMARY KEY,
    EmployerID    INT           NOT NULL,
    PackageID     INT           NOT NULL,
    Amount        DECIMAL(15,0) NOT NULL,
    PaymentMethod NVARCHAR(30)  NOT NULL DEFAULT 'BankTransfer',
    Status        NVARCHAR(20)  NOT NULL DEFAULT 'Pending',
    ExpiredAt     DATETIME      NULL,
    CreatedAt     DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Trans_Employer FOREIGN KEY (EmployerID) REFERENCES Employers(EmployerID),
    CONSTRAINT FK_Trans_Package  FOREIGN KEY (PackageID)  REFERENCES ServicePackages(PackageID)
);

-- BẢNG 14: BLOG_POSTS
CREATE TABLE BlogPosts (
    PostID      INT IDENTITY(1,1) PRIMARY KEY,
    AuthorID    INT           NOT NULL,
    Title       NVARCHAR(300) NOT NULL,
    Slug        NVARCHAR(350) NOT NULL UNIQUE,
    Excerpt     NVARCHAR(500) NULL,
    Content     NVARCHAR(MAX) NULL,
    CoverURL    NVARCHAR(300) NULL,
    IsPublished BIT           NOT NULL DEFAULT 0,
    PublishedAt DATETIME      NULL,
    CreatedAt   DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Blog_Author FOREIGN KEY (AuthorID) REFERENCES Users(UserID)
);

-- BẢNG 15: SYSTEM_LOGS
CREATE TABLE SystemLogs (
    LogID     INT IDENTITY(1,1) PRIMARY KEY,
    UserID    INT           NULL,
    Action    NVARCHAR(100) NOT NULL,
    IPAddress NVARCHAR(45)  NULL,
    Detail    NVARCHAR(MAX) NULL,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Log_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO

-- ============================================================
--  SEED DATA (dữ liệu mẫu ban đầu)
-- ============================================================

-- Tài khoản Admin (password: Admin@123)
-- BCrypt hash của "Admin@123":
INSERT INTO Users (Email, PasswordHash, Role, FullName, Status) VALUES
('admin@jobconnect.vn','$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/MIJthivqi',
 'Admin', 'Quản trị viên', 'Active');

-- Tài khoản Nhà tuyển dụng mẫu (password: Test@123)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('hr@fptsoft.com',
 '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/MIJthivqi',
 'Employer', 'Nguyễn Thị HR', '0909123456', 'Active');

-- Tài khoản Ứng viên mẫu (password: Test@123)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('candidate@gmail.com',
 '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/MIJthivqi',
 'Candidate', 'Trần Văn Ứng Viên', '0901234567', 'Active');

-- Employer record cho user ID 2
INSERT INTO Employers (UserID, CompanyName, Industry, CompanySize, Address, Website, IsVerified, Description)
VALUES (2, 'FPT Software', 'Công nghệ thông tin', '1000+',
        '17 Duy Tân, Cầu Giấy, Hà Nội',
        'https://www.fpt-software.com', 1,
        'FPT Software là công ty phần mềm hàng đầu Việt Nam với hơn 27,000 nhân viên toàn cầu.');

-- Candidate profile cho user ID 3
INSERT INTO CandidateProfiles (UserID, Gender, Address, Summary, ExperienceYears, IsOpenToWork)
VALUES (3, 'Nam', 'Hà Nội', 'Lập trình viên với 2 năm kinh nghiệm về .NET và SQL Server.', 2, 1);

-- Danh mục ngành nghề
INSERT INTO Categories (Name, Type, Slug) VALUES
('Công nghệ thông tin',      'Industry', 'cong-nghe-thong-tin'),
('Marketing & Truyền thông', 'Industry', 'marketing'),
('Tài chính – Kế toán',     'Industry', 'tai-chinh-ke-toan'),
('Kỹ thuật – Cơ khí',       'Industry', 'ky-thuat-co-khi'),
('Y tế – Dược phẩm',        'Industry', 'y-te-duoc-pham'),
('Thiết kế – Mỹ thuật',     'Industry', 'thiet-ke'),
('Hà Nội',                  'Location', 'ha-noi'),
('TP. Hồ Chí Minh',         'Location', 'ho-chi-minh'),
('Đà Nẵng',                 'Location', 'da-nang'),
('Cần Thơ',                 'Location', 'can-tho'),
('Fresher',                 'Level',    'fresher'),
('Junior',                  'Level',    'junior'),
('Middle',                  'Level',    'middle'),
('Senior',                  'Level',    'senior'),
('FullTime',                'JobType',  'full-time'),
('PartTime',                'JobType',  'part-time'),
('Internship',              'JobType',  'internship'),
('Remote',                  'JobType',  'remote');

-- Kỹ năng
INSERT INTO Skills (Name) VALUES
('JavaScript'), ('Python'), ('Java'), ('C#'), ('.NET Core'),
('React.js'), ('Angular'), ('SQL Server'), ('MySQL'), ('MongoDB'),
('PHP'), ('HTML/CSS'), ('Excel'), ('Photoshop'), ('AutoCAD'),
('Figma'), ('Project Management'), ('English');

-- Gói dịch vụ
INSERT INTO ServicePackages (Name, Price, DurationDays, MaxJobPosts, MaxFeatured, Description) VALUES
('Miễn phí', 0,       30,  3,   0,  'Đăng tối đa 3 tin/tháng, không nổi bật'),
('Pro',       990000,  30,  15,  3,  '15 tin/tháng, 3 tin nổi bật, hỗ trợ ưu tiên'),
('Enterprise',2490000, 30, 999, 10, 'Không giới hạn tin, 10 tin nổi bật, logo premium');

-- Tin tuyển dụng mẫu
INSERT INTO JobPosts (EmployerID, CategoryID, Title, Description, Requirements, Benefits,
    SalaryMin, SalaryMax, JobType, Location, ExperienceLevel, Deadline, Status, IsFeatured)
VALUES
(1, 1,
 '.NET Developer (C# / ASP.NET Core)',
 N'Phát triển và bảo trì các ứng dụng web sử dụng ASP.NET Core MVC, API RESTful.',
 N'- Tối thiểu 1 năm kinh nghiệm C#/.NET' + CHAR(10) +
 N'- Biết SQL Server, EF Core' + CHAR(10) +
 N'- Có kiến thức HTML/CSS cơ bản',
 N'- Lương hấp dẫn theo năng lực' + CHAR(10) +
 N'- Thưởng hiệu suất hàng quý' + CHAR(10) +
 N'- Bảo hiểm sức khỏe cao cấp',
 15000000, 30000000, 'FullTime', N'Hà Nội', 'Junior',
 DATEADD(DAY, 30, GETDATE()), 'Open', 1),

(1, 1,
 'Frontend Developer – React.js',
 N'Xây dựng giao diện web hiện đại với React.js và TailwindCSS.',
 N'- 1+ năm kinh nghiệm React.js' + CHAR(10) +
 N'- Thành thạo HTML, CSS, JavaScript' + CHAR(10) +
 N'- Biết Git, REST API',
 N'- Remote 2 ngày/tuần' + CHAR(10) +
 N'- Môi trường startup năng động',
 12000000, 25000000, 'FullTime', N'TP. Hồ Chí Minh', 'Junior',
 DATEADD(DAY, 45, GETDATE()), 'Open', 1),

(1, 1,
 'Thực tập sinh IT – Backend Python',
 N'Hỗ trợ team backend phát triển các tính năng mới bằng Python/Django.',
 N'- Đang học năm 3-4 CNTT' + CHAR(10) +
 N'- Biết Python cơ bản' + CHAR(10) +
 N'- Ham học hỏi, chăm chỉ',
 N'- Phụ cấp 3-5 triệu/tháng' + CHAR(10) +
 N'- Hỗ trợ xét tuyển chính thức sau thực tập',
 3000000, 5000000, 'Intern', N'Hà Nội', 'Fresher',
 DATEADD(DAY, 60, GETDATE()), 'Open', 0);
GO

-- Kiểm tra dữ liệu
SELECT 'Users' AS [Table], COUNT(*) AS [Count] FROM Users
UNION ALL SELECT 'JobPosts', COUNT(*) FROM JobPosts
UNION ALL SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL SELECT 'Skills', COUNT(*) FROM Skills;

DELETE FROM Users WHERE Email = 'admin@jobconnect.vn';



UPDATE Users
SET Role = 'Admin'
WHERE Email = 'admin@jobconnect.vn';