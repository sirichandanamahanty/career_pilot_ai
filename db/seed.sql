-- CareerPilot sample data. Re-running this file replaces the sample rows.
-- Enrollments are Started on purpose. A Completed enrollment would fire
-- trg_enrollment_after_insert and change the skill levels loaded below.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE roadmap_phases;
TRUNCATE TABLE roadmaps;
TRUNCATE TABLE mentor_sessions;
TRUNCATE TABLE enrollments;
TRUNCATE TABLE courses;
TRUNCATE TABLE student_goals;
TRUNCATE TABLE student_skills;
TRUNCATE TABLE role_skills;
TRUNCATE TABLE mentors;
TRUNCATE TABLE students;
TRUNCATE TABLE skills;
TRUNCATE TABLE roles;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO students (student_id, name, email, branch, `year`, hours_per_week) VALUES
    (1, 'Ananya Rao', 'ananya.rao@example.edu', 'CSE', 3, 12),
    (2, 'Rohan Mehta', 'rohan.mehta@example.edu', 'IT', 2, 8),
    (3, 'Priya Nair', 'priya.nair@example.edu', 'CSE', 4, 15),
    (4, 'Arjun Shah', 'arjun.shah@example.edu', 'AIML', 3, 10),
    (5, 'Sneha Iyer', 'sneha.iyer@example.edu', 'ECE', 1, 6),
    (6, 'Karthik Reddy', 'karthik.reddy@example.edu', 'CSE', 2, 9),
    (7, 'Meera Joshi', 'meera.joshi@example.edu', 'IT', 4, 14),
    (8, 'Vikram Das', 'vikram.das@example.edu', 'AIML', 1, 5),
    (9, 'Divya Kapoor', 'divya.kapoor@example.edu', 'CSE', 3, 11),
    (10, 'Aditya Menon', 'aditya.menon@example.edu', 'ECE', 2, 7);

INSERT INTO skills (skill_id, skill_name, category) VALUES
    (1, 'Python', 'Programming'),
    (2, 'Java', 'Programming'),
    (3, 'JavaScript', 'Programming'),
    (4, 'SQL', 'Data'),
    (5, 'Data Structures', 'Computer Science'),
    (6, 'Algorithms', 'Computer Science'),
    (7, 'HTML and CSS', 'Frontend'),
    (8, 'React', 'Frontend'),
    (9, 'Node.js', 'Backend'),
    (10, 'REST APIs', 'Backend'),
    (11, 'System Design', 'Architecture'),
    (12, 'Git', 'Tools'),
    (13, 'Statistics', 'Data'),
    (14, 'Excel', 'Data'),
    (15, 'Machine Learning', 'AI'),
    (16, 'Pandas', 'Data'),
    (17, 'Databases', 'Data'),
    (18, 'Object-Oriented Programming', 'Computer Science'),
    (19, 'Linux', 'Tools'),
    (20, 'Azure AI', 'Cloud');

INSERT INTO roles (role_id, role_name, description) VALUES
    (1, 'Software Engineer', 'Builds and maintains software using programming, data, and design skills.'),
    (2, 'Data Analyst', 'Uses queries, statistics, and spreadsheets to answer questions about data.'),
    (3, 'Frontend Developer', 'Builds the parts of a website that people see and use.'),
    (4, 'Backend Developer', 'Builds server-side logic, data access, and APIs.'),
    (5, 'ML Engineer', 'Builds machine learning features with Python, data, and models.');

INSERT INTO role_skills (role_id, skill_id, required_level, priority) VALUES
    -- Software Engineer: 8 skills
    (1, 5, 4, 'High'),
    (1, 6, 4, 'High'),
    (1, 18, 3, 'High'),
    (1, 11, 4, 'High'),
    (1, 4, 3, 'Medium'),
    (1, 2, 3, 'Medium'),
    (1, 10, 3, 'Medium'),
    (1, 12, 2, 'Low'),
    -- Data Analyst: 6 skills
    (2, 4, 4, 'High'),
    (2, 13, 4, 'High'),
    (2, 16, 4, 'High'),
    (2, 14, 3, 'Medium'),
    (2, 1, 3, 'Medium'),
    (2, 17, 3, 'Medium'),
    -- Frontend Developer: 5 skills (the HAVING query asks for more than 5)
    (3, 7, 4, 'High'),
    (3, 3, 4, 'High'),
    (3, 8, 3, 'High'),
    (3, 10, 2, 'Medium'),
    (3, 12, 2, 'Low'),
    -- Backend Developer: 7 skills
    (4, 2, 4, 'High'),
    (4, 4, 4, 'High'),
    (4, 10, 4, 'High'),
    (4, 17, 3, 'Medium'),
    (4, 11, 3, 'Medium'),
    (4, 18, 3, 'Medium'),
    (4, 12, 2, 'Low'),
    -- ML Engineer: 7 skills
    (5, 1, 4, 'High'),
    (5, 13, 4, 'High'),
    (5, 15, 4, 'High'),
    (5, 16, 3, 'Medium'),
    (5, 4, 3, 'Medium'),
    (5, 20, 3, 'Medium'),
    (5, 6, 3, 'Low');

