namespace EduFinal.Models.Domain
{
    public abstract class SurveyQuestion
    {
        public int SurveyID { get; set; }
        public string Question { get; set; }

        // Navigation property
        public Survey Survey { get; set; }
    }
}