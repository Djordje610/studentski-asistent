package com.studentski.asistent.repository;

import com.studentski.asistent.entity.Exam;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExamRepository extends JpaRepository<Exam, Long> {

    List<Exam> findByExamMsGreaterThanEqualOrderByExamMsAsc(long now);

    List<Exam> findAllByOrderByExamMsDesc();
}
