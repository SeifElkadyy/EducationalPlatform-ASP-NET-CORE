namespace EduFinal.Models.Domain
{
    public class LearnersGoals
    {
        public int GoalID { get; set; }
        public int LearnerID { get; set; }

        // Navigation properties
        public LearningGoal LearningGoal { get; set; }
        public Learner Learner { get; set;}
    }
}