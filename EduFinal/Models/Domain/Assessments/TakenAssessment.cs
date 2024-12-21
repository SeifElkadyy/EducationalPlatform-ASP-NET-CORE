using EduFinal.Models.Domain;
using EduFinal.Models.Domain.Assessments;

namespace EduFinal.Models.Domain
{
    public abstract class TakenAssessment
    {
        public int AssessmentID { get; set; }
        public int LearnerID { get; set; }
        public int ScoredPoint { get; set; }
        public Assessment Assessment { get; set; }
        public Learner Learner { get; set; }
    }
}