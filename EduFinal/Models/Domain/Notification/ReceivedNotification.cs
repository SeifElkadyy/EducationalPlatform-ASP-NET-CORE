namespace EduFinal.Models.Domain
{
    public class ReceivedNotification
    {
        public int NotificationID { get; set; }
        public int LearnerID { get; set; }

        // Navigation properties
        public Notification Notification { get; set; }
        public Learner Learner { get;set;}
    }
}