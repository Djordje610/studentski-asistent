package com.studentski.asistent.dto;

public record ProgressSummary(
        int totalEspb,
        int earnedEspbWithGrade,
        Double weightedAverage,
        Double simpleAverage,
        int subjectsWithGrade
) {
}
