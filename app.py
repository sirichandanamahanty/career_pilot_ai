import os
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

import mysql.connector
from flask import Flask, abort, flash, redirect, render_template, request, url_for

from database import call_procedure, execute, fetch_all, fetch_one, run_select
from queries import QUERIES, QUERY_BY_KEY

app = Flask(__name__, template_folder=".")
app.secret_key = os.getenv("SECRET_KEY", "careerpilot-dev")


def friendly_db_error(exc):
    """Turn a MySQL error into a short message for the form."""
    message = getattr(exc, "msg", None) or str(exc)
    errno = getattr(exc, "errno", None)
    low = message.lower()

    if errno in (2002, 2003, 2005):
        return "Could not connect to MySQL. Start the server, then check DB_HOST in .env."
    if errno == 1045:
        return "MySQL rejected the username or password in .env."
    if errno == 1049:
        return "The database in DB_NAME does not exist yet. Create it and run db/schema.sql."
    if errno == 1062:
        if "student_skills" in low:
            return "This student already has that skill."
        if "enrollments" in low:
            return "This student is already enrolled in that course."
        if "uq_student_goals_role" in low:
            return "This student already has that career goal."
        if "email" in low or "idx_students_email" in low or "uq_mentors_email" in low:
            return "That email is already used. Choose a different one."
        if "skill_name" in low or "idx_skills_skill_name" in low:
            return "A skill with that name already exists."
        if "role_name" in low:
            return "That role name already exists."
        return "That record already exists."
    if errno in (3819, 4025) or "check constraint" in low:
        if "chk_students_year" in low:
            return "Year must be between 1 and 4."
        if "chk_students_hours" in low:
            return "Hours per week must be between 0 and 168."
        if "level" in low:
            return "Skill level must be between 1 and 5."
        if "chk_courses_price" in low:
            return "Price must be 0 or more and less than 100."
        return "A value failed a database check. Please correct the form."
    if errno == 1644 or "sqlstate '45000'" in low:
        if "skill level must be between 1 and 5" in low:
            return "Skill level must be between 1 and 5."
        if "goal does not exist" in low:
            return "That goal does not exist."
        if "enrollment status must be started or completed" in low:
            return "Enrollment status must be Started or Completed."
        return message.splitlines()[0][:240]
    if errno == 1452:
        return "That selection refers to a record that does not exist."
    if errno == 1451:
        return "This record cannot be deleted because other rows still reference it."
    if errno == 1265:
        return "One of the choices is not allowed."
    if errno == 1048:
        return "A required value was missing."
    if errno == 1406:
        return "One of the text fields is too long."
    if errno == 1366:
        return "One of the fields has a value of the wrong type."
    return "The database rejected this change. Please check the values and try again."


def parse_int(raw):
    try:
        return int(str(raw).strip())
    except (TypeError, ValueError):
        return None


def required_text(raw, label, errors, max_len):
    text = (raw or "").strip()
    if not text:
        errors.append(f"{label} is required.")
    elif len(text) > max_len:
        errors.append(f"{label} must be {max_len} characters or fewer.")
    return text


def student_from_form():
    errors = []
    name = required_text(request.form.get("name"), "Name", errors, 100)
    email = required_text(request.form.get("email"), "Email", errors, 255)
    branch = required_text(request.form.get("branch"), "Branch", errors, 80)
    year_raw = (request.form.get("year") or "").strip()
    hours_raw = (request.form.get("hours_per_week") or "").strip()
    year = parse_int(year_raw)
    hours = parse_int(hours_raw)
    if year is None:
        errors.append("Year must be a whole number.")
    if hours is None:
        errors.append("Hours per week must be a whole number.")
    if email and "@" not in email:
        errors.append("Email must contain @.")
    display = {
        "name": name,
        "email": email,
        "branch": branch,
        "year": year_raw,
        "hours_per_week": hours_raw,
    }
    parsed = {
        "name": name,
        "email": email,
        "branch": branch,
        "year": year,
        "hours_per_week": hours,
    }
    return display, parsed, errors


