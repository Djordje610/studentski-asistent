package com.studentski.asistent.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;

@Entity
@Table(name = "student_profiles")
public class StudentProfile {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @NotNull
    @ManyToOne(optional = false)
    @JoinColumn(name = "study_program_id")
    private StudyProgram studyProgram;

    @NotNull
    @ManyToOne(optional = false)
    @JoinColumn(name = "program_year_id")
    private ProgramYear programYear;

    /** Ime i prezime (isti tekst kao u auth servisu; čuva se pri registraciji studenta). */
    @Column(name = "full_name")
    private String fullName;

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public StudyProgram getStudyProgram() {
        return studyProgram;
    }

    public void setStudyProgram(StudyProgram studyProgram) {
        this.studyProgram = studyProgram;
    }

    public ProgramYear getProgramYear() {
        return programYear;
    }

    public void setProgramYear(ProgramYear programYear) {
        this.programYear = programYear;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
}
