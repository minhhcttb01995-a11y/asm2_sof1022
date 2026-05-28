using JobConnect.Models;
using JobConnect.ViewModels;

namespace JobConnect.Services;

public interface IAuthService
{
    Task<User?> LoginAsync(string email, string password);
    Task<User> RegisterCandidateAsync(RegisterViewModel model);
    Task<User> RegisterEmployerAsync(RegisterEmployerViewModel model);
    Task<bool> EmailExistsAsync(string email);
}