USE EducationalPlatform

-- ==================================================================================================
--                                       Admin Procedures
-- ==================================================================================================

GO
CREATE PROCEDURE CreateAdminUser
    @Email VARCHAR(100),
    @PasswordHash VARCHAR(255)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        INSERT INTO Users (Email, PasswordHash, Role, IsActive, CreationDate)
        VALUES (@Email, @PasswordHash, 'Admin', 1, GETDATE());
        
        SELECT SCOPE_IDENTITY() as ID;
    END
END

GO
CREATE PROCEDURE AddLearner
    @Email VARCHAR(100),
    @PasswordHash VARCHAR(255),
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Gender CHAR(1) = NULL,
    @BirthDate DATE = NULL,
    @Country VARCHAR(50) = NULL,
    @CulturalBackground VARCHAR(100) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @UserID INT;
        INSERT INTO Users (Email, PasswordHash, Role, IsActive)
        VALUES (@Email, @PasswordHash, 'Learner', 1);
        
        SET @UserID = SCOPE_IDENTITY();
        
        INSERT INTO Learner (
            LearnerID, 
            first_name, 
            last_name, 
            gender, 
            birth_date, 
            country, 
            cultural_background
        )
        VALUES (
            @UserID,
            @FirstName,
            @LastName,
            @Gender,
            @BirthDate,
            @Country,
            @CulturalBackground
        );
        
        COMMIT TRANSACTION;
        SELECT @UserID AS ID;  -- Change RETURN to SELECT
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH;
END;


-- Procedure to Add a New Instructor
GO
CREATE PROCEDURE AddInstructor
    @Email VARCHAR(100),
    @PasswordHash VARCHAR(255),
    @Name VARCHAR(100),
    @LatestQualification VARCHAR(100),
    @ExpertiseArea VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insert into Users table first
        DECLARE @UserID INT;
        INSERT INTO Users (Email, PasswordHash, Role, IsActive)
        VALUES (@Email, @PasswordHash, 'Instructor', 1);
        
        -- Get the newly created UserID
        SET @UserID = SCOPE_IDENTITY();
        
        -- Insert into Instructor table
        INSERT INTO Instructor (
            InstructorID, 
            name, 
            latest_qualification, 
            expertise_area,
            email
        )
        VALUES (
            @UserID,
            @Name,
            @LatestQualification,
            @ExpertiseArea,
            @Email
        );
        
        COMMIT TRANSACTION;
        SELECT @UserID AS ID;  -- Changed from RETURN to SELECT
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH;
END;

-- Procedure to Delete a User
GO
CREATE PROCEDURE DeleteUser
    @UserID INT,
    @Role VARCHAR(20) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate the role if provided
        IF @Role IS NOT NULL
        BEGIN
            DECLARE @ActualRole VARCHAR(20);
            SELECT @ActualRole = Role 
            FROM Users 
            WHERE UserID = @UserID;
            
            IF @ActualRole != @Role
            BEGIN
                RAISERROR('User role does not match the specified role.', 16, 1);
                RETURN -1;
            END
        END
        
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User not found.', 16, 1);
            RETURN -1;
        END
        
        -- Delete the user (cascading delete will remove related records)
        DELETE FROM Users WHERE UserID = @UserID;
        
        COMMIT TRANSACTION;
        RETURN 1;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if any error occurs
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Raise the error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
                @ErrorSeverity INT = ERROR_SEVERITY(),
                @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH;
END;
GO

CREATE PROCEDURE ViewModules
    @CourseID INT
AS
BEGIN
    SELECT 
        ModuleID,
        Title,
        Difficulty,
        ContentURL
    FROM Modules
    WHERE CourseID = @CourseID;
END;


GO
CREATE PROCEDURE GetCompletedCourses
    @UserId INT
AS
BEGIN
    SELECT c.CourseID, c.Title, c.Description, c.CreditPoints, c.DifficultyLevel
    FROM Courses c
    INNER JOIN CourseCompletion cc ON c.CourseID = cc.CourseID
    WHERE cc.UserID = @UserId
END

GO
CREATE PROCEDURE GetModulesByCourse
    @CourseId INT
AS
BEGIN
    SELECT m.ModuleID, m.Title, m.Difficulty, m.ContentURL
    FROM Modules m
    WHERE m.CourseID = @CourseId
END

GO
CREATE PROCEDURE GetTeachingCourses
    @InstructorID INT
