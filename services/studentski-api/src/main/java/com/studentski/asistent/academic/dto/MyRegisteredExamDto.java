package com.studentski.asistent.academic.dto;

public record MyRegisteredExamDto(
        long registrationId,
        long offeringId,
        String subjectName,
        long examMs,
        String location,
        String examPeriodName,
        boolean passed
) {
}
