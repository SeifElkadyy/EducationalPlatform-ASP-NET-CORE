namespace EduFinal.Models.Domain
{
    // Models/Domain/PersonalizationProfile.cs
    public class PersonalizationProfile
    {
        public int LearnerId { get; set; }
        public int ProfileID { get; set; }  // Changed from ProfileId to ProfileID to match DB
        public string PreferredContentType { get; set; }
        public string EmotionalState { get; set; }
        public string PersonalityType { get; set; }
        public List<string> HealthConditions { get; set; } = new List<string>();
    }
}