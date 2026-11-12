# CareerPilot entity-relationship diagram

Cardinality uses crow's foot notation. `||` is exactly one. `o{` is zero or many.

```mermaid
erDiagram
    students ||--o{ student_skills : "records"
    skills ||--o{ student_skills : "is rated in"
    roles ||--o{ role_skills : "requires"
    skills ||--o{ role_skills : "is required by"
    students ||--o{ student_goals : "sets"
    roles ||--o{ student_goals : "is the target of"
    student_goals ||--o{ roadmaps : "produces"
    roadmaps ||--o{ roadmap_phases : "contains"
    skills ||--o{ courses : "is taught by"
    students ||--o{ enrollments : "enrolls in"
    courses ||--o{ enrollments : "has"
    students ||--o{ mentor_sessions : "attends"
    mentors ||--o{ mentor_sessions : "hosts"

    students {
        int student_id PK
        varchar name
        varchar email UK
        varchar branch
        tinyint year
        int hours_per_week
    }
    skills {
        int skill_id PK
        varchar skill_name UK
        varchar category
    }
    roles {
        int role_id PK
        varchar role_name UK
        varchar description
    }
    student_skills {
        int student_id PK_FK
        int skill_id PK_FK
        tinyint level
    }
    role_skills {
        int role_id PK_FK
        int skill_id PK_FK
        tinyint required_level
        enum priority
    }
    student_goals {
        int goal_id PK
        int student_id FK
        int role_id FK
        datetime created_at
    }
    roadmaps {
        int roadmap_id PK
        int goal_id FK
        datetime generated_on
    }
    roadmap_phases {
        int phase_id PK
        int roadmap_id FK
        int phase_order
        varchar phase_name
        int weeks
        varchar milestone
    }
    courses {
        int course_id PK
        varchar title
        int skill_id FK
        varchar provider
        decimal price
        varchar url
    }
    enrollments {
        int student_id PK_FK
        int course_id PK_FK
        enum status
        date enrolled_on
    }
    mentors {
        int mentor_id PK
        varchar name
        varchar email UK
    }
    mentor_sessions {
        int session_id PK
        int student_id FK
        int mentor_id FK
        datetime session_time
        varchar meet_link
    }
```

`student_skills`, `role_skills`, and `enrollments` are the associative tables for the three many-to-many relationships: student–skill, role–skill, and student–course.
