use EducationalPlatform
go

-- ==================================================================================================
-- Triggers to make sure that no Collaborative Quests are is also a Mastery Quest and vice versa 
--									( ENSURE THEY ARE DISJOINT )								   --
--===================================================================================================
GO
CREATE TRIGGER trg_Collaborative_Disjoint
ON Collaborative
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Skill_Mastery sm
        ON i.QuestID = sm.QuestID
    )
    BEGIN
        RAISERROR ('QuestID already exists in Skill_Mastery, disjoint constraint violated.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER trg_Skill_Mastery_Disjoint
ON Skill_Mastery
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Collaborative c
        ON i.QuestID = c.QuestID
    )
    BEGIN
        RAISERROR ('QuestID already exists in Collaborative, disjoint constraint violated.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO



-- ==================================================================================================
-- Insert Statements for EducationalPlatform Database
-- ==================================================================================================
-- Learner Table Insertions

INSERT INTO Users (Email, PasswordHash, Role)
VALUES 
('john@example.com', '12345678', 'Learner'),
('jane.smith@example.com', 'hashed_password_2', 'Instructor'),
('admin.user@example.com', 'hashed_password_3', 'Admin'),
('sayed@gmail.com' , '12345678', 'Learner'),
('ali@gmail.com', 'password_ali', 'Learner'),
('goofy@gmail.com', 'password_goofy', 'Learner'),
('ebaid@gmail.com', 'password_ebaid', 'Learner'),
('darwish@gmail.com', 'password_darwish', 'Learner'),
('king@gmail.com', 'password_king', 'Learner'),
('watson@gmail.com', 'password_watson', 'Learner');



-- Inserting into Learner table
INSERT INTO Learner (LearnerID, first_name, last_name, gender, birth_date, country, cultural_background)
VALUES 
(1, 'John', 'Doe', 'M', '1995-05-15', 'United States', 'Caucasian'),
(2, 'Emily', 'Johnson', 'F', '1998-03-22', 'Canada', 'Asian-American'),
(3, 'Ali', 'Tharwat', 'M', '1997-07-10', 'Egypt', 'Middle-Eastern'),
(4, 'Goofy', 'Nafsy', 'M', '1990-01-01', 'Egypt', 'Cartoon'),
(5, 'Ebaid', 'Yassin', 'M', '1996-12-25', 'Egypt', 'Middle-Eastern'),
(6, 'Marwan', 'Darwish', 'M', '1993-09-30', 'Egypt', 'Middle-Eastern'),
(7, 'King', 'Tut', 'M', '1990-06-01', 'Egypt', 'Middle-Eastern'),
(8, 'Watson', 'Sherlock', 'M', '1995-11-12', 'United Kingdom', 'Caucasian'),
(9, 'Mickey', 'Mouse', 'M', '1928-11-18', 'United States', 'Cartoon'),
(10, 'Minnie', 'Mouse', 'F', '1928-11-18', 'United States', 'Cartoon');


-- Skills Table Insertions
INSERT INTO Skills (LearnerID, skill) VALUES
(1, 'Python Programming'),
(2, 'Data Analysis');



-- LearningPreference Table Insertions
INSERT INTO LearningPreference (LearnerID, preference) VALUES
(1, 'Video Lectures'),
(2, 'Hands-on Projects');


-- PersonalizationProfiles Table Insertions
INSERT INTO PersonalizationProfiles (LearnerID, ProfileID, Prefered_content_type, emotional_state, personality_type) VALUES
(1, 1, 'Video', 'Happy', 'Extrovert'),
(2, 2, 'Text', 'Focused', 'Introvert');


-- HealthCondition Table Insertions
INSERT INTO HealthCondition (LearnerID, ProfileID, condition) VALUES
(1, 1, 'Asthma'),
(2, 2, 'Dyslexia');


-- Course Table Insertions
INSERT INTO Course (Title, learning_objective, credit_points, difficulty_level, description) VALUES
('Introduction to Programming', 'Learn basic programming concepts', 4, 'Beginner', 'A beginner course in programming using Python.'),
('Data Structures', 'Understand data organization', 4, 'Intermediate', 'Covers various data structures such as arrays, linked lists, and trees.'),
('Database Management', 'Learn SQL and database concepts', 4, 'Intermediate',  'An intermediate course on relational databases.'),
('Machine Learning Basics', 'Introduction to ML concepts', 4, 'Advanced', 'A course on the basics of machine learning techniques.'),
('Communication Skills', 'Develop effective communication skills', 3, 'Beginner', 'Focuses on verbal and written communication.');

-- Insert prerequisites for Course 101
INSERT INTO CoursePrerequisite (CourseID, Prereq)
VALUES 
(100, 'Basic Mathematics'),
(100, 'Introduction to Algebra');

-- Insert prerequisites for Course 102
INSERT INTO CoursePrerequisite (CourseID, Prereq)
VALUES 
(101, 'Basic Programming Concepts'),
(101, 'Introduction to Algorithms');

-- Insert prerequisites for Course 103
INSERT INTO CoursePrerequisite (CourseID, Prereq)
VALUES 
(102, 'Data Structures Basics'),
(102, 'Object-Oriented Programming');

-- Insert prerequisites for Course 104
INSERT INTO CoursePrerequisite (CourseID, Prereq)
VALUES 
(103, 'Database Concepts'),
(103, 'SQL Fundamentals');

INSERT INTO CoursePrerequisite (CourseID, Prereq)
VALUES 
(104, 'Sayed Method');

-- Modules Table Insertions
INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(1, 100, 'Introduction to Variables', 'Beginner', 'http://example.com/intro-to-variables'),
(2, 100, 'Control Flow Basics', 'Beginner', 'http://example.com/control-flow-basics'),
(3, 101, 'Linked Lists', 'Intermediate', 'http://example.com/linked-lists'),
(4, 102, 'SQL Basics', 'Intermediate', 'http://example.com/sql-basics'),
(5, 103, 'Supervised Learning', 'Advanced', 'http://example.com/supervised-learning');

INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(3, 100, 'Linked Lists', 'Intermediate', 'http://example.com/linked-lists')

INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(6, 100, 'Linked Lists', 'Beginner', 'http://example.com/linked-lists')
INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(5, 100, 'Linked Lists', 'Advanced', 'http://example.com/linked-lists')

INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(7, 101, 'Linked Lists', 'Advanced', 'http://example.com/linked-lists')


INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL) VALUES
(6, 101, 'Supervised Learning', 'Advanced', 'http://example.com/supervised-learning');


