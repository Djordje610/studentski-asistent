CREATE TABLE IF NOT EXISTS student_subject_results (
    user_id BIGINT NOT NULL,
    catalog_subject_id BIGINT NOT NULL REFERENCES catalog_subjects(id) ON DELETE CASCADE,
    passed BOOLEAN NOT NULL DEFAULT FALSE,
    grade INT,
    passed_in_period VARCHAR(255),
    PRIMARY KEY (user_id, catalog_subject_id)
);

CREATE INDEX IF NOT EXISTS idx_student_subject_results_user
    ON student_subject_results(user_id);
