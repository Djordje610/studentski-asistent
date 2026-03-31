package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CatalogSubjectRepository extends JpaRepository<CatalogSubject, Long> {

    List<CatalogSubject> findByProgramYearIdOrderByNameAsc(Long programYearId);

    List<CatalogSubject> findByProgramYearIdIn(List<Long> programYearIds);
}