-- Target_traits Table Insertions
INSERT INTO Target_traits (ModuleID, CourseID, Trait) VALUES
(1, 100, 'Logical Thinking'),
(2, 100, 'Problem Solving'),
(3, 101, 'Data Management'),
(4, 102, 'Query Optimization'),
(5, 103, 'Predictive Analysis');

-- Target_traits Table Insertions
INSERT INTO Target_traits (ModuleID, CourseID, Trait) VALUES
(6, 101, 'Data Management');

-- ModuleContent Table Insertions
INSERT INTO ModuleContent (ModuleID, CourseID, content_type) VALUES
(1, 100, 'Video'),
(2, 100, 'Text'),
(3, 101, 'Interactive Exercise'),
(4, 102, 'Quiz'),
(5, 103, 'Project');

-- ContentLibrary Table Insertions
INSERT INTO ContentLibrary (ModuleID, CourseID, Title, description, metadata, type, content_URL) VALUES
(1, 100, 'Intro Video', 'Introduction to Variables', 'Length: 5 minutes', 'Video', 'http://example.com/intro-video'),
(2, 100, 'Control Flow PDF', 'Explanation of Control Flow', 'Pages: 10', 'Document', 'http://example.com/control-flow-pdf'),
(3, 101, 'Linked List Animation', 'Visualizing Linked Lists', 'Length: 3 minutes', 'Animation', 'http://example.com/linked-list-animation'),
(4, 102, 'SQL Exercise', 'Practice SQL Queries', NULL, 'Interactive', 'http://example.com/sql-exercise'),
(5, 103, 'Supervised Learning Guide', 'Introduction to Supervised Learning', 'Pages: 20', 'Document', 'http://example.com/supervised-learning-guide');

