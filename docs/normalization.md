# Normalization

CareerPilot is designed through third normal form. Readiness and skill gaps are calculated in views, so those results are not stored as columns.

## Definitions

**First normal form (1NF).** Every column holds one value, and every row can be identified. There are no repeating groups such as a list of skills inside one student column.

**Second normal form (2NF).** The table is in 1NF, and every non-key column depends on the whole primary key. This rule matters for composite keys. A column that depends on only one part of the key does not belong in that table.

**Third normal form (3NF).** The table is in 2NF, and no non-key column depends on another non-key column. A fact is stored once, with the entity it describes.

## students

Columns: `student_id`, `name`, `email`, `branch`, `year`, `hours_per_week`.

- **1NF.** Each column is a single value. `student_id` identifies the row. Skills are not stored here as a comma-separated list.
- **2NF.** The primary key is one column, so a non-key column cannot depend on only part of the key.
- **3NF.** Name, email, branch, year, and hours each describe the student. Branch does not determine year or hours, and email is an alternate key for the same student, not a path to a separate entity's attributes.

## skills

Columns: `skill_id`, `skill_name`, `category`.

- **1NF.** One skill name and one category per row.
- **2NF.** The primary key is `skill_id` alone.
- **3NF.** Category describes the skill. It is not copied onto students, roles, or courses.

## roles

Columns: `role_id`, `role_name`, `description`.

- **1NF.** One role name and one description per row.
- **2NF.** The primary key is a single column.
- **3NF.** The description depends on the role. Required skills are not stored in this table; they are in `role_skills`, because one role has many skills.

## student_skills

Columns: `student_id`, `skill_id`, `level`. Primary key: `(student_id, skill_id)`.

- **1NF.** One level per student-skill pair. Adding another skill adds another row.
- **2NF.** `level` depends on both parts of the key. A student's level in Python is not a fact about the student alone, and it is not a fact about Python alone.
- **3NF.** The only non-key column is `level`. It does not determine another stored column. The student's name and the skill's category stay in their own tables.

## role_skills

Columns: `role_id`, `skill_id`, `required_level`, `priority`. Primary key: `(role_id, skill_id)`.

- **1NF.** One required level and one priority per role-skill pair.
- **2NF.** Both non-key columns depend on the pair. The level required for SQL is different for a data analyst and a frontend developer, so it does not belong on `skills` or on `roles` alone.
- **3NF.** `priority` does not determine `required_level`, and neither column stores the role name or the skill name.

## student_goals

Columns: `goal_id`, `student_id`, `role_id`, `created_at`.

- **1NF.** One role per goal row. A second target role is a second row.
- **2NF.** The primary key is `goal_id`.
- **3NF.** `created_at` describes the goal. The role name is not copied here; `role_id` points at `roles`. Readiness is not stored on the goal, because it is derived from skill levels and would have to be rewritten whenever a level changes.

## roadmaps

Columns: `roadmap_id`, `goal_id`, `generated_on`.

- **1NF.** One timestamp per roadmap row.
- **2NF.** The primary key is a single column.
- **3NF.** `generated_on` depends on the roadmap. The student and the role are reached through `goal_id`, so they are not repeated.

## roadmap_phases

Columns: `phase_id`, `roadmap_id`, `phase_order`, `phase_name`, `weeks`, `milestone`.

- **1NF.** Each phase is its own row, with one name, one week count, and one milestone.
- **2NF.** The primary key is `phase_id`. `phase_order` is unique within a roadmap, but the stored key is `phase_id`, and every other column describes that phase.
- **3NF.** The milestone describes the phase. It does not store the student's email or the role description. Weeks is the size of the gap for that phase, saved when the roadmap is generated so the plan stays as it was on that date.

## courses

Columns: `course_id`, `title`, `skill_id`, `provider`, `price`, `url`.

- **1NF.** One title, provider, price, and URL per course.
- **2NF.** The primary key is `course_id`.
- **3NF.** Provider and price describe the course, not the skill. Two courses can teach the same skill at different prices, so those columns do not belong on `skills`. The skill name is not copied here.

## enrollments

Columns: `student_id`, `course_id`, `status`, `enrolled_on`. Primary key: `(student_id, course_id)`.

- **1NF.** One status and one enrollment date per student-course pair.
- **2NF.** Status and date depend on both the student and the course. A student does not have one enrollment status for every course, and a course does not have one status for every student.
- **3NF.** `enrolled_on` does not determine `status`. The course price and the student name are not stored on the enrollment.

## mentors

Columns: `mentor_id`, `name`, `email`.

- **1NF.** One name and one email per mentor.
- **2NF.** The primary key is a single column.
- **3NF.** Both non-key columns describe the mentor. Session times are not stored here, because one mentor has many sessions.

## mentor_sessions

Columns: `session_id`, `student_id`, `mentor_id`, `session_time`, `meet_link`.

- **1NF.** One time and one link per session.
- **2NF.** The primary key is `session_id`.
- **3NF.** Time and link describe the session. The mentor's email is not copied into the session row. The link does not determine the mentor's name.

## Why the views are outside the tables

`v_skill_gap` and `v_readiness` are queries, not base tables. A gap changes as soon as `student_skills.level` changes. Storing the gap or the percentage on `student_goals` would duplicate data that is already determined by `role_skills` and `student_skills`, and those stored numbers would go stale. Calculating them in views keeps the base tables in 3NF.
