using EduFinal.Models.Domain;

namespace EduFinal.Models.Domain
{
    public abstract class CoursePrerequisite
    {
        public int CourseID { get; set; }
        public string Prereq { get; set; }
        public Course Course { get; set; }
    }
}