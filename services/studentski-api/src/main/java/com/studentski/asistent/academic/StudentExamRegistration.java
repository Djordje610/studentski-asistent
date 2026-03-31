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
@Table(name = "student_exam_registrations")
public class StudentExamRegistration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @NotNull
    @ManyToOne(optional = false)
    @JoinColumn(name = "exam_period_offering_id")
    private ExamPeriodOffering examPeriodOffering;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public ExamPeriodOffering getExamPeriodOffering() {
        return examPeriodOffering;
    }

    public void setExamPeriodOffering(ExamPeriodOffering examPeriodOffering) {
        this.examPeriodOffering = examPeriodOffering;
    }
}