-- Assessments Table Insertions
INSERT INTO Assessments (ModuleID, CourseID, type, total_marks, passing_marks, criteria, weightage, description, title) VALUES
(1, 100, 'Quiz', 10, 6, 'Multiple Choice', 10.00, 'Basic Quiz on Variables', 'Variables Quiz'),
(2, 100, 'Assignment', 20, 12, 'Coding Exercise', 20.00, 'Control Flow Assignment', 'Control Flow Task'),
(3, 101, 'Exam', 50, 25, 'Written Exam', 40.00, 'Linked List Exam', 'Linked List Test'),
(4, 102, 'Practical Test', 30, 18, 'SQL Queries', 30.00, 'Test on SQL Basics', 'SQL Basics Practical'),
(5, 103, 'Project', 40, 20, 'ML Application', 50.00, 'Machine Learning Project', 'ML Basics Project');

INSERT INTO Takenassessment (AssessmentID,LearnerID, ScoredPoint)
VALUES
(4000,1, 8),
(4001,2, 15);


-- Learning_activities Table Insertions
INSERT INTO Learning_activities (ModuleID, CourseID, activity_type, instruction_details, Max_points) VALUES
(1, 100, 'Lecture', 'Introduction to Variables', 10),
(2, 100, 'Exercise', 'Practice Control Flow', 15),
(3, 101, 'Lecture', 'Understanding Linked Lists', 20),
(4, 102, 'Quiz', 'SQL Practice Quiz', 25),
(5, 103, 'Project', 'Apply ML Techniques', 30);

-- Emotional_feedback Table Insertions
INSERT INTO Emotional_feedback (LearnerID, activityID,emotional_state) VALUES
(1,5000,'Motivated'),
(2,5001,'Focused');



INSERT INTO Emotional_feedback (timestamp,LearnerID, activityID,emotional_state) VALUES
(2023-01-15,6,5000,'Motivated')


-- Learning_path Table Insertions
INSERT INTO Learning_path (LearnerID, ProfileID, completion_status, custom_content, adaptive_rules) VALUES
(1, 1, 'in progress', 'Advanced Python Topics', 'Adjust based on quiz performance'),
(2, 2, 'completed', 'Data Analysis Tools', 'Provide more group discussions');


-- Instructor Table Insertions
INSERT INTO Instructor (InstructorID, name, latest_qualification, expertise_area, email)
VALUES 
(1, 'Jane Smith', 'PhD in Computer Science', 'Machine Learning', 'jane.smith@example.com'),
(2, 'Michael Brown', 'Master of Education', 'Educational Technology', 'michael.brown@example.com');



-- Pathreview Table Insertions
INSERT INTO Pathreview (InstructorID, PathID, review) VALUES
(1, 50000, 'Good progress, keep up the work'),
(2, 50001, 'Excellent understanding of concepts');


-- Emotionalfeedback_review Table Insertions
INSERT INTO Emotionalfeedback_review (FeedbackID, InstructorID, review) VALUES
(20000, 1, 'Keep up the motivation'),
(20001, 2, 'Focus is key to success');


