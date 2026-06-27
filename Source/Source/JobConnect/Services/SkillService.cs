using JobConnect.Data;
using JobConnect.Models;
using Microsoft.EntityFrameworkCore;

namespace JobConnect.Services;

/// <summary>
/// Service implementation for skill management operations
/// </summary>
public class SkillService : ISkillService
{
    private readonly AppDbContext _db;

    public SkillService(AppDbContext db)
    {
        _db = db;
    }

    #region Admin Operations

    /// <summary>
    /// Get all skills (including inactive)
    /// </summary>
    public async Task<List<Skill>> GetAllAsync()
    {
        return await _db.Skills
            .OrderBy(s => s.Category)
            .ThenBy(s => s.Name)
            .ToListAsync();
    }

    /// <summary>
    /// Get only active skills
    /// </summary>
    public async Task<List<Skill>> GetActiveAsync()
    {
        return await _db.Skills
            .Where(s => s.IsActive)
            .OrderBy(s => s.Category)
            .ThenBy(s => s.Name)
            .ToListAsync();
    }

    /// <summary>
    /// Get skills by category
    /// </summary>
    public async Task<List<Skill>> GetByCategoryAsync(SkillCategory category)
    {
        return await _db.Skills
            .Where(s => s.Category == category && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();
    }

    /// <summary>
    /// Get skill by ID
    /// </summary>
    public async Task<Skill?> GetByIdAsync(int id)
    {
        return await _db.Skills.FindAsync(id);
    }

    /// <summary>
    /// Create a new skill
    /// </summary>
    public async Task<bool> CreateAsync(Skill skill)
    {
        // Check if skill name already exists
        if (await ExistsAsync(skill.Name))
            return false;

        skill.CreatedAt = DateTime.Now;
        _db.Skills.Add(skill);
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Update an existing skill
    /// </summary>
    public async Task<bool> UpdateAsync(Skill skill)
    {
        // Check if skill name exists for another skill
        if (await ExistsAsync(skill.Name, skill.SkillID))
            return false;

        var existing = await _db.Skills.FindAsync(skill.SkillID);
        if (existing == null)
            return false;

        existing.Name = skill.Name;
        existing.Description = skill.Description;
        existing.Category = skill.Category;
        existing.IsActive = skill.IsActive;
        existing.UpdatedAt = DateTime.Now;

        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Delete a skill
    /// </summary>
    public async Task<bool> DeleteAsync(int id)
    {
        var skill = await _db.Skills.FindAsync(id);
        if (skill == null)
            return false;

        // Check if skill is assigned to any candidate
        var hasCandidates = await _db.CandidateSkills.AnyAsync(cs => cs.SkillID == id);
        if (hasCandidates)
            return false; // Cannot delete if in use

        _db.Skills.Remove(skill);
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Toggle skill active status
    /// </summary>
    public async Task<bool> ToggleActiveAsync(int id)
    {
        var skill = await _db.Skills.FindAsync(id);
        if (skill == null)
            return false;

        skill.IsActive = !skill.IsActive;
        skill.UpdatedAt = DateTime.Now;
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Check if skill name exists
    /// </summary>
    public async Task<bool> ExistsAsync(string name, int? excludeId = null)
    {
        var query = _db.Skills.Where(s => s.Name == name);
        if (excludeId.HasValue)
            query = query.Where(s => s.SkillID != excludeId.Value);
        return await query.AnyAsync();
    }

    #endregion

    #region Candidate Operations

    /// <summary>
    /// Get all skills for a candidate
    /// </summary>
    public async Task<List<CandidateSkill>> GetCandidateSkillsAsync(int profileId)
    {
        return await _db.CandidateSkills
            .Include(cs => cs.Skill)
            .Where(cs => cs.ProfileID == profileId)
            .OrderBy(cs => cs.Skill.Category)
            .ThenBy(cs => cs.Skill.Name)
            .ToListAsync();
    }

    /// <summary>
    /// Add a skill to candidate's profile
    /// </summary>
    public async Task<bool> AddCandidateSkillAsync(int profileId, int skillId, ProficiencyLevel proficiency, decimal yearsOfExp, DateTime? lastUsed)
    {
        // Check if skill already exists for candidate
        if (await HasCandidateSkillAsync(profileId, skillId))
            return false;

        // Verify skill exists and is active
        var skill = await _db.Skills.FindAsync(skillId);
        if (skill == null || !skill.IsActive)
            return false;

        var candidateSkill = new CandidateSkill
        {
            ProfileID = profileId,
            SkillID = skillId,
            ProficiencyLevel = proficiency,
            YearsOfExperience = yearsOfExp,
            LastUsedDate = lastUsed,
            CreatedAt = DateTime.Now
        };

        _db.CandidateSkills.Add(candidateSkill);
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Update a candidate's skill
    /// </summary>
    public async Task<bool> UpdateCandidateSkillAsync(int profileId, int skillId, ProficiencyLevel proficiency, decimal yearsOfExp, DateTime? lastUsed)
    {
        var candidateSkill = await _db.CandidateSkills
            .FirstOrDefaultAsync(cs => cs.ProfileID == profileId && cs.SkillID == skillId);

        if (candidateSkill == null)
            return false;

        candidateSkill.ProficiencyLevel = proficiency;
        candidateSkill.YearsOfExperience = yearsOfExp;
        candidateSkill.LastUsedDate = lastUsed;
        candidateSkill.UpdatedAt = DateTime.Now;

        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Remove a skill from candidate's profile
    /// </summary>
    public async Task<bool> RemoveCandidateSkillAsync(int profileId, int skillId)
    {
        var candidateSkill = await _db.CandidateSkills
            .FirstOrDefaultAsync(cs => cs.ProfileID == profileId && cs.SkillID == skillId);

        if (candidateSkill == null)
            return false;

        _db.CandidateSkills.Remove(candidateSkill);
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Check if candidate has a specific skill
    /// </summary>
    public async Task<bool> HasCandidateSkillAsync(int profileId, int skillId)
    {
        return await _db.CandidateSkills
            .AnyAsync(cs => cs.ProfileID == profileId && cs.SkillID == skillId);
    }

    /// <summary>
    /// Calculate profile completion percentage based on skills
    /// </summary>
    public async Task<int> GetProfileCompletionPercentageAsync(int profileId)
    {
        const int targetSkillCount = 5; // Target: 5 skills for full completion
        var skillCount = await _db.CandidateSkills
            .CountAsync(cs => cs.ProfileID == profileId);

        return Math.Min(100, (skillCount * 100) / targetSkillCount);
    }

    #endregion
}
