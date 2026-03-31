package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentHomeworkStatusRepository extends JpaRepository<StudentHomeworkStatus, Long> {

    List<StudentHomeworkStatus> findByUserId(Long userId);

    Optional<StudentHomeworkStatus> findByUserIdAndHomeworkAssignmentId(Long userId, Long homeworkAssignmentId);
}
