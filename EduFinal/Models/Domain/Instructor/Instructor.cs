// Models/Domain/Instructor.cs

namespace EduFinal.Models.Domain
{
    public class Instructor
    {
        public int InstructorID { get; set; }
        public string Name { get; set; }
        public string LatestQualification { get; set; }
        public string ExpertiseArea { get; set; }
        public string Email { get; set; }

        // Navigation property to User
        public User User { get; set; }
    }
}