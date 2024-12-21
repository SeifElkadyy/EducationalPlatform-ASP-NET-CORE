namespace EduFinal.Models.Domain
{
    public abstract class Badge
    {
        public int BadgeID { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Criteria { get; set; }
        public int Points { get;set;}
    }
}