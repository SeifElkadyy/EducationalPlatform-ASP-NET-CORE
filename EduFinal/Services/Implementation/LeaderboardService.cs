using System.Data;
using Dapper;
using EduFinal.Models.Domain.Leaderboard;
using EduFinal.Services.Interfaces;
using Microsoft.Data.SqlClient;

namespace EduFinal.Services.Implementation
{
    public class LeaderboardService : ILeaderboardService
    {
        private readonly IConfiguration _configuration;
        private readonly string _connectionString;

        public LeaderboardService(IConfiguration configuration)
        {
            _configuration = configuration;
            _connectionString = _configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Leaderboard.Ranking>> GetLeaderboardFilter(int learnerId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                return await connection.QueryAsync<Leaderboard.Ranking>(
                    "LeaderboardFilter",
                    new { LearnerID = learnerId },
                    commandType: CommandType.StoredProcedure
                );
            }
        }

        public async Task<IEnumerable<Leaderboard.Ranking>> GetLeaderboardRank(int leaderboardId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                return await connection.QueryAsync<Leaderboard.Ranking>(
                    "LeaderboardRank",
                    new { LeaderboardID = leaderboardId },
                    commandType: CommandType.StoredProcedure
                );
            }
        }

        public async Task<bool> UpdateRanking(int boardId, int learnerId, int courseId, 
            int rank, int totalPoints)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var sql = @"UPDATE Ranking 
                           SET rank = @Rank, total_points = @TotalPoints 
                           WHERE BoardID = @BoardId AND LearnerID = @LearnerId 
                           AND CourseID = @CourseId";
                var affected = await connection.ExecuteAsync(sql, 
                    new { BoardId = boardId, LearnerId = learnerId, CourseId = courseId, 
                          Rank = rank, TotalPoints = totalPoints });
                return affected > 0;
            }
        }
    }
}