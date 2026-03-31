package com.studentski.asistent.academic;

import com.studentski.asistent.academic.dto.CatalogSubjectDto;
import com.studentski.asistent.academic.dto.ExamOfferDto;
import com.studentski.asistent.academic.dto.HomeworkRowDto;
import com.studentski.asistent.academic.dto.MyRegisteredExamDto;
import com.studentski.asistent.academic.dto.StudentProgressSubjectDto;
import com.studentski.asistent.academic.dto.StudentProgressSummaryDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class StudentPortalService {

    private final StudentProfileRepository studentProfileRepository;
    private final CatalogSubjectRepository catalogSubjectRepository;
    private final HomeworkAssignmentRepository homeworkAssignmentRepository;
    private final StudentHomeworkStatusRepository studentHomeworkStatusRepository;
    private final ExamPeriodRepository examPeriodRepository;
    private final ExamPeriodOfferingRepository examPeriodOfferingRepository;
    private final StudentExamRegistrationRepository studentExamRegistrationRepository;
    private final StudentSubjectResultRepository studentSubjectResultRepository;

    public StudentPortalService(
            StudentProfileRepository studentProfileRepository,
            CatalogSubjectRepository catalogSubjectRepository,
            HomeworkAssignmentRepository homeworkAssignmentRepository,
            StudentHomeworkStatusRepository studentHomeworkStatusRepository,
            ExamPeriodRepository examPeriodRepository,
            ExamPeriodOfferingRepository examPeriodOfferingRepository,
            StudentExamRegistrationRepository studentExamRegistrationRepository,
            StudentSubjectResultRepository studentSubjectResultRepository
    ) {
        this.studentProfileRepository = studentProfileRepository;
        this.catalogSubjectRepository = catalogSubjectRepository;
        this.homeworkAssignmentRepository = homeworkAssignmentRepository;
        this.studentHomeworkStatusRepository = studentHomeworkStatusRepository;
        this.examPeriodRepository = examPeriodRepository;
        this.examPeriodOfferingRepository = examPeriodOfferingRepository;
        this.studentExamRegistrationRepository = studentExamRegistrationRepository;
        this.studentSubjectResultRepository = studentSubjectResultRepository;
    }

    private StudentProfile requireProfile(Long userId) {
        return studentProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Profil studenta nije podešen. Obratite se administratoru."));
    }

    public List<CatalogSubjectDto> listCatalogSubjects(Long userId) {
        StudentProfile p = requireProfile(userId);
        Long pyId = p.getProgramYear().getId();
        List<CatalogSubject> list = catalogSubjectRepository.findByProgramYearIdOrderByNameAsc(pyId);
        List<CatalogSubjectDto> out = new ArrayList<>();
        for (CatalogSubject s : list) {
            ProgramYear y = s.getProgramYear();
            out.add(new CatalogSubjectDto(
                    s.getId(),
                    s.getCode(),
                    s.getName(),
                    s.getEspb(),
                    y.getId(),
                    y.getStudyProgram().getCode(),
                    y.getYearNumber()
            ));
        }
        return out;
    }

    public List<HomeworkRowDto> listHomework(Long userId) {
        StudentProfile p = requireProfile(userId);
        Long pyId = p.getProgramYear().getId();
        List<CatalogSubject> subjects = catalogSubjectRepository.findByProgramYearIdOrderByNameAsc(pyId);
        List<Long> subjectIds = subjects.stream().map(CatalogSubject::getId).toList();
        if (subjectIds.isEmpty()) {
            return List.of();
        }
        List<Long> passedSubjectIds = studentSubjectResultRepository
                .findByIdUserIdAndIdCatalogSubjectIdIn(userId, subjectIds).stream()
                .filter(StudentSubjectResult::isPassed)
                .map(r -> r.getId().getCatalogSubjectId())
                .toList();
        List<Long> activeSubjectIds = subjectIds.stream()
                .filter(id -> !passedSubjectIds.contains(id))
                .toList();
        if (activeSubjectIds.isEmpty()) {
            return List.of();
        }
        List<HomeworkAssignment> assignments = homeworkAssignmentRepository.findByCatalogSubject_IdIn(activeSubjectIds);
        List<HomeworkRowDto> rows = new ArrayList<>();
        for (HomeworkAssignment a : assignments) {
            var status = studentHomeworkStatusRepository.findByUserIdAndHomeworkAssignmentId(userId, a.getId());
            boolean completed = status.map(StudentHomeworkStatus::getCompleted).orElse(false);
            CatalogSubject cs = a.getCatalogSubject();
            rows.add(new HomeworkRowDto(
                    a.getId(),
                    a.getTitle(),
                    a.getDescription(),
                    a.getDueDateMs(),
                    cs.getId(),
                    cs.getName(),
                    completed
            ));
        }
        return rows;
    }

    @Transactional
    public void setHomeworkCompleted(Long userId, long assignmentId, boolean completed) {
        StudentProfile p = requireProfile(userId);
        Long pyId = p.getProgramYear().getId();
        HomeworkAssignment a = homeworkAssignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (!a.getCatalogSubject().getProgramYear().getId().equals(pyId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Zadatak ne pripada vašoj godini.");
        }
        boolean passedSubject = studentSubjectResultRepository
                .findByIdUserIdAndIdCatalogSubjectId(userId, a.getCatalogSubject().getId())
                .map(StudentSubjectResult::isPassed)
                .orElse(false);
        if (passedSubject) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Predmet je položen i više nije u obavezama.");
        }
        StudentHomeworkStatus st = studentHomeworkStatusRepository
                .findByUserIdAndHomeworkAssignmentId(userId, assignmentId)
                .orElseGet(() -> {
                    StudentHomeworkStatus n = new StudentHomeworkStatus();
                    n.setUserId(userId);
                    n.setHomeworkAssignment(a);
                    n.setCompleted(false);
                    return n;
                });
        st.setCompleted(completed);
        studentHomeworkStatusRepository.save(st);
    }

    public List<ExamOfferDto> listExamOffersForStudent(Long userId) {
        StudentProfile p = requireProfile(userId);
        ExamPeriod period = examPeriodRepository.findByActiveIsTrue()
                .or(() -> examPeriodRepository.findTopByOrderByStartMsDesc())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nema kreiranog ispitnog roka."));
        Long pyId = p.getProgramYear().getId();
        List<ExamPeriodOffering> offers = examPeriodOfferingRepository
                .findByExamPeriod_IdAndCatalogSubject_ProgramYear_Id(period.getId(), pyId);
        List<Long> offerSubjectIds = offers.stream()
                .map(o -> o.getCatalogSubject().getId())
                .distinct()
                .toList();
        List<Long> passedSubjectIds = studentSubjectResultRepository
                .findByIdUserIdAndIdCatalogSubjectIdIn(userId, offerSubjectIds).stream()
                .filter(StudentSubjectResult::isPassed)
                .map(r -> r.getId().getCatalogSubjectId())
                .toList();
        List<ExamOfferDto> out = new ArrayList<>();
        for (ExamPeriodOffering o : offers) {
            CatalogSubject cs = o.getCatalogSubject();
            if (passedSubjectIds.contains(cs.getId())) {
                continue;
            }
            out.add(new ExamOfferDto(
                    o.getId(),
                    period.getName(),
                    cs.getId(),
                    cs.getName(),
                    o.getExamMs(),
                    o.getLocation()
            ));
        }
        return out;
    }

    @Transactional
    public void registerForExam(Long userId, long offeringId) {
        StudentProfile p = requireProfile(userId);
        ExamPeriodOffering off = examPeriodOfferingRepository.findById(offeringId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        ExamPeriod period = off.getExamPeriod();
        long now = System.currentTimeMillis();
        if (now > period.getEndMs()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ispitni rok za ovu ponudu je završen."
            );
        }
        if (!off.getCatalogSubject().getProgramYear().getId().equals(p.getProgramYear().getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Predmet nije u vašoj godini studija.");
        }
        if (studentExamRegistrationRepository.existsByUserIdAndExamPeriodOfferingId(userId, offeringId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Već ste prijavljeni.");
        }
        StudentExamRegistration r = new StudentExamRegistration();
        r.setUserId(userId);
        r.setExamPeriodOffering(off);
        studentExamRegistrationRepository.save(r);
    }

    public List<MyRegisteredExamDto> myRegisteredExams(Long userId) {
        requireProfile(userId);
        List<StudentExamRegistration> regs = studentExamRegistrationRepository.findByUserIdOrderByIdAsc(userId);
        List<Long> subjectIds = regs.stream()
                .map(r -> r.getExamPeriodOffering().getCatalogSubject().getId())
                .distinct()
                .toList();
        List<Long> passedSubjectIds = studentSubjectResultRepository
                .findByIdUserIdAndIdCatalogSubjectIdIn(userId, subjectIds).stream()
                .filter(StudentSubjectResult::isPassed)
                .map(r -> r.getId().getCatalogSubjectId())
                .toList();
        List<MyRegisteredExamDto> out = new ArrayList<>();
        for (StudentExamRegistration r : regs) {
            ExamPeriodOffering o = r.getExamPeriodOffering();
            ExamPeriod ep = o.getExamPeriod();
            CatalogSubject cs = o.getCatalogSubject();
            out.add(new MyRegisteredExamDto(
                    r.getId(),
                    o.getId(),
                    cs.getName(),
                    o.getExamMs(),
                    o.getLocation(),
                    ep.getName(),
                    passedSubjectIds.contains(cs.getId())
            ));
        }
        return out;
    }

    public List<StudentProgressSubjectDto> listProgressSubjects(Long userId) {
        StudentProfile p = requireProfile(userId);
        Long pyId = p.getProgramYear().getId();
        List<CatalogSubject> subjects = catalogSubjectRepository.findByProgramYearIdOrderByNameAsc(pyId);
        List<Long> subjectIds = subjects.stream().map(CatalogSubject::getId).toList();
        Map<Long, StudentSubjectResult> resultBySubjectId = new HashMap<>();
        if (!subjectIds.isEmpty()) {
            List<StudentSubjectResult> results = studentSubjectResultRepository
                    .findByIdUserIdAndIdCatalogSubjectIdIn(userId, subjectIds);
            for (StudentSubjectResult r : results) {
                resultBySubjectId.put(r.getId().getCatalogSubjectId(), r);
            }
        }

        List<StudentProgressSubjectDto> out = new ArrayList<>();
        for (CatalogSubject s : subjects) {
            StudentSubjectResult r = resultBySubjectId.get(s.getId());
            out.add(new StudentProgressSubjectDto(
                    s.getId(),
                    s.getCode(),
                    s.getName(),
                    s.getEspb(),
                    r != null && r.isPassed(),
                    r != null ? r.getGrade() : null,
                    r != null ? r.getPassedInPeriod() : null
            ));
        }
        return out;
    }

    public StudentProgressSummaryDto progressSummary(Long userId) {
        List<StudentProgressSubjectDto> subjects = listProgressSubjects(userId);
        int totalEspb = 0;
        int earnedEspb = 0;
        int passedCount = 0;
        double weighted = 0.0;
        int weightedEspb = 0;

        for (StudentProgressSubjectDto s : subjects) {
            totalEspb += s.espb();
            if (s.passed()) {
                earnedEspb += s.espb();
                passedCount++;
                if (s.grade() != null) {
                    weighted += s.grade() * s.espb();
                    weightedEspb += s.espb();
                }
            }
        }
        Double avg = weightedEspb > 0 ? (weighted / weightedEspb) : null;
        return new StudentProgressSummaryDto(totalEspb, earnedEspb, avg, passedCount);
    }

    @Transactional
    public void upsertSubjectResult(Long userId, long catalogSubjectId, boolean passed, Integer grade, String passedInPeriod) {
        StudentProfile p = requireProfile(userId);
        CatalogSubject subject = catalogSubjectRepository.findById(catalogSubjectId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Predmet nije pronađen."));
        if (!subject.getProgramYear().getId().equals(p.getProgramYear().getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Predmet nije u vašoj godini.");
        }
        StudentSubjectResult result = studentSubjectResultRepository
                .findByIdUserIdAndIdCatalogSubjectId(userId, catalogSubjectId)
                .orElseGet(() -> {
                    StudentSubjectResult n = new StudentSubjectResult();
                    n.setId(new StudentSubjectResultId(userId, catalogSubjectId));
                    n.setCatalogSubject(subject);
                    return n;
                });
        result.setPassed(passed);
        if (passed) {
            if (grade == null || grade < 6 || grade > 10) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ocena mora biti od 6 do 10.");
            }
            if (passedInPeriod == null || passedInPeriod.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Navedite ispitni rok.");
            }
            result.setGrade(grade);
            result.setPassedInPeriod(passedInPeriod.trim());
        } else {
            result.setGrade(null);
            result.setPassedInPeriod(null);
        }
        studentSubjectResultRepository.save(result);
    }
}
