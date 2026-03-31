package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeworkAssignmentRepository extends JpaRepository<HomeworkAssignment, Long> {

    List<HomeworkAssignment> findByCatalogSubject_IdIn(List<Long> catalogSubjectIds);

    List<HomeworkAssignment> findByCatalogSubject_IdOrderByIdDesc(Long catalogSubjectId);
}
