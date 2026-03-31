package com.studentski.asistent.academic.dto;

public record StudentProgressSubjectDto(
        long catalogSubjectId,
        String code,
        String name,
        int espb,
        boolean passed,
        Integer grade,
        String passedInPeriod
) {
}
