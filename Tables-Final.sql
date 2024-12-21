IF EXISTS (SELECT * FROM sys.databases WHERE name = 'EducationalPlatform')
BEGIN
    USE master
    DROP DATABASE EducationalPlatform
END;

-- Create the database
CREATE DATABASE EducationalPlatform;
GO

-- Switch to the new database
USE EducationalPlatform;
GO



-- =====================================================================================================
-- Entities & Relationships(TABLES), Ordered like Schema Model Answer, Numbered Like Project Description
-- =====================================================================================================


-- Milestone 2 Changes 

-- Parent User 

CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Learner', 'Instructor', 'Admin')),
    ProfileImage VARBINARY(MAX) DEFAULT NULL,
    CreationDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
)
---------------------------      ENTITY 1) Learner        -----------------------
CREATE TABLE Learner (
    LearnerID INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1) CHECK (gender IN ('M', 'F')) DEFAULT NULL,
    birth_date DATE CHECK (birth_date <= GETDATE()) DEFAULT NULL,
    country VARCHAR(50) DEFAULT NULL,
    cultural_background VARCHAR(100) DEFAULT NULL,
    FOREIGN KEY (LearnerID) REFERENCES Users(UserID) ON DELETE CASCADE
);

CREATE TABLE Skills ( -- Multivalued attribute skills
    LearnerID INT NOT NULL,
    skill VARCHAR(100) NOT NULL,
    PRIMARY KEY (LearnerID, skill),
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE LearningPreference ( -- Multivalued attribute learning preferences
    LearnerID INT NOT NULL,
    preference VARCHAR(100) NOT NULL,
    PRIMARY KEY (LearnerID, preference),
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);


-----------------      ENTITY 2) PersonalizationProfiles     --------------------
CREATE TABLE PersonalizationProfiles (
    LearnerID INT NOT NULL,
    ProfileID INT NOT NULL,
    Prefered_content_type VARCHAR(100) NULL,
    emotional_state VARCHAR(100) NULL,
    personality_type VARCHAR(100) NULL,
    PRIMARY KEY (LearnerID, ProfileID), --Weak entity , depends on Learner 
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID) -- Weak Relationship with Learner
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE HealthCondition ( -- Multivalued attribute health conditions
    LearnerID INT NOT NULL,
    ProfileID INT NOT NULL,
    condition VARCHAR(100) NOT NULL,
    PRIMARY KEY (LearnerID, ProfileID, condition),
    FOREIGN KEY (LearnerID, ProfileID) REFERENCES PersonalizationProfiles(LearnerID, ProfileID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 3) Course     -------------------------------------
CREATE TABLE Course (
    CourseID INT PRIMARY KEY IDENTITY(100,1) NOT NULL,
    Title VARCHAR(100) NOT NULL,
    learning_objective VARCHAR(255) NULL,
    credit_points INT NOT NULL DEFAULT 4,
    difficulty_level VARCHAR(50) NOT NULL DEFAULT 'Beginner',
    description VARCHAR(255) NULL
);


CREATE TABLE CoursePrerequisite( --Multivalued attribute prerequisites
    CourseID INT NOT NULL,
    Prereq VARCHAR(50) NOT NULL,
    PRIMARY KEY(CourseID,Prereq),
    Foreign Key(CourseID) REFERENCES  Course(CourseID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 4) Modules      -----------------------------------
CREATE TABLE Modules (
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    Title VARCHAR(100) NOT NULL,
    difficulty VARCHAR(50) NOT NULL,
    contentURL VARCHAR(255) NULL,
    PRIMARY KEY (ModuleID, CourseID), --Weak entity, depends on Course
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID) --Weak Relationship with Course
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT CK_Modules_Difficulty
    CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')) --make sure difficulty is one of the three
);



CREATE TABLE Target_traits ( --Multivalued attribute target traits
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    Trait VARCHAR(100) NOT NULL,
    PRIMARY KEY (ModuleID, CourseID, Trait),
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE ModuleContent ( --Multivalued attribute Module content
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    PRIMARY KEY (ModuleID, CourseID, content_type),
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 18) ContentLibrary     ----------------------------
CREATE TABLE ContentLibrary (
    ID INT PRIMARY KEY IDENTITY(3000,1) NOT NULL,
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    Title VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    metadata VARCHAR(255) NULL,
    type VARCHAR(50) NOT NULL,
    content_URL VARCHAR(255) NOT NULL,
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID) --Relationship with Modules
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 16) Assessments     -------------------------------
CREATE TABLE Assessments (
    ID INT PRIMARY KEY IDENTITY(4000,1) NOT NULL,
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    total_marks INT NOT NULL,
    passing_marks INT NOT NULL,
    criteria VARCHAR(255) NULL,
    weightage DECIMAL(5,2) CHECK (weightage >= 0 AND weightage <= 100),
    description VARCHAR(255) NULL,
    title VARCHAR(100) NOT NULL,
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID) --Relationship with Modules
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (passing_marks <= total_marks)
);


