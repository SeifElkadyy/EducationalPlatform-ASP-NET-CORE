using EduFinal.Models.Domain;

namespace EduFinal.Models.Domain
{
    public abstract class DiscussionForum
    {
        public int ForumID { get; set; }
        public int ModuleID { get; set; }
        public int CourseID { get; set; }
        public string Title { get; set; }
        public DateTime? LastActive { get; set; }
        public DateTime? Timestamp { get; set; }
        public string Description { get; set; }
        public List<LearnerDiscussion> Discussions { get; set; }
    }
}