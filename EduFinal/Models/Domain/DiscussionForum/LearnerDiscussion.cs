using EduFinal.Models.Domain;

namespace EduFinal.Models.Domain
{
    public abstract class LearnerDiscussion
    {
        public int ForumID { get; set; }
        public int LearnerID { get; set; }
        public string Post { get; set; }
        public DateTime? Time { get; set; }
        public Learner Learner { get; set; }
        public DiscussionForum Forum { get; set; }
    }
}