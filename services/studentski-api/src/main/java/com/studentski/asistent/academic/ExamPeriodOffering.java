package com.studentski.asistent.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;

@Entity
@Table(name = "exam_period_offerings")
public class ExamPeriodOffering {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @ManyToOne(optional = false)
    @JoinColumn(name = "exam_period_id")
    private ExamPeriod examPeriod;

    @NotNull
    @ManyToOne(optional = false)
    @JoinColumn(name = "catalog_subject_id")
    private CatalogSubject catalogSubject;

    @NotNull
    @Column(name = "exam_ms", nullable = false)
    private Long examMs;

    private String location;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public ExamPeriod getExamPeriod() {
        return examPeriod;
    }

    public void setExamPeriod(ExamPeriod examPeriod) {
        this.examPeriod = examPeriod;
    }

    public CatalogSubject getCatalogSubject() {
        return catalogSubject;
    }

    public void setCatalogSubject(CatalogSubject catalogSubject) {
        this.catalogSubject = catalogSubject;
    }

    public Long getExamMs() {
        return examMs;
    }

    public void setExamMs(Long examMs) {
        this.examMs = examMs;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }
}