-- Course_enrollment Table Insertions
INSERT INTO Course_enrollment (CourseID, LearnerID, completion_date, enrollment_date, status) VALUES
(100, 1, '2024-01-15', '2023-09-01', 'completed'),
(101, 2, NULL, '2023-09-01', 'ongoing'),
(102, 1, '2024-02-10', '2023-09-01', 'completed'),
(103, 2, NULL, '2023-09-01', 'ongoing'),
(104, 3, '2024-03-20', '2023-10-01', 'completed'),
(100, 4, NULL, '2023-11-01', 'ongoing'),
(101, 5, '2024-04-15', '2023-12-01', 'completed'),
(102, 6, NULL, '2023-09-15', 'ongoing'),
(103, 7, '2024-05-10', '2023-10-15', 'completed'),
(104, 8, NULL, '2023-11-15', 'ongoing'),
(100, 9, '2024-06-01', '2023-12-15', 'completed'),
(101, 10, NULL, '2023-09-20', 'ongoing'),
(102, 1, '2024-07-10', '2023-10-20', 'completed'),
(103, 2, NULL, '2023-11-20', 'ongoing'),
(104, 3, '2024-08-15', '2023-12-20', 'completed'),
(100, 4, NULL, '2023-09-25', 'ongoing'),
(101, 5, '2024-09-20', '2023-10-25', 'completed'),
(102, 6, NULL, '2023-11-25', 'ongoing'),
(103, 7, '2024-10-15', '2023-12-25', 'completed'),
(104, 8, NULL, '2023-09-30', 'ongoing'),
(100, 9, '2024-11-10', '2023-10-30', 'completed'),
(101, 10, NULL, '2023-11-30', 'ongoing'),
(102, 1, '2024-12-05', '2023-12-30', 'completed'),
(103, 2, NULL, '2023-09-05', 'ongoing'),
(104, 3, '2024-01-10', '2023-10-05', 'completed'),
(100, 4, NULL, '2023-11-05', 'ongoing'),
(101, 5, '2024-02-15', '2023-12-05', 'completed'),
(102, 6, NULL, '2023-09-10', 'ongoing'),
(103, 7, '2024-03-20', '2023-10-10', 'completed'),
(104, 8, NULL, '2023-11-10', 'ongoing'),
(100, 9, '2024-04-25', '2023-12-10', 'completed'),
(101, 10, NULL, '2023-09-15', 'ongoing'),
(102, 1, '2024-05-30', '2023-10-15', 'completed'),
(103, 2, NULL, '2023-11-15', 'ongoing'),
(104, 3, '2024-06-05', '2023-12-15', 'completed'),
(100, 4, NULL, '2023-09-20', 'ongoing'),
(101, 5, '2024-07-10', '2023-10-20', 'completed'),
(102, 6, NULL, '2023-11-20', 'ongoing'),
(103, 7, '2024-08-15', '2023-12-20', 'completed'),
(104, 8, NULL, '2023-09-25', 'ongoing'),
(100, 9, '2024-09-30', '2023-10-25', 'completed'),
(101, 10, NULL, '2023-11-25', 'ongoing'),
(102, 1, '2024-10-15', '2023-12-25', 'completed'),
(103, 2, NULL, '2023-09-30', 'ongoing'),
(104, 3, '2024-11-10', '2023-10-30', 'completed'),
(100, 4, NULL, '2023-11-30', 'ongoing'),
(101, 5, '2024-12-05', '2023-12-30', 'completed'),
(102, 6, NULL, '2023-09-05', 'ongoing'),
(103, 7, '2024-01-10', '2023-10-05', 'completed'),
(104, 8, NULL, '2023-11-05', 'ongoing'),
(100, 9, '2024-02-15', '2023-12-05', 'completed'),
(101, 10, NULL, '2023-09-10', 'ongoing'),
(102, 1, '2024-03-20', '2023-10-10', 'completed'),
(103, 2, NULL, '2023-11-10', 'ongoing'),
(104, 3, '2024-04-25', '2023-12-10', 'completed');




-- Teaches Table Insertions
INSERT INTO Teaches (InstructorID, CourseID) VALUES
(1, 100),
(2, 101);


-- Leaderboard Table Insertions
SET IDENTITY_INSERT Leaderboard OFF;
INSERT INTO Leaderboard (season) VALUES
('Spring 2024'),
('Summer 2024'),
('Fall 2024'),
('Winter 2024'),
('Spring 2025'),
('Summer 2025'),
('Fall 2025'),
('Winter 2025'),
('Spring 2026'),
('Summer 2026'),
('Fall 2026'),
('Winter 2026'),
('Spring 2027'),
('Summer 2027'),
('Fall 2027'),
('Winter 2027'),
('Spring 2028'),
('Summer 2028'),
('Fall 2028'),
('Winter 2028');

