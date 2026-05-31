using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Services;

public interface IAuthService
{
    Task<User?> LoginAsync(string email, string password);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> RegisterCandidateAsync(RegisterViewModel model);
    Task<bool> RegisterEmployerAsync(RegisterEmployerViewModel model);
}