def skill_from_form():
    errors = []
    skill_name = required_text(request.form.get("skill_name"), "Skill name", errors, 80)
    category = required_text(request.form.get("category"), "Category", errors, 50)
    display = {"skill_name": skill_name, "category": category}
    return display, display.copy(), errors


def course_from_form():
    errors = []
    title = required_text(request.form.get("title"), "Title", errors, 150)
    provider = required_text(request.form.get("provider"), "Provider", errors, 80)
    url = required_text(request.form.get("url"), "URL", errors, 500)
    skill_raw = (request.form.get("skill_id") or "").strip()
    price_raw = (request.form.get("price") or "").strip()
    skill_id = parse_int(skill_raw)
    if skill_id is None:
        errors.append("Choose a skill.")
    try:
        price = Decimal(price_raw)
    except (InvalidOperation, ValueError):
        price = None
        errors.append("Price must be a number.")
    if url and not (url.startswith("http://") or url.startswith("https://")):
        errors.append("URL must start with http:// or https://.")
    display = {
        "title": title,
        "provider": provider,
        "url": url,
        "skill_id": skill_raw,
        "price": price_raw,
    }
    parsed = {
        "title": title,
        "provider": provider,
        "url": url,
        "skill_id": skill_id,
        "price": price,
    }
    return display, parsed, errors


@app.template_filter("inr")
def format_inr(value):
    if value is None:
        return "—"
    amount = Decimal(str(value))
    if amount == 0:
        return "Free"
    return f"Rs {amount:.2f}"


@app.template_filter("cell")
def format_cell(value):
    if value is None:
        return "—"
    if isinstance(value, Decimal):
        text = format(value, "f")
        if "." in text:
            text = text.rstrip("0").rstrip(".")
        return text
    if isinstance(value, datetime):
        return value.strftime("%d %b %Y, %H:%M")
    if isinstance(value, date):
        return value.strftime("%d %b %Y")
    return value


@app.template_filter("when")
def format_when(value):
    return format_cell(value)


@app.errorhandler(mysql.connector.Error)
def handle_database_error(exc):
    message = friendly_db_error(exc)
    if request.method == "POST":
        flash(message, "error")
        return redirect(url_for("index"))
    return render_template("error.html", message=message), 500


@app.errorhandler(404)
def page_not_found(_exc):
    return render_template("error.html", message="That page does not exist."), 404


@app.get("/")
def index():
    students = fetch_all(
        """
        SELECT
            s.student_id,
            s.name,
            s.branch,
            s.`year`,
            r.role_name,
            v.readiness_pct
        FROM students s
        LEFT JOIN student_goals g
            ON g.goal_id = (
                SELECT g2.goal_id
                FROM student_goals g2
                WHERE g2.student_id = s.student_id
                ORDER BY g2.created_at DESC, g2.goal_id DESC
                LIMIT 1
            )
        LEFT JOIN roles r ON r.role_id = g.role_id
        LEFT JOIN v_readiness v ON v.goal_id = g.goal_id
        ORDER BY s.name
        """
    )
    counts = fetch_one(
        """
        SELECT
            (SELECT COUNT(*) FROM students) AS students,
            (SELECT COUNT(*) FROM skills) AS skills,
            (SELECT COUNT(*) FROM roles) AS roles,
            (SELECT COUNT(*) FROM courses) AS courses
        """
    )
    return render_template("index.html", students=students, counts=counts)


@app.get("/open-student")
def open_student():
    student_id = request.args.get("student_id", type=int)
    if not student_id:
        flash("Choose a student.", "error")
        return redirect(url_for("index"))
    return redirect(url_for("student_profile", student_id=student_id))


