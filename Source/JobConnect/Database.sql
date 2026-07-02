IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Categories] (
    [CategoryID] int NOT NULL IDENTITY,
    [ParentID] int NULL,
    [Name] nvarchar(max) NOT NULL,
    [Type] nvarchar(max) NOT NULL,
    [Slug] nvarchar(max) NOT NULL,
    [Description] nvarchar(max) NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY ([CategoryID]),
    CONSTRAINT [FK_Categories_Categories_ParentID] FOREIGN KEY ([ParentID]) REFERENCES [Categories] ([CategoryID]) ON DELETE NO ACTION
);

CREATE TABLE [PasswordResetTokens] (
    [Id] int NOT NULL IDENTITY,
    [Email] nvarchar(max) NOT NULL,
    [Code] nvarchar(6) NOT NULL,
    [ExpiresAt] datetime2 NOT NULL,
    [IsUsed] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY ([Id])
);

CREATE TABLE [ServicePackages] (
    [PackageID] int NOT NULL IDENTITY,
    [Name] nvarchar(max) NOT NULL,
    [Price] decimal(15,0) NOT NULL,
    [DurationDays] int NOT NULL,
    [MaxJobPosts] int NOT NULL,
    [MaxFeatured] int NOT NULL,
    [Description] nvarchar(max) NULL,
    [IsActive] bit NOT NULL,
    CONSTRAINT [PK_ServicePackages] PRIMARY KEY ([PackageID])
);

CREATE TABLE [Users] (
    [UserID] int NOT NULL IDENTITY,
    [Email] nvarchar(max) NOT NULL,
    [PasswordHash] nvarchar(max) NOT NULL,
    [Role] nvarchar(max) NOT NULL,
    [FullName] nvarchar(max) NOT NULL,
    [PhoneNumber] nvarchar(max) NULL,
    [AvatarURL] nvarchar(max) NULL,
    [Status] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    [LastLoginAt] datetime2 NULL,
    [OtpCode] nvarchar(max) NULL,
    [OtpExpiry] datetime2 NULL,
    [DeletedAt] datetime2 NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([UserID])
);

CREATE TABLE [Skills] (
    [SkillID] int NOT NULL IDENTITY,
    [Name] nvarchar(100) NOT NULL,
    [Description] nvarchar(500) NULL,
    [Category] int NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    [CategoryID] int NULL,
    CONSTRAINT [PK_Skills] PRIMARY KEY ([SkillID]),
    CONSTRAINT [FK_Skills_Categories_CategoryID] FOREIGN KEY ([CategoryID]) REFERENCES [Categories] ([CategoryID])
);

CREATE TABLE [BlogPosts] (
    [PostID] int NOT NULL IDENTITY,
    [AuthorID] int NOT NULL,
    [Title] nvarchar(max) NOT NULL,
    [Slug] nvarchar(max) NOT NULL,
    [Excerpt] nvarchar(max) NULL,
    [Content] nvarchar(max) NULL,
    [CoverURL] nvarchar(max) NULL,
    [IsPublished] bit NOT NULL,
    [PublishedAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_BlogPosts] PRIMARY KEY ([PostID]),
    CONSTRAINT [FK_BlogPosts_Users_AuthorID] FOREIGN KEY ([AuthorID]) REFERENCES [Users] ([UserID]) ON DELETE CASCADE
);

CREATE TABLE [CandidateProfiles] (
    [ProfileID] int NOT NULL IDENTITY,
    [UserID] int NOT NULL,
    [FullName] nvarchar(100) NULL,
    [Phone] nvarchar(15) NULL,
    [Avatar] nvarchar(500) NULL,
    [DateOfBirth] datetime2 NULL,
    [Gender] nvarchar(20) NULL,
    [Address] nvarchar(200) NULL,
    [JobTitle] nvarchar(100) NULL,
    [Summary] nvarchar(1000) NULL,
    [ExperienceYears] int NOT NULL,
    [DesiredSalary] decimal(15,0) NULL,
    [IsOpenToWork] bit NOT NULL,
    CONSTRAINT [PK_CandidateProfiles] PRIMARY KEY ([ProfileID]),
    CONSTRAINT [FK_CandidateProfiles_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID]) ON DELETE CASCADE
);

