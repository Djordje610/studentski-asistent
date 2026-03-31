package com.studentski.asistent.academic;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentExamRegistrationRepository extends JpaRepository<StudentExamRegistration, Long> {

    List<StudentExamRegistration> findByUserIdOrderByIdAsc(Long userId);

    Optional<StudentExamRegistration> findByUserIdAndExamPeriodOfferingId(Long userId, Long offeringId);

    boolean existsByUserIdAndExamPeriodOfferingId(Long userId, Long offeringId);
}