def load_student(student_id):
    student = fetch_one(
        """
        SELECT student_id, name, email, branch, `year`, hours_per_week
        FROM students
        WHERE student_id = %s
        """,
        (student_id,),
    )
    if not student:
        abort(404)
    return student


@app.get("/student/<int:student_id>")
def student_profile(student_id):
    student = load_student(student_id)
    skills = fetch_all(
        """
        SELECT sk.skill_id, sk.skill_name, sk.category, ss.level
        FROM student_skills ss
        INNER JOIN skills sk ON sk.skill_id = ss.skill_id
        WHERE ss.student_id = %s
        ORDER BY sk.category, sk.skill_name
        """,
        (student_id,),
    )
    owned = {row["skill_id"] for row in skills}
    available_skills = [
        row
        for row in fetch_all(
            "SELECT skill_id, skill_name, category FROM skills ORDER BY skill_name"
        )
        if row["skill_id"] not in owned
    ]
    roles = fetch_all("SELECT role_id, role_name FROM roles ORDER BY role_name")
    goals = fetch_all(
        """
        SELECT
            g.goal_id,
            g.created_at,
            r.role_name,
            r.description,
            v.readiness_pct
        FROM student_goals g
        INNER JOIN roles r ON r.role_id = g.role_id
        LEFT JOIN v_readiness v ON v.goal_id = g.goal_id
        WHERE g.student_id = %s
        ORDER BY g.created_at, g.goal_id
        """,
        (student_id,),
    )
    for goal in goals:
        goal["gaps"] = fetch_all(
            """
            SELECT skill_name, required_level, student_level, gap, priority, skill_id
            FROM v_skill_gap
            WHERE goal_id = %s
            ORDER BY FIELD(priority, 'High', 'Medium', 'Low'), gap DESC, skill_name
            """,
            (goal["goal_id"],),
        )
        goal["roadmap"] = fetch_one(
            """
            SELECT roadmap_id, generated_on
            FROM roadmaps
            WHERE goal_id = %s
            ORDER BY generated_on DESC, roadmap_id DESC
            LIMIT 1
            """,
            (goal["goal_id"],),
        )
        goal["phases"] = []
        if goal["roadmap"]:
            goal["phases"] = fetch_all(
                """
                SELECT phase_order, phase_name, weeks, milestone
                FROM roadmap_phases
                WHERE roadmap_id = %s
                ORDER BY phase_order
                """,
                (goal["roadmap"]["roadmap_id"],),
            )
        goal["courses"] = fetch_all(
            """
            SELECT
                g.skill_name,
                g.gap,
                g.priority,
                c.course_id,
                c.title,
                c.provider,
                c.price,
                c.url
            FROM v_skill_gap g
            INNER JOIN courses c ON c.skill_id = g.skill_id
            WHERE g.goal_id = %s
              AND c.price = (
                  SELECT MIN(c2.price) FROM courses c2 WHERE c2.skill_id = g.skill_id
              )
            ORDER BY FIELD(g.priority, 'High', 'Medium', 'Low'), g.gap DESC, c.title
            """,
            (goal["goal_id"],),
        )
    enrollments = fetch_all(
        """
        SELECT e.status, e.enrolled_on, c.course_id, c.title
        FROM enrollments e
        INNER JOIN courses c ON c.course_id = e.course_id
        WHERE e.student_id = %s
        ORDER BY c.title
        """,
        (student_id,),
    )
    enrolled = {row["course_id"]: row["status"] for row in enrollments}
    return render_template(
        "student.html",
        student=student,
        skills=skills,
        available_skills=available_skills,
        roles=roles,
        goals=goals,
        enrollments=enrollments,
        enrolled=enrolled,
    )


@app.post("/student/<int:student_id>/goal")
def set_goal(student_id):
    load_student(student_id)
    role_id = parse_int(request.form.get("role_id"))
    if role_id is None:
        flash("Choose a role.", "error")
        return redirect(url_for("student_profile", student_id=student_id))
    try:
        execute(
            "INSERT INTO student_goals (student_id, role_id) VALUES (%s, %s)",
            (student_id, role_id),
        )
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Career goal saved.", "ok")
    return redirect(url_for("student_profile", student_id=student_id))


