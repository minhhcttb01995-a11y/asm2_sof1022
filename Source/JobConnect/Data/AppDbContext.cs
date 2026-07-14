using System;
using System.Collections.Generic;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<ActivityLog> ActivityLogs { get; set; }

    public virtual DbSet<Application> Applications { get; set; }

    public virtual DbSet<BlogPost> BlogPosts { get; set; }

    public virtual DbSet<CandidateProfile> CandidateProfiles { get; set; }

    public virtual DbSet<CandidateSkill> CandidateSkills { get; set; }

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<CvFile> CvFiles { get; set; }

    public virtual DbSet<CompanyHighlight> CompanyHighlights { get; set; }

    public virtual DbSet<Employer> Employers { get; set; }

    public virtual DbSet<Interview> Interviews { get; set; }

    public virtual DbSet<JobPost> JobPosts { get; set; }

    public virtual DbSet<Message> Messages { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<PasswordResetToken> PasswordResetTokens { get; set; }

    public virtual DbSet<Report> Reports { get; set; }

    public virtual DbSet<SavedJob> SavedJobs { get; set; }

    public virtual DbSet<CompanyFollow> CompanyFollows { get; set; }

    public virtual DbSet<ServicePackage> ServicePackages { get; set; }

    public virtual DbSet<Skill> Skills { get; set; }

    public virtual DbSet<StatusCatalog> StatusCatalogs { get; set; }

    public virtual DbSet<Staff> Staff { get; set; }

    public virtual DbSet<SupportTicket> SupportTickets { get; set; }

    public virtual DbSet<SystemLog> SystemLogs { get; set; }

    public virtual DbSet<Transaction> Transactions { get; set; }

    public virtual DbSet<User> Users { get; set; }

    //protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    //#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
    // => optionsBuilder.UseSqlServer("Server=DESKTOP-5SHF71M;Database=JobConnectDB9;Trusted_Connection=True;TrustServerCertificate=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ActivityLog>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Activity__3214EC0798E2F6FE");

            entity.HasIndex(e => e.StaffId, "IX_ActivityLogs_StaffId");

            entity.Property(e => e.Action).HasMaxLength(100);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.IpAddress).HasMaxLength(100);
            entity.Property(e => e.UserAgent).HasMaxLength(500);

            entity.HasOne(d => d.Staff).WithMany(p => p.ActivityLogs)
                .HasForeignKey(d => d.StaffId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ActivityLogs_Staff");
        });

        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(e => e.AppID).HasName("PK__Applicat__8E2CF7D9E7DB0FAA");

            entity.HasIndex(e => e.Cvid, "IX_Applications_Cvid");

            entity.HasIndex(e => e.JobId, "IX_Applications_JobId");

            entity.HasIndex(e => e.ProfileId, "IX_Applications_ProfileId");

            entity.HasIndex(e => new { e.JobId, e.ProfileId }, "UQ_Applications_JobId_ProfileId").IsUnique();

            entity.Property(e => e.AppID).HasColumnName("AppID");
            entity.Property(e => e.AppliedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.CoverLetter).HasMaxLength(1000);
            entity.Property(e => e.JobId).HasColumnName("JobId");
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Pending");

            entity.HasOne(d => d.Cv).WithMany(p => p.Applications)
                .HasForeignKey(d => d.Cvid)
                .HasConstraintName("FK_Applications_Cv");

            entity.HasOne(d => d.Job).WithMany(p => p.Applications)
                .HasForeignKey(d => d.JobId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Applications_Job");

            entity.HasOne(d => d.CandidateProfile).WithMany(p => p.Applications)
                .HasForeignKey(d => d.ProfileId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Applications_Profile");
        });

        modelBuilder.Entity<BlogPost>(entity =>
        {
            entity.HasKey(e => e.PostId).HasName("PK__BlogPost__AA126038548B973C");

            entity.HasIndex(e => e.AuthorId, "IX_BlogPosts_AuthorID");
            entity.HasIndex(e => e.BlogCode, "UQ_BlogPosts_BlogCode").IsUnique();

            entity.Property(e => e.PostId).HasColumnName("PostID");
            entity.Property(e => e.BlogCode).HasMaxLength(20);
            entity.Property(e => e.AuthorId).HasColumnName("AuthorID");
            entity.Property(e => e.CoverUrl)
                .HasMaxLength(500)
                .HasColumnName("CoverURL");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Slug).HasMaxLength(300);
            entity.Property(e => e.Title).HasMaxLength(300);

            entity.HasOne(d => d.Author).WithMany(p => p.BlogPosts)
                .HasForeignKey(d => d.AuthorId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BlogPosts_Author");
        });

        modelBuilder.Entity<CandidateProfile>(entity =>
        {
            entity.HasKey(e => e.ProfileId).HasName("PK__Candidat__290C88E4A8192495");

            entity.HasIndex(e => e.UserId, "UQ_CandidateProfiles_UserId").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(200);
            entity.Property(e => e.Avatar).HasMaxLength(500);
            entity.Property(e => e.DesiredSalary).HasColumnType("decimal(15, 0)");
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.Gender).HasMaxLength(20);
            entity.Property(e => e.IsOpenToWork).HasDefaultValue(true);
            entity.Property(e => e.JobTitle).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(15);
            entity.Property(e => e.Summary).HasMaxLength(1000);

            entity.HasOne(d => d.User).WithOne(p => p.CandidateProfile)
                .HasForeignKey<CandidateProfile>(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CandidateProfiles_User");
        });

        modelBuilder.Entity<CandidateSkill>(entity =>
        {
            entity.HasKey(e => new { e.ProfileId, e.SkillId });

            entity.HasIndex(e => e.SkillId, "IX_CandidateSkills_SkillID");

            entity.Property(e => e.SkillId).HasColumnName("SkillID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.YearsOfExperience).HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.Profile).WithMany(p => p.CandidateSkills)
                .HasForeignKey(d => d.ProfileId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CandidateSkills_Profile");

            entity.HasOne(d => d.Skill).WithMany(p => p.CandidateSkills)
                .HasForeignKey(d => d.SkillId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CandidateSkills_Skill");
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.CategoryId).HasName("PK__Categori__19093A2B4B95AA82");

            entity.HasIndex(e => e.ParentId, "IX_Categories_ParentID");

            entity.Property(e => e.CategoryId).HasColumnName("CategoryID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Name).HasMaxLength(150);
            entity.Property(e => e.ParentId).HasColumnName("ParentID");
            entity.Property(e => e.Slug).HasMaxLength(150);
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.Parent).WithMany(p => p.InverseParent)
                .HasForeignKey(d => d.ParentId)
                .HasConstraintName("FK_Categories_Parent");
        });

        modelBuilder.Entity<CvFile>(entity =>
        {
            entity.HasKey(e => e.Cvid).HasName("PK__CvFiles__4FB410A12C50CD83");

            entity.HasIndex(e => e.ProfileId, "IX_CvFiles_ProfileId");

            entity.Property(e => e.FileName).HasMaxLength(200);
            entity.Property(e => e.FilePath).HasMaxLength(500);
            entity.Property(e => e.UploadedAt).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.Profile).WithMany(p => p.CvFiles)
                .HasForeignKey(d => d.ProfileId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CvFiles_Profile");
        });

        modelBuilder.Entity<Employer>(entity =>
        {
            entity.HasKey(e => e.EmployerId).HasName("PK__Employer__CA445261B9EC31B5");

            entity.HasIndex(e => e.UserId, "UQ_Employers_UserId").IsUnique();
            entity.HasIndex(e => e.CompanyCode, "UQ_Employers_CompanyCode").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(300);
            entity.Property(e => e.Gender).HasMaxLength(20);
            entity.Property(e => e.CCCD).HasMaxLength(20);
            entity.Property(e => e.CompanyCode).HasMaxLength(20);
            entity.Property(e => e.CompanyName).HasMaxLength(200);
            entity.Property(e => e.CompanySize).HasMaxLength(50);
            entity.Property(e => e.CoverUrl)
                .HasMaxLength(500)
                .HasColumnName("CoverURL");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Industry).HasMaxLength(100);
            entity.Property(e => e.LogoUrl)
                .HasMaxLength(500)
                .HasColumnName("LogoURL");
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Active");
            entity.Property(e => e.TaxCode).HasMaxLength(50);
            entity.Property(e => e.Website).HasMaxLength(300);
            entity.Property(e => e.IsFeatured).HasDefaultValue(false);

            entity.HasOne(d => d.User).WithOne(p => p.Employer)
                .HasForeignKey<Employer>(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Employers_User");
        });

        modelBuilder.Entity<Interview>(entity =>
        {
            entity.HasKey(e => e.InterviewId).HasName("PK__Intervie__C97C5832D5B7A508");
            entity.HasIndex(e => e.AppID, "IX_Interviews_AppID");

            entity.Property(e => e.InterviewId).HasColumnName("InterviewID");
            entity.Property(e => e.AppID).HasColumnName("AppID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Location).HasMaxLength(200);
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.HasOne(d => d.Application).WithMany(p => p.Interviews)
                .HasForeignKey(d => d.AppID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Interviews_Applications");
        });

        modelBuilder.Entity<JobPost>(entity =>
        {
            entity.HasKey(e => e.JobId).HasName("PK__JobPosts__056690E24DC12FC1");

            entity.HasIndex(e => e.CategoryId, "IX_JobPosts_CategoryID");

            entity.HasIndex(e => e.EmployerId, "IX_JobPosts_EmployerId");
            entity.HasIndex(e => e.JobCode, "UQ_JobPosts_JobCode").IsUnique();

            entity.Property(e => e.JobId).HasColumnName("JobId");
            entity.Property(e => e.JobCode).HasMaxLength(20);
            entity.Property(e => e.CategoryId).HasColumnName("CategoryID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.ExperienceLevel).HasMaxLength(50);
            entity.Property(e => e.JobType).HasMaxLength(50);
            entity.Property(e => e.Location).HasMaxLength(200);
            entity.Property(e => e.SalaryMax).HasColumnType("decimal(15, 0)");
            entity.Property(e => e.SalaryMin).HasColumnType("decimal(15, 0)");
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.Title).HasMaxLength(200);

            entity.HasOne(d => d.Category).WithMany(p => p.JobPosts)
                .HasForeignKey(d => d.CategoryId)
                .HasConstraintName("FK_JobPosts_Category");

            entity.HasOne(d => d.Employer).WithMany(p => p.JobPosts)
                .HasForeignKey(d => d.EmployerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_JobPosts_Employer");
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.MessageId).HasName("PK__Messages__C87C037C8050DD3D");

            entity.HasIndex(e => e.JobId, "IX_Messages_JobId");

            entity.HasIndex(e => e.ReceiverId, "IX_Messages_ReceiverId");

            entity.HasIndex(e => e.SenderId, "IX_Messages_SenderId");

            entity.Property(e => e.MessageId).HasColumnName("MessageId");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.JobId).HasColumnName("JobId");
            entity.Property(e => e.ReceiverId).HasColumnName("ReceiverId");
            entity.Property(e => e.SenderId).HasColumnName("SenderId");

            entity.HasOne(d => d.Job).WithMany(p => p.Messages)
                .HasForeignKey(d => d.JobId)
                .HasConstraintName("FK_Messages_Job");

            entity.HasOne(d => d.Receiver).WithMany(p => p.MessageReceivers)
                .HasForeignKey(d => d.ReceiverId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Messages_Receiver");

            entity.HasOne(d => d.Sender).WithMany(p => p.MessageSenders)
                .HasForeignKey(d => d.SenderId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Messages_Sender");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotifId).HasName("PK__Notifica__DDBFF33312327ADF");

            entity.HasIndex(e => e.UserId, "IX_Notifications_UserId");

            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Notifications_User");
        });

        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Password__3214EC070019E513");

            entity.Property(e => e.Code).HasMaxLength(6);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Email).HasMaxLength(200);
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Reports__3214EC071409C61C");

            entity.HasIndex(e => e.CompanyId, "IX_Reports_CompanyId");

            entity.HasIndex(e => e.JobPostId, "IX_Reports_JobPostId");

            entity.HasIndex(e => e.ProcessedByStaffId, "IX_Reports_ProcessedByStaffId");

            entity.HasIndex(e => e.ReporterId, "IX_Reports_ReporterId");

            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.ProcessNote).HasMaxLength(500);
            entity.Property(e => e.Reason).HasMaxLength(500);
            entity.Property(e => e.ReportedEntityName).HasMaxLength(100);

            entity.HasOne(d => d.Company).WithMany(p => p.Reports)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_Reports_Company");

            entity.HasOne(d => d.JobPost).WithMany(p => p.Reports)
                .HasForeignKey(d => d.JobPostId)
                .HasConstraintName("FK_Reports_JobPost");

            entity.HasOne(d => d.ProcessedByStaff).WithMany(p => p.Reports)
                .HasForeignKey(d => d.ProcessedByStaffId)
                .HasConstraintName("FK_Reports_Staff");

            entity.HasOne(d => d.Reporter).WithMany(p => p.Reports)
                .HasForeignKey(d => d.ReporterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Reports_Reporter");
        });

        modelBuilder.Entity<SavedJob>(entity =>
        {
            entity.HasKey(e => e.SaveId).HasName("PK__SavedJob__1450D386600989B5");

            entity.HasIndex(e => e.JobId, "IX_SavedJobs_JobId");

            entity.HasIndex(e => e.UserId, "IX_SavedJobs_UserId");

            entity.HasIndex(e => new { e.UserId, e.JobId }, "UQ_SavedJobs_UserId_JobId").IsUnique();

            entity.Property(e => e.SaveId).HasColumnName("SaveID");
            entity.Property(e => e.JobId).HasColumnName("JobId");
            entity.Property(e => e.SavedAt).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.Job).WithMany(p => p.SavedJobs)
                .HasForeignKey(d => d.JobId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SavedJobs_Job");

            entity.HasOne(d => d.User).WithMany(p => p.SavedJobs)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SavedJobs_User");
        });

        modelBuilder.Entity<CompanyFollow>(entity =>
        {
            entity.HasKey(e => e.FollowId).HasName("PK__CompanyFollows__FollowId");

            entity.HasIndex(e => e.UserId, "IX_CompanyFollows_UserId");

            entity.HasIndex(e => e.EmployerId, "IX_CompanyFollows_EmployerId");

            entity.HasIndex(e => new { e.UserId, e.EmployerId }, "UQ_CompanyFollows_UserId_EmployerId").IsUnique();

            entity.Property(e => e.FollowId).HasColumnName("FollowID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.User).WithMany()
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CompanyFollows_User");

            entity.HasOne(d => d.Employer).WithMany()
                .HasForeignKey(d => d.EmployerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CompanyFollows_Employer");
        });

        modelBuilder.Entity<ServicePackage>(entity =>
        {
            entity.HasKey(e => e.PackageId).HasName("PK__ServiceP__322035EC608B3677");

            entity.Property(e => e.PackageId).HasColumnName("PackageID");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Name).HasMaxLength(150);
            entity.Property(e => e.Price).HasColumnType("decimal(15, 0)");
        });

        modelBuilder.Entity<StatusCatalog>(entity =>
        {
            entity.ToTable("StatusCatalog");

            entity.HasKey(e => e.Id);

            entity.HasIndex(e => e.EntityType, "IX_StatusCatalog_EntityType");

            entity.HasIndex(e => new { e.EntityType, e.Code }, "UQ_StatusCatalog_Entity_Code").IsUnique();

            entity.Property(e => e.EntityType).HasMaxLength(30);
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.ColorClass).HasMaxLength(80);
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.BlocksLogin).HasDefaultValue(false);
            entity.Property(e => e.ShowPublicly).HasDefaultValue(true);
            entity.Property(e => e.IsSystem).HasDefaultValue(false);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
        });

        modelBuilder.Entity<Skill>(entity =>
        {
            entity.HasKey(e => e.SkillId).HasName("PK__Skills__DFA091E7B01A197E");

            entity.HasIndex(e => e.CategoryId, "IX_Skills_CategoryID");

            entity.HasIndex(e => e.Name, "UQ_Skills_Name").IsUnique();

            entity.Property(e => e.SkillId).HasColumnName("SkillID");
            entity.Property(e => e.CategoryId).HasColumnName("CategoryID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.Category).WithMany(p => p.Skills)
                .HasForeignKey(d => d.CategoryId)
                .HasConstraintName("FK_Skills_Category");
        });

        modelBuilder.Entity<Staff>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Staff__3214EC077BC00A47");

            entity.HasIndex(e => e.ApplicationUserId, "UQ_Staff_ApplicationUserId").IsUnique();

            entity.HasIndex(e => e.EmployeeCode, "UQ_Staff_EmployeeCode").IsUnique();

            entity.Property(e => e.Avatar).HasMaxLength(500);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Department).HasMaxLength(100);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.EmployeeCode).HasMaxLength(20);
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.Gender).HasMaxLength(20);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Position).HasMaxLength(100);
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Active");

            entity.HasOne(d => d.ApplicationUser).WithOne(p => p.Staff)
                .HasForeignKey<Staff>(d => d.ApplicationUserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Staff_User");
        });

        modelBuilder.Entity<SupportTicket>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__SupportT__3214EC07837E0921");

            entity.HasIndex(e => e.AssignedToStaffId, "IX_SupportTickets_AssignedToStaffId");

            entity.HasIndex(e => e.UserId, "IX_SupportTickets_UserId");

            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Subject).HasMaxLength(200);

            entity.HasOne(d => d.AssignedToStaff).WithMany(p => p.SupportTickets)
                .HasForeignKey(d => d.AssignedToStaffId)
                .HasConstraintName("FK_SupportTickets_Staff");

            entity.HasOne(d => d.User).WithMany(p => p.SupportTickets)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportTickets_User");
        });

        modelBuilder.Entity<SystemLog>(entity =>
        {
            entity.HasKey(e => e.LogId).HasName("PK__SystemLo__5E5499A815DD0ABD");

            entity.HasIndex(e => e.UserId, "IX_SystemLogs_UserId");

            entity.Property(e => e.LogId).HasColumnName("LogID");
            entity.Property(e => e.Action).HasMaxLength(200);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Ipaddress)
                .HasMaxLength(100)
                .HasColumnName("IPAddress");

            entity.HasOne(d => d.User).WithMany(p => p.SystemLogs)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK_SystemLogs_User");
        });

        modelBuilder.Entity<Transaction>(entity =>
        {
            entity.HasKey(e => e.TransId).HasName("PK__Transact__9E5DDB1C4600C2FD");

            entity.HasIndex(e => e.EmployerId, "IX_Transactions_EmployerId");

            entity.HasIndex(e => e.PackageId, "IX_Transactions_PackageID");

            entity.Property(e => e.TransId).HasColumnName("TransID");
            entity.Property(e => e.Amount).HasColumnType("decimal(15, 0)");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.PackageId).HasColumnName("PackageID");
            entity.Property(e => e.PaymentMethod).HasMaxLength(50);
            entity.Property(e => e.Status).HasMaxLength(50);

            entity.HasOne(d => d.Employer).WithMany(p => p.Transactions)
                .HasForeignKey(d => d.EmployerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Transactions_Employer");

            entity.HasOne(d => d.Package).WithMany(p => p.Transactions)
                .HasForeignKey(d => d.PackageId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Transactions_Package");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__Users__1788CC4C87A7D02E");

            entity.HasIndex(e => e.Email, "UQ_Users_Email").IsUnique();
            entity.HasIndex(e => e.UserCode, "UQ_Users_UserCode").IsUnique();

            entity.Property(e => e.AvatarUrl).HasMaxLength(500);
            entity.Property(e => e.UserCode).HasMaxLength(20);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.FullName).HasMaxLength(200);
            entity.Property(e => e.OtpCode).HasMaxLength(10);
            entity.Property(e => e.PhoneNumber).HasMaxLength(20);
            entity.Property(e => e.Role).HasMaxLength(50);
            entity.Property(e => e.Status).HasMaxLength(50);
        });
        modelBuilder.Entity<CompanyHighlight>(entity =>
        {
            entity.ToTable("CompanyHighlight");
            entity.HasKey(ch => ch.Id);

            entity.HasOne(ch => ch.Employer)
                .WithMany()
                .HasForeignKey(ch => ch.EmployerId)
                .HasConstraintName("FK_CompanyHighlight_Employers");
        });
        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}