CREATE TABLE [Employers] (
    [EmployerID] int NOT NULL IDENTITY,
    [UserID] int NOT NULL,
    [CompanyName] nvarchar(max) NOT NULL,
    [TaxCode] nvarchar(max) NULL,
    [Industry] nvarchar(max) NULL,
    [CompanySize] nvarchar(max) NULL,
    [Address] nvarchar(max) NULL,
    [Website] nvarchar(max) NULL,
    [LogoURL] nvarchar(max) NULL,
    [CoverURL] nvarchar(max) NULL,
    [IsVerified] bit NOT NULL,
    [IsLocked] bit NOT NULL,
    [Description] nvarchar(max) NULL,
    [WhyWorkHereJson] nvarchar(max) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Employers] PRIMARY KEY ([EmployerID]),
    CONSTRAINT [FK_Employers_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID]) ON DELETE CASCADE
);

CREATE TABLE [Notifications] (
    [NotifID] int NOT NULL IDENTITY,
    [UserID] int NOT NULL,
    [Title] nvarchar(max) NOT NULL,
    [Content] nvarchar(max) NULL,
    [Type] nvarchar(max) NOT NULL,
    [IsRead] bit NOT NULL,
    [RelatedID] int NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Notifications] PRIMARY KEY ([NotifID]),
    CONSTRAINT [FK_Notifications_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION
);

CREATE TABLE [Staff] (
    [Id] int NOT NULL IDENTITY,
    [ApplicationUserId] int NOT NULL,
    [EmployeeCode] nvarchar(20) NOT NULL,
    [FullName] nvarchar(100) NOT NULL,
    [Email] nvarchar(100) NOT NULL,
    [Phone] nvarchar(20) NULL,
    [Avatar] nvarchar(500) NULL,
    [Position] nvarchar(100) NOT NULL,
    [Department] nvarchar(100) NOT NULL,
    [Status] int NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_Staff] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Staff_Users_ApplicationUserId] FOREIGN KEY ([ApplicationUserId]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION
);

CREATE TABLE [SystemLogs] (
    [LogID] int NOT NULL IDENTITY,
    [UserID] int NULL,
    [Action] nvarchar(max) NOT NULL,
    [IPAddress] nvarchar(max) NULL,
    [Detail] nvarchar(max) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_SystemLogs] PRIMARY KEY ([LogID]),
    CONSTRAINT [FK_SystemLogs_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID])
);

CREATE TABLE [CandidateSkills] (
    [ProfileID] int NOT NULL,
    [SkillID] int NOT NULL,
    [ProficiencyLevel] int NOT NULL,
    [YearsOfExperience] decimal(5,2) NOT NULL,
    [LastUsedDate] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_CandidateSkills] PRIMARY KEY ([ProfileID], [SkillID]),
    CONSTRAINT [FK_CandidateSkills_CandidateProfiles_ProfileID] FOREIGN KEY ([ProfileID]) REFERENCES [CandidateProfiles] ([ProfileID]) ON DELETE CASCADE,
    CONSTRAINT [FK_CandidateSkills_Skills_SkillID] FOREIGN KEY ([SkillID]) REFERENCES [Skills] ([SkillID]) ON DELETE CASCADE
);

CREATE TABLE [CvFiles] (
    [CvID] int NOT NULL IDENTITY,
    [ProfileID] int NOT NULL,
    [FileName] nvarchar(200) NOT NULL,
    [FilePath] nvarchar(500) NOT NULL,
    [FileSize] bigint NULL,
    [IsDefault] bit NOT NULL,
    [UploadedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_CvFiles] PRIMARY KEY ([CvID]),
    CONSTRAINT [FK_CvFiles_CandidateProfiles_ProfileID] FOREIGN KEY ([ProfileID]) REFERENCES [CandidateProfiles] ([ProfileID]) ON DELETE CASCADE
);

