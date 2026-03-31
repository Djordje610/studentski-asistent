package com.studentski.asistent.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class StudentSubjectResultId implements Serializable {

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "catalog_subject_id")
    private Long catalogSubjectId;

    public StudentSubjectResultId() {
    }

    public StudentSubjectResultId(Long userId, Long catalogSubjectId) {
        this.userId = userId;
        this.catalogSubjectId = catalogSubjectId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getCatalogSubjectId() {
        return catalogSubjectId;
    }

    public void setCatalogSubjectId(Long catalogSubjectId) {
        this.catalogSubjectId = catalogSubjectId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof StudentSubjectResultId that)) return false;
        return Objects.equals(userId, that.userId) && Objects.equals(catalogSubjectId, that.catalogSubjectId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, catalogSubjectId);
    }
}