--*--
CREATE TABLE Takenassessment ( --Relationship between Learner and Assessments
    AssessmentID INT NOT NULL,
    LearnerID INT NOT NULL,
    ScoredPoint INT NOT NULL,  
    PRIMARY KEY (LearnerID, AssessmentID),   
    FOREIGN KEY (AssessmentID) REFERENCES Assessments(ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE

);

-----------------      ENTITY 5) Learning activities   --------------------------
CREATE TABLE Learning_activities (
    ActivityID INT PRIMARY KEY IDENTITY(5000,1) NOT NULL,
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    instruction_details VARCHAR(255) NULL,
    Max_points INT NOT NULL,
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID) --Relationship with Modules
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*--


-----------------      ENTITY 11) Interaction Log   -----------------------------
CREATE TABLE Interaction_log (
    LogID INT PRIMARY KEY IDENTITY(10000,1) NOT NULL,
    activity_ID INT NOT NULL,
    LearnerID INT NOT NULL,
    Duration AS DATEDIFF(SECOND, Timestamp, GETDATE()), 
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action_type VARCHAR(50) NULL,
    FOREIGN KEY (activity_ID) REFERENCES Learning_activities(ActivityID) --Relationship with Learning activities
         ON DELETE CASCADE
         ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID) --Relationship with Learner
         ON DELETE CASCADE
         ON UPDATE CASCADE
);


--*--

-----------------      ENTITY 12) Emotional Feedback   --------------------------
CREATE TABLE Emotional_feedback (
    FeedbackID INT PRIMARY KEY IDENTITY(20000,1) NOT NULL,
    LearnerID INT NOT NULL,
    activityID INT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    emotional_state VARCHAR(100) NOT NULL,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID) --Relationship with Learner
        ON DELETE CASCADE
        ON UPDATE CASCADE,
        
    FOREIGN KEY (activityID) REFERENCES Learning_activities(ActivityID) --Relationship with Learning activities
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 10) Learning Path   -------------------------------
CREATE TABLE Learning_path (
    pathID INT PRIMARY KEY IDENTITY(50000,1) NOT NULL,
    LearnerID INT NOT NULL,
    ProfileID INT NOT NULL,
    completion_status VARCHAR(50) NOT NULL DEFAULT 'not started',
    custom_content VARCHAR(255) NULL,
    adaptive_rules VARCHAR(255) NULL,
    FOREIGN KEY (LearnerID, ProfileID) REFERENCES PersonalizationProfiles(LearnerID, ProfileID) --Relationship with PersonalizationProfiles
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


--*--

-----------------      ENTITY 17) Instructor   ----------------------------------

CREATE TABLE Instructor (
    InstructorID INT PRIMARY KEY,
    name VARCHAR(100),
    latest_qualification VARCHAR(100),
    expertise_area VARCHAR(100),
    email VARCHAR(100),
    FOREIGN KEY (InstructorID) REFERENCES Users(UserID) ON DELETE CASCADE
);


