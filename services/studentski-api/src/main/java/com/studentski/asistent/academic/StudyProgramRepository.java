package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudyProgramRepository extends JpaRepository<StudyProgram, Long> {

    Optional<StudyProgram> findByCodeIgnoreCase(String code);
}
