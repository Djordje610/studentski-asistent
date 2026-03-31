package com.studentski.asistent.academic.dto;

public record StudentProgressSummaryDto(
        int totalEspb,
        int earnedEspb,
        Double weightedAverage,
        int passedCount
) {
}
