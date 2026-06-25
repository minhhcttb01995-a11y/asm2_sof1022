using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobConnect.Migrations
{
    /// <inheritdoc />
    public partial class AddIsLockedToEmployer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsLocked",
                table: "Employers",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsLocked",
                table: "Employers");
        }
    }
}