AS
BEGIN
    SELECT 
        c.CourseID,
        c.Title AS Title,
        c.description AS Description,
        c.learning_objective AS LearningObjective,
        c.credit_points AS CreditPoints,
        c.difficulty_level AS DifficultyLevel,
        ISNULL(MAX(ce.enrollment_date), NULL) AS EnrollmentDate, -- Earliest enrollment date
        ISNULL(MAX(ce.completion_date), NULL) AS CompletionDate, -- Latest completion date
        ISNULL(
            MAX(CASE 
                WHEN ce.completion_date IS NULL THEN ce.status -- Ongoing or not completed
                ELSE 'completed' -- If there's a completion date, mark as completed
            END), 
            'No Enrollments'
        ) AS Status, -- Representative Status
        ISNULL(COUNT(DISTINCT ce.LearnerID), 0) AS EnrolledStudentsCount, -- Total enrollments
        ISNULL(
            CAST(SUM(CASE WHEN ce.completion_date IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) 
            / NULLIF(COUNT(ce.LearnerID), 0) * 100, 
            0.0
        ) AS CompletionPercentage -- Completion rate
    FROM 
        Course c
    INNER JOIN 
        Teaches t ON c.CourseID = t.CourseID
    LEFT JOIN 
        Course_enrollment ce ON c.CourseID = ce.CourseID -- Join with enrollment table
    WHERE 
        t.InstructorID = @InstructorID
    GROUP BY 
        c.CourseID, c.Title, c.description, c.learning_objective, c.credit_points, 
        c.difficulty_level;
END;
GO

GO
CREATE PROCEDURE GetPendingAssessments
    @InstructorID INT,
    @CourseID INT = NULL
AS
BEGIN
    SELECT 
        a.ID AS AssessmentID,
        a.title AS AssessmentTitle,
        a.description AS AssessmentDescription,
        a.total_marks AS TotalMarks,
        a.type AS AssessmentType,
        a.criteria AS AssessmentCriteria,
        a.weightage AS AssessmentWeightage
    FROM 
        Assessments a
    INNER JOIN 
        Course c ON a.CourseID = c.CourseID
    INNER JOIN 
        Teaches t ON c.CourseID = t.CourseID
    WHERE 
        t.InstructorID = @InstructorID
        AND (@CourseID IS NULL OR a.CourseID = @CourseID);
END;


GO
CREATE PROCEDURE GetStudentProgress
    @InstructorID INT,
    @CourseID INT = NULL
AS
BEGIN
    SELECT 
        ta.LearnerID,
        a.CourseID,
        SUM(CASE WHEN ta.ScoredPoint >= a.passing_marks THEN 1 ELSE 0 END) AS CompletedModules,
        COUNT(a.ID) AS TotalModules,
        c.Title AS CourseTitle
    FROM 
        Takenassessment ta
    INNER JOIN 
        Assessments a ON ta.AssessmentID = a.ID
    INNER JOIN 
        Course c ON a.CourseID = c.CourseID
    INNER JOIN 
        Teaches t ON c.CourseID = t.CourseID
    WHERE 
        t.InstructorID = @InstructorID
        AND (@CourseID IS NULL OR a.CourseID = @CourseID)
    GROUP BY 
        ta.LearnerID, a.CourseID, c.Title;
END;

GO
CREATE PROCEDURE ViewAllActivities
AS
BEGIN
    SELECT 
        la.ActivityID,
        la.activity_type AS ActivityType,
        la.instruction_details AS InstructionDetails,
        la.Max_points AS MaxPoints,
        m.Title AS ModuleTitle,
        c.Title AS CourseTitle
    FROM Learning_activities la
    INNER JOIN Modules m ON la.ModuleID = m.ModuleID
    INNER JOIN Course c ON m.CourseID = c.CourseID
    ORDER BY c.Title, m.Title, la.ActivityID;
END;


go
CREATE PROCEDURE GetCollaborativeQuests
AS
BEGIN
    SELECT 
        q.QuestID,
        q.title,
        q.description,
        q.difficulty_level,
        q.criteria,
        c.deadline,
        COUNT(lc.LearnerID) AS CurrentMembers,
        c.max_num_participants AS MaxMembers
    FROM 
        Quest q
    INNER JOIN Collaborative c ON q.QuestID = c.QuestID
    LEFT JOIN LearnersCollaboration lc ON q.QuestID = lc.QuestID
    GROUP BY 
        q.QuestID, q.title, q.description, q.difficulty_level, q.criteria, c.deadline, c.max_num_participants;
END;

go 
CREATE PROCEDURE GetUserActiveQuests
    @LearnerID INT
AS
BEGIN
    SELECT QuestID
    FROM LearnersCollaboration
    WHERE LearnerID = @LearnerID;
END;

go
CREATE PROCEDURE GetQuestParticipants
    @LearnerID INT
AS
BEGIN
    SELECT 
        lc.QuestID,
        l.LearnerID,
        l.first_name AS FirstName,
        l.last_name AS LastName,
        lc.completion_status AS CompletionStatus
    FROM 
        LearnersCollaboration lc
    INNER JOIN Learner l ON lc.LearnerID = l.LearnerID
    WHERE 
        lc.QuestID IN (
            SELECT QuestID 
            FROM LearnersCollaboration 
            WHERE LearnerID = @LearnerID
        )
        AND lc.LearnerID <> @LearnerID; -- Exclude the current user if desired
END;

exec GetQuestParticipants @LearnerID = 1;

-- Update the stored procedure to return all needed fields
GO
CREATE PROCEDURE GetAvailableCourses
AS
BEGIN
    SELECT 
        CourseID,
        Title,
        Description,
        learning_objective AS LearningObjective,
        credit_points AS CreditPoints,
        difficulty_level AS DifficultyLevel,
        (SELECT COUNT(*) FROM Course_enrollment WHERE CourseID = c.CourseID) as EnrolledStudentsCount
    FROM Course c;
END;



GO
CREATE PROCEDURE GetLearnerAchievements
    @LearnerID INT
AS
BEGIN
    SELECT A.AchievementID, A.BadgeID, B.title, A.description, A.date_earned, A.type
    FROM Achievement A
    INNER JOIN Badge B ON A.BadgeID = B.BadgeID
    WHERE A.LearnerID = @LearnerID
    ORDER BY A.date_earned DESC;
END;
GO
CREATE PROCEDURE ReviewTakenAssessments
    @UserID INT,          -- UserID of the logged-in user
    @CourseID INT = NULL  -- Optional filter by course
AS
BEGIN
    -- Determine the Role of the user
    DECLARE @Role VARCHAR(20);

    SELECT @Role = Role
    FROM Users
    WHERE UserID = @UserID;

    -- Role-Based Queries
    IF @Role = 'Learner'
    BEGIN
        SELECT 
            t.AssessmentID,
            a.title AS AssessmentTitle,
            a.description AS AssessmentDescription,
            t.ScoredPoint,
            a.total_marks,
            a.passing_marks,
            a.weightage,
            m.ModuleID,
            c.CourseID
        FROM TakenAssessment t
        INNER JOIN Assessments a ON t.AssessmentID = a.ID
        INNER JOIN Modules m ON a.ModuleID = m.ModuleID AND a.CourseID = m.CourseID
        INNER JOIN Course c ON m.CourseID = c.CourseID
        INNER JOIN Learner l ON t.LearnerID = l.LearnerID
        WHERE t.LearnerID = @UserID
        AND (@CourseID IS NULL OR c.CourseID = @CourseID);
    END
    ELSE IF @Role = 'Instructor'
    BEGIN
        SELECT 
            t.AssessmentID,
            a.title AS AssessmentTitle,
            a.description AS AssessmentDescription,
            t.ScoredPoint,
            a.total_marks,
            a.passing_marks,
            a.weightage,
            m.ModuleID,
            c.CourseID,
             CONCAT(l.first_name, ' ', l.last_name) AS Learner_Name
        FROM TakenAssessment t
        INNER JOIN Assessments a ON t.AssessmentID = a.ID
        INNER JOIN Learner l ON t.LearnerID = l.LearnerID
        INNER JOIN Modules m ON a.ModuleID = m.ModuleID AND a.CourseID = m.CourseID
        INNER JOIN Course c ON m.CourseID = c.CourseID
        WHERE (@CourseID IS NULL OR c.CourseID = @CourseID);
    END
    ELSE
    BEGIN
        -- Optional: Handle cases for Admin or invalid roles
        RAISERROR ('Access Denied: You do not have permission to review assessments.', 16, 1);
    END
END

GO

CREATE PROCEDURE ReviewTakenAssessmentsInstructor
AS
BEGIN
    -- Prevent recursive trigger calls
    SET NOCOUNT ON;
    DISABLE TRIGGER ALL ON TakenAssessment;
    DISABLE TRIGGER ALL ON Assessments;
    
    -- Main Query Logic
   SELECT 
    t.AssessmentID AS AssessmentID,
    a.title AS AssessmentTitle,
    a.description AS AssessmentDescription,
    t.ScoredPoint AS ScoredPoint,
    a.total_marks AS TotalMarks,
    a.passing_marks AS PassingMarks,
    a.weightage AS Weightage,
    m.ModuleID AS ModuleID,
    c.CourseID AS CourseID,
    CONCAT(l.first_name, ' ', l.last_name) AS LearnerName
FROM TakenAssessment t
INNER JOIN Assessments a ON t.AssessmentID = a.ID
LEFT JOIN Learner l ON t.LearnerID = l.LearnerID
INNER JOIN Modules m ON a.ModuleID = m.ModuleID AND a.CourseID = m.CourseID
INNER JOIN Course c ON m.CourseID = c.CourseID;


    -- Re-enable triggers
    ENABLE TRIGGER ALL ON TakenAssessment;
    ENABLE TRIGGER ALL ON Assessments;
END;

GO
CREATE PROCEDURE viewAllAssessments
AS
BEGIN
 SET NOCOUNT ON;
    DISABLE TRIGGER ALL ON TakenAssessment;
    DISABLE TRIGGER ALL ON Assessments;
    
SELECT * FROM Assessments;
   -- Re-enable triggers
    ENABLE TRIGGER ALL ON TakenAssessment;
    ENABLE TRIGGER ALL ON Assessments
END

GO
CREATE PROCEDURE AddAssessment
    @ModuleID INT,
    @Title NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @TotalMarks INT,
    @PassingMarks INT,
    @Weightage FLOAT = NULL,
    @Criteria NVARCHAR(MAX) = NULL,
    @Type NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Get CourseID directly from the Modules table based on ModuleID
        DECLARE @CourseID INT;
        SELECT @CourseID = CourseID
        FROM Modules
        WHERE ModuleID = @ModuleID;

        -- Insert into Assessments table
        INSERT INTO Assessments (CourseID, ModuleID, Title, Description, total_marks, passing_marks, Weightage, Criteria, type)
        VALUES (@CourseID, @ModuleID, @Title, @Description, @TotalMarks, @PassingMarks, @Weightage, @Criteria, @Type);

        -- Return the newly inserted AssessmentID
        SELECT SCOPE_IDENTITY() AS AssessmentID;

    END TRY
    BEGIN CATCH
        -- Handle errors
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
        RETURN -1; -- Indicate failure
    END CATCH
END;



-------------------------------------------------------------------------------------------------------------------------------------------------------
GO
CREATE PROCEDURE ViewInfo
    @LearnerID INT
AS
BEGIN
    -- Retrieve learner's information along with their skills and learning preferences
    SELECT 
        L.LearnerID,
        L.first_name,
        L.last_name,
        L.gender,
        L.birth_date,
        L.country,
        L.cultural_background,
        S.skill,
        P.preference
    FROM 
        Learner L
    LEFT JOIN 
        Skills S ON L.LearnerID = S.LearnerID
    LEFT JOIN 
        LearningPreference P ON L.LearnerID = P.LearnerID
    WHERE 
        L.LearnerID = @LearnerID;
END;
GO


-- add exec 
EXEC ViewInfo @LearnerID = 1

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 2
Go
CREATE PROCEDURE LearnerInfo
    @LearnerID INT
AS
BEGIN
    -- Retrieve all profile information for a specific learner from PersonalizationProfiles and related tables
    SELECT 
        PP.ProfileID,
        PP.Prefered_content_type,
        PP.emotional_state,
        PP.personality_type,
        HC.condition AS HealthCondition
    FROM 
        PersonalizationProfiles AS PP
    LEFT JOIN 
        HealthCondition AS HC ON PP.LearnerID = HC.LearnerID AND PP.ProfileID = HC.ProfileID
    WHERE 
        PP.LearnerID = @LearnerID;
END;
Go

-- Test Procedure
EXEC LearnerInfo @LearnerID = 2;

select * from learner

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 3 

GO
CREATE PROCEDURE EmotionalState
    @LearnerID INT
AS
BEGIN
    SELECT TOP 1
        PP.emotional_state AS EmotionalState
    FROM 
        PersonalizationProfiles AS PP
    WHERE 
        PP.LearnerID = @LearnerID
    ORDER BY 
        PP.ProfileID DESC;
END;
GO

EXEC EmotionalState @LearnerID = 1;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 4
Go
CREATE PROCEDURE LogDetails
    @LearnerID INT
AS
BEGIN
    -- Retrieve all interaction logs for the specified learner, ordered by timestamp (latest first)
    SELECT 
        LogID,
        activity_ID,
        LearnerID,
        action_type,
        Timestamp,
        Duration
    FROM 
        Interaction_log
    WHERE 
        LearnerID = @LearnerID
    ORDER BY 
        Timestamp DESC;
END;
Go

-- Test Procedure
EXEC LogDetails @LearnerID = 1;





----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 5
Go

CREATE PROCEDURE InstructorReview
    @InstructorID INT
AS
BEGIN
    -- Retrieve all emotional feedbacks reviewed by the specified instructor
    SELECT 
        EFR.FeedbackID,
        EF.LearnerID,
        EF.timestamp,
        EF.emotional_state,
        EFR.review AS InstructorFeedback
    FROM 
        Emotionalfeedback_review AS EFR
    JOIN 
        Emotional_feedback AS EF ON EFR.FeedbackID = EF.FeedbackID
    WHERE 
        EFR.InstructorID = @InstructorID
    ORDER BY 
        EF.timestamp DESC;
END;

Go

-- Test Procedure
EXEC InstructorReview @InstructorID = 1;



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 6


GO
CREATE PROCEDURE CourseRemove
    @courseID INT
AS
BEGIN

    RAISERROR('Warning: You are about to delete a course and all its related records. This action cannot be undone.', 10, 1) WITH NOWAIT;


    BEGIN TRANSACTION;

    BEGIN TRY

        DELETE FROM ModuleContent WHERE CourseID = @courseID;
        DELETE FROM Target_traits WHERE CourseID = @courseID;
        DELETE FROM Assessments WHERE CourseID = @courseID;
        DELETE FROM ContentLibrary WHERE CourseID = @courseID;
        DELETE FROM Learning_activities WHERE CourseID = @courseID;
        DELETE FROM Discussion_forum WHERE CourseID = @courseID;
        DELETE FROM Course_enrollment WHERE CourseID = @courseID;
        DELETE FROM Teaches WHERE CourseID = @courseID;
        DELETE FROM Ranking WHERE CourseID = @courseID;
        DELETE FROM Modules WHERE CourseID = @courseID;

        -- Finally, delete the course record itself
        DELETE FROM Course WHERE CourseID = @courseID;

        -- Commit transaction if all deletions are successful
        COMMIT TRANSACTION;
        PRINT 'Success: Course and all its related records were successfully deleted.';
    END TRY
    BEGIN CATCH
        -- Rollback transaction if any error occurs
        ROLLBACK TRANSACTION;
        -- Optional: Raise an error or provide feedback if needed
        PRINT 'There is an Error while deleting the Course ID';
        THROW;
    END CATCH;
END;
GO

-- Test Procedure
EXEC CourseRemove @courseID = 101;





------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 7

Go

CREATE PROCEDURE Highestgrade
AS
BEGIN
    -- Retrieve the assessment with the highest maximum points for each course
    SELECT 
        A.CourseID,
        C.Title AS CourseTitle,
        A.ID AS AssessmentID,
        A.title AS AssessmentTitle,
        A.type AS AssessmentType,
        A.total_marks AS MaxPoints,
        A.passing_marks,
        A.criteria,
        A.weightage,
        A.description
    FROM 
        Assessments AS A
    JOIN 
        Course AS C ON A.CourseID = C.CourseID
    WHERE 
        A.total_marks = (
            SELECT MAX(total_marks)
            FROM Assessments AS SubA
            WHERE SubA.CourseID = A.CourseID
        )
           ORDER BY 
        MaxPoints DESC; 
END;



Go

-- Test Procedure
EXEC Highestgrade



-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 8

Go

CREATE PROCEDURE InstructorCount
AS
BEGIN
    -- Retrieve all courses taught by more than one instructor
    SELECT 
        T.CourseID,
        C.Title AS CourseTitle,
        COUNT(T.InstructorID) AS InstructorCount
    FROM 
        Teaches AS T
    JOIN 
        Course AS C ON T.CourseID = C.CourseID
    GROUP BY 
        T.CourseID, C.Title
    HAVING 
        COUNT(T.InstructorID) > 1;
END;

Go

-- Test Procedure
EXEC InstructorCount



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 9

Go

CREATE PROCEDURE ViewNot
    @LearnerID INT
AS
BEGIN
    -- Retrieve all notifications sent to the specified learner
    SELECT 
        N.ID AS NotificationID,
        N.timestamp,
        N.message,
        N.urgency_level,
        N.ReadStatus
    FROM 
        ReceivedNotification AS RN
    JOIN 
        Notification AS N ON RN.NotificationID = N.ID
    WHERE 
        RN.LearnerID = @LearnerID
    ORDER BY 
        N.timestamp DESC;
END;


Go

-- Test Procedure
EXEC ViewNot @LearnerID = 1;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 10

Go

CREATE PROCEDURE CreateDiscussion
    @ModuleID INT,
    @CourseID INT,
    @Title VARCHAR(50),
    @Description VARCHAR(50)
AS
BEGIN
    DECLARE @ConfirmationMessage VARCHAR(100);

    -- Insert a new discussion forum record
    INSERT INTO Discussion_forum (ModuleID, CourseID, title, description, timestamp, last_active)
    VALUES (@ModuleID, @CourseID, @Title, @Description, GETDATE(), GETDATE());

    -- Confirmation message
    SET @ConfirmationMessage = 'Discussion forum "' + @Title + '" created successfully for ModuleID ' + CAST(@ModuleID AS VARCHAR) + ' and CourseID ' + CAST(@CourseID AS VARCHAR) + '.';

    -- Return confirmation message
    SELECT @ConfirmationMessage AS Confirmation;
END;



Go

-- Test Procedure
EXEC CreateDiscussion @ModuleID = 1, @CourseID = 100, @Title = 'New Discussion', @Description = 'This is a new discussion forum.';

select * from Discussion_forum


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 11

Go

CREATE PROCEDURE RemoveBadge
    @BadgeID INT
AS
BEGIN
    DECLARE @ConfirmationMessage VARCHAR(100);

    -- Begin transaction to ensure consistency
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Remove references to the badge from other tables, if applicable
        DELETE FROM Achievement WHERE BadgeID = @BadgeID;

        -- Delete the badge itself
        DELETE FROM Badge WHERE BadgeID = @BadgeID;

        -- Confirmation message
        SET @ConfirmationMessage = 'Badge with ID ' + CAST(@BadgeID AS VARCHAR) + ' has been successfully removed.';

        -- Commit transaction
        COMMIT TRANSACTION;

        -- Return confirmation message
        SELECT @ConfirmationMessage AS Confirmation;

    END TRY
    BEGIN CATCH
        -- Rollback transaction in case of error
        ROLLBACK TRANSACTION;

        -- Return error message
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;



Go

-- Test Procedure
EXEC RemoveBadge @BadgeID = 15;

select * from Badge

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 12

Go

CREATE PROCEDURE CriteriaDelete
    @criteria VARCHAR(50)
AS
BEGIN
    -- Begin a transaction to ensure all deletions are atomic
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Delete related records from QuestReward table if there are rewards tied to the quests with the given criteria
        DELETE FROM QuestReward 
        WHERE QuestID IN (SELECT QuestID FROM Quest WHERE criteria = @criteria);

        -- Delete skill mastery records if there are specific skill quests tied to the given criteria
        DELETE FROM Skill_Mastery 
        WHERE QuestID IN (SELECT QuestID FROM Quest WHERE criteria = @criteria);

        -- Delete collaborative quest records if there are collaborative quests tied to the given criteria
        DELETE FROM Collaborative 
        WHERE QuestID IN (SELECT QuestID FROM Quest WHERE criteria = @criteria);

        -- Delete quests that match the specified criteria
        DELETE FROM Quest 
        WHERE criteria = @criteria;

        -- Commit transaction if all deletions are successful
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Rollback transaction if any error occurs
        ROLLBACK TRANSACTION;

        -- Optional: Raise an error or provide feedback if needed
        THROW;
    END CATCH;
END;




Go

-- Test Procedure
EXEC CriteriaDelete @criteria = 'Complete Intro Modules';

select * from Quest



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 13

GO

CREATE PROCEDURE NotificationUpdate
    @LearnerID INT,
    @NotificationID INT,
    @ReadStatus BIT
AS
BEGIN
    -- Begin a transaction to ensure atomicity
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the notification exists for the learner
        IF EXISTS (
            SELECT 1 
            FROM ReceivedNotification
            WHERE NotificationID = @NotificationID AND LearnerID = @LearnerID
        )
        BEGIN
            IF @ReadStatus = 1
            BEGIN
                -- Mark the notification as read
                UPDATE Notification
                SET ReadStatus = 1
                WHERE ID = @NotificationID;

                PRINT 'Notification marked as read successfully.';
            END
            ELSE
            BEGIN
                -- Delete the notification for the learner
                DELETE FROM ReceivedNotification
                WHERE NotificationID = @NotificationID AND LearnerID = @LearnerID;

                PRINT 'Notification deleted successfully.';
            END
        END
        ELSE
        BEGIN
            PRINT 'Notification not found for the specified Learner and Notification ID.';
        END

        -- Commit the transaction if everything is successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of errors
        ROLLBACK TRANSACTION;

        -- Re-raise the error for debugging purposes
        THROW;
    END CATCH
END;
GO

-- Test Procedure
EXEC NotificationUpdate @LearnerID = 1,@NotificationID = 65000,@ReadStatus = 1;




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 14

-- Create the stored procedure for emotional trend analysis
GO
CREATE PROCEDURE EmotionalTrendAnalysis
    @CourseID INT,
    @ModuleID INT,
    @TimePeriod DATETIME
AS
BEGIN
    SELECT 
        CAST(ef.timestamp AS DATE) as Date,
        ef.emotional_state as EmotionalState,
        COUNT(*) as Count,
        c.Title as CourseTitle,
        m.Title as ModuleTitle
    FROM Emotional_feedback ef
    INNER JOIN Learning_activities la ON ef.activityID = la.ActivityID
    INNER JOIN Modules m ON la.ModuleID = m.ModuleID
    INNER JOIN Course c ON m.CourseID = c.CourseID
    WHERE (@CourseID = 0 OR c.CourseID = @CourseID)
    AND (@ModuleID = 0 OR m.ModuleID = @ModuleID)
    AND ef.timestamp >= @TimePeriod
    GROUP BY CAST(ef.timestamp AS DATE), ef.emotional_state, c.Title, m.Title
    ORDER BY Date;
END;
GO


-- Test Procedure
EXEC EmotionalTrendAnalysis @CourseID = 100, @ModuleID = 1, @TimePeriod = '2024-01-01';
select * from Emotional_feedback
SELECT * FROM Modules





-- ==================================================================================================
--                                       Learner Procedures
-- ==================================================================================================

-- Procedure 1 --
GO
CREATE PROCEDURE ProfileUpdate
    @LearnerID INT,
    @ProfileID INT,
    @PreferedContentType VARCHAR(50),
    @emotional_state VARCHAR(50),
    @PersonalityType VARCHAR(50)
AS
BEGIN
    -- Update the learner's profile details in the PersonalizationProfiles table
    UPDATE PersonalizationProfiles
    SET 
        Prefered_content_type = @PreferedContentType,
        emotional_state = @emotional_state,
        personality_type = @PersonalityType
        
    WHERE 
        LearnerID = @LearnerID 
        AND ProfileID = @ProfileID;
END;
GO
    

GO
CREATE PROCEDURE HealthConditionUpdate
    @HealthCondition VARCHAR(50),
    @ProfileID INT,
    @LearnerID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the record already exists
    IF EXISTS (SELECT 1 FROM HealthCondition WHERE LearnerID = @LearnerID AND ProfileID = @ProfileID AND condition = @HealthCondition)
    BEGIN
        -- If the record exists, update it
        UPDATE HealthCondition
        SET condition = @HealthCondition
        WHERE LearnerID = @LearnerID AND ProfileID = @ProfileID AND condition = @HealthCondition;
    END
    ELSE
    BEGIN
        -- If the record does not exist, insert it
        INSERT INTO HealthCondition (LearnerID, ProfileID, condition)
        VALUES (@LearnerID, @ProfileID, @HealthCondition);
    END
END;
GO
GO
CREATE PROCEDURE DeleteHealthConditions
    @ProfileID INT,
    @LearnerID INT
AS
BEGIN
    DELETE FROM HealthCondition 
    WHERE LearnerID = @LearnerID AND ProfileID = @ProfileID;
END;
GO
GO

-- Test the procedure
EXEC HealthConditionUpdate @HealthCondition = 'Sayed', @ProfileID = 1, @LearnerID = 1;
SELECT * FROM HealthCondition;

-- Test Procedure 
Exec ProfileUpdate @LearnerID =1 ,@ProfileID =1 ,@PreferedContentType = 'Video',@emotional_state ='Nervous' ,@PersonalityType='Introvert'

select * from PersonalizationProfiles

--------------------------------------------------------------------------------------------------------------------------------------------------------- Procedure 1
-- Procedure 2

GO
CREATE PROCEDURE TotalPoints
    @LearnerID INT,
    @RewardType VARCHAR(50)
AS
BEGIN
    DECLARE @TotalPoints DECIMAL(10, 2);

    -- Calculate the total points from rewards of the specified type for the learner
    SELECT 
        @TotalPoints = COALESCE(SUM(R.value), 0)
    FROM 
        QuestReward AS QR
    JOIN 
        Reward AS R ON QR.RewardID = R.RewardID
    WHERE 
        QR.LearnerID = @LearnerID
        AND R.type = @RewardType;

    -- Return the total points
    SELECT @TotalPoints AS TotalPointsEarned;
END;

GO

DECLARE @TotalPoints DECIMAL(10, 2);


-- Test Procedure 
EXEC TotalPoints 
    @LearnerID = 1,        
    @RewardType = 'Gift Card';     
    
select * from Reward
select * from QuestReward


-------------------------------------------------------------------------------------------------------------------------------------------------------

-- Procedure 12
GO
CREATE PROCEDURE Courseregister
    @LearnerID INT,
    @CourseID INT
AS
BEGIN
    -- Start a transaction
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- First check if already enrolled
        IF EXISTS (SELECT 1 FROM Course_enrollment 
                  WHERE LearnerID = @LearnerID 
                  AND CourseID = @CourseID)
        BEGIN
            ROLLBACK;
            RETURN 1; -- Already enrolled
        END

        -- Insert the enrollment
        INSERT INTO Course_enrollment (
            CourseID, 
            LearnerID, 
            enrollment_date, 
            status
        )
        VALUES (
            @CourseID,
            @LearnerID,
            GETDATE(),
            'ongoing'
        );

        COMMIT;
        RETURN 0; -- Success
    END TRY
    BEGIN CATCH
        ROLLBACK;
        RETURN -1; -- Error
    END CATCH
END;

-- Test Procedure
EXEC Courseregister @LearnerID =1,@CourseID=100;

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 3

GO
CREATE OR ALTER PROCEDURE EnrolledCourses
    @LearnerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.CourseID,
        c.Title,
        c.Description,
        c.learning_objective AS LearningObjective,
        c.credit_points AS CreditPoints,
        c.difficulty_level AS DifficultyLevel,
        ce.enrollment_date AS EnrollmentDate,
        ce.status AS Status,
        COUNT(ce.CourseID) OVER (PARTITION BY c.CourseID) AS EnrolledStudentsCount
    FROM Course c
    INNER JOIN Course_enrollment ce ON c.CourseID = ce.CourseID
    WHERE ce.LearnerID = @LearnerID
    AND ce.status = 'ongoing';
END;


--------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Procedure 4

GO 

CREATE PROCEDURE Prerequisites
    @LearnerID INT,
    @CourseID INT
AS
BEGIN
    SELECT cp.Prereq
    FROM CoursePrerequisite cp
    WHERE cp.CourseID = @CourseID
    AND cp.Prereq NOT IN (
        SELECT s.skill
        FROM Skills s
        WHERE s.LearnerID = @LearnerID
    );
END;
GO


-- Test Procedure 
EXEC Prerequisites @LearnerID = 1, @CourseID = 100;

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 5

GO

CREATE PROCEDURE Moduletraits
    @TargetTrait VARCHAR(50),
    @CourseID INT
AS
BEGIN
    -- Retrieve all modules for the specified course that train the specified trait
    SELECT 
        M.ModuleID,
        M.Title AS ModuleTitle,
        M.difficulty,
        M.contentURL,
        TT.Trait AS TargetTrait
    FROM 
        Modules AS M
    JOIN 
        Target_traits AS TT ON M.ModuleID = TT.ModuleID AND M.CourseID = TT.CourseID
    WHERE 
        M.CourseID = @CourseID
        AND TT.Trait = @TargetTrait
    ORDER BY 
        M.ModuleID;
END;

GO

-- Test Procedure 
EXEC Moduletraits @TargetTrait = 'Data Management', @CourseID = 101;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 6

GO

CREATE PROCEDURE LeaderboardRank
    @LeaderboardID INT
AS
BEGIN
    -- Retrieve all participants and their rankings for the specified leaderboard
    SELECT 
        R.LearnerID,
        L.first_name,
        L.last_name,
        R.rank,
        R.total_points
    FROM 
        Ranking AS R
    JOIN 
        Learner AS L ON R.LearnerID = L.LearnerID
    WHERE 
        R.BoardID = @LeaderboardID
    ORDER BY 
        R.rank;
END;

GO

-- Test Procedure 
EXEC LeaderboardRank @LeaderboardID = 2;

--------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Procedure 7 


GO
CREATE PROCEDURE ActivityEmotionalFeedback
    @ActivityID INT,
    @LearnerID INT,
    @timestamp TIME,
    @emotionalstate VARCHAR(50)
AS
BEGIN
    INSERT INTO Emotional_feedback (ActivityID,LearnerID, timestamp, emotional_state)
    VALUES (@ActivityID,@LearnerID, CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST(@timestamp AS DATETIME), @emotionalstate);

END;
GO

-- Test Procedure
EXEC ActivityEmotionalFeedback 
    @ActivityID = 5000, 
    @LearnerID = 1, 
    @timestamp = '14:30:10', 
    @emotionalstate = 'Nervouse';


--------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Procedure 8

GO

CREATE PROCEDURE JoinQuest
    @LearnerID INT,
    @QuestID INT
AS
BEGIN
    -- Declare variables to track maximum participants and current participants
    DECLARE @MaxParticipants INT, @CurrentParticipants INT;

    -- Retrieve maximum number of participants for the quest
    SELECT @MaxParticipants = max_num_participants
    FROM Collaborative
    WHERE QuestID = @QuestID;

    -- Calculate the current number of participants in the quest
    SELECT @CurrentParticipants = COUNT(*)
    FROM LearnersCollaboration
    WHERE QuestID = @QuestID;

    -- Check if space is available
    IF @CurrentParticipants < @MaxParticipants
    BEGIN
        -- Insert the learner into LearnersCollaboration if space is available
        INSERT INTO LearnersCollaboration (LearnerID, QuestID, completion_status)
        VALUES (@LearnerID, @QuestID, 'In Progress');

        PRINT 'Approval: You have successfully joined the quest.';
    END
    ELSE
    BEGIN
        -- Notify the learner that the quest is full
        PRINT 'Rejection: The quest is full. You cannot join.';
    END
END;
GO


-- Test Procedure
EXEC JoinQuest @LearnerID = 1, @QuestID = 17000;

---------------------------------------------------------------------------------------------------------------------------------------------------------

-- Procedure 9

GO

CREATE PROCEDURE SkillsProficiency
    @LearnerID INT
AS
BEGIN
    -- Retrieve all skills and their proficiency levels for the specified learner
    SELECT 
        skill_name AS SkillName,
        proficiency_level AS ProficiencyLevel,
        timestamp AS LastUpdated
    FROM 
        SkillProgression
    WHERE 
        LearnerID = @LearnerID
    ORDER BY 
        timestamp DESC; -- Orders by most recent proficiency updates
END;


GO

-- Test Procedure
EXEC SkillsProficiency @LearnerID = 1;

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 10

GO

CREATE PROCEDURE ViewScore
    @LearnerID INT,         
    @AssessmentID INT,      
    @score INT OUTPUT       
AS
BEGIN
    -- Validate input
    IF NOT EXISTS (SELECT 1 FROM Assessments WHERE ID = @AssessmentID)
    BEGIN
        PRINT 'Invalid Assessment ID.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Learner WHERE LearnerID = @LearnerID)
    BEGIN
        PRINT 'Invalid Learner ID.';
        RETURN;
    END

    -- Retrieve the score from Takenassessment 
    SELECT @score = la.ScoredPoint
    FROM Takenassessment  la
    WHERE la.LearnerID = @LearnerID AND la.AssessmentID = @AssessmentID;

    -- Handle case where no score is found
    IF @score IS NULL
    BEGIN
        PRINT 'No score found for the specified Learner and Assessment.';
        RETURN;
    END

    -- Output the score
    PRINT 'Score retrieved successfully: ' + CAST(@score AS VARCHAR);
END;

GO

-- Test Procedure
DECLARE @score INT;
EXEC ViewScore @LearnerID = 1, @AssessmentID = 4001, @score = @score OUTPUT;
PRINT 'Score: ' + CAST(@score AS VARCHAR);



-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 11

GO
CREATE PROCEDURE AssessmentsList
    @CourseID INT,
    @ModuleID INT,
    @LearnerID INT
AS
BEGIN
    -- Retrieve all assessments for the specified course and module where the learner is enrolled
    SELECT 
        A.ID AS AssessmentID,           -- Assuming 'ID' is the primary key in Assessments
        A.title AS AssessmentTitle,
        A.type AS AssessmentType,
        A.total_marks AS MaxPoints,
        A.passing_marks AS PassingMarks
    FROM 
        Assessments AS A
    JOIN 
        Course_enrollment AS CE ON A.CourseID = CE.CourseID
    WHERE 
        A.CourseID = @CourseID
        AND A.ModuleID = @ModuleID
        AND CE.LearnerID = @LearnerID
    ORDER BY 
        A.ID;
END;
GO

-- Test
EXEC AssessmentsList @CourseID =100,@ModuleID=1,@LearnerID=1;

----------------------------------------------------------------------------------------------------------------------------------------------------------- 

-- Procedure 13

GO
CREATE PROCEDURE Post
    @LearnerID INT,
    @DiscussionID INT,
    @Post VARCHAR(MAX)
AS
BEGIN
    -- Insert a new post into the LearnerDiscussion table
    INSERT INTO LearnerDiscussion (ForumID, LearnerID, Post, time)
    VALUES (@DiscussionID, @LearnerID, @Post, GETDATE());
END;

GO



-- Test Procedure
EXEC Post @LearnerID =1,@DiscussionID=1447,@Post='Test the post ';

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 14

GO
CREATE PROCEDURE AddGoal
    @LearnerID INT,
    @GoalID INT
AS
BEGIN
    -- Insert a new learning goal for the learner
    INSERT INTO LearnersGoals (GoalID, LearnerID)
    VALUES (@GoalID, @LearnerID);
END;

GO



-- Test Procedure
EXEC AddGoal @LearnerID = 2,@GoalID=8002;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 15

GO

CREATE PROCEDURE CurrentPath
    @LearnerID INT
AS
BEGIN
    -- Retrieve all learning paths and their statuses for the specified learner
    SELECT 
        pathID,
        completion_status AS Status,
        custom_content AS ContentDescription,
        adaptive_rules AS AdaptiveRules
    FROM 
        Learning_path
    WHERE 
        LearnerID = @LearnerID
    ORDER BY 
        pathID;
END;

GO



-- Test Procedure
EXEC CurrentPath @LearnerID =1;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 16
GO

CREATE PROCEDURE QuestMembers
    @LearnerID INT
AS
BEGIN
    -- Retrieve all quests the learner is participating in and whose deadlines have not passed
    SELECT 
        lc.QuestID,
        c.deadline,
        l.LearnerID,
        l.first_name AS FirstName,
        l.last_name AS LastName
    FROM 
        LearnersCollaboration lc
    INNER JOIN 
        Collaborative c ON lc.QuestID = c.QuestID
    INNER JOIN 
        LearnersCollaboration members ON members.QuestID = lc.QuestID
    INNER JOIN 
        Learner l ON members.LearnerID = l.LearnerID
    WHERE 
        lc.LearnerID = @LearnerID
        AND c.deadline >= GETDATE()
    ORDER BY 
        lc.QuestID, l.LearnerID;
END;
GO



-- Test Procedure
EXEC QuestMembers @LearnerID =1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 17

GO
CREATE PROCEDURE QuestProgress
    @LearnerID INT
AS
BEGIN
    -- Retrieve the completion status for the specified learner across all active quests and badges
    SELECT 
        lc.QuestID,
        q.title AS QuestTitle,
        q.criteria AS QuestCriteria,
        lc.completion_status AS QuestCompletionStatus,
        b.BadgeID,
        b.title AS BadgeTitle,
        a.date_earned AS BadgeEarnedDate
    FROM 
        LearnersCollaboration lc
    JOIN 
        Quest q ON lc.QuestID = q.QuestID
    LEFT JOIN 
        Achievement a ON lc.LearnerID = a.LearnerID
    LEFT JOIN 
        Badge b ON a.BadgeID = b.BadgeID
    WHERE 
        lc.LearnerID = @LearnerID
    ORDER BY 
        lc.QuestID, b.BadgeID;
END;
GO

-- Test Procedure
EXEC QuestProgress @LearnerID = 1;



-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 18
GO
CREATE PROCEDURE GoalReminder
    @LearnerID INT
AS
BEGIN
    -- Retrieve overdue and upcoming learning goals and send reminders
    SELECT 
        lg.ID AS GoalID,
        lg.Description,          -- No alias
        lg.Deadline,             -- No alias
        CASE 
            WHEN lg.deadline < GETDATE() THEN 'Overdue'
            WHEN lg.deadline BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE()) THEN 'Due Soon'
            ELSE 'Upcoming'
        END AS Status,
        CONCAT(
            'Reminder: Your goal "', 
            lg.Description, 
            '" is ', 
            CASE 
                WHEN lg.Deadline < GETDATE() THEN 'overdue (was due on '
                WHEN lg.Deadline BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE()) THEN 'due soon (on '
                ELSE 'upcoming (on '
            END,
            FORMAT(lg.Deadline, 'yyyy-MM-dd'), 
            ')'
        ) AS NotificationMessage
    FROM 
        Learning_goal lg
    JOIN 
        LearnersGoals lg_rel ON lg.ID = lg_rel.GoalID
    WHERE 
        lg_rel.LearnerID = @LearnerID
    ORDER BY 
        CASE 
            WHEN lg.Deadline < GETDATE() THEN 1
            WHEN lg.Deadline BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE()) THEN 2
            ELSE 3
        END, 
        lg.Deadline ASC; -- Prioritize overdue, then due soon, then upcoming goals