CREATE TABLE [JobPosts] (
    [JobID] int NOT NULL IDENTITY,
    [EmployerID] int NOT NULL,
    [CategoryID] int NULL,
    [Title] nvarchar(max) NOT NULL,
    [Description] nvarchar(max) NULL,
    [Requirements] nvarchar(max) NULL,
    [Benefits] nvarchar(max) NULL,
    [SalaryMin] decimal(15,0) NULL,
    [SalaryMax] decimal(15,0) NULL,
    [SalaryNegotiable] bit NOT NULL,
    [JobType] nvarchar(max) NOT NULL,
    [Location] nvarchar(max) NULL,
    [ExperienceLevel] nvarchar(max) NULL,
    [Deadline] datetime2 NULL,
    [Status] nvarchar(max) NOT NULL,
    [ViewCount] int NOT NULL,
    [IsFeatured] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_JobPosts] PRIMARY KEY ([JobID]),
    CONSTRAINT [FK_JobPosts_Categories_CategoryID] FOREIGN KEY ([CategoryID]) REFERENCES [Categories] ([CategoryID]),
    CONSTRAINT [FK_JobPosts_Employers_EmployerID] FOREIGN KEY ([EmployerID]) REFERENCES [Employers] ([EmployerID]) ON DELETE CASCADE
);

CREATE TABLE [Transactions] (
    [TransID] int NOT NULL IDENTITY,
    [EmployerID] int NOT NULL,
    [PackageID] int NOT NULL,
    [Amount] decimal(15,0) NOT NULL,
    [PaymentMethod] nvarchar(max) NOT NULL,
    [Status] nvarchar(max) NOT NULL,
    [ExpiredAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL,
    [ServicePackagePackageID] int NOT NULL,
    CONSTRAINT [PK_Transactions] PRIMARY KEY ([TransID]),
    CONSTRAINT [FK_Transactions_Employers_EmployerID] FOREIGN KEY ([EmployerID]) REFERENCES [Employers] ([EmployerID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Transactions_ServicePackages_ServicePackagePackageID] FOREIGN KEY ([ServicePackagePackageID]) REFERENCES [ServicePackages] ([PackageID]) ON DELETE CASCADE
);

CREATE TABLE [ActivityLogs] (
    [Id] int NOT NULL IDENTITY,
    [StaffId] int NOT NULL,
    [Action] nvarchar(100) NOT NULL,
    [Description] nvarchar(500) NULL,
    [IpAddress] nvarchar(100) NULL,
    [UserAgent] nvarchar(500) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_ActivityLogs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ActivityLogs_Staff_StaffId] FOREIGN KEY ([StaffId]) REFERENCES [Staff] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [SupportTickets] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Type] int NOT NULL,
    [Subject] nvarchar(200) NOT NULL,
    [Message] nvarchar(max) NOT NULL,
    [Status] int NOT NULL,
    [AssignedToStaffId] int NULL,
    [Priority] int NULL,
    [StaffResponse] nvarchar(max) NULL,
    [AssignedAt] datetime2 NULL,
    [ResolvedAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_SupportTickets] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SupportTickets_Staff_AssignedToStaffId] FOREIGN KEY ([AssignedToStaffId]) REFERENCES [Staff] ([Id]) ON DELETE SET NULL,
    CONSTRAINT [FK_SupportTickets_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION
);

