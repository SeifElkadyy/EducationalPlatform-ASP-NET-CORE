using System.Reflection;

namespace EduFinal.Models.Domain
{
    public abstract class Course
    {
        public int CourseID { get; set; }
        public string Title { get; set; }
        public string LearningObjective { get; set; }
        public int CreditPoints { get; set; }
        public string DifficultyLevel { get; set; }
        public string Description { get; set; }
        public List<CoursePrerequisite> Prerequisites { get; set; }
        public List<Module> Modules { get; set; }
        public List<CourseEnrollment> Enrollments { get; set; }
    }
    
}