END;
GO


-- Test Procedure
EXEC GoalReminder @LearnerID = 1





-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 19

GO
CREATE PROCEDURE SkillProgressHistory
    @LearnerID INT,
    @Skill VARCHAR(50)
AS
BEGIN
    -- Retrieve the skill progression history for the specified learner and skill
    SELECT 
        timestamp AS Date,
        proficiency_level AS ProficiencyLevel
    FROM 
        SkillProgression
    WHERE 
        LearnerID = @LearnerID
        AND skill_name = @Skill
    ORDER BY 
        timestamp;
END;


GO


-- Test Procedure
EXEC SkillProgressHistory @LearnerID =1,@Skill='Python Programming';

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 20

GO
CREATE PROCEDURE AssessmentAnalysis
    @LearnerID INT
AS
BEGIN
    -- Retrieve detailed score breakdowns and performance analysis for the learner
    SELECT 
        A.ID AS AssessmentID,
        A.Title AS AssessmentTitle,
        A.type AS AssessmentType,
        A.Total_Marks AS MaxPoints,
        A.Passing_Marks AS PassingMarks,
        TA.ScoredPoint AS LearnerScore,
        CASE 
            WHEN TA.ScoredPoint >= A.Passing_Marks THEN 'Pass'
            ELSE 'Fail'
        END AS Performance,
        CASE 
            WHEN TA.ScoredPoint >= A.Passing_Marks THEN 'Strength'
            ELSE 'Weakness'
        END AS Analysis
    FROM 
        Assessments AS A
    LEFT JOIN 
        TakenAssessment AS TA ON A.ID = TA.AssessmentID
    WHERE 
        TA.LearnerID = @LearnerID
    ORDER BY 
        A.ID;
