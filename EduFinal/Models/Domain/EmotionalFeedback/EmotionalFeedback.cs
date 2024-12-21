using EduFinal.Models.Domain.Learning_activities;

namespace EduFinal.Models.Domain
{
    public class EmotionalFeedback
    {
        public int FeedbackID { get; set; }
        public int LearnerID { get; set; }
        public int ActivityID { get; set; }
        public DateTime Timestamp { get; set; }
        public string EmotionalState { get; set; }

        // Navigation properties
        public Learner Learner { get; set; }
        public LearningActivity LearningActivity { get;set;}
    }
}