SET IDENTITY_INSERT Leaderboard ON;
-- Ranking Table Insertions
INSERT INTO Ranking (BoardID, LearnerID, CourseID, rank, total_points) VALUES
(1, 1, 100, 1, 95),
(1, 2, 101, 2, 90),
(1, 3, 104, 5, 75),
(1, 4, 100, 6, 70),
(1, 5, 101, 7, 65),
(1, 6, 102, 8, 60),
(1, 7, 103, 9, 55),
(1, 8, 104, 10, 50),
(1, 9, 100, 11, 45),
(2, 1, 100, 1, 95),
(2, 2, 101, 2, 90),
(2, 3, 104, 5, 75),
(2, 4, 100, 6, 70),
(2, 5, 101, 7, 65),
(2, 6, 102, 8, 60),
(2, 7, 103, 9, 55),
(2, 8, 104, 10, 50),
(2, 9, 100, 11, 45),
(2, 10, 101, 12, 40);


-- Learning_goal Table Insertions
INSERT INTO Learning_goal (status, deadline, description) VALUES
('in progress', '2024-03-01', 'Complete Python Certification'),
('not started', '2024-05-15', 'Finish Data Structures Course'),
('completed', '2024-02-10', 'Attend ML Bootcamp'),
('in progress', '2025-04-20', 'Complete SQL Challenges'),
('completed', '2025-01-25', 'Learn Public Speaking');

-- LearnersGoals Table Insertions
INSERT INTO LearnersGoals (GoalID, LearnerID) VALUES
(8000, 1),
(8001, 2);


-- Insert data for Interaction_log
INSERT INTO Interaction_log (activity_ID, LearnerID, action_type) VALUES
(5000, 1, 'Started Module'),
(5001, 2, 'Completed Quiz');


-- Survey Table Insertions
INSERT INTO Survey (Title) VALUES
('Course Feedback Survey'),
('Instructor Evaluation Survey'),
('Platform Usability Survey'),
('Learning Path Feedback Survey'),
('Skill Development Survey');

-- SurveyQuestions Table Insertions
INSERT INTO SurveyQuestions (SurveyID, Question) VALUES
(100000000, 'How satisfied are you with the course content?'),
(100000001, 'How would you rate the instructor''s teaching?'),
(100000002, 'Is the platform user-friendly?'),
(100000003, 'Is the learning path suitable for your needs?'),
(100000004, 'How useful was the skill development section?');

-- FilledSurvey Table Insertions
INSERT INTO FilledSurvey (SurveyID, Question, LearnerID, Answer) VALUES
(100000000, 'How satisfied are you with the course content?', 1, 'Very Satisfied'),
(100000001, 'How would you rate the instructor''s teaching?', 2, 'Excellent');

-- Notification Table Insertions
INSERT INTO Notification (timestamp, message, urgency_level) VALUES
(CURRENT_TIMESTAMP, 'Your assignment is due tomorrow', 'High'),
(CURRENT_TIMESTAMP, 'New course available: Data Structures', 'Medium'),
(CURRENT_TIMESTAMP, 'Complete your profile for better recommendations', 'Low'),
(CURRENT_TIMESTAMP, 'Feedback requested for your recent learning path', 'Medium'),
(CURRENT_TIMESTAMP, 'Course enrollment deadline approaching', 'High');

-- ReceivedNotification Table Insertions
INSERT INTO ReceivedNotification (NotificationID, LearnerID) VALUES
(65000, 1),
(65001, 2);

-- ReceivedNotification Table Insertions
INSERT INTO ReceivedNotification (NotificationID, LearnerID) VALUES
(65002, 2);



-- Badge Table Insertions
INSERT INTO Badge (title, description, criteria, points) VALUES
('Python Pro', 'Awarded for completing the Python course', 'Complete all modules', 50),
('Data Analyst', 'Awarded for excelling in Data Analysis', 'Score above 80%', 40),
('ML Beginner', 'Awarded for finishing ML Basics', 'Pass all assessments', 60),
('SQL Specialist', 'Awarded for mastering SQL queries', 'Complete SQL exercises', 30),
('Communication Expert', 'Awarded for completing Communication Skills', 'Participate in all activities', 20);