@app.post("/student/<int:student_id>/skills")
def add_skill(student_id):
    load_student(student_id)
    skill_id = parse_int(request.form.get("skill_id"))
    level_raw = (request.form.get("level") or "").strip()
    level = parse_int(level_raw)
    if skill_id is None or level is None:
        flash("Choose a skill and enter a whole-number level.", "error")
        return redirect(url_for("student_profile", student_id=student_id))
    try:
        execute(
            "INSERT INTO student_skills (student_id, skill_id, level) VALUES (%s, %s, %s)",
            (student_id, skill_id, level),
        )
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Skill saved.", "ok")
    return redirect(url_for("student_profile", student_id=student_id))


@app.post("/student/<int:student_id>/skills/<int:skill_id>/delete")
def remove_skill(student_id, skill_id):
    load_student(student_id)
    execute(
        "DELETE FROM student_skills WHERE student_id = %s AND skill_id = %s",
        (student_id, skill_id),
    )
    flash("Skill removed.", "ok")
    return redirect(url_for("student_profile", student_id=student_id))


@app.post("/student/<int:student_id>/roadmap")
def generate_roadmap(student_id):
    load_student(student_id)
    goal_id = parse_int(request.form.get("goal_id"))
    goal = fetch_one(
        "SELECT goal_id FROM student_goals WHERE goal_id = %s AND student_id = %s",
        (goal_id, student_id),
    )
    if not goal:
        flash("That goal does not belong to this student.", "error")
        return redirect(url_for("student_profile", student_id=student_id))
    try:
        call_procedure("CALL sp_generate_roadmap(%s)", (goal_id,))
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Roadmap generated from the current skill gaps.", "ok")
    return redirect(url_for("student_profile", student_id=student_id))


@app.post("/student/<int:student_id>/enroll")
def enroll(student_id):
    load_student(student_id)
    course_id = parse_int(request.form.get("course_id"))
    status = (request.form.get("status") or "").strip()
    if course_id is None:
        flash("Choose a course.", "error")
        return redirect(url_for("student_profile", student_id=student_id))
    try:
        call_procedure(
            "CALL sp_enroll_student(%s, %s, %s)",
            (student_id, course_id, status),
        )
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        if status == "Completed":
            flash(
                "Enrolled as Completed. The database trigger raised that skill by 1, up to level 5.",
                "ok",
            )
        else:
            flash("Enrolled as Started. The skill level was not changed.", "ok")
    return redirect(url_for("student_profile", student_id=student_id))


@app.get("/students")
def students_list():
    students = fetch_all(
        """
        SELECT student_id, name, email, branch, `year`, hours_per_week
        FROM students
        ORDER BY name
        """
    )
    return render_template("students.html", students=students)


@app.get("/students/new")
def student_new():
    return render_template("student_form.html", student=None, errors=[])


