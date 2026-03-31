package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface StudentSubjectResultRepository extends JpaRepository<StudentSubjectResult, StudentSubjectResultId> {

    Optional<StudentSubjectResult> findByIdUserIdAndIdCatalogSubjectId(Long userId, Long catalogSubjectId);

    List<StudentSubjectResult> findByIdUserIdAndIdCatalogSubjectIdIn(Long userId, Collection<Long> catalogSubjectIds);
}
