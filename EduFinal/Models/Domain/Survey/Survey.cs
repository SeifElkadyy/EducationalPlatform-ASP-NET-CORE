namespace EduFinal.Models.Domain
{
    public abstract class Survey
    {
        public int ID { get; set; }
        public string Title { get; set; }

        // Navigation property
        public ICollection<SurveyQuestion> SurveyQuestions { get; set; }
    }
}