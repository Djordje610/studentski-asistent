package com.studentski.asistent.academic;

import com.studentski.asistent.academic.dto.CatalogSubjectDto;
import com.studentski.asistent.academic.dto.ExamOfferDto;
import com.studentski.asistent.academic.dto.HomeworkRowDto;
import com.studentski.asistent.academic.dto.MyRegisteredExamDto;
import com.studentski.asistent.academic.dto.StudentProgressSubjectDto;
import com.studentski.asistent.academic.dto.StudentProgressSummaryDto;
import com.studentski.asistent.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PutMapping;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/student")
public class StudentPortalController {

    private final StudentPortalService studentPortalService;
    private final CurrentUser currentUser;

    public StudentPortalController(StudentPortalService studentPortalService, CurrentUser currentUser) {
        this.studentPortalService = studentPortalService;
        this.currentUser = currentUser;
    }

    @GetMapping("/catalog-subjects")
    public List<CatalogSubjectDto> catalogSubjects() {
        return studentPortalService.listCatalogSubjects(currentUser.id());
    }

    @GetMapping("/homework")
    public List<HomeworkRowDto> homework() {
        return studentPortalService.listHomework(currentUser.id());
    }

    @PatchMapping("/homework/{assignmentId}/complete")
    public void completeHomework(
            @PathVariable long assignmentId,
            @RequestBody Map<String, Boolean> body
    ) {
        boolean completed = Boolean.TRUE.equals(body.get("completed"));
        studentPortalService.setHomeworkCompleted(currentUser.id(), assignmentId, completed);
    }

    @GetMapping("/exam-offers")
    public List<ExamOfferDto> examOffers() {
        return studentPortalService.listExamOffersForStudent(currentUser.id());
    }

    public record RegisterExamBody(long offeringId) {
    }

    @PostMapping("/exam-registrations")
    public void registerExam(@RequestBody RegisterExamBody body) {
        studentPortalService.registerForExam(currentUser.id(), body.offeringId());
    }

    @GetMapping("/my-exams")
    public List<MyRegisteredExamDto> myExams() {
        return studentPortalService.myRegisteredExams(currentUser.id());
    }

    @GetMapping("/progress/subjects")
    public List<StudentProgressSubjectDto> progressSubjects() {
        return studentPortalService.listProgressSubjects(currentUser.id());
    }

    @GetMapping("/progress/summary")
    public StudentProgressSummaryDto progressSummary() {
        return studentPortalService.progressSummary(currentUser.id());
    }

    public record UpdateSubjectResultBody(
            boolean passed,
            Integer grade,
            String passedInPeriod
    ) {
    }

    @PutMapping("/progress/subjects/{catalogSubjectId}/result")
    public void updateSubjectResult(
            @PathVariable long catalogSubjectId,
            @RequestBody UpdateSubjectResultBody body
    ) {
        studentPortalService.upsertSubjectResult(
                currentUser.id(),
                catalogSubjectId,
                body.passed(),
                body.grade(),
                body.passedInPeriod()
        );
    }
}
