"""The eight queries shown on /queries. The SQL matches db/queries.sql.

Query 6 binds the student id with %s. db/queries.sql uses @student_id so the
same statement can be run in the mysql client without string concatenation.
"""

QUERIES = [
    {
        "key": "inner_join",
        "number": 1,
        "concept": "INNER JOIN",
        "title": "Students with their skills and levels",
        "needs_student": False,
        "sql": """
            SELECT
                s.student_id,
                s.name AS student_name,
                sk.skill_name,
                ss.level
            FROM students s
            INNER JOIN student_skills ss ON ss.student_id = s.student_id
            INNER JOIN skills sk ON sk.skill_id = ss.skill_id
            ORDER BY s.name, sk.skill_name
        """,
    },
    {
        "key": "left_join",
        "number": 2,
        "concept": "LEFT JOIN",
        "title": "Students with no goal set",
        "needs_student": False,
        "sql": """
            SELECT
                s.student_id,
                s.name AS student_name,
                s.email,
                s.branch,
                s.`year`
            FROM students s
            LEFT JOIN student_goals sg ON sg.student_id = s.student_id
            WHERE sg.goal_id IS NULL
            ORDER BY s.name
        """,
    },
    {
        "key": "group_by",
        "number": 3,
        "concept": "GROUP BY + HAVING",
        "title": "Roles with more than 5 required skills",
        "needs_student": False,
        "sql": """
            SELECT
                r.role_id,
                r.role_name,
                COUNT(rs.skill_id) AS required_skill_count
            FROM roles r
            INNER JOIN role_skills rs ON rs.role_id = r.role_id
            GROUP BY r.role_id, r.role_name
            HAVING COUNT(rs.skill_id) > 5
            ORDER BY required_skill_count DESC, r.role_name
        """,
    },
    {
        "key": "subquery",
        "number": 4,
        "concept": "Subquery",
        "title": "Students whose average skill level is above the overall average",
        "needs_student": False,
        "sql": """
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
            ORDER BY avg_level DESC, s.name
        """,
    },
    {
        "key": "aggregate",
        "number": 5,
        "concept": "Aggregate",
        "title": "Top 3 most-enrolled courses",
        "needs_student": False,
        "sql": """
            SELECT
                c.course_id,
                c.title,
                COUNT(e.student_id) AS enrollment_count
            FROM courses c
            INNER JOIN enrollments e ON e.course_id = c.course_id
            GROUP BY c.course_id, c.title
            ORDER BY enrollment_count DESC, c.title
            LIMIT 3
        """,
    },
    {
        "key": "skill_gap",
        "number": 6,
        "concept": "View v_skill_gap",
        "title": "Skill gap list for one student",
        "needs_student": True,
        "sql": """
            SELECT
                student_name,
                role_name,
                skill_name,
                required_level,
                student_level,
                gap,
                priority
            FROM v_skill_gap
            WHERE student_id = %s
            ORDER BY FIELD(priority, 'High', 'Medium', 'Low'), gap DESC, skill_name
        """,
    },
    {
        "key": "readiness",
        "number": 7,
        "concept": "View v_readiness",
        "title": "Readiness ranking of student goals",
        "needs_student": False,
        "sql": """
            SELECT
                student_id,
                student_name,
                role_name,
                readiness_pct
            FROM v_readiness
            ORDER BY readiness_pct DESC, student_name
        """,
    },
    {
        "key": "recommendation",
        "number": 8,
        "concept": "Course recommendation",
        "title": "For each gap skill, the cheapest matching course",
        "needs_student": False,
        "sql": """
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
            ORDER BY g.student_name, g.gap DESC, c.title
        """,
    },
]

QUERY_BY_KEY = {item["key"]: item for item in QUERIES}
