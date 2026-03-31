package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProgramYearRepository extends JpaRepository<ProgramYear, Long> {

    List<ProgramYear> findByStudyProgramIdOrderByYearNumberAsc(Long studyProgramId);

    Optional<ProgramYear> findByStudyProgramIdAndYearNumber(Long studyProgramId, int yearNumber);
}