INSERT INTO student_skills (student_id, skill_id, level) VALUES
    -- Ananya Rao, goal Software Engineer
    (1, 5, 2),
    (1, 6, 2),
    (1, 18, 3),
    (1, 4, 3),
    (1, 2, 2),
    (1, 12, 2),
    (1, 11, 1),
    -- Rohan Mehta, no goal
    (2, 3, 3),
    (2, 7, 2),
    (2, 12, 2),
    (2, 1, 1),
    -- Priya Nair, goal Data Analyst
    (3, 4, 4),
    (3, 13, 3),
    (3, 14, 3),
    (3, 1, 4),
    (3, 16, 2),
    (3, 17, 3),
    -- Arjun Shah, goal ML Engineer
    (4, 1, 4),
    (4, 13, 3),
    (4, 15, 2),
    (4, 16, 3),
    (4, 4, 2),
    (4, 6, 3),
    -- Sneha Iyer, no goal
    (5, 14, 2),
    (5, 4, 1),
    (5, 13, 1),
    -- Karthik Reddy, goal Backend Developer
    (6, 2, 3),
    (6, 4, 3),
    (6, 10, 2),
    (6, 17, 2),
    (6, 12, 2),
    (6, 11, 1),
    (6, 18, 3),
    -- Meera Joshi, goal Frontend Developer
    (7, 7, 4),
    (7, 3, 3),
    (7, 8, 2),
    (7, 12, 3),
    (7, 10, 2),
    -- Vikram Das, no goal
    (8, 1, 2),
    (8, 15, 1),
    (8, 13, 2),
    (8, 16, 1),
    -- Divya Kapoor, goal Software Engineer
    (9, 5, 4),
    (9, 6, 3),
    (9, 18, 4),
    (9, 4, 4),
    (9, 2, 3),
    (9, 10, 3),
    (9, 12, 3),
    (9, 11, 2),
    (9, 1, 2),
    -- Aditya Menon, goal Data Analyst
    (10, 4, 2),
    (10, 13, 1),
    (10, 14, 2),
    (10, 1, 2),
    (10, 17, 1);

INSERT INTO student_goals (goal_id, student_id, role_id, created_at) VALUES
    (1, 1, 1, '2026-02-02 09:00:00'),
    (2, 3, 2, '2026-02-03 09:00:00'),
    (3, 4, 5, '2026-02-04 09:00:00'),
    (4, 6, 4, '2026-02-05 09:00:00'),
    (5, 7, 3, '2026-02-06 09:00:00'),
    (6, 9, 1, '2026-02-07 09:00:00'),
    (7, 10, 2, '2026-02-08 09:00:00');

INSERT INTO courses (course_id, title, skill_id, provider, price, url) VALUES
    (1, 'Data Structures and Algorithms', 5, 'Microsoft Learn', 0.00,
        'https://learn.microsoft.com/en-us/search/?terms=data%20structures%20and%20algorithms'),
    (2, 'ASP.NET Core Web App', 10, 'Microsoft Learn', 0.00,
        'https://learn.microsoft.com/en-us/training/paths/aspnet-core-web-app/'),
    (3, 'Querying with Transact-SQL', 4, 'Microsoft Learn', 0.00,
        'https://learn.microsoft.com/en-us/training/paths/get-started-querying-with-transact-sql/'),
    (4, 'Beginner Python', 1, 'Microsoft Learn', 0.00,
        'https://learn.microsoft.com/en-us/training/paths/beginner-python/'),
    (5, 'Azure Well-Architected Framework', 11, 'Microsoft Learn', 49.00,
        'https://learn.microsoft.com/en-us/training/paths/azure-well-architected-framework/'),
    (6, 'AI Services Administrator', 20, 'Microsoft Learn', 99.00,
        'https://learn.microsoft.com/en-us/credentials/certifications/ai-services-administrator-associate/');

INSERT INTO enrollments (student_id, course_id, status, enrolled_on) VALUES
    (1, 1, 'Started', '2026-03-01'),
    (6, 1, 'Started', '2026-03-02'),
    (9, 1, 'Started', '2026-03-03'),
    (7, 2, 'Started', '2026-03-04'),
    (2, 2, 'Started', '2026-03-05'),
    (3, 3, 'Started', '2026-03-06'),
    (5, 3, 'Started', '2026-03-07'),
    (10, 3, 'Started', '2026-03-08'),
    (6, 3, 'Started', '2026-03-09'),
    (4, 4, 'Started', '2026-03-10'),
    (8, 4, 'Started', '2026-03-11'),
    (2, 4, 'Started', '2026-03-12'),
    (1, 5, 'Started', '2026-03-13'),
    (4, 6, 'Started', '2026-03-14');

INSERT INTO mentors (mentor_id, name, email) VALUES
    (1, 'Neha Kulkarni', 'neha.kulkarni@example.edu'),
    (2, 'Sameer Iqbal', 'sameer.iqbal@example.edu'),
    (3, 'Lata Krishnan', 'lata.krishnan@example.edu');

-- meet.google.com/new opens Google Meet to start a meeting.
INSERT INTO mentor_sessions (session_id, student_id, mentor_id, session_time, meet_link) VALUES
    (1, 1, 1, '2026-04-10 16:00:00', 'https://meet.google.com/new'),
    (2, 4, 2, '2026-04-12 11:00:00', 'https://meet.google.com/new'),
    (3, 7, 3, '2026-04-15 18:30:00', 'https://meet.google.com/new'),
    (4, 3, 1, '2026-04-18 10:00:00', 'https://meet.google.com/new');

-- Sample roadmap for Ananya Rao's Software Engineer goal.
CALL sp_generate_roadmap(1);

COMMIT;