@app.post("/students/new")
def student_create():
    display, parsed, errors = student_from_form()
    if errors:
        return render_template("student_form.html", student=display, errors=errors), 400
    try:
        execute(
            """
            INSERT INTO students (name, email, branch, `year`, hours_per_week)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                parsed["name"],
                parsed["email"],
                parsed["branch"],
                parsed["year"],
                parsed["hours_per_week"],
            ),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "student_form.html",
            student=display,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Student added.", "ok")
    return redirect(url_for("students_list"))


@app.get("/students/<int:student_id>/edit")
def student_edit(student_id):
    student = load_student(student_id)
    return render_template("student_form.html", student=student, errors=[])


@app.post("/students/<int:student_id>/edit")
def student_update(student_id):
    load_student(student_id)
    display, parsed, errors = student_from_form()
    display["student_id"] = student_id
    if errors:
        return render_template("student_form.html", student=display, errors=errors), 400
    try:
        execute(
            """
            UPDATE students
            SET name = %s, email = %s, branch = %s, `year` = %s, hours_per_week = %s
            WHERE student_id = %s
            """,
            (
                parsed["name"],
                parsed["email"],
                parsed["branch"],
                parsed["year"],
                parsed["hours_per_week"],
                student_id,
            ),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "student_form.html",
            student=display,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Student updated.", "ok")
    return redirect(url_for("students_list"))


@app.post("/students/<int:student_id>/delete")
def student_delete(student_id):
    try:
        execute("DELETE FROM students WHERE student_id = %s", (student_id,))
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Student deleted.", "ok")
    return redirect(url_for("students_list"))


@app.get("/skills")
def skills_list():
    skills = fetch_all(
        "SELECT skill_id, skill_name, category FROM skills ORDER BY category, skill_name"
    )
    return render_template("skills.html", skills=skills)


@app.get("/skills/new")
def skill_new():
    return render_template("skill_form.html", skill=None, errors=[])


@app.post("/skills/new")
def skill_create():
    display, parsed, errors = skill_from_form()
    if errors:
        return render_template("skill_form.html", skill=display, errors=errors), 400
    try:
        execute(
            "INSERT INTO skills (skill_name, category) VALUES (%s, %s)",
            (parsed["skill_name"], parsed["category"]),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "skill_form.html",
            skill=display,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Skill added.", "ok")
    return redirect(url_for("skills_list"))


@app.get("/skills/<int:skill_id>/edit")
def skill_edit(skill_id):
    skill = fetch_one(
        "SELECT skill_id, skill_name, category FROM skills WHERE skill_id = %s",
        (skill_id,),
    )
    if not skill:
        abort(404)
    return render_template("skill_form.html", skill=skill, errors=[])


@app.post("/skills/<int:skill_id>/edit")
def skill_update(skill_id):
    current = fetch_one("SELECT skill_id FROM skills WHERE skill_id = %s", (skill_id,))
    if not current:
        abort(404)
    display, parsed, errors = skill_from_form()
    display["skill_id"] = skill_id
    if errors:
        return render_template("skill_form.html", skill=display, errors=errors), 400
    try:
        execute(
            "UPDATE skills SET skill_name = %s, category = %s WHERE skill_id = %s",
            (parsed["skill_name"], parsed["category"], skill_id),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "skill_form.html",
            skill=display,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Skill updated.", "ok")
    return redirect(url_for("skills_list"))


@app.post("/skills/<int:skill_id>/delete")
def skill_delete(skill_id):
    try:
        execute("DELETE FROM skills WHERE skill_id = %s", (skill_id,))
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Skill deleted.", "ok")
    return redirect(url_for("skills_list"))


@app.get("/courses")
def courses_list():
    courses = fetch_all(
        """
        SELECT c.course_id, c.title, c.provider, c.price, c.url, sk.skill_name
        FROM courses c
        INNER JOIN skills sk ON sk.skill_id = c.skill_id
        ORDER BY c.title
        """
    )
    return render_template("courses.html", courses=courses)


@app.get("/courses/new")
def course_new():
    skills = fetch_all("SELECT skill_id, skill_name FROM skills ORDER BY skill_name")
    return render_template("course_form.html", course=None, skills=skills, errors=[])


@app.post("/courses/new")
def course_create():
    skills = fetch_all("SELECT skill_id, skill_name FROM skills ORDER BY skill_name")
    display, parsed, errors = course_from_form()
    if errors:
        return render_template(
            "course_form.html", course=display, skills=skills, errors=errors
        ), 400
    try:
        execute(
            """
            INSERT INTO courses (title, skill_id, provider, price, url)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                parsed["title"],
                parsed["skill_id"],
                parsed["provider"],
                parsed["price"],
                parsed["url"],
            ),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "course_form.html",
            course=display,
            skills=skills,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Course added.", "ok")
    return redirect(url_for("courses_list"))


