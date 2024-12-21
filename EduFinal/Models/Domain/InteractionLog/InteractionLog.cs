using EduFinal.Models.Domain.Learning_activities;

namespace EduFinal.Models.Domain
{
    public class InteractionLog
    {
        public int LogID { get; set; }
        public int ActivityID { get; set; }
        public int LearnerID { get; set; }
        public DateTime Timestamp { get; set; }
        public string ActionType { get; set; }

        // Computed property for Duration (not stored in the database)
        public TimeSpan Duration => DateTime.Now - Timestamp;

        // Navigation properties
        public LearningActivity LearningActivity { get; set; }
        public Learner Learner { get;set;}
    }
}