END;
GO




-- Test Procedure
EXEC AssessmentAnalysis @LearnerID =1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 21

GO
CREATE PROCEDURE LeaderboardFilter
    @LearnerID INT
AS
BEGIN
    -- Retrieve leaderboard rankings for the specified learner, sorted by rank in descending order
    SELECT 
        L.BoardID,
        LB.season AS LeaderboardSeason,
        L.rank,
        L.total_points AS TotalPoints
    FROM 
        Ranking AS L
    JOIN 
        Leaderboard AS LB ON L.BoardID = LB.BoardID
    WHERE 
        L.LearnerID = @LearnerID
    ORDER BY 
        L.rank DESC;
END;
GO


-- Test Procedure
EXEC LeaderboardFilter @LearnerID =1;

-- ==================================================================================================
--                                       Instructor Procedures
-- ==================================================================================================


-- Procedure 1

GO


CREATE PROCEDURE SkillLearners
    @Skillname VARCHAR(50)
AS
BEGIN
    -- Retrieve all learners who have the specified skill
    SELECT 
        S.skill AS SkillName,
        L.LearnerID,
        L.first_name AS FirstName,
        L.last_name AS LastName
    FROM 
        Skills AS S
    JOIN 
        Learner AS L ON S.LearnerID = L.LearnerID
    WHERE 
        S.skill = @Skillname
    ORDER BY 
        L.last_name, L.first_name;
