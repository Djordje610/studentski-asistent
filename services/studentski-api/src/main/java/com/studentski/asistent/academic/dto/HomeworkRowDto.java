package com.studentski.asistent.academic.dto;

public record HomeworkRowDto(
        long assignmentId,
        String title,
        String description,
        Long dueDateMs,
        long catalogSubjectId,
        String subjectName,
        boolean completed
) {
}
