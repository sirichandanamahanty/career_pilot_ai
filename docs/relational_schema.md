# CareerPilot relational schema

`PK` means primary key, `FK` means foreign key, and `UK` means unique key. All tables use InnoDB. The exact column types, checks, indexes, and constraint names are defined in `db/schema.sql`.

| Relation | Columns | Keys and constraints |
| --- | --- | --- |
| `students` | `student_id`, `name`, `email`, `branch`, `year`, `hours_per_week` | PK `student_id`; UK `email`; `year` 1-4; hours 0-168 |
| `skills` | `skill_id`, `skill_name`, `category` | PK `skill_id`; UK/index `skill_name` |
| `roles` | `role_id`, `role_name`, `description` | PK `role_id`; UK `role_name` |
| `student_skills` | `student_id`, `skill_id`, `level` | PK (`student_id`, `skill_id`); FK `student_id` -> `students.student_id` ON DELETE CASCADE; FK `skill_id` -> `skills.skill_id` ON DELETE CASCADE; level 1-5 |
| `role_skills` | `role_id`, `skill_id`, `required_level`, `priority` | PK (`role_id`, `skill_id`); FK `role_id` -> `roles.role_id` ON DELETE CASCADE; FK `skill_id` -> `skills.skill_id` ON DELETE RESTRICT; required level 1-5; priority High/Medium/Low |
| `student_goals` | `goal_id`, `student_id`, `role_id`, `created_at` | PK `goal_id`; UK (`student_id`, `role_id`); FK `student_id` -> `students.student_id` ON DELETE CASCADE; FK `role_id` -> `roles.role_id` ON DELETE RESTRICT |
| `roadmaps` | `roadmap_id`, `goal_id`, `generated_on` | PK `roadmap_id`; FK `goal_id` -> `student_goals.goal_id` ON DELETE CASCADE |
| `roadmap_phases` | `phase_id`, `roadmap_id`, `phase_order`, `phase_name`, `weeks`, `milestone` | PK `phase_id`; UK (`roadmap_id`, `phase_order`); FK `roadmap_id` -> `roadmaps.roadmap_id` ON DELETE CASCADE; order and weeks >= 1 |
| `courses` | `course_id`, `title`, `skill_id`, `provider`, `price`, `url` | PK `course_id`; FK `skill_id` -> `skills.skill_id` ON DELETE RESTRICT; price >= 0 and < 100 |
| `enrollments` | `student_id`, `course_id`, `status`, `enrolled_on` | PK (`student_id`, `course_id`); FK `student_id` -> `students.student_id` ON DELETE CASCADE; FK `course_id` -> `courses.course_id` ON DELETE RESTRICT; status Started/Completed |
| `mentors` | `mentor_id`, `name`, `email` | PK `mentor_id`; UK `email` |
| `mentor_sessions` | `session_id`, `student_id`, `mentor_id`, `session_time`, `meet_link` | PK `session_id`; FK `student_id` -> `students.student_id` ON DELETE CASCADE; FK `mentor_id` -> `mentors.mentor_id` ON DELETE RESTRICT |

All foreign keys use ON UPDATE CASCADE. MySQL automatically creates or uses indexes to support foreign keys; explicit secondary indexes are also declared in the schema where useful.

## Views

- `v_skill_gap`: one row per unmet role-skill requirement for each student goal. `student_level` uses `COALESCE(level, 0)`, and `gap` is `required_level - student_level`.
- `v_readiness`: one row per student goal. It divides the sum of `LEAST(student level, required level)` by the sum of required levels and multiplies by 100. Missing levels count as 0.