END;

GO


-- Test Procedure
EXEC SkillLearners @Skillname ='Python Programming';

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 2

GO

CREATE PROCEDURE NewActivity
    @CourseID INT,
    @ModuleID INT,
    @activitytype VARCHAR(50),
    @instructiondetails VARCHAR(MAX),
    @maxpoints INT
AS
BEGIN
    -- Insert a new learning activity for the specified course and module
    INSERT INTO Learning_activities (CourseID, ModuleID, activity_type, instruction_details, Max_points)
    VALUES (@CourseID, @ModuleID, @activitytype, @instructiondetails, @maxpoints);
END;

GO


-- Test Procedure
EXEC NewActivity @CourseID = 100 , @ModuleID =1,@activitytype='Zoom and audio',@instructiondetails='Quiz1',@maxpoints=1000;




-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 3


GO
CREATE PROCEDURE NewAchievement
    @LearnerID INT,
    @BadgeID INT,
    @description VARCHAR(MAX),
    @date_earned DATE,
    @type VARCHAR(50)
AS
BEGIN
    -- Insert a new achievement for the specified learner
    INSERT INTO Achievement (LearnerID, BadgeID, description, date_earned, type)
    VALUES (@LearnerID, @BadgeID, @description, @date_earned, @type);
END;

GO


