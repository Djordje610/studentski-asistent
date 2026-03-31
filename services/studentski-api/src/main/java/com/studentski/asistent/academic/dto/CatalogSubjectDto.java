package com.studentski.asistent.academic.dto;

public record CatalogSubjectDto(
        long id,
        String code,
        String name,
        int espb,
        long programYearId,
        String programCode,
        int yearNumber
) {
}
