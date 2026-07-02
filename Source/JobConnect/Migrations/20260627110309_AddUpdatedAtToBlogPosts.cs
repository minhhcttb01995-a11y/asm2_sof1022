using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobConnect.Migrations
{
    /// <inheritdoc />
    public partial class AddUpdatedAtToBlogPosts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Staff_ApplicationUserId",
                table: "Staff");

            migrationBuilder.AlterColumn<int>(
                name: "Priority",
                table: "SupportTickets",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Staff_ApplicationUserId",
                table: "Staff",
                column: "ApplicationUserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Staff_ApplicationUserId",
                table: "Staff");

            migrationBuilder.AlterColumn<int>(
                name: "Priority",
                table: "SupportTickets",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_Staff_ApplicationUserId",
                table: "Staff",
                column: "ApplicationUserId");
        }
    }
}