-- Test Procedure
EXEC NewAchievement @LearnerID = 1, @BadgeID = 10, @description = 'Completed advanced course', @date_earned = '2023-10-01', @type = 'Course Completion';

select * from Achievement
-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 4

GO
CREATE PROCEDURE LearnerBadge
    @BadgeID INT
AS
BEGIN
    -- Retrieve all learners who have earned the specified badge
    SELECT 
        L.LearnerID,
        L.first_name AS FirstName,
        L.last_name AS LastName,
        A.date_earned AS DateEarned,
        A.description AS AchievementDescription
    FROM 
        Achievement AS A
    JOIN 
        Learner AS L ON A.LearnerID = L.LearnerID
    WHERE 
        A.BadgeID = @BadgeID
    ORDER BY 
        A.date_earned DESC;
END;

GO


-- Test Procedure
EXEC LearnerBadge  @BadgeID = 14;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 5

GO
CREATE PROCEDURE NewPath
    @LearnerID INT,
    @ProfileID INT,
    @completion_status VARCHAR(50),
    @custom_content VARCHAR(MAX),
    @adaptiverules VARCHAR(MAX)
AS
BEGIN
    -- Insert a new learning path for the specified learner
    INSERT INTO Learning_path (LearnerID, ProfileID, completion_status, custom_content, adaptive_rules)
    VALUES (@LearnerID, @ProfileID, @completion_status, @custom_content, @adaptiverules);
END;

GO


-- Test Procedure
EXEC NewPath  @LearnerID=1,@ProfileID=1,@completion_status='in progress',@custom_content='None',@adaptiverules='Reduce Quizes';

select * from Learning_path
-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 6
GO
CREATE PROCEDURE TakenCourses
    @LearnerID INT
AS
BEGIN
    SELECT DISTINCT
        c.CourseID,
        c.Title,
        c.Description,
        c.learning_objective AS LearningObjective,
        c.credit_points AS CreditPoints,
        c.difficulty_level AS DifficultyLevel,
        ce.enrollment_date AS EnrollmentDate,
        ce.completion_date AS CompletionDate,
        ce.status AS Status,
        (SELECT COUNT(*) FROM Course_enrollment 
         WHERE CourseID = c.CourseID) as EnrolledStudentsCount
    FROM Course c
    INNER JOIN Course_enrollment ce ON c.CourseID = ce.CourseID
    WHERE ce.LearnerID = @LearnerID 
    AND ce.status = 'completed'
    ORDER BY ce.completion_date DESC;
END;

-- Test Procedure
EXEC TakenCourses  @LearnerID=1;


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 7

GO
CREATE PROCEDURE CollaborativeQuest
    @difficulty_level VARCHAR(50),
    @criteria VARCHAR(50),
    @description VARCHAR(50),
    @title VARCHAR(50),
    @Maxnumparticipants INT,
    @deadline DATETIME
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Step 1: Insert into Quest table
        DECLARE @QuestID INT;

        INSERT INTO Quest (difficulty_level, criteria, description, title)
        VALUES (@difficulty_level, @criteria, @description, @title);

        -- Retrieve the auto-generated QuestID
        SET @QuestID = SCOPE_IDENTITY();

        -- Step 2: Insert into Collaborative table
        INSERT INTO Collaborative (QuestID, max_num_participants, deadline)
        VALUES (@QuestID, @Maxnumparticipants, @deadline);

        -- Commit the transaction if everything succeeds
        COMMIT TRANSACTION;

        PRINT 'Collaborative Quest added successfully.';
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Optional: Raise an error or return a message
        PRINT 'Error occurred while adding the collaborative quest.';
        THROW;
    END CATCH
END;
GO


-- Test Procedure
EXEC CollaborativeQuest 
    @difficulty_level = 'Intermediate', 
    @criteria = 'Complete all tasks', 
    @description = 'A quest for intermediate learners', 
    @title = 'Intermediate Quest', 
    @Maxnumparticipants = 5, 
    @deadline = '2023-12-31';

    select * from Quest
    select * from Collaborative


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 8

GO

CREATE PROCEDURE DeadlineUpdate
    @QuestID INT,
    @deadline DATETIME
AS
BEGIN
    BEGIN TRY
        -- Update the deadline in the Collaborative table
        UPDATE Collaborative
        SET deadline = @deadline
        WHERE QuestID = @QuestID;

        PRINT 'Quest deadline updated successfully.';
    END TRY
    BEGIN CATCH
        -- Handle any errors
        PRINT 'Error occurred while updating the quest deadline.';
        THROW;
    END CATCH
END;
GO


-- Test Procedure
EXEC DeadlineUpdate @QuestID=17006, @deadline='2025-12-31'

SELECT * FROM Collaborative

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 9

GO
CREATE PROCEDURE GradeUpdate
    @LearnerID INT,
    @AssessmentID INT,
    @Points INT
AS
BEGIN
    DECLARE @Message VARCHAR(100);

    UPDATE Takenassessment 
    SET ScoredPoint = @Points  
    WHERE LearnerID = @LearnerID
      AND AssessmentID = @AssessmentID;

    -- Set confirmation message
    SET @Message = 'Grade successfully updated for LearnerID ' + CAST(@LearnerID AS VARCHAR) 
                   + ' in AssessmentID ' + CAST(@AssessmentID AS VARCHAR) + '.';

    -- Return confirmation message
    SELECT @Message AS ConfirmationMessage;
END;
GO