INSERT INTO Badge (title, description, criteria, points) VALUES
('Communication Expert', 'Awarded for completing Communication Skills', 'Participate in all activities', 20);


-- SkillProgression Table Insertions
INSERT INTO SkillProgression (proficiency_level, LearnerID, skill_name, timestamp) VALUES
('Beginner', 1, 'Python Programming', CURRENT_TIMESTAMP),
('Intermediate', 2, 'Data Analysis', CURRENT_TIMESTAMP);

-- Achievement Table Insertions
INSERT INTO Achievement (LearnerID, BadgeID, description, date_earned, type) VALUES
(1, 10, 'Completed all Python modules', '2024-01-15', 'Course Completion'),
(2, 11, 'Scored above 80% in Data Analysis', '2024-02-10', 'Exam Excellence');

-- Reward Table Insertions
INSERT INTO Reward (value, description, type) VALUES
(50.00, 'Gift Card for Bookstore', 'Gift Card'),
(30.00, 'Discount on Next Course', 'Discount'),
(100.00, 'Cash Prize for Top Scorer', 'Cash Prize'),
(20.00, 'Voucher for Online Tools', 'Voucher'),
(15.00, 'Free Course Enrollment', 'Free Enrollment');

INSERT INTO Reward (value, description, type) VALUES
(10.00,'The BEST','Title')
-- Quest Table Insertions

INSERT INTO Quest (difficulty_level, criteria, description, title) VALUES
('Easy', 'Complete Intro Modules', 'Finish all introductory modules', 'Intro Quest'),
('Intermediate', 'Score above 70%', 'Achieve a score above 70% in all quizzes', 'Quiz Master'),
('Advanced', 'Complete ML Project', 'Submit a completed machine learning project', 'ML Specialist'),
('Intermediate', 'Participate in Group Discussions', 'Take part in at least 3 discussions', 'Discussion Guru'),
('Easy', 'Watch all Videos', 'View all video lectures for the course', 'Video Viewer');

INSERT INTO Quest (difficulty_level, criteria, description, title) 
VALUES
('Advanced', 'Publish Research Paper', 'Write and publish a research paper on AI', 'AI Researcher'),
('Intermediate', 'Develop a Web App', 'Build a functioning web application using React', 'Web Developer Quest'),
('Easy', 'Pass All Assignments', 'Successfully complete all assignments with a passing grade', 'Assignment Achiever'),
('Intermediate', 'Collaborate on a Project', 'Work with peers on a group project and present the results', 'Team Collaborator'),
('Advanced', 'Solve Complex Problems', 'Solve 5 advanced coding problems in competitive programming', 'Coding Champion');

INSERT INTO Quest (difficulty_level, criteria, description, title) VALUES
('Easy','Complete DB Project','Finish Project','DB Specialist')

-- Skill_Mastery Table Insertions
INSERT INTO Skill_Mastery (QuestID, skill) VALUES
(17000, 'Python Programming'),
(17001, 'Data Analysis'),
(17002, 'Machine Learning'),
(17003, 'Public Speaking'),
(17004, 'SQL');

-- Collaborative Table Insertions
INSERT INTO Collaborative (QuestID, deadline, max_num_participants) VALUES
(17005, '2024-06-01', 10),
(17006, '2025-07-01', 5),
(17007, '2025-08-15', 8),
(17008, '2026-09-01', 6),
(17009, '2027-10-01', 12);



INSERT INTO LearnersCollaboration (LearnerID, QuestID, completion_status)
VALUES
(1, 17005, 'In Progress'),  
(2, 17006, 'Completed');

INSERT INTO LearnersCollaboration (LearnerID, QuestID, completion_status)
VALUES
(3, 17006, 'In Progress'),
(6, 17006, 'In Progress'),
(5, 17006, 'Completed');


INSERT INTO LearnersMastery (LearnerID, QuestID, skill, completion_status)
VALUES
(1, 17000, 'Python Programming', 'Completed'),     
(2, 17001, 'Data Analysis', 'In Progress');


