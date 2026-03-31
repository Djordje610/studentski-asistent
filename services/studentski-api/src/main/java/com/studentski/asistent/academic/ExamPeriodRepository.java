package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ExamPeriodRepository extends JpaRepository<ExamPeriod, Long> {

    Optional<ExamPeriod> findByActiveIsTrue();
    Optional<ExamPeriod> findTopByOrderByStartMsDesc();

    List<ExamPeriod> findAllByOrderByStartMsDesc();
}