-- Test Procedure
EXEC GradeUpdate @LearnerID=1,@AssessmentID=4004,@points=18
select * from Takenassessment 

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 10
-- no timestamp in sql


GO

CREATE PROCEDURE AssessmentNot
    @NotificationID INT,
    @timestamp DATETIME,
    @message VARCHAR(MAX),
    @urgencylevel VARCHAR(50),
    @LearnerID INT
AS
BEGIN
    BEGIN TRY
        -- Begin transaction
        BEGIN TRANSACTION;

        -- Step 1: Enable explicit insertion into the IDENTITY column
        SET IDENTITY_INSERT Notification ON;

        -- Step 2: Insert the notification into the Notification table
        INSERT INTO Notification (ID, timestamp, message, urgency_level)
        VALUES (@NotificationID, @timestamp, @message, @urgencylevel);

        -- Step 3: Disable explicit insertion into the IDENTITY column
        SET IDENTITY_INSERT Notification OFF;

        -- Step 4: Link the notification to the learner in the ReceivedNotification table
        INSERT INTO ReceivedNotification (NotificationID, LearnerID)
        VALUES (@NotificationID, @LearnerID);

        -- Commit transaction
        COMMIT TRANSACTION;

        PRINT 'Notification sent successfully to the learner.';
    END TRY
    BEGIN CATCH
        -- Rollback transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Ensure IDENTITY_INSERT is turned off even in case of error
        IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'ID' AND object_id = OBJECT_ID('Notification'))
            SET IDENTITY_INSERT Notification OFF;

        PRINT 'Error occurred while sending the notification.';
        THROW;
    END CATCH
END;
GO



EXEC AssessmentNot 
    @NotificationID = 65021, 
    @timestamp = '2024-12-01 14:30:00',
    @message = 'TEST', 
    @urgencylevel = 'HIGH', 
    @LearnerID = 1;




SELECT * FROM Notification
SELECT * FROM ReceivedNotification


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 11

GO
CREATE PROCEDURE NewGoal
    @GoalID INT,
    @status VARCHAR(MAX),
    @deadline DATETIME,
    @description VARCHAR(MAX)
AS
BEGIN
    SET IDENTITY_INSERT Learning_goal ON;
    INSERT INTO Learning_goal (ID, status, deadline, description)
    VALUES (@GoalID, @status, @deadline, @description);
    SET IDENTITY_INSERT Learning_goal OFF;
END;
GO



-- Test Procedure
EXEC NewGoal @GoalID=8010,@status='Completed',@deadline='2025-12-31',@description='Test';
SELECT * FROM Learning_goal

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 12

GO
CREATE PROCEDURE LearnersCourses
    @InstructorID INT,
    @CourseID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        C.CourseID,
        C.Title AS CourseTitle,
        C.learning_objective AS LearningObjective,
        C.credit_points AS CreditPoints,
        C.difficulty_level AS DifficultyLevel,
        C.description AS Description
    FROM 
        Teaches AS T
    INNER JOIN 
        Course AS C ON T.CourseID = C.CourseID
    WHERE 
        T.InstructorID = @InstructorID
        AND (@CourseID IS NULL OR C.CourseID = @CourseID);
END;

GO

-- Test Procedure
EXEC LearnersCourses @CourseID=100,@InstructorID=1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 13

GO
CREATE PROCEDURE LastActive
    @ForumID INT,
    @lastactive DATETIME OUTPUT
AS
BEGIN
    SELECT @lastactive = last_active
    FROM Discussion_forum
    WHERE forumID = @ForumID;
END;

GO



-- Test Procedure
DECLARE @lastactive DATETIME;
EXEC LastActive @ForumID = 1450, @lastactive = @lastactive OUTPUT;
SELECT @lastactive AS LastActiveTimestamp;

SELECT * FROM Discussion_forum


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 14

GO
CREATE PROCEDURE CommonEmotionalState
    @state VARCHAR(50) OUTPUT
AS
BEGIN
    SELECT TOP 1 @state = emotional_state
    FROM Emotional_feedback
    GROUP BY emotional_state
    ORDER BY COUNT(emotional_state) DESC;
END;

GO

-- Test Procedure
DECLARE @state VARCHAR(50);
EXEC CommonEmotionalState @state = @state OUTPUT;
SELECT @state AS MostCommonEmotionalState;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 15

GO
CREATE PROCEDURE ModuleDifficulty
    @courseID INT
AS
BEGIN
    SELECT 
        ModuleID,
        Title AS ModuleTitle,
        difficulty,
        contentURL
    FROM 
        Modules
    WHERE 
        CourseID = @courseID
    ORDER BY 
        CASE 
            WHEN difficulty = 'Beginner' THEN 1
            WHEN difficulty = 'Intermediate' THEN 2
            WHEN difficulty = 'Advanced' THEN 3
            ELSE 4
        END;
END;

GO

-- Test Procedure
EXEC ModuleDifficulty @courseID = 100;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 16
GO
CREATE PROCEDURE ProficiencyLevel
    @LearnerID INT,
    @skill VARCHAR(50) OUTPUT
AS
BEGIN
    SELECT TOP 1 @skill = skill_name
    FROM SkillProgression
    WHERE LearnerID = @LearnerID
    ORDER BY 
        CASE 
            WHEN proficiency_level = 'Expert' THEN 4
            WHEN proficiency_level = 'Advanced' THEN 3
            WHEN proficiency_level = 'Intermediate' THEN 2
            WHEN proficiency_level = 'Beginner' THEN 1
            ELSE 0
        END DESC;
END;

GO



-- Test Procedure
DECLARE @skill VARCHAR(50);
EXEC ProficiencyLevel @LearnerID = 1, @skill = @skill OUTPUT;
SELECT @skill AS HighestProficiencySkill;


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 17

GO
CREATE PROCEDURE ProficiencyUpdate
    @Skill VARCHAR(50),
    @LearnerID INT,
    @Level VARCHAR(50)
AS
BEGIN
    -- Update the proficiency level for the specified learner and skill
    UPDATE SkillProgression
    SET proficiency_level = @Level,
        timestamp = GETDATE()  -- Update the timestamp to reflect the recent change
    WHERE LearnerID = @LearnerID
      AND skill_name = @Skill;
END;

GO



-- Test Procedure
EXEC ProficiencyUpdate @Skill='Public Speaking',@LearnerID = 1, @Level='Intermediate';

SELECT * FROM SkillProgression



-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 18


GO
CREATE PROCEDURE LeastBadge
    @LearnerID INT OUTPUT
AS
BEGIN
    -- Find the learner with the least number of badges earned
    SELECT TOP 1 @LearnerID = LearnerID
    FROM (
        SELECT LearnerID, COUNT(BadgeID) AS BadgeCount
        FROM Achievement
        GROUP BY LearnerID
    ) AS BadgeCounts
    ORDER BY BadgeCount ASC;
END;

GO



-- Test Procedure
DECLARE @LearnerID INT;
EXEC LeastBadge @LearnerID = @LearnerID OUTPUT;
SELECT @LearnerID AS LearnerWithLeastBadges;

select * from badge
select * from QuestReward


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Procedure 19

GO
CREATE PROCEDURE PreferredType
    @type VARCHAR(50) OUTPUT
AS
BEGIN
    -- Retrieve the most common preferred learning type among learners
    SELECT TOP 1 @type = preference
    FROM LearningPreference
    GROUP BY preference
    ORDER BY COUNT(preference) DESC;
END;


GO



-- Test Procedure
DECLARE @type VARCHAR(50);
EXEC PreferredType @type = @type OUTPUT;
SELECT @type AS MostPreferredLearningType;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure 20
GO
CREATE OR ALTER PROCEDURE AssessmentAnalytics
    @CourseID INT,
    @ModuleID INT   
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            a.CourseID,
            a.ModuleID,
            AVG(la.ScoredPoint) AS Average_Score,
            COUNT(DISTINCT ce.LearnerID) AS Total_Learners,
            COUNT(DISTINCT a.ID) AS Total_Assessments,
            l.LearnerID,
            l.first_name,
            l.last_name
        FROM 
            Assessments a
        LEFT JOIN 
            TakenAssessment la ON a.ID = la.AssessmentID AND la.ScoredPoint IS NOT NULL
        LEFT JOIN 
            Course_enrollment ce ON a.CourseID = ce.CourseID AND ce.LearnerID = la.LearnerID
        LEFT JOIN 
            Learner l ON ce.LearnerID = l.LearnerID
        WHERE 
            a.CourseID = @CourseID AND a.ModuleID = @ModuleID
        GROUP BY 
            a.CourseID, a.ModuleID, l.LearnerID, l.first_name, l.last_name;

    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_LINE() AS ErrorLine;
    END CATCH
END;
GO


EXEC AssessmentAnalytics @CourseID=100 ,@ModuleID=1


-----------------------------------------------------------------------------------------------------------------------------------------------------------

GO
Create PROCEDURE EmotionalTrendAnalysisIns
    @CourseID INT,
    @ModuleID INT,
    @TimePeriod DATETIME
