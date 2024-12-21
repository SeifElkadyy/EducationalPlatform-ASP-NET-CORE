namespace EduFinal.Models.Domain
{
    public class SkillProgression
    {
        public int ID { get; set; }
        public string ProficiencyLevel { get; set; }
        public int LearnerID { get; set; }
        public string SkillName { get; set; }
        public DateTime Timestamp { get; set; }

        // Navigation property
        public Skill Skill { get;set;}
    }
}