-- Discussion_forum Table Insertions
INSERT INTO Discussion_forum (ModuleID, CourseID, title, last_active, description) VALUES
(1, 100, 'Variables Discussion', '2024-01-15', 'Discussion on variables and data types'),
(2, 100, 'Control Flow Talk', '2024-02-05', 'Talk about control flow statements'),
(3, 101, 'Linked Lists Forum', '2024-03-10', 'Understanding linked lists'),
(4, 102, 'SQL Queries Help', '2024-04-20', 'Help and questions on SQL queries'),
(5, 103, 'ML Basics Discussion', '2024-05-25', 'Discussion on machine learning basics');

-- LearnerDiscussion Table Insertions
INSERT INTO LearnerDiscussion (ForumID, LearnerID, Post, time) VALUES
(1446, 1, 'How do I declare a variable in Python?', '2024-01-12'),
(1447, 2, 'Can someone explain if-else statements?', '2024-02-02');
-- QuestReward Table Insertions
INSERT INTO QuestReward (RewardID, QuestID, LearnerID, Time_earned) VALUES
(6969, 17000, 1, '2024-06-01'),
(6970, 17001, 2, '2024-07-01');

INSERT INTO Teaches (InstructorID, CourseID)
VALUES (2, 100);





-------------------For Testing Purposes)DELETES ALL DATA FROM ALL TABLES -------------------
-- Disable foreign key constraints

--EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

-- Delete all data from all tables
--EXEC sp_MSforeachtable "DELETE FROM ?";

-- Re-enable foreign key constraints
--EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";

--drop trigger trg_Skill_Mastery_Disjoint
--drop trigger trg_Collaborative_Disjoint


----------------- For Testing Purposes SHOWS YOU ALL TABLES AT ONCE-------------------


/*

SELECT 'SELECT * FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '];' AS SelectStatement
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
SELECT * FROM [dbo].[Learner];
SELECT * FROM [dbo].[Skills];
SELECT * FROM [dbo].[LearningPreference];
SELECT * FROM [dbo].[PersonalizationProfiles];
SELECT * FROM [dbo].[HealthCondition];
SELECT * FROM [dbo].[Course];
SELECT * FROM [dbo].[CoursePrerequisite];
SELECT * FROM [dbo].[Modules];
SELECT * FROM [dbo].[Target_traits];
SELECT * FROM [dbo].[ModuleContent];
SELECT * FROM [dbo].[ContentLibrary];
SELECT * FROM [dbo].[Assessments];
SELECT * FROM [dbo].[Takenassessment];
SELECT * FROM [dbo].[Learning_activities];
SELECT * FROM [dbo].[Interaction_log];
SELECT * FROM [dbo].[Emotional_feedback];
SELECT * FROM [dbo].[Learning_path];
SELECT * FROM [dbo].[Instructor];
SELECT * FROM [dbo].[Pathreview];
SELECT * FROM [dbo].[Emotionalfeedback_review];
SELECT * FROM [dbo].[Course_enrollment];
SELECT * FROM [dbo].[Teaches];
SELECT * FROM [dbo].[Leaderboard];
SELECT * FROM [dbo].[Ranking];
SELECT * FROM [dbo].[Learning_goal];
SELECT * FROM [dbo].[LearnersGoals];
SELECT * FROM [dbo].[Survey];
SELECT * FROM [dbo].[SurveyQuestions];
SELECT * FROM [dbo].[FilledSurvey];
SELECT * FROM [dbo].[Notification];
SELECT * FROM [dbo].[ReceivedNotification];
SELECT * FROM [dbo].[Badge];
SELECT * FROM [dbo].[SkillProgression];
SELECT * FROM [dbo].[Achievement];
SELECT * FROM [dbo].[Reward];
SELECT * FROM [dbo].[Quest];
SELECT * FROM [dbo].[Skill_Mastery];
SELECT * FROM [dbo].[Collaborative];
SELECT * FROM [dbo].[LearnersCollaboration];
SELECT * FROM [dbo].[LearnersMastery];
SELECT * FROM [dbo].[Discussion_forum];
SELECT * FROM [dbo].[LearnerDiscussion];
SELECT * FROM [dbo].[QuestReward];


*/

