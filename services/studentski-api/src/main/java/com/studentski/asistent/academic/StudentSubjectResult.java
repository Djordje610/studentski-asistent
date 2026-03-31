package com.studentski.asistent.academic;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;

@Entity
@Table(name = "student_subject_results")
public class StudentSubjectResult {

    @EmbeddedId
    private StudentSubjectResultId id;

    @MapsId("catalogSubjectId")
    @ManyToOne(optional = false)
    @JoinColumn(name = "catalog_subject_id")
    private CatalogSubject catalogSubject;

    @Column(nullable = false)
    private boolean passed = false;

    private Integer grade;

    @Column(name = "passed_in_period")
    private String passedInPeriod;

    public StudentSubjectResultId getId() {
        return id;
    }

    public void setId(StudentSubjectResultId id) {
        this.id = id;
    }

    public CatalogSubject getCatalogSubject() {
        return catalogSubject;
    }

    public void setCatalogSubject(CatalogSubject catalogSubject) {
        this.catalogSubject = catalogSubject;
    }

    public boolean isPassed() {
        return passed;
    }

    public void setPassed(boolean passed) {
        this.passed = passed;
    }

    public Integer getGrade() {
        return grade;
    }

    public void setGrade(Integer grade) {
        this.grade = grade;
    }

    public String getPassedInPeriod() {
        return passedInPeriod;
    }

    public void setPassedInPeriod(String passedInPeriod) {
        this.passedInPeriod = passedInPeriod;
    }
}
