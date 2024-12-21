namespace EduFinal.Models.Domain
{
    public class Achievement
    {
        public int AchievementID { get; set; }
        public int LearnerID { get; set; }
        public int BadgeID { get; set; }
        public string Description { get; set; }
        public DateTime DateEarned { get; set; }
        public string Type { get; set; }

        // Navigation properties
        public Learner Learner { get; set; }
        public Badge Badge { get;set;}
    }
}