AS
BEGIN
    SELECT 
        L.LearnerID,
        L.first_name AS FirstName,
        L.last_name AS LastName,
        C.CourseID,
        C.Title AS CourseTitle,
        M.ModuleID,
        M.Title AS ModuleTitle,
        EF.emotional_state AS EmotionalState,
        COUNT(EF.emotional_state) AS Frequency,
        FORMAT(EF.timestamp, 'yyyy-MM-dd HH:mm:ss') AS Timestamp
    FROM 
        Emotional_feedback AS EF
    JOIN 
        Learner AS L ON EF.LearnerID = L.LearnerID
    JOIN 
        Course_enrollment AS CE ON L.LearnerID = CE.LearnerID AND CE.CourseID = @CourseID
    JOIN 
        Modules AS M ON M.CourseID = @CourseID AND M.ModuleID = @ModuleID -- ModuleID is required
    JOIN 
        Course AS C ON C.CourseID = CE.CourseID
    JOIN 
        Teaches AS T ON T.CourseID = C.CourseID -- Ensures instructor teaches the course
    WHERE 
        EF.timestamp >= @TimePeriod -- Include feedback starting from the specified time period
    GROUP BY 
        L.LearnerID, 
        L.first_name, 
        L.last_name, 
        C.CourseID, 
        C.Title, 
        M.ModuleID, 
        M.Title, 
        EF.emotional_state,
        FORMAT(EF.timestamp, 'yyyy-MM-dd HH:mm:ss')
    ORDER BY 
        Timestamp, Frequency DESC;
END;
GO



-- Test Procedure
EXEC EmotionalTrendAnalysisIns 
    @CourseID = 100, 
    @ModuleID = 1, 
    @TimePeriod = '2023-11-01 00:00:00';

    select *from Modules
    select * from Emotional_feedback

/*
-- ALL THE FOLLOWING IS FOR TESTING PURPOSES

-- ==================================================================================================
--                                       Drop Admin Procedures
-- ==================================================================================================

drop procedure ViewInfo
drop procedure LearnerInfo
drop procedure EmotionalState
drop procedure LogDetails
drop procedure InstructorReview
drop procedure CourseRemove
drop procedure Highestgrade
drop procedure InstructorCount
drop procedure ViewNot
drop procedure CreateDiscussion
drop procedure RemoveBadge
drop procedure CriteriaDelete
drop procedure NotificationUpdate
drop procedure EmotionalTrendAnalysis

-- ==================================================================================================
--                                       Drop Learrner Procedures
-- ==================================================================================================

drop procedure ProfileUpdate
drop procedure TotalPoints
drop procedure EnrolledCourses
drop procedure Prerequisites
drop procedure ActivityEmotionalFeedback
drop procedure JoinQuest
drop procedure SkillsProficiency
drop procedure Viewscore
drop procedure AssessmentsList
drop procedure Courseregister
drop procedure Post
drop procedure AddGoal
drop procedure CurrentPath
drop procedure QuestMembers
drop procedure QuestProgress
drop procedure GoalReminder
drop procedure AssessmentAnalysis
drop procedure LeaderboardFilter

-- ==================================================================================================
--                                       Drop Instructor Procedures
-- ==================================================================================================
drop procedure SkillLearners
drop procedure NewActivity
drop procedure NewAchievement
drop procedure LearnerBadge
drop procedure NewPath
drop procedure TakenCourses
drop procedure CollaborativeQuest
drop procedure Sp_Inventory
drop procedure DeadlineUpdate
drop procedure GradeUpdate
drop procedure AssessmentNot
drop procedure NewGoal
drop procedure LearnersCourses
drop procedure LastActive
drop procedure CommonEmotionalState
drop procedure ModuleDifficulty
drop procedure ProficiencyLevel
drop procedure ProficiencyUpdate
drop procedure PreferredType
drop procedure AssessmentAnalytics
drop procedure LeastBadge
drop procedure PreferredType
drop procedure AssessmentAnalytics
drop procedure EmotionalTrendAnalysisIns

-------------------------------------------------------------
            SHOW ME ALL PROCEDURES WE HAVE
-------------------------------------------------------------

SELECT 
    name AS Procedure_Name,
    create_date AS Created_On,
    modify_date AS Last_Modified_On
FROM 
    sys.procedures
ORDER BY 
    create_date;
-----------------------------------------------------------
-- Execute all procedures sequentially

-- Admin Procedures
EXEC ViewInfo @LearnerID = 13000000;
EXEC LearnerInfo @LearnerID = 13000000;
EXEC EmotionalState @LearnerID = 13000001;
EXEC LogDetails @LearnerID = 13000003;
EXEC InstructorReview @InstructorID = 1;
EXEC CourseRemove @courseID = 101;
EXEC Highestgrade;
EXEC InstructorCount;
EXEC ViewNot @LearnerID = 13000003;
EXEC CreateDiscussion @ModuleID = 1, @CourseID = 100, @Title = 'New Discussion', @Description = 'This is a new discussion forum.';
-- EXEC RemoveBadge @BadgeID = 15;
-- EXEC CriteriaDelete @criteria = 'Complete Intro Modules';
EXEC NotificationUpdate @LearnerID = 13000000, @NotificationID = 65000, @ReadStatus = 1;
EXEC EmotionalTrendAnalysisIns @CourseID = 100, @ModuleID = 1, @TimePeriod = '2024-11-01 00:00:00';

-- Learner Procedures
EXEC ProfileUpdate @LearnerID = 13000001, @ProfileID = 2, @PreferedContentType = 'Video', @emotional_state = 'Nervous', @PersonalityType = 'Introvert';
EXEC TotalPoints @LearnerID = 13000000, @RewardType = 'Gift Card';
EXEC EnrolledCourses @LearnerID = 13000001;
EXEC Prerequisites @LearnerID = 13000000, @CourseID = 104;
EXEC ActivityEmotionalFeedback @ActivityID = 5000, @LearnerID = 13000000, @timestamp = '14:30:10', @emotionalstate = 'Nervous';
EXEC JoinQuest @LearnerID = 13000006, @QuestID = 17006;
EXEC SkillsProficiency @LearnerID = 13000000;
EXEC ViewScore @LearnerID = 13000001, @AssessmentID = 4001, @score = @score OUTPUT;
EXEC AssessmentsList @CourseID = 100, @ModuleID = 1, @LearnerID = 13000000;
EXEC Courseregister @LearnerID = 13000000, @CourseID = 104;
EXEC Post @LearnerID = 13000000, @DiscussionID = 1446, @Post = 'Test the post';
EXEC AddGoal @LearnerID = 13000002, @GoalID = 8003;
EXEC CurrentPath @LearnerID = 13000000;
EXEC QuestMembers @LearnerID = 13000005;
EXEC QuestProgress @LearnerID = 13000000;
EXEC GoalReminder @LearnerID = 13000004;
EXEC AssessmentAnalysis @LearnerID = 13000004;
EXEC LeaderboardFilter @LearnerID = 13000000;

-- Instructor Procedures
EXEC SkillLearners @Skillname = 'Python Programming';
EXEC NewActivity @CourseID = 100, @ModuleID = 1, @activitytype = 'Zoom and audio', @instructiondetails = 'Quiz1', @maxpoints = 1000;
EXEC NewAchievement @LearnerID = 13000000, @BadgeID = 10, @description = 'Completed advanced course', @date_earned = '2023-10-01', @type = 'Course Completion';
EXEC LearnerBadge @BadgeID = 14;
EXEC NewPath @LearnerID = 13000000, @ProfileID = 1, @completion_status = 'in progress', @custom_content = 'None', @adaptiverules = 'Reduce Quizes';
EXEC TakenCourses @LearnerID = 13000000;
EXEC CollaborativeQuest @difficulty_level = 'Intermediate', @criteria = 'Complete all tasks', @description = 'A quest for intermediate learners', @title = 'Intermediate Quest', @Maxnumparticipants = 5, @deadline = '2023-12-31';
EXEC DeadlineUpdate @QuestID = 17006, @deadline = '2025-12-31';
EXEC GradeUpdate @LearnerID = 13000004, @AssessmentID = 4004, @points = 18;
EXEC AssessmentNot @NotificationID = 65021, @timestamp = '2024-12-01 14:30:00', @message = 'TEST', @urgencylevel = 'HIGH', @LearnerID = 13000000;
EXEC NewGoal @GoalID = 8010, @status = 'Completed', @deadline = '2025-12-31', @description = 'Test';
EXEC LearnersCourses @CourseID = 100, @InstructorID = 1;
EXEC LastActive @ForumID = 1450, @lastactive = @lastactive OUTPUT;
EXEC CommonEmotionalState @state = @state OUTPUT;
EXEC ModuleDifficulty @courseID = 100;
EXEC ProficiencyLevel @LearnerID = 13000003, @skill = @skill OUTPUT;
EXEC ProficiencyUpdate @Skill = 'Public Speaking', @LearnerID = 13000003, @Level = 'Intermediate';
EXEC LeastBadge @LearnerID = @LearnerID OUTPUT;
EXEC PreferredType @type = @type OUTPUT;
EXEC AssessmentAnalytics @CourseID = 100, @ModuleID = 1;

-- Print completion message
PRINT 'All procedures executed successfully.';

*/

