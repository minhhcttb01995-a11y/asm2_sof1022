using Microsoft.EntityFrameworkCore;
using JobConnect.Models;

namespace JobConnect.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<CandidateProfile> CandidateProfiles => Set<CandidateProfile>();
    public DbSet<CvFile> CvFiles => Set<CvFile>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Skill> Skills => Set<Skill>();
    public DbSet<CandidateSkill> CandidateSkills => Set<CandidateSkill>();
    public DbSet<Employer> Employers => Set<Employer>();
    public DbSet<JobPost> JobPosts => Set<JobPost>();
    public DbSet<Application> Applications => Set<Application>();
    public DbSet<SavedJob> SavedJobs => Set<SavedJob>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<ServicePackage> ServicePackages => Set<ServicePackage>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<BlogPost> BlogPosts => Set<BlogPost>();
    public DbSet<SystemLog> SystemLogs => Set<SystemLog>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<Interview> Interviews => Set<Interview>();
    public DbSet<Staff> Staff => Set<Staff>();
    public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<Message> Messages => Set<Message>();
    protected override void OnModelCreating(ModelBuilder mb)
    {
        base.OnModelCreating(mb);

        // CandidateSkill – composite PK
        mb.Entity<CandidateSkill>()
          .HasKey(cs => new { cs.ProfileID, cs.SkillID });

        // Skill – unique name
        mb.Entity<Skill>()
          .HasIndex(s => s.Name).IsUnique();

        // SavedJob – unique
        mb.Entity<SavedJob>()
          .HasIndex(sj => new { sj.UserID, sj.JobID }).IsUnique();

        // Application – unique per job+candidate
        mb.Entity<Application>()
          .HasIndex(a => new { a.JobID, a.ProfileID }).IsUnique();

        // Category self-reference
        mb.Entity<Category>()
          .HasOne(c => c.Parent)
          .WithMany(c => c.Children)
          .HasForeignKey(c => c.ParentID)
          .OnDelete(DeleteBehavior.Restrict);

        // ===== FIX CASCADE PATHS =====
        mb.Entity<Application>()
          .HasOne(a => a.Job)
          .WithMany(j => j.Applications)
          .HasForeignKey(a => a.JobID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Application>()
          .HasOne(a => a.CandidateProfile)
          .WithMany(p => p.Applications)
          .HasForeignKey(a => a.ProfileID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<SavedJob>()
          .HasOne(sj => sj.JobPost)
          .WithMany(j => j.SavedJobs)
          .HasForeignKey(sj => sj.JobID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Notification>()
          .HasOne(n => n.User)
          .WithMany(u => u.Notifications)
          .HasForeignKey(n => n.UserID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Transaction>()
          .HasOne(t => t.Employer)
          .WithMany(e => e.Transactions)
          .HasForeignKey(t => t.EmployerID)
          .OnDelete(DeleteBehavior.Restrict);

        // ===== CvFile Configuration (QUAN TRỌNG) =====
        mb.Entity<CvFile>(entity =>
        {
            entity.HasKey(e => e.CvID);
            entity.Property(e => e.CvID).ValueGeneratedOnAdd();

            entity.HasOne(e => e.Profile)
                  .WithMany(p => p.CvFiles)
                  .HasForeignKey(e => e.ProfileID)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // ===== DECIMAL PRECISION =====
        mb.Entity<JobPost>().Property(j => j.SalaryMin).HasColumnType("decimal(15,0)");
        mb.Entity<JobPost>().Property(j => j.SalaryMax).HasColumnType("decimal(15,0)");
        mb.Entity<CandidateProfile>().Property(cp => cp.DesiredSalary).HasColumnType("decimal(15,0)");
        mb.Entity<Transaction>().Property(t => t.Amount).HasColumnType("decimal(15,0)");
        mb.Entity<ServicePackage>().Property(sp => sp.Price).HasColumnType("decimal(15,0)");
        mb.Entity<CandidateSkill>().Property(cs => cs.YearsOfExperience).HasColumnType("decimal(5,2)");

        // ===== Interview Configuration =====
        mb.Entity<Interview>()
          .HasOne(i => i.Application)
          .WithMany()
          .HasForeignKey(i => i.AppID)
          .OnDelete(DeleteBehavior.Cascade);

        // ===== Staff Configuration =====
        mb.Entity<Staff>()
          .HasOne(s => s.User)
          .WithOne(u => u.Staff)
          .HasForeignKey<Staff>(s => s.ApplicationUserId)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Staff>()
          .HasIndex(s => s.EmployeeCode).IsUnique();

        // ===== ActivityLog Configuration =====
        mb.Entity<ActivityLog>()
          .HasOne(al => al.Staff)
          .WithMany(s => s.ActivityLogs)
          .HasForeignKey(al => al.StaffId)
          .OnDelete(DeleteBehavior.Cascade);

        // ===== Report Configuration =====
        mb.Entity<Report>()
          .HasOne(r => r.Reporter)
          .WithMany()
          .HasForeignKey(r => r.ReporterId)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Report>()
          .HasOne(r => r.JobPost)
          .WithMany()
          .HasForeignKey(r => r.JobPostId)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Report>()
          .HasOne(r => r.Company)
          .WithMany()
          .HasForeignKey(r => r.CompanyId)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Report>()
          .HasOne(r => r.ProcessedByStaff)
          .WithMany()
          .HasForeignKey(r => r.ProcessedByStaffId)
          .OnDelete(DeleteBehavior.SetNull);

        // ===== SupportTicket Configuration =====
        mb.Entity<SupportTicket>()
          .HasOne(st => st.User)
          .WithMany()
          .HasForeignKey(st => st.UserId)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<SupportTicket>()
          .HasOne(st => st.AssignedToStaff)
          .WithMany()
          .HasForeignKey(st => st.AssignedToStaffId)
          .OnDelete(DeleteBehavior.SetNull);

        // ===== Message Configuration =====
        mb.Entity<Message>()
          .HasOne(m => m.Sender)
          .WithMany(u => u.SentMessages)
          .HasForeignKey(m => m.SenderID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Message>()
          .HasOne(m => m.Receiver)
          .WithMany(u => u.ReceivedMessages)
          .HasForeignKey(m => m.ReceiverID)
          .OnDelete(DeleteBehavior.Restrict);

        mb.Entity<Message>()
          .HasOne(m => m.Job)
          .WithMany()
          .HasForeignKey(m => m.JobID)
          .OnDelete(DeleteBehavior.Restrict);
    }
}