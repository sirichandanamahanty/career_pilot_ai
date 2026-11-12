-- Transaction example: enroll a student and let the completion trigger
-- update the skill level in the same transaction.
--
-- This script is safe to run against the seed data. It rolls back, so the
-- enrollment is not kept and the skill level returns to its previous value.
--
-- Divya Kapoor (student 9) is not enrolled in course 5.
-- Her System Design level (skill 11) in the seed data is 2.
-- Status Completed makes trg_enrollment_after_insert add 1 to that level.

START TRANSACTION;

SELECT student_id, skill_id, level
FROM student_skills
WHERE student_id = 9 AND skill_id = 11;

INSERT INTO enrollments (student_id, course_id, status, enrolled_on)
VALUES (9, 5, 'Completed', CURDATE());

-- Expected level after the trigger, still uncommitted: 3.
SELECT student_id, skill_id, level
FROM student_skills
WHERE student_id = 9 AND skill_id = 11;

ROLLBACK;

-- Expected level after rollback: 2. The enrollment row is gone as well.
SELECT student_id, skill_id, level
FROM student_skills
WHERE student_id = 9 AND skill_id = 11;

-- The application uses sp_enroll_student, which wraps the same two changes
-- (the enrollment insert and the trigger's skill update) like this:
--
--   START TRANSACTION;
--   INSERT INTO enrollments ...;
--   COMMIT;
--
-- The procedure has an EXIT HANDLER that issues ROLLBACK, then RESIGNAL,
-- when any statement in the transaction fails. Example of the error path
-- (this call fails because student 1 is already enrolled in course 1):
--
--   CALL sp_enroll_student(1, 1, 'Started');
--
-- After that error, the enrollment count is unchanged.