CREATE TABLE [Applications] (
    [AppID] int NOT NULL IDENTITY,
    [JobID] int NOT NULL,
    [ProfileID] int NOT NULL,
    [CVID] int NULL,
    [CoverLetter] nvarchar(1000) NULL,
    [Status] nvarchar(50) NOT NULL,
    [AppliedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_Applications] PRIMARY KEY ([AppID]),
    CONSTRAINT [FK_Applications_CandidateProfiles_ProfileID] FOREIGN KEY ([ProfileID]) REFERENCES [CandidateProfiles] ([ProfileID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Applications_CvFiles_CVID] FOREIGN KEY ([CVID]) REFERENCES [CvFiles] ([CvID]),
    CONSTRAINT [FK_Applications_JobPosts_JobID] FOREIGN KEY ([JobID]) REFERENCES [JobPosts] ([JobID]) ON DELETE NO ACTION
);

CREATE TABLE [Reports] (
    [Id] int NOT NULL IDENTITY,
    [ReporterId] int NOT NULL,
    [ReporterType] int NOT NULL,
    [ReportType] int NOT NULL,
    [JobPostId] int NULL,
    [CompanyId] int NULL,
    [ReportedEntityName] nvarchar(100) NULL,
    [Reason] nvarchar(500) NOT NULL,
    [Description] nvarchar(2000) NULL,
    [Status] int NOT NULL,
    [ProcessedByStaffId] int NULL,
    [ProcessNote] nvarchar(500) NULL,
    [ProcessedAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Reports] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Reports_Employers_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Employers] ([EmployerID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Reports_JobPosts_JobPostId] FOREIGN KEY ([JobPostId]) REFERENCES [JobPosts] ([JobID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Reports_Staff_ProcessedByStaffId] FOREIGN KEY ([ProcessedByStaffId]) REFERENCES [Staff] ([Id]) ON DELETE SET NULL,
    CONSTRAINT [FK_Reports_Users_ReporterId] FOREIGN KEY ([ReporterId]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION
);

CREATE TABLE [SavedJobs] (
    [SaveID] int NOT NULL IDENTITY,
    [UserID] int NOT NULL,
    [JobID] int NOT NULL,
    [SavedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_SavedJobs] PRIMARY KEY ([SaveID]),
    CONSTRAINT [FK_SavedJobs_JobPosts_JobID] FOREIGN KEY ([JobID]) REFERENCES [JobPosts] ([JobID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SavedJobs_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID]) ON DELETE CASCADE
);

CREATE TABLE [Interviews] (
    [InterviewID] int NOT NULL IDENTITY,
    [AppID] int NOT NULL,
    [InterviewDate] datetime2 NOT NULL,
    [Location] nvarchar(200) NOT NULL,
    [Notes] nvarchar(1000) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Interviews] PRIMARY KEY ([InterviewID]),
    CONSTRAINT [FK_Interviews_Applications_AppID] FOREIGN KEY ([AppID]) REFERENCES [Applications] ([AppID]) ON DELETE CASCADE
);

CREATE INDEX [IX_ActivityLogs_StaffId] ON [ActivityLogs] ([StaffId]);

CREATE INDEX [IX_Applications_CVID] ON [Applications] ([CVID]);

CREATE UNIQUE INDEX [IX_Applications_JobID_ProfileID] ON [Applications] ([JobID], [ProfileID]);

CREATE INDEX [IX_Applications_ProfileID] ON [Applications] ([ProfileID]);

CREATE INDEX [IX_BlogPosts_AuthorID] ON [BlogPosts] ([AuthorID]);

CREATE UNIQUE INDEX [IX_CandidateProfiles_UserID] ON [CandidateProfiles] ([UserID]);

CREATE INDEX [IX_CandidateSkills_SkillID] ON [CandidateSkills] ([SkillID]);

CREATE INDEX [IX_Categories_ParentID] ON [Categories] ([ParentID]);

CREATE INDEX [IX_CvFiles_ProfileID] ON [CvFiles] ([ProfileID]);

CREATE UNIQUE INDEX [IX_Employers_UserID] ON [Employers] ([UserID]);

CREATE INDEX [IX_Interviews_AppID] ON [Interviews] ([AppID]);

CREATE INDEX [IX_JobPosts_CategoryID] ON [JobPosts] ([CategoryID]);

CREATE INDEX [IX_JobPosts_EmployerID] ON [JobPosts] ([EmployerID]);

CREATE INDEX [IX_Notifications_UserID] ON [Notifications] ([UserID]);

CREATE INDEX [IX_Reports_CompanyId] ON [Reports] ([CompanyId]);

CREATE INDEX [IX_Reports_JobPostId] ON [Reports] ([JobPostId]);

CREATE INDEX [IX_Reports_ProcessedByStaffId] ON [Reports] ([ProcessedByStaffId]);

CREATE INDEX [IX_Reports_ReporterId] ON [Reports] ([ReporterId]);

CREATE INDEX [IX_SavedJobs_JobID] ON [SavedJobs] ([JobID]);

CREATE UNIQUE INDEX [IX_SavedJobs_UserID_JobID] ON [SavedJobs] ([UserID], [JobID]);

CREATE INDEX [IX_Skills_CategoryID] ON [Skills] ([CategoryID]);

CREATE UNIQUE INDEX [IX_Skills_Name] ON [Skills] ([Name]);

CREATE INDEX [IX_Staff_ApplicationUserId] ON [Staff] ([ApplicationUserId]);

CREATE UNIQUE INDEX [IX_Staff_EmployeeCode] ON [Staff] ([EmployeeCode]);

CREATE INDEX [IX_SupportTickets_AssignedToStaffId] ON [SupportTickets] ([AssignedToStaffId]);

CREATE INDEX [IX_SupportTickets_UserId] ON [SupportTickets] ([UserId]);

CREATE INDEX [IX_SystemLogs_UserID] ON [SystemLogs] ([UserID]);

CREATE INDEX [IX_Transactions_EmployerID] ON [Transactions] ([EmployerID]);

CREATE INDEX [IX_Transactions_ServicePackagePackageID] ON [Transactions] ([ServicePackagePackageID]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260627084840_InitialCreate', N'10.0.9');

COMMIT;
GO

BEGIN TRANSACTION;
DROP INDEX [IX_Staff_ApplicationUserId] ON [Staff];

DECLARE @var nvarchar(max);
SELECT @var = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[SupportTickets]') AND [c].[name] = N'Priority');
IF @var IS NOT NULL EXEC(N'ALTER TABLE [SupportTickets] DROP CONSTRAINT ' + @var + ';');
UPDATE [SupportTickets] SET [Priority] = 0 WHERE [Priority] IS NULL;
ALTER TABLE [SupportTickets] ALTER COLUMN [Priority] int NOT NULL;
ALTER TABLE [SupportTickets] ADD DEFAULT 0 FOR [Priority];

CREATE UNIQUE INDEX [IX_Staff_ApplicationUserId] ON [Staff] ([ApplicationUserId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260627110309_AddUpdatedAtToBlogPosts', N'10.0.9');

COMMIT;
GO

BEGIN TRANSACTION;
CREATE TABLE [Messages] (
    [MessageID] int NOT NULL IDENTITY,
    [SenderID] int NOT NULL,
    [ReceiverID] int NOT NULL,
    [Content] nvarchar(max) NOT NULL,
    [IsRead] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [JobID] int NULL,
    CONSTRAINT [PK_Messages] PRIMARY KEY ([MessageID]),
    CONSTRAINT [FK_Messages_JobPosts_JobID] FOREIGN KEY ([JobID]) REFERENCES [JobPosts] ([JobID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Messages_Users_ReceiverID] FOREIGN KEY ([ReceiverID]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Messages_Users_SenderID] FOREIGN KEY ([SenderID]) REFERENCES [Users] ([UserID]) ON DELETE NO ACTION
);

CREATE INDEX [IX_Messages_JobID] ON [Messages] ([JobID]);

CREATE INDEX [IX_Messages_ReceiverID] ON [Messages] ([ReceiverID]);

CREATE INDEX [IX_Messages_SenderID] ON [Messages] ([SenderID]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260627131525_AddMessageTable', N'10.0.9');

COMMIT;
GO

