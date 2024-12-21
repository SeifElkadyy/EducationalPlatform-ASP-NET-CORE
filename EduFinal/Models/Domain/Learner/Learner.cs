// Models/Domain/Learner.cs

namespace EduFinal.Models.Domain
{
    public class Learner
    {
        public int LearnerID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public char? Gender { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? Country { get; set; }
        public string? CulturalBackground { get; set; }

        // Navigation property to User
        public User User { get; set; }

        // Collections for related entities
        public List<Skill> Skills { get; set; }
        public List<LearningPreference> LearningPreferences { get; set; }
    }

// Related classes for Learner's collections
    public abstract class Skill
    {
        public int LearnerID { get; set; }
        public string SkillName { get; set; }
        public Learner Learner { get; set; }
    }

    public abstract class LearningPreference
    {
        public int LearnerID { get; set; }
        public string Preference { get; set; }
        public Learner Learner { get; set; }
    }
}