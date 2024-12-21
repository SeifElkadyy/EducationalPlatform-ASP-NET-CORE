namespace EduFinal.Models.Domain
{
    public abstract class Module
    {
        public int ModuleID { get; set; }
        public int CourseID { get; set; }
        public string Title { get; set; }
        public string Difficulty { get; set; }
        public string ContentURL { get; set; }
        public Course.Course Course { get; set; }
        public List<Assessment> Assessments { get; set; }
        public List<LearningActivity> Activities { get; set; }
    }
}