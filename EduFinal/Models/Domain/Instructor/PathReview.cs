using EduFinal.Models.Domain;

namespace EduFinal.Models.Domain
{
    public abstract class PathReview
    {
        public int InstructorID { get; set; }
        public int PathID { get; set; }
        public string Review { get; set; }
        public Instructor Instructor { get; set; }
        public LearningPath.LearningPath LearningPath { get; set; }
    }
}
