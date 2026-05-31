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

    protected override void OnModelCreating(ModelBuilder mb)
    {
        base.OnModelCreating(mb);

        // CandidateSkill – composite PK
        mb.Entity<CandidateSkill>()
          .HasKey(cs => new { cs.ProfileID, cs.SkillID });

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
          .HasOne(a => a.JobPost)
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
            entity.HasKey(e => e.CvFileID);
            entity.Property(e => e.CvFileID).ValueGeneratedOnAdd();

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
        mb.Entity<CandidateSkill>().Property(cs => cs.YearsOfExp).HasColumnType("decimal(5,2)");
    }
}