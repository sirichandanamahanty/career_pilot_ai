-- CareerPilot schema (MySQL 8, InnoDB, 3NF)
-- Apply with the database already selected:
--   mysql -u root -p careerpilot < db/schema.sql

SET NAMES utf8mb4;

DROP VIEW IF EXISTS v_readiness;
DROP VIEW IF EXISTS v_skill_gap;

DROP PROCEDURE IF EXISTS sp_generate_roadmap;
DROP PROCEDURE IF EXISTS sp_enroll_student;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS roadmap_phases;
DROP TABLE IF EXISTS roadmaps;
DROP TABLE IF EXISTS mentor_sessions;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS student_goals;
DROP TABLE IF EXISTS student_skills;
DROP TABLE IF EXISTS role_skills;
DROP TABLE IF EXISTS mentors;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS roles;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE students (
    student_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    branch VARCHAR(80) NOT NULL,
    `year` TINYINT NOT NULL,
    hours_per_week INT NOT NULL,
    PRIMARY KEY (student_id),
    UNIQUE KEY idx_students_email (email),
    CONSTRAINT chk_students_year CHECK (`year` BETWEEN 1 AND 4),
    CONSTRAINT chk_students_hours CHECK (hours_per_week >= 0 AND hours_per_week <= 168)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE skills (
    skill_id INT NOT NULL AUTO_INCREMENT,
    skill_name VARCHAR(80) NOT NULL,
    category VARCHAR(50) NOT NULL,
    PRIMARY KEY (skill_id),
    -- Index on skill_name, required for lookups by name.
    UNIQUE KEY idx_skills_skill_name (skill_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE roles (
    role_id INT NOT NULL AUTO_INCREMENT,
    role_name VARCHAR(80) NOT NULL,
    description VARCHAR(255) NOT NULL,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_roles_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- M:N students and skills. level depends on both ids, so it lives here (2NF).
CREATE TABLE student_skills (
    student_id INT NOT NULL,
    skill_id INT NOT NULL,
    level TINYINT NOT NULL,
    PRIMARY KEY (student_id, skill_id),
    -- student_id is indexed by the primary key. skill_id needs its own index.
    INDEX idx_student_skills_skill (skill_id),
    CONSTRAINT chk_student_skills_level CHECK (level BETWEEN 1 AND 5),
    CONSTRAINT fk_student_skills_student FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_student_skills_skill FOREIGN KEY (skill_id)
        REFERENCES skills (skill_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- M:N roles and skills.
CREATE TABLE role_skills (
    role_id INT NOT NULL,
    skill_id INT NOT NULL,
    required_level TINYINT NOT NULL,
    priority ENUM('High', 'Medium', 'Low') NOT NULL,
    PRIMARY KEY (role_id, skill_id),
    INDEX idx_role_skills_skill (skill_id),
    CONSTRAINT chk_role_skills_level CHECK (required_level BETWEEN 1 AND 5),
    CONSTRAINT fk_role_skills_role FOREIGN KEY (role_id)
        REFERENCES roles (role_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_role_skills_skill FOREIGN KEY (skill_id)
        REFERENCES skills (skill_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE student_goals (
    goal_id INT NOT NULL AUTO_INCREMENT,
    student_id INT NOT NULL,
    role_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (goal_id),
    UNIQUE KEY uq_student_goals_role (student_id, role_id),
    INDEX idx_student_goals_student (student_id),
    INDEX idx_student_goals_role (role_id),
    CONSTRAINT fk_student_goals_student FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_student_goals_role FOREIGN KEY (role_id)
        REFERENCES roles (role_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE roadmaps (
    roadmap_id INT NOT NULL AUTO_INCREMENT,
    goal_id INT NOT NULL,
    generated_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (roadmap_id),
    INDEX idx_roadmaps_goal (goal_id),
    CONSTRAINT fk_roadmaps_goal FOREIGN KEY (goal_id)
        REFERENCES student_goals (goal_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE roadmap_phases (
    phase_id INT NOT NULL AUTO_INCREMENT,
    roadmap_id INT NOT NULL,
    phase_order INT NOT NULL,
    phase_name VARCHAR(80) NOT NULL,
    weeks INT NOT NULL,
    milestone VARCHAR(255) NOT NULL,
    PRIMARY KEY (phase_id),
    UNIQUE KEY uq_roadmap_phase_order (roadmap_id, phase_order),
    INDEX idx_roadmap_phases_roadmap (roadmap_id),
    CONSTRAINT chk_roadmap_phases_order CHECK (phase_order >= 1),
    CONSTRAINT chk_roadmap_phases_weeks CHECK (weeks >= 1),
    CONSTRAINT fk_roadmap_phases_roadmap FOREIGN KEY (roadmap_id)
        REFERENCES roadmaps (roadmap_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE courses (
    course_id INT NOT NULL AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    skill_id INT NOT NULL,
    provider VARCHAR(80) NOT NULL,
    price DECIMAL(6, 2) NOT NULL,
    url VARCHAR(500) NOT NULL,
    PRIMARY KEY (course_id),
    INDEX idx_courses_skill (skill_id),
    CONSTRAINT chk_courses_price CHECK (price >= 0 AND price < 100),
    CONSTRAINT fk_courses_skill FOREIGN KEY (skill_id)
        REFERENCES skills (skill_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollments (
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    status ENUM('Started', 'Completed') NOT NULL,
    enrolled_on DATE NOT NULL,
    PRIMARY KEY (student_id, course_id),
    INDEX idx_enrollments_course (course_id),
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id)
        REFERENCES courses (course_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mentors (
    mentor_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    PRIMARY KEY (mentor_id),
    UNIQUE KEY uq_mentors_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mentor_sessions (
    session_id INT NOT NULL AUTO_INCREMENT,
    student_id INT NOT NULL,
    mentor_id INT NOT NULL,
    session_time DATETIME NOT NULL,
    meet_link VARCHAR(255) NOT NULL,
    PRIMARY KEY (session_id),
    INDEX idx_mentor_sessions_student (student_id),
    INDEX idx_mentor_sessions_mentor (mentor_id),
    CONSTRAINT fk_mentor_sessions_student FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_mentor_sessions_mentor FOREIGN KEY (mentor_id)
        REFERENCES mentors (mentor_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gap = required level minus the student's level. A missing skill counts as 0.
-- Rows with no gap are excluded, so the view is only unfinished work.
CREATE VIEW v_skill_gap AS
SELECT
    sg.goal_id,
    sg.student_id,
    s.name AS student_name,
    sg.role_id,
    r.role_name,
    rs.skill_id,
    sk.skill_name,
    rs.required_level,
    COALESCE(ss.level, 0) AS student_level,
    rs.required_level - COALESCE(ss.level, 0) AS gap,
    rs.priority
FROM student_goals sg
INNER JOIN students s ON s.student_id = sg.student_id
INNER JOIN roles r ON r.role_id = sg.role_id
INNER JOIN role_skills rs ON rs.role_id = sg.role_id
INNER JOIN skills sk ON sk.skill_id = rs.skill_id
LEFT JOIN student_skills ss
    ON ss.student_id = sg.student_id
   AND ss.skill_id = rs.skill_id
WHERE rs.required_level - COALESCE(ss.level, 0) > 0;

-- Readiness is earned credit over required credit.
-- LEAST stops a level above the requirement from raising the percentage.
-- A missing skill contributes 0. The result is a percentage per goal.
CREATE VIEW v_readiness AS
SELECT
    sg.goal_id,
    sg.student_id,
    s.name AS student_name,
    sg.role_id,
    r.role_name,
    ROUND(
        100 * SUM(LEAST(COALESCE(ss.level, 0), rs.required_level))
        / NULLIF(SUM(rs.required_level), 0),
        2
    ) AS readiness_pct
FROM student_goals sg
INNER JOIN students s ON s.student_id = sg.student_id
INNER JOIN roles r ON r.role_id = sg.role_id
INNER JOIN role_skills rs ON rs.role_id = sg.role_id
LEFT JOIN student_skills ss
    ON ss.student_id = sg.student_id
   AND ss.skill_id = rs.skill_id
GROUP BY sg.goal_id, sg.student_id, s.name, sg.role_id, r.role_name;

DELIMITER $$

-- Builds one roadmap for a goal. Phases follow v_skill_gap:
-- High, then Medium, then Low, and a larger gap comes first inside a priority.
CREATE PROCEDURE sp_generate_roadmap(IN p_goal_id INT)
BEGIN
    DECLARE v_roadmap_id INT;
    DECLARE v_phase_count INT DEFAULT 0;

    IF p_goal_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM student_goals WHERE goal_id = p_goal_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Goal does not exist';
    END IF;

    INSERT INTO roadmaps (goal_id, generated_on)
    VALUES (p_goal_id, NOW());

    SET v_roadmap_id = LAST_INSERT_ID();
    SET @roadmap_id = v_roadmap_id;

    INSERT INTO roadmap_phases (roadmap_id, phase_order, phase_name, weeks, milestone)
    SELECT
        @roadmap_id,
        ROW_NUMBER() OVER (
            ORDER BY FIELD(priority, 'High', 'Medium', 'Low'), gap DESC, skill_name
        ),
        skill_name,
        gap,
        CONCAT('Raise ', skill_name, ' from ', student_level, ' to ', required_level)
    FROM v_skill_gap
    WHERE goal_id = p_goal_id;

    SET v_phase_count = ROW_COUNT();

    IF v_phase_count = 0 THEN
        INSERT INTO roadmap_phases (roadmap_id, phase_order, phase_name, weeks, milestone)
        VALUES (
            v_roadmap_id,
            1,
            'Apply your skills',
            1,
            'Required levels are already met for this role'
        );
    END IF;
END$$

-- Enrolls a student and, when status is Completed, the enrollment trigger
-- updates the matching skill in the same transaction. Any error rolls both back.
CREATE PROCEDURE sp_enroll_student(
    IN p_student_id INT,
    IN p_course_id INT,
    IN p_status VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_status NOT IN ('Started', 'Completed') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enrollment status must be Started or Completed';
    END IF;

    START TRANSACTION;

    INSERT INTO enrollments (student_id, course_id, status, enrolled_on)
    VALUES (p_student_id, p_course_id, p_status, CURDATE());

    COMMIT;
END$$

-- Custom message when a new skill rating is outside 1-5.
-- CHECK chk_student_skills_level also rejects bad values, including on UPDATE.
CREATE TRIGGER trg_student_skills_before_insert
BEFORE INSERT ON student_skills
FOR EACH ROW
BEGIN
    IF NEW.level < 1 OR NEW.level > 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Skill level must be between 1 and 5';
    END IF;
END$$

-- A completed enrollment raises the course skill by one level, capped at 5.
-- If the student has no row for that skill yet, the trigger inserts level 1.
CREATE TRIGGER trg_enrollment_after_insert
AFTER INSERT ON enrollments
FOR EACH ROW
BEGIN
    DECLARE v_skill_id INT;

    IF NEW.status = 'Completed' THEN
        SELECT skill_id
        INTO v_skill_id
        FROM courses
        WHERE course_id = NEW.course_id;

        IF EXISTS (
            SELECT 1
            FROM student_skills
            WHERE student_id = NEW.student_id
              AND skill_id = v_skill_id
        ) THEN
            UPDATE student_skills
            SET level = LEAST(level + 1, 5)
            WHERE student_id = NEW.student_id
              AND skill_id = v_skill_id;
        ELSE
            INSERT INTO student_skills (student_id, skill_id, level)
            VALUES (NEW.student_id, v_skill_id, 1);
        END IF;
    END IF;
END$$

DELIMITER ;
