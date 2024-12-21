namespace EduFinal.Models.Domain
{
    // Models/Domain/LearningGoal.cs
    public abstract class LearningGoal
    {
        public int ID { get; set; }
        public string Status { get; set; }
        public DateTime? Deadline { get; set; }
        public string Description { get; set; }
        public List<Learner> Learners { get; set; }
    }
}