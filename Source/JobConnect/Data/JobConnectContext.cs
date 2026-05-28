using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

public class JobConnectContext(DbContextOptions<JobConnectContext> options) : IdentityDbContext<JobConnect.Data.ApplicationUser>(options)
{
}
