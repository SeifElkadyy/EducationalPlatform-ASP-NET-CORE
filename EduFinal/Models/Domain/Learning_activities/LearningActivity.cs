using EduFinal.Models.Domain.Modules;

namespace EduFinal.Models.Domain
{
    public abstract class LearningActivity
    {
        public int ActivityID { get; set; }
        public int ModuleID { get; set; }
        public int CourseID { get; set; }
        public string ActivityType { get; set; }
        public string InstructionDetails { get; set; }
        public int MaxPoints { get; set; }

        // Navigation property
        public Module Module { get;set;}
    }
}