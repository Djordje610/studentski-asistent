CREATE TABLE study_programs (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE program_years (
    id BIGSERIAL PRIMARY KEY,
    study_program_id BIGINT NOT NULL REFERENCES study_programs(id) ON DELETE CASCADE,
    year_number INT NOT NULL,
    UNIQUE (study_program_id, year_number)
);

CREATE TABLE catalog_subjects (
    id BIGSERIAL PRIMARY KEY,
    program_year_id BIGINT NOT NULL REFERENCES program_years(id) ON DELETE CASCADE,
    code VARCHAR(64),
    name VARCHAR(255) NOT NULL,
    espb INT NOT NULL DEFAULT 6
);

CREATE INDEX idx_catalog_py ON catalog_subjects(program_year_id);

CREATE TABLE student_profiles (
    user_id BIGINT PRIMARY KEY,
    study_program_id BIGINT NOT NULL REFERENCES study_programs(id),
    program_year_id BIGINT NOT NULL REFERENCES program_years(id)
);

CREATE TABLE homework_assignments (
    id BIGSERIAL PRIMARY KEY,
    catalog_subject_id BIGINT NOT NULL REFERENCES catalog_subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_date_ms BIGINT
);

CREATE TABLE student_homework_status (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    homework_assignment_id BIGINT NOT NULL REFERENCES homework_assignments(id) ON DELETE CASCADE,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (user_id, homework_assignment_id)
);

CREATE TABLE exam_periods (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_ms BIGINT NOT NULL,
    end_ms BIGINT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE exam_period_offerings (
    id BIGSERIAL PRIMARY KEY,
    exam_period_id BIGINT NOT NULL REFERENCES exam_periods(id) ON DELETE CASCADE,
    catalog_subject_id BIGINT NOT NULL REFERENCES catalog_subjects(id) ON DELETE CASCADE,
    exam_ms BIGINT NOT NULL,
    location VARCHAR(255),
    UNIQUE (exam_period_id, catalog_subject_id)
);

CREATE TABLE student_exam_registrations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    exam_period_offering_id BIGINT NOT NULL REFERENCES exam_period_offerings(id) ON DELETE CASCADE,
    UNIQUE (user_id, exam_period_offering_id)
);
