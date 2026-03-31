CREATE TABLE subjects (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    espb INT NOT NULL DEFAULT 6,
    final_grade DOUBLE PRECISION
);

CREATE INDEX idx_subjects_user ON subjects(user_id);

CREATE TABLE schedule_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    day_of_week INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    activity_type VARCHAR(64) NOT NULL,
    start_time VARCHAR(16) NOT NULL,
    end_time VARCHAR(16) NOT NULL,
    room VARCHAR(255),
    notes TEXT
);

CREATE INDEX idx_schedule_user_day ON schedule_entries(user_id, day_of_week);

CREATE TABLE colloquiums (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    max_points DOUBLE PRECISION NOT NULL,
    points DOUBLE PRECISION NOT NULL,
    date_ms BIGINT
);

CREATE INDEX idx_colloquiums_user ON colloquiums(user_id);

CREATE TABLE attendance (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    present INT NOT NULL,
    total INT NOT NULL,
    UNIQUE (user_id, subject_id)
);

CREATE TABLE homework (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    max_points DOUBLE PRECISION,
    points DOUBLE PRECISION,
    due_date_ms BIGINT,
    completed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_homework_user ON homework(user_id);

CREATE TABLE exams (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject_id BIGINT REFERENCES subjects(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    exam_ms BIGINT NOT NULL,
    location VARCHAR(255),
    notes TEXT
);

CREATE INDEX idx_exams_user ON exams(user_id);
