package com.studentski.asistent.academic.dto;

public record ExamOfferDto(
        long offeringId,
        String examPeriodName,
        long catalogSubjectId,
        String subjectName,
        long examMs,
        String location
) {
}
