namespace EduFinal.Models.Domain
{
    public class FilledSurvey
    {
        public int SurveyID { get; set; }
        public string Question { get; set; }
        public int LearnerID { get; set; }
        public string Answer { get; set; }

        // Navigation properties
        public SurveyQuestion SurveyQuestion { get; set; }
        public Learner Learner { get; set; }
    }
}