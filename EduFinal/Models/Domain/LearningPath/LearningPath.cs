using EduFinal.Models.Domain;

namespace EduFinal.Models.Domain
{
    public abstract class LearningPath
    {
        public int PathID { get; set; }
        public int LearnerID { get; set; }
        public int ProfileID { get; set; }
        public string CompletionStatus { get; set; }
        public string CustomContent { get; set; }
        public string AdaptiveRules { get; set; }
        public Learner Learner { get; set; }
        public List<PathReview> Reviews { get; set; }
    }
}