using JobConnect.Models;

namespace JobConnect.Services;

/// <summary>
/// Service interface for skill management operations
/// </summary>
public interface ISkillService
{
    // Admin operations
    Task<List<Skill>> GetAllAsync();
    Task<List<Skill>> GetActiveAsync();
    Task<List<Skill>> GetByCategoryAsync(SkillCategory category);
    Task<Skill?> GetByIdAsync(int id);
    Task<bool> CreateAsync(Skill skill);
    Task<bool> UpdateAsync(Skill skill);
    Task<bool> DeleteAsync(int id);
    Task<bool> ToggleActiveAsync(int id);
    Task<bool> ExistsAsync(string name, int? excludeId = null);

    // Candidate operations
    Task<List<CandidateSkill>> GetCandidateSkillsAsync(int profileId);
    Task<bool> AddCandidateSkillAsync(int profileId, int skillId, ProficiencyLevel proficiency, decimal yearsOfExp, DateTime? lastUsed);
    Task<bool> UpdateCandidateSkillAsync(int profileId, int skillId, ProficiencyLevel proficiency, decimal yearsOfExp, DateTime? lastUsed);
    Task<bool> RemoveCandidateSkillAsync(int profileId, int skillId);
    Task<bool> HasCandidateSkillAsync(int profileId, int skillId);
    Task<int> GetProfileCompletionPercentageAsync(int profileId);
}