CREATE TABLE Pathreview ( --Relationship between Instructor and Learning Path
    InstructorID INT NOT NULL,
    PathID INT NOT NULL,
    review VARCHAR(255) NULL,
    PRIMARY KEY (InstructorID, PathID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (PathID) REFERENCES Learning_path(pathID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE Emotionalfeedback_review ( --Relationship between Emotional Feedback and Instructor
    FeedbackID INT NOT NULL,
    InstructorID INT NOT NULL,
    review VARCHAR(255) NULL,
    PRIMARY KEY (FeedbackID, InstructorID),
    FOREIGN KEY (FeedbackID) REFERENCES Emotional_feedback(FeedbackID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);


--*--

-----------------      ENTITY 6) Course Enrollment   ----------------------------
CREATE TABLE Course_enrollment (
    EnrollmentID INT PRIMARY KEY IDENTITY(70000,1) NOT NULL,
    CourseID INT NOT NULL,
    LearnerID INT NOT NULL,
    completion_date DATE NULL,
    enrollment_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ongoing',
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID) --Relationship with Course
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID) --Relationship with Learner
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (completion_date IS NULL OR completion_date >= enrollment_date)
);
--*--

CREATE TABLE Teaches ( --Relationship between Instructor and Course
    InstructorID INT NOT NULL,
    CourseID INT NOT NULL,
    PRIMARY KEY (InstructorID, CourseID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 9)  Leaderboard   ---------------------------------
CREATE TABLE Leaderboard (
    BoardID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    season VARCHAR(50) NOT NULL
);


CREATE TABLE Ranking ( --Ternary relationship between Leaderboard, Learner and Course
    BoardID INT NOT NULL,
    LearnerID INT NOT NULL,
    CourseID INT NOT NULL,
    rank INT NULL CHECK (rank > 0),
    total_points INT NULL CHECK (total_points >= 0),
    PRIMARY KEY (BoardID, LearnerID),
    FOREIGN KEY (BoardID) REFERENCES Leaderboard(BoardID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--*****************************************************************************
-----------------      ENTITY 21)  Learning Goal   ------------------------------

CREATE TABLE Learning_goal (
    ID INT PRIMARY KEY IDENTITY(8000,1) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'not started',
    deadline DATE NULL,
    description VARCHAR(255) NULL
);

CREATE TABLE LearnersGoals ( --Relationship between Learner and Learning Goal
    GoalID INT NOT NULL,
    LearnerID INT NOT NULL,
    PRIMARY KEY (GoalID, LearnerID),
    FOREIGN KEY (GoalID) REFERENCES Learning_goal(ID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 22)  Survey   -------------------------------------

CREATE TABLE Survey (
    ID INT PRIMARY KEY IDENTITY(100000000,1) NOT NULL,
    Title VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE SurveyQuestions ( --Multivalued attribute questions
    SurveyID INT NOT NULL,
    Question VARCHAR(400) NOT NULL,
    PRIMARY KEY (SurveyID, Question),
    FOREIGN KEY (SurveyID) REFERENCES Survey(ID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE FilledSurvey ( --Relationship between Learner and Survey
    SurveyID INT NOT NULL,
    Question VARCHAR(400) NOT NULL,
    LearnerID INT NOT NULL,
    Answer VARCHAR(255) NOT NULL,
    PRIMARY KEY (SurveyID, Question, LearnerID),
    FOREIGN KEY (SurveyID, Question) REFERENCES SurveyQuestions(SurveyID, Question)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 19) Notification   --------------------------------

CREATE TABLE Notification (
    ID INT PRIMARY KEY IDENTITY(65000,1) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message VARCHAR(255) NOT NULL,
    urgency_level VARCHAR(50) NOT NULL,
    ReadStatus BIT DEFAULT 0
);

CREATE TABLE ReceivedNotification ( --Relationship between Learner and Notification
    NotificationID INT NOT NULL,
    LearnerID INT NOT NULL,

    PRIMARY KEY (NotificationID, LearnerID),
    FOREIGN KEY (NotificationID) REFERENCES Notification(ID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 8)  Badge       -----------------------------------

CREATE TABLE Badge (
    BadgeID INT PRIMARY KEY IDENTITY(10,1) NOT NULL,
    title VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    criteria VARCHAR(255) NULL,
    points INT NOT NULL CHECK (points > 0)
);

--*--

-----------------      ENTITY 15) Skill Progression   ---------------------------

CREATE TABLE SkillProgression (
    ID INT PRIMARY KEY IDENTITY(60,1) NOT NULL,
    proficiency_level VARCHAR(50) NULL,
    LearnerID INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (LearnerID, skill_name) REFERENCES Skills(LearnerID, skill) --Relationship with Skills which is a multivalued attribute in learner
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 7) Achievement   ----------------------------------

CREATE TABLE Achievement (
    AchievementID INT PRIMARY KEY IDENTITY(1010,1) NOT NULL,
    LearnerID INT NOT NULL,
    BadgeID INT NOT NULL,
    description VARCHAR(255) NULL,
    date_earned DATE NOT NULL,
    type VARCHAR(50) NOT NULL,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID) --Relationship with Learner
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (BadgeID) REFERENCES Badge(BadgeID) --Relationship with Badge
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 14)  Reward   -------------------------------------

CREATE TABLE Reward (
    RewardID INT PRIMARY KEY IDENTITY(6969,1) NOT NULL,
    value DECIMAL(10, 2) NOT NULL CHECK (value >= 0),
    description VARCHAR(255) NULL,
    type VARCHAR(50) NOT NULL
);

--*--

-----------------      ENTITY 13)  Quest   --------------------------------------

CREATE TABLE Quest (
    QuestID INT PRIMARY KEY IDENTITY(17000,1) NOT NULL,
    difficulty_level VARCHAR(50) NOT NULL DEFAULT 'Easy',
    criteria VARCHAR(50) NULL,
    description VARCHAR(255) NULL,
    title VARCHAR(100) NOT NULL
);

CREATE TABLE Skill_Mastery ( --Skill Mastery Quest
    QuestID INT NOT NULL,
    skill VARCHAR(100) NOT NULL,
    PRIMARY KEY (QuestID, skill),
    FOREIGN KEY (QuestID) REFERENCES Quest(QuestID) --Specialization of Quest(Sub Class of Quest/Inheritance from Quest)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE Collaborative ( --Collaborative Quest
    QuestID INT PRIMARY KEY NOT NULL,
    deadline DATE NULL,
    max_num_participants INT CHECK (max_num_participants > 0),
    FOREIGN KEY (QuestID) REFERENCES Quest(QuestID) --Specialization of Quest(Sub Class of Quest/Inheritance from Quest)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE LearnersCollaboration(--Relationship between Learner and Collaborative Quest
    LearnerID INT NOT NULL,
    QuestID INT NOT NULL,
    completion_status VARCHAR(50) ,
    
    PRIMARY KEY(LearnerID,QuestID),
    
    FOREIGN KEY (LearnerID) REFERENCES Learner (LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (QuestID) REFERENCES Collaborative (QuestID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE 


);
-- Added skill not in schema , because its foreign key in skill mastery  
CREATE TABLE LearnersMastery ( --Relationship between Learner and Skill Mastery Quest
    LearnerID INT NOT NULL,
    QuestID INT NOT NULL,
    skill VARCHAR(100) NOT NULL,
    completion_status VARCHAR(50),
    PRIMARY KEY (LearnerID, QuestID, skill),
    FOREIGN KEY (QuestID, skill) REFERENCES Skill_Mastery(QuestID, skill)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

-----------------      ENTITY 20)  Discussion Forum   ---------------------------

CREATE TABLE Discussion_forum (
    forumID INT PRIMARY KEY IDENTITY(1446,1) NOT NULL,
    ModuleID INT NOT NULL,
    CourseID INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    last_active DATETIME NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP NULL,
    description VARCHAR(255) NULL,
    FOREIGN KEY (ModuleID, CourseID) REFERENCES Modules(ModuleID, CourseID) --Relationship with Modules
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

CREATE TABLE LearnerDiscussion (--Relationship between Learner and Discussion Forum
    ForumID INT NOT NULL,
    LearnerID INT NOT NULL,
    Post VARCHAR(400) NOT NULL,
    time DATETIME NULL,
    PRIMARY KEY (ForumID, LearnerID, Post),
    FOREIGN KEY (ForumID) REFERENCES Discussion_forum(forumID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Users(UserID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

--*--

CREATE TABLE QuestReward ( -- Ternary relationship between Reward, Quest and Learner
    RewardID INT NOT NULL,
    QuestID INT NOT NULL,
    LearnerID INT NOT NULL,
    Time_earned DATETIME NULL,
    PRIMARY KEY (RewardID, QuestID, LearnerID),
    FOREIGN KEY (RewardID) REFERENCES Reward(RewardID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (QuestID) REFERENCES Quest(QuestID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (LearnerID) REFERENCES Learner(LearnerID)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

----- FOR TESTING PURPOSES) DELETE DATABASE ---------------
/* 

USE master;
GO

-- Set the database to single-user mode to close all active connections
ALTER DATABASE EducationalPlatform
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- Drop the database
DROP DATABASE EducationalPlatform;
GO

*/

/*-- Insert into Skills table
-- Insert into Skills
INSERT INTO Skills (LearnerID, skill) VALUES
(2, 'Python Programming'),
(2, 'Machine Learning'),
(2, 'Data Analysis');

-- Insert into LearningPreference
INSERT INTO LearningPreference (LearnerID, preference) VALUES
(2, 'Video Lectures'),
(2, 'Hands-on Projects');

-- Insert into PersonalizationProfiles
INSERT INTO PersonalizationProfiles (LearnerID, ProfileID, Prefered_content_type, emotional_state, personality_type)
VALUES (2, 1, 'Interactive', 'Focused', 'Introvert');

-- Insert into HealthCondition
INSERT INTO HealthCondition (LearnerID, ProfileID, condition)
VALUES (2, 1, 'None');

-- Insert into Course
INSERT INTO Course (Title, learning_objective, credit_points, difficulty_level, description)
VALUES
('Python Programming Basics', 'Learn Python fundamentals', 4, 'Beginner', 'A beginner-friendly course on Python.');

-- Insert into Modules
INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL)
VALUES
(1, 100, 'Introduction to Variables', 'Beginner', 'http://example.com/intro-to-variables'),
(2, 100, 'Control Flow Basics', 'Beginner', 'http://example.com/control-flow-basics');

-- Insert into Course_enrollment
INSERT INTO Course_enrollment (CourseID, LearnerID, completion_date, enrollment_date, status)
VALUES (100, 2, NULL, '2023-09-01', 'ongoing');

-- Insert into Learning_activities
INSERT INTO Learning_activities (ModuleID, CourseID, activity_type, instruction_details, Max_points)
VALUES
(1, 100, 'Lecture', 'Introduction to Variables', 10),
(2, 100, 'Exercise', 'Practice Control Flow', 15);

-- Insert into Interaction_log
INSERT INTO Interaction_log (activity_ID, LearnerID, action_type)
VALUES
(5000, 2, 'Started Module'),
(5001, 2, 'Completed Quiz');

-- Insert into Emotional_feedback
INSERT INTO Emotional_feedback (LearnerID, activityID, emotional_state)
VALUES
(2, 5000, 'Motivated'),
(2, 5001, 'Engaged');

-- Insert into Learning_path
INSERT INTO Learning_path (LearnerID, ProfileID, completion_status, custom_content, adaptive_rules)
VALUES (2, 1, 'in progress', 'Advanced Data Analysis', 'Adjust based on performance');

-- Insert into Learning_goal
INSERT INTO Learning_goal (status, deadline, description)
VALUES
('in progress', '2024-03-01', 'Complete Python Certification'),
('not started', '2024-05-15', 'Finish Data Structures Course');

-- Insert into LearnersGoals
INSERT INTO LearnersGoals (GoalID, LearnerID)
VALUES
(8000, 2),
(8001, 2);

-- Insert into Badge
INSERT INTO Badge (title, description, criteria, points)
VALUES
('Python Master', 'Awarded for completing Python course', 'Complete all modules', 50);

-- Insert into Achievement
INSERT INTO Achievement (LearnerID, BadgeID, description, date_earned, type)
VALUES
(2, 10, 'Completed Python Programming', '2024-02-01', 'Course Completion');

-- Insert into Survey
INSERT INTO Survey (Title)
VALUES
('Python Course Feedback'),
('Data Analysis Survey');

-- Insert into SurveyQuestions
INSERT INTO SurveyQuestions (SurveyID, Question)
VALUES
(100000000, 'How would you rate the course content?'),
(100000001, 'How would you rate the instructor?');

-- Insert into FilledSurvey
INSERT INTO FilledSurvey (SurveyID, Question, LearnerID, Answer)
VALUES
(100000000, 'How would you rate the course content?', 2, 'Very Satisfied'),
(100000001, 'How would you rate the instructor?', 2, 'Excellent');

-- Insert into Discussion_forum
INSERT INTO Discussion_forum (ModuleID, CourseID, title, last_active, description)
VALUES
(1, 100, 'Variables Discussion', '2024-01-15', 'Discussion on variables in Python'),
(2, 100, 'Control Flow Talk', '2024-02-05', 'Discussion on control flow concepts');

-- Insert into LearnerDiscussion
INSERT INTO LearnerDiscussion (ForumID, LearnerID, Post, time)
VALUES
(1446, 2, 'What are the best practices for declaring variables?', '2024-01-16');

-- Insert into Quest
INSERT INTO Quest (difficulty_level, criteria, description, title)
VALUES
('Intermediate', 'Score above 80%', 'Achieve a high score on assessments', 'Assessment Master');

-- Insert into Collaborative
INSERT INTO Collaborative (QuestID, deadline, max_num_participants)
VALUES
(17001, '2024-06-01', 5);

-- Insert into LearnersCollaboration
INSERT INTO LearnersCollaboration (LearnerID, QuestID, completion_status)
VALUES
(2, 17001, 'In Progress');

-- Insert into Reward
INSERT INTO Reward (value, description, type)
VALUES
(50.00, 'Gift Card', 'Gift');

-- Insert into QuestReward
INSERT INTO QuestReward (RewardID, QuestID, LearnerID, Time_earned)
VALUES
(6969, 17001, 2, '2024-06-10');





-- 1. First, let's create a course
INSERT INTO Course (Title, learning_objective, credit_points, difficulty_level, description)
VALUES ('Python Programming', 'Master Python fundamentals', 4, 'Beginner', 'Comprehensive Python course for beginners');

DECLARE @CourseID int = SCOPE_IDENTITY();

-- 2. Create a module for the course
INSERT INTO Modules (ModuleID, CourseID, Title, difficulty, contentURL)
VALUES 
(1, @CourseID, 'Python Basics', 'Beginner', 'http://example.com/python-basics');

-- 3. Create learning activities
INSERT INTO Learning_activities (ModuleID, CourseID, activity_type, instruction_details, Max_points)
VALUES 
(1, @CourseID, 'Lecture', 'Introduction to Python Variables', 10),
(1, @CourseID, 'Exercise', 'Python Practice Problems', 20);

-- 4. Create personalization profile for the learner
INSERT INTO PersonalizationProfiles (LearnerID, ProfileID, Prefered_content_type, emotional_state, personality_type)
VALUES (1005, 1, 'Interactive', 'Focused', 'Visual Learner');

-- 5. Enroll the learner in the course
INSERT INTO Course_enrollment (CourseID, LearnerID, enrollment_date, status)
VALUES (@CourseID, 1005, GETDATE(), 'ongoing');

-- 6. Add some initial emotional feedback
INSERT INTO Emotional_feedback (LearnerID, activityID, emotional_state, comments)
VALUES 
(1005, (SELECT TOP 1 ActivityID FROM Learning_activities WHERE activity_type = 'Lecture'), 'Happy', 'Really enjoying learning Python!'),
(1005, (SELECT TOP 1 ActivityID FROM Learning_activities WHERE activity_type = 'Lecture'), 'Neutral', 'The pace is good'),
(1005, (SELECT TOP 1 ActivityID FROM Learning_activities WHERE activity_type = 'Lecture'), 'Confused', 'Need help with functions'),
(1005, (SELECT TOP 1 ActivityID FROM Learning_activities WHERE activity_type = 'Exercise'), 'Frustrated', 'Loops are tricky');

-- Verification queries
-- Check course enrollment
SELECT * FROM Course_enrollment WHERE LearnerID = 1005;

-- Check available activities
SELECT 
    la.ActivityID,
    la.activity_type,
    la.instruction_details,
    c.Title as CourseTitle
FROM Learning_activities la
JOIN Modules m ON la.ModuleID = m.ModuleID AND la.CourseID = m.CourseID
JOIN Course c ON m.CourseID = c.CourseID
JOIN Course_enrollment ce ON c.CourseID = ce.CourseID
WHERE ce.LearnerID = 1005;

-- Check emotional feedback
SELECT 
    ef.emotional_state,
    ef.comments,
    la.activity_type,
    ef.timestamp
FROM Emotional_feedback ef
JOIN Learning_activities la ON ef.activityID = la.ActivityID
WHERE ef.LearnerID = 1005
ORDER BY ef.timestamp DESC;

-- Check personalization profile
SELECT * FROM PersonalizationProfiles WHERE LearnerID = 1005;

*/
