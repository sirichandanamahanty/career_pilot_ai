# CareerPilot

CareerPilot is a Flask and MySQL career-guidance mini project. It records student skills and career goals, calculates skill gaps and role readiness with SQL views, generates roadmaps with a stored procedure, and updates skill levels through an enrollment trigger.

## Requirements

- MySQL 8.0 or later
- Python 3.10 or later
- A terminal with the MySQL client available, or MySQL Workbench

## Setup on Windows

1. Create the database in MySQL:

   ```sql
   CREATE DATABASE careerpilot CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. From the project directory, apply the schema and sample data. In Command Prompt, run:

   ```bat
   mysql -u root -p careerpilot < db\schema.sql
   mysql -u root -p careerpilot < db\seed.sql
   ```

   The schema script drops and recreates the project tables, views, procedures, and triggers. The seed script truncates and replaces the sample rows. Do not run these scripts against a database containing data you need to keep.

3. Create and activate a virtual environment, then install dependencies:

   ```powershell
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   ```

4. Copy `.env.example` to `.env` and set the MySQL connection values:

   ```dotenv
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=careerpilot
   SECRET_KEY=replace-with-a-random-local-secret
   ```

   Keep `.env` private; it contains local credentials.

5. Start the development server:

   ```powershell
   python app.py
   ```

   Open `http://127.0.0.1:5000`.

## Application pages

- `/` provides the dashboard and student picker.
- `/student/<id>` shows a student's skills, goals, readiness, gaps, roadmap, course recommendations, and enrollments.
- `/students`, `/skills`, and `/courses` provide create, edit, and delete workflows.
- `/queries` runs the eight labeled SQL examples in `db/queries.sql`.
- `/mentors` lists mentors and their saved Google Meet session links.

All request values passed to SQL use connector parameters. The query page uses a fixed SQL catalog; the student ID for its skill-gap query is bound as a parameter.

## Database behavior

- `v_skill_gap` compares required and recorded levels, treating a missing student skill as level 0 and omitting zero gaps.
- `v_readiness` calculates a percentage per goal, counting no more than each role's required skill level.
- `sp_generate_roadmap(goal_id)` creates ordered phases from the current gaps, with high-priority gaps first.
- A completed course enrollment raises the course's skill by one level, up to 5. The before-insert skill trigger rejects levels outside 1-5; table checks also protect stored values.
- `sp_enroll_student` inserts an enrollment and commits it with the trigger's skill update, rolling back if the operation fails.
- `db/transaction_example.sql` demonstrates the trigger update inside a transaction and then rolls it back so the seeded data remains unchanged.

## Viva Q&A

**What is a primary key?** A primary key uniquely identifies each row and cannot be null. CareerPilot uses single-column keys for entities and composite keys for student-skill, role-skill, and student-course associations.

**What is a foreign key?** A foreign key enforces a valid reference to another table. Delete rules are chosen by relationship: student-owned details cascade, while shared catalog rows referenced by existing data are generally restricted.

**Why use a composite key in `student_skills`?** A student can have many skills and each skill can belong to many students. `(student_id, skill_id)` identifies one rating per pair and prevents duplicate ratings for the same pair.

**What does an INNER JOIN do?** It returns rows with matching records on both sides. Query 1 joins students, their skill ratings, and the skill catalog.

**What does a LEFT JOIN do?** It preserves every row from its left input and fills unmatched right-side columns with NULL. Query 2 uses this pattern to find students without goals.

**What is normalization?** It organizes facts to reduce duplication and update anomalies. The tables use atomic values, composite relationships where needed, and keep each entity's attributes with that entity; details are in `docs/normalization.md`.

**Why use views for gaps and readiness?** Both are derived from role requirements and current skill ratings. Views calculate current values without storing duplicate, potentially stale percentages or gap values.

**What does the enrollment trigger do?** After an enrollment marked `Completed`, it finds the course skill and raises the student's level by one, capped at 5; if no rating exists, it inserts level 1.

**What is a transaction?** A transaction groups changes so they commit together or can be rolled back on failure. The enrollment procedure groups the enrollment and trigger-driven skill update.

**Why add indexes?** Indexes speed up lookups and joins on frequently searched keys. Primary keys and unique keys create indexes, and the schema adds indexes for foreign keys not already covered by a leading primary-key column.

**How does the app avoid SQL injection?** SQL statements are fixed, and request values are supplied separately using MySQL Connector/Python parameter placeholders.