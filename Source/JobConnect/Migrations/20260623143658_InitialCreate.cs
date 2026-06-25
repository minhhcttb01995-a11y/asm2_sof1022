using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobConnect.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Categories",
                columns: table => new
                {
                    CategoryID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ParentID = table.Column<int>(type: "int", nullable: true),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Slug = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Categories", x => x.CategoryID);
                    table.ForeignKey(
                        name: "FK_Categories_Categories_ParentID",
                        column: x => x.ParentID,
                        principalTable: "Categories",
                        principalColumn: "CategoryID",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ServicePackages",
                columns: table => new
                {
                    PackageID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(15,0)", nullable: false),
                    DurationDays = table.Column<int>(type: "int", nullable: false),
                    MaxJobPosts = table.Column<int>(type: "int", nullable: false),
                    MaxFeatured = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServicePackages", x => x.PackageID);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Email = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Role = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AvatarURL = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserID);
                });

            migrationBuilder.CreateTable(
                name: "Skills",
                columns: table => new
                {
                    SkillID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CategoryID = table.Column<int>(type: "int", nullable: true),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Skills", x => x.SkillID);
                    table.ForeignKey(
                        name: "FK_Skills_Categories_CategoryID",
                        column: x => x.CategoryID,
                        principalTable: "Categories",
                        principalColumn: "CategoryID");
                });

            migrationBuilder.CreateTable(
                name: "BlogPosts",
                columns: table => new
                {
                    PostID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AuthorID = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Slug = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Excerpt = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CoverURL = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsPublished = table.Column<bool>(type: "bit", nullable: false),
                    PublishedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BlogPosts", x => x.PostID);
                    table.ForeignKey(
                        name: "FK_BlogPosts_Users_AuthorID",
                        column: x => x.AuthorID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CandidateProfiles",
                columns: table => new
                {
                    ProfileID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Phone = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: true),
                    Avatar = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DateOfBirth = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Gender = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Address = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Summary = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ExperienceYears = table.Column<int>(type: "int", nullable: false),
                    DesiredSalary = table.Column<decimal>(type: "decimal(15,0)", nullable: true),
                    IsOpenToWork = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CandidateProfiles", x => x.ProfileID);
                    table.ForeignKey(
                        name: "FK_CandidateProfiles_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Employers",
                columns: table => new
                {
                    EmployerID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: false),
                    CompanyName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TaxCode = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Industry = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CompanySize = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Website = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    LogoURL = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CoverURL = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsVerified = table.Column<bool>(type: "bit", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Employers", x => x.EmployerID);
                    table.ForeignKey(
                        name: "FK_Employers_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    NotifID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false),
                    RelatedID = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.NotifID);
                    table.ForeignKey(
                        name: "FK_Notifications_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SystemLogs",
                columns: table => new
                {
                    LogID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: true),
                    Action = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IPAddress = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Detail = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemLogs", x => x.LogID);
                    table.ForeignKey(
                        name: "FK_SystemLogs_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID");
                });

            migrationBuilder.CreateTable(
                name: "CandidateSkills",
                columns: table => new
                {
                    ProfileID = table.Column<int>(type: "int", nullable: false),
                    SkillID = table.Column<int>(type: "int", nullable: false),
                    Level = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    YearsOfExp = table.Column<decimal>(type: "decimal(5,2)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CandidateSkills", x => new { x.ProfileID, x.SkillID });
                    table.ForeignKey(
                        name: "FK_CandidateSkills_CandidateProfiles_ProfileID",
                        column: x => x.ProfileID,
                        principalTable: "CandidateProfiles",
                        principalColumn: "ProfileID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CandidateSkills_Skills_SkillID",
                        column: x => x.SkillID,
                        principalTable: "Skills",
                        principalColumn: "SkillID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CvFiles",
                columns: table => new
                {
                    CvID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ProfileID = table.Column<int>(type: "int", nullable: false),
                    FileName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    FilePath = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    FileSize = table.Column<long>(type: "bigint", nullable: true),
                    IsDefault = table.Column<bool>(type: "bit", nullable: false),
                    UploadedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CvFiles", x => x.CvID);
                    table.ForeignKey(
                        name: "FK_CvFiles_CandidateProfiles_ProfileID",
                        column: x => x.ProfileID,
                        principalTable: "CandidateProfiles",
                        principalColumn: "ProfileID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "JobPosts",
                columns: table => new
                {
                    JobID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EmployerID = table.Column<int>(type: "int", nullable: false),
                    CategoryID = table.Column<int>(type: "int", nullable: true),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Requirements = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Benefits = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SalaryMin = table.Column<decimal>(type: "decimal(15,0)", nullable: true),
                    SalaryMax = table.Column<decimal>(type: "decimal(15,0)", nullable: true),
                    SalaryNegotiable = table.Column<bool>(type: "bit", nullable: false),
                    JobType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Location = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ExperienceLevel = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Deadline = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ViewCount = table.Column<int>(type: "int", nullable: false),
                    IsFeatured = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobPosts", x => x.JobID);
                    table.ForeignKey(
                        name: "FK_JobPosts_Categories_CategoryID",
                        column: x => x.CategoryID,
                        principalTable: "Categories",
                        principalColumn: "CategoryID");
                    table.ForeignKey(
                        name: "FK_JobPosts_Employers_EmployerID",
                        column: x => x.EmployerID,
                        principalTable: "Employers",
                        principalColumn: "EmployerID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Transactions",
                columns: table => new
                {
                    TransID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EmployerID = table.Column<int>(type: "int", nullable: false),
                    PackageID = table.Column<int>(type: "int", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(15,0)", nullable: false),
                    PaymentMethod = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ExpiredAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ServicePackagePackageID = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Transactions", x => x.TransID);
                    table.ForeignKey(
                        name: "FK_Transactions_Employers_EmployerID",
                        column: x => x.EmployerID,
                        principalTable: "Employers",
                        principalColumn: "EmployerID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Transactions_ServicePackages_ServicePackagePackageID",
                        column: x => x.ServicePackagePackageID,
                        principalTable: "ServicePackages",
                        principalColumn: "PackageID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Applications",
                columns: table => new
                {
                    AppID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    JobID = table.Column<int>(type: "int", nullable: false),
                    ProfileID = table.Column<int>(type: "int", nullable: false),
                    CVID = table.Column<int>(type: "int", nullable: true),
                    CoverLetter = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    AppliedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Applications", x => x.AppID);
                    table.ForeignKey(
                        name: "FK_Applications_CandidateProfiles_ProfileID",
                        column: x => x.ProfileID,
                        principalTable: "CandidateProfiles",
                        principalColumn: "ProfileID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Applications_CvFiles_CVID",
                        column: x => x.CVID,
                        principalTable: "CvFiles",
                        principalColumn: "CvID");
                    table.ForeignKey(
                        name: "FK_Applications_JobPosts_JobID",
                        column: x => x.JobID,
                        principalTable: "JobPosts",
                        principalColumn: "JobID",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SavedJobs",
                columns: table => new
                {
                    SaveID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: false),
                    JobID = table.Column<int>(type: "int", nullable: false),
                    SavedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SavedJobs", x => x.SaveID);
                    table.ForeignKey(
                        name: "FK_SavedJobs_JobPosts_JobID",
                        column: x => x.JobID,
                        principalTable: "JobPosts",
                        principalColumn: "JobID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SavedJobs_Users_UserID",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Applications_CVID",
                table: "Applications",
                column: "CVID");

            migrationBuilder.CreateIndex(
                name: "IX_Applications_JobID_ProfileID",
                table: "Applications",
                columns: new[] { "JobID", "ProfileID" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Applications_ProfileID",
                table: "Applications",
                column: "ProfileID");

            migrationBuilder.CreateIndex(
                name: "IX_BlogPosts_AuthorID",
                table: "BlogPosts",
                column: "AuthorID");

            migrationBuilder.CreateIndex(
                name: "IX_CandidateProfiles_UserID",
                table: "CandidateProfiles",
                column: "UserID",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CandidateSkills_SkillID",
                table: "CandidateSkills",
                column: "SkillID");

            migrationBuilder.CreateIndex(
                name: "IX_Categories_ParentID",
                table: "Categories",
                column: "ParentID");

            migrationBuilder.CreateIndex(
                name: "IX_CvFiles_ProfileID",
                table: "CvFiles",
                column: "ProfileID");

            migrationBuilder.CreateIndex(
                name: "IX_Employers_UserID",
                table: "Employers",
                column: "UserID",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobPosts_CategoryID",
                table: "JobPosts",
                column: "CategoryID");

            migrationBuilder.CreateIndex(
                name: "IX_JobPosts_EmployerID",
                table: "JobPosts",
                column: "EmployerID");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserID",
                table: "Notifications",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_SavedJobs_JobID",
                table: "SavedJobs",
                column: "JobID");

            migrationBuilder.CreateIndex(
                name: "IX_SavedJobs_UserID_JobID",
                table: "SavedJobs",
                columns: new[] { "UserID", "JobID" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Skills_CategoryID",
                table: "Skills",
                column: "CategoryID");

            migrationBuilder.CreateIndex(
                name: "IX_SystemLogs_UserID",
                table: "SystemLogs",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_Transactions_EmployerID",
                table: "Transactions",
                column: "EmployerID");

            migrationBuilder.CreateIndex(
                name: "IX_Transactions_ServicePackagePackageID",
                table: "Transactions",
                column: "ServicePackagePackageID");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Applications");

            migrationBuilder.DropTable(
                name: "BlogPosts");

            migrationBuilder.DropTable(
                name: "CandidateSkills");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "SavedJobs");

            migrationBuilder.DropTable(
                name: "SystemLogs");

            migrationBuilder.DropTable(
                name: "Transactions");

            migrationBuilder.DropTable(
                name: "CvFiles");

            migrationBuilder.DropTable(
                name: "Skills");

            migrationBuilder.DropTable(
                name: "JobPosts");

            migrationBuilder.DropTable(
                name: "ServicePackages");

            migrationBuilder.DropTable(
                name: "CandidateProfiles");

            migrationBuilder.DropTable(
                name: "Categories");

            migrationBuilder.DropTable(
                name: "Employers");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
