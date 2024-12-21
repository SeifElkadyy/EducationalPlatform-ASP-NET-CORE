namespace EduFinal.Models.Domain
{
    public abstract class Notification
    {
        public int ID { get; set; }
        public DateTime Timestamp { get; set; }
        public string Message { get; set; }
        public string UrgencyLevel { get; set; }
        public bool ReadStatus { get;set;}
    }
}