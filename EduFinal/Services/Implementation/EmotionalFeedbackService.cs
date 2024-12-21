using System.Data;
using Dapper;
using EduFinal.Services.Interfaces;
using Microsoft.Data.SqlClient;

public class EmotionalFeedbackService : IEmotionalFeedbackService
{
    private readonly IConfiguration _configuration;
    private readonly string _connectionString;

    public EmotionalFeedbackService(IConfiguration configuration)
    {
        _configuration = configuration;
        _connectionString = _configuration.GetConnectionString("DefaultConnection");
    }

    public async Task<IEnumerable<dynamic>> GetEmotionalTrendAnalysis(int courseId, int moduleId, DateTime timePeriod)
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            var parameters = new DynamicParameters();
            parameters.Add("@CourseID", courseId);
            parameters.Add("@ModuleID", moduleId);
            parameters.Add("@TimePeriod", timePeriod);

            return await connection.QueryAsync(
                "EmotionalTrendAnalysis",
                parameters,
                commandType: CommandType.StoredProcedure
            );
        }
    }

    public async Task<bool> CreateEmotionalFeedback(int learnerId, int activityId, string emotionalState)
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            var sql = @"INSERT INTO Emotional_feedback (LearnerID, ActivityID, emotional_state) 
                       VALUES (@LearnerId, @ActivityId, @EmotionalState)";
            try
            {
                await connection.ExecuteAsync(sql,
                    new { LearnerId = learnerId, ActivityId = activityId, EmotionalState = emotionalState });
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}