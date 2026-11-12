-- CareerPilot queries. Each block is labelled with the concept it demonstrates.
-- The Flask page at /queries runs the same statements.
-- Query 6 uses @student_id so this file can be run in the mysql client.
-- The app binds that value as a parameter instead of concatenating it.

-- 1. INNER JOIN: students with their skills and levels
SELECT
    s.student_id,
    s.name AS student_name,
    sk.skill_name,
    ss.level
FROM students s
INNER JOIN student_skills ss ON ss.student_id = s.student_id
INNER JOIN skills sk ON sk.skill_id = ss.skill_id
ORDER BY s.name, sk.skill_name;

-- 2. LEFT JOIN: students with no goal set
SELECT
    s.student_id,
    s.name AS student_name,
    s.email,
    s.branch,
    s.`year`
FROM students s
LEFT JOIN student_goals sg ON sg.student_id = s.student_id
WHERE sg.goal_id IS NULL
ORDER BY s.name;

-- 3. GROUP BY + HAVING: roles with more than 5 required skills
SELECT
    r.role_id,
    r.role_name,
    COUNT(rs.skill_id) AS required_skill_count
FROM roles r
INNER JOIN role_skills rs ON rs.role_id = r.role_id
GROUP BY r.role_id, r.role_name
HAVING COUNT(rs.skill_id) > 5
ORDER BY required_skill_count DESC, r.role_name;

-- 4. Subquery: students whose average skill level is above the overall average
SELECT
    s.student_id,
    s.name AS student_name,
    ROUND(AVG(ss.level), 2) AS avg_level
FROM students s
INNER JOIN student_skills ss ON ss.student_id = s.student_id
GROUP BY s.student_id, s.name
HAVING AVG(ss.level) > (
    SELECT AVG(level) FROM student_skills
)
ORDER BY avg_level DESC, s.name;

-- 5. Aggregate: top 3 most-enrolled courses
SELECT
    c.course_id,
    c.title,
    COUNT(e.student_id) AS enrollment_count
FROM courses c
INNER JOIN enrollments e ON e.course_id = c.course_id
GROUP BY c.course_id, c.title
ORDER BY enrollment_count DESC, c.title
LIMIT 3;

-- 6. Skill gap list for one student (from v_skill_gap)
SET @student_id = 1;

SELECT
    student_name,
    role_name,
    skill_name,
    required_level,
    student_level,
    gap,
    priority
FROM v_skill_gap
WHERE student_id = @student_id
ORDER BY FIELD(priority, 'High', 'Medium', 'Low'), gap DESC, skill_name;

-- 7. Readiness ranking of all students (from v_readiness)
-- A student with no goal has no row here, because readiness is calculated per goal.
SELECT
    student_id,
    student_name,
    role_name,
    readiness_pct
FROM v_readiness
ORDER BY readiness_pct DESC, student_name;

-- 8. Course recommendation: for each gap skill, the cheapest matching course
SELECT
    g.student_name,
    g.role_name,
    g.skill_name,
    g.gap,
    c.title AS course_title,
    c.provider,
    c.price,
    c.url
FROM v_skill_gap g
INNER JOIN courses c ON c.skill_id = g.skill_id
INNER JOIN (
    SELECT skill_id, MIN(price) AS min_price
    FROM courses
    GROUP BY skill_id
) cheapest
    ON cheapest.skill_id = c.skill_id
   AND cheapest.min_price = c.price
ORDER BY g.student_name, g.gap DESC, c.title;
