package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExamPeriodOfferingRepository extends JpaRepository<ExamPeriodOffering, Long> {

    List<ExamPeriodOffering> findByExamPeriodIdOrderByExamMsAsc(Long examPeriodId);

    List<ExamPeriodOffering> findByExamPeriod_IdAndCatalogSubject_ProgramYear_Id(Long examPeriodId, Long programYearId);
}