@app.get("/courses/<int:course_id>/edit")
def course_edit(course_id):
    course = fetch_one(
        """
        SELECT course_id, title, skill_id, provider, price, url
        FROM courses
        WHERE course_id = %s
        """,
        (course_id,),
    )
    if not course:
        abort(404)
    skills = fetch_all("SELECT skill_id, skill_name FROM skills ORDER BY skill_name")
    return render_template("course_form.html", course=course, skills=skills, errors=[])


@app.post("/courses/<int:course_id>/edit")
def course_update(course_id):
    current = fetch_one("SELECT course_id FROM courses WHERE course_id = %s", (course_id,))
    if not current:
        abort(404)
    skills = fetch_all("SELECT skill_id, skill_name FROM skills ORDER BY skill_name")
    display, parsed, errors = course_from_form()
    display["course_id"] = course_id
    if errors:
        return render_template(
            "course_form.html", course=display, skills=skills, errors=errors
        ), 400
    try:
        execute(
            """
            UPDATE courses
            SET title = %s, skill_id = %s, provider = %s, price = %s, url = %s
            WHERE course_id = %s
            """,
            (
                parsed["title"],
                parsed["skill_id"],
                parsed["provider"],
                parsed["price"],
                parsed["url"],
                course_id,
            ),
        )
    except mysql.connector.Error as exc:
        return render_template(
            "course_form.html",
            course=display,
            skills=skills,
            errors=[friendly_db_error(exc)],
        ), 400
    flash("Course updated.", "ok")
    return redirect(url_for("courses_list"))


@app.post("/courses/<int:course_id>/delete")
def course_delete(course_id):
    try:
        execute("DELETE FROM courses WHERE course_id = %s", (course_id,))
    except mysql.connector.Error as exc:
        flash(friendly_db_error(exc), "error")
    else:
        flash("Course deleted.", "ok")
    return redirect(url_for("courses_list"))


@app.get("/queries")
def queries_page():
    students = fetch_all(
        "SELECT student_id, name FROM students ORDER BY name"
    )
    selected_key = request.args.get("q")
    selected_student = request.args.get("student_id", type=int)
    result = None
    active = QUERY_BY_KEY.get(selected_key)
    if active:
        if active["needs_student"] and not selected_student:
            flash("Choose a student for the skill-gap query.", "error")
        else:
            params = (selected_student,) if active["needs_student"] else ()
            columns, rows = run_select(active["sql"], params)
            result = {
                "query": active,
                "columns": columns,
                "rows": rows,
                "student_id": selected_student,
            }
    return render_template(
        "queries.html",
        queries=QUERIES,
        students=students,
        result=result,
        selected_student=selected_student,
    )


@app.get("/mentors")
def mentors_page():
    rows = fetch_all(
        """
        SELECT
            m.mentor_id,
            m.name,
            m.email,
            ms.session_id,
            ms.session_time,
            ms.meet_link,
            s.name AS student_name
        FROM mentors m
        LEFT JOIN mentor_sessions ms ON ms.mentor_id = m.mentor_id
        LEFT JOIN students s ON s.student_id = ms.student_id
        ORDER BY m.name, ms.session_time
        """
    )
    mentors = []
    index = {}
    for row in rows:
        mentor = index.get(row["mentor_id"])
        if mentor is None:
            mentor = {
                "mentor_id": row["mentor_id"],
                "name": row["name"],
                "email": row["email"],
                "sessions": [],
            }
            index[row["mentor_id"]] = mentor
            mentors.append(mentor)
        if row["session_id"] is not None:
            mentor["sessions"].append(row)
    return render_template("mentors.html", mentors=mentors)

@app.get("/demo")
def demo():
    return render_template("demo.html")
    
if __name__ == "__main__":
    app.run(debug=True)
