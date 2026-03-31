package com.studentski.asistent.academic;

import com.studentski.asistent.integration.AuthClient;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AcademicAdminController {

    private final StudyProgramRepository studyProgramRepository;
    private final ProgramYearRepository programYearRepository;
    private final CatalogSubjectRepository catalogSubjectRepository;
    private final StudentProfileRepository studentProfileRepository;
    private final ExamPeriodRepository examPeriodRepository;
    private final ExamPeriodOfferingRepository examPeriodOfferingRepository;
    private final HomeworkAssignmentRepository homeworkAssignmentRepository;
    private final AuthClient authClient;

    public AcademicAdminController(
            StudyProgramRepository studyProgramRepository,
            ProgramYearRepository programYearRepository,
            CatalogSubjectRepository catalogSubjectRepository,
            StudentProfileRepository studentProfileRepository,
            ExamPeriodRepository examPeriodRepository,
            ExamPeriodOfferingRepository examPeriodOfferingRepository,
            HomeworkAssignmentRepository homeworkAssignmentRepository,
            AuthClient authClient
    ) {
        this.studyProgramRepository = studyProgramRepository;
        this.programYearRepository = programYearRepository;
        this.catalogSubjectRepository = catalogSubjectRepository;
        this.studentProfileRepository = studentProfileRepository;
        this.examPeriodRepository = examPeriodRepository;
        this.examPeriodOfferingRepository = examPeriodOfferingRepository;
        this.homeworkAssignmentRepository = homeworkAssignmentRepository;
        this.authClient = authClient;
    }

    public record StudyProgramBody(@NotBlank String code, @NotBlank String name) {
    }

    @PostMapping("/study-programs")
    @ResponseStatus(HttpStatus.CREATED)
    public StudyProgram createProgram(@Valid @RequestBody StudyProgramBody body) {
        if (studyProgramRepository.findByCodeIgnoreCase(body.code()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Kod smera postoji");
        }
        StudyProgram s = new StudyProgram();
        s.setCode(body.code().trim());
        s.setName(body.name().trim());
        return studyProgramRepository.save(s);
    }

    @GetMapping("/study-programs")
    public List<StudyProgram> listPrograms() {
        return studyProgramRepository.findAll();
    }

    public record ProgramYearBody(@NotNull Long studyProgramId, @NotNull Integer yearNumber) {
    }

    @PostMapping("/program-years")
    @ResponseStatus(HttpStatus.CREATED)
    public ProgramYear createProgramYear(@Valid @RequestBody ProgramYearBody body) {
        StudyProgram sp = studyProgramRepository.findById(body.studyProgramId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (programYearRepository.findByStudyProgramIdAndYearNumber(sp.getId(), body.yearNumber()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Godina za ovaj smer već postoji");
        }
        ProgramYear py = new ProgramYear();
        py.setStudyProgram(sp);
        py.setYearNumber(body.yearNumber());
        return programYearRepository.save(py);
    }

    @GetMapping("/program-years")
    public List<ProgramYear> listProgramYears(@RequestParam Long studyProgramId) {
        return programYearRepository.findByStudyProgramIdOrderByYearNumberAsc(studyProgramId);
    }

    public record CatalogSubjectBody(
            @NotNull Long programYearId,
            String code,
            @NotBlank String name,
            @NotNull Integer espb
    ) {
    }

    @PostMapping("/catalog-subjects")
    @ResponseStatus(HttpStatus.CREATED)
    public CatalogSubject createCatalogSubject(@Valid @RequestBody CatalogSubjectBody body) {
        ProgramYear py = programYearRepository.findById(body.programYearId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        CatalogSubject c = new CatalogSubject();
        c.setProgramYear(py);
        c.setCode(body.code() != null ? body.code().trim() : null);
        c.setName(body.name().trim());
        c.setEspb(body.espb());
        return catalogSubjectRepository.save(c);
    }

    @GetMapping("/catalog-subjects")
    public List<CatalogSubject> listCatalogByYear(@RequestParam Long programYearId) {
        return catalogSubjectRepository.findByProgramYearIdOrderByNameAsc(programYearId);
    }

    @DeleteMapping("/catalog-subjects/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCatalogSubject(@PathVariable Long id) {
        catalogSubjectRepository.deleteById(id);
    }

    public record ExamPeriodBody(@NotBlank String name, @NotNull Long startMs, @NotNull Long endMs) {
    }

    @PostMapping("/exam-periods")
    @ResponseStatus(HttpStatus.CREATED)
    public ExamPeriod createExamPeriod(@Valid @RequestBody ExamPeriodBody body) {
        ExamPeriod e = new ExamPeriod();
        e.setName(body.name().trim());
        e.setStartMs(body.startMs());
        e.setEndMs(body.endMs());
        e.setActive(false);
        return examPeriodRepository.save(e);
    }

    @GetMapping("/exam-periods")
    public List<ExamPeriod> listExamPeriods() {
        return examPeriodRepository.findAllByOrderByStartMsDesc();
    }

    @PatchMapping("/exam-periods/{id}/activate")
    @Transactional
    public void activateExamPeriod(@PathVariable Long id) {
        List<ExamPeriod> all = examPeriodRepository.findAll();
        for (ExamPeriod e : all) {
            e.setActive(e.getId().equals(id));
        }
        examPeriodRepository.saveAll(all);
    }

    public record ExamOfferingBody(
            @NotNull Long examPeriodId,
            @NotNull Long catalogSubjectId,
            @NotNull Long examMs,
            String location
    ) {
    }

    @PostMapping("/exam-offerings")
    @ResponseStatus(HttpStatus.CREATED)
    public ExamPeriodOffering createOffering(@Valid @RequestBody ExamOfferingBody body) {
        ExamPeriod ep = examPeriodRepository.findById(body.examPeriodId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        CatalogSubject cs = catalogSubjectRepository.findById(body.catalogSubjectId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        ExamPeriodOffering o = new ExamPeriodOffering();
        o.setExamPeriod(ep);
        o.setCatalogSubject(cs);
        o.setExamMs(body.examMs());
        o.setLocation(body.location());
        return examPeriodOfferingRepository.save(o);
    }

    @DeleteMapping("/exam-offerings/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteOffering(@PathVariable Long id) {
        examPeriodOfferingRepository.deleteById(id);
    }

    @GetMapping("/exam-offerings")
    public List<ExamPeriodOffering> listOfferings(@RequestParam Long examPeriodId) {
        return examPeriodOfferingRepository.findByExamPeriodIdOrderByExamMsAsc(examPeriodId);
    }

    @GetMapping("/homework-assignments")
    public List<HomeworkAssignment> listHomeworkAssignments(@RequestParam Long catalogSubjectId) {
        return homeworkAssignmentRepository.findByCatalogSubject_IdOrderByIdDesc(catalogSubjectId);
    }

    public record HomeworkBody(
            @NotNull Long catalogSubjectId,
            @NotBlank String title,
            String description,
            Long dueDateMs
    ) {
    }

    @PostMapping("/homework-assignments")
    @ResponseStatus(HttpStatus.CREATED)
    public HomeworkAssignment createHomework(@Valid @RequestBody HomeworkBody body) {
        CatalogSubject cs = catalogSubjectRepository.findById(body.catalogSubjectId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        HomeworkAssignment h = new HomeworkAssignment();
        h.setCatalogSubject(cs);
        h.setTitle(body.title().trim());
        h.setDescription(body.description());
        h.setDueDateMs(body.dueDateMs());
        return homeworkAssignmentRepository.save(h);
    }

    @DeleteMapping("/homework-assignments/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteHomework(@PathVariable Long id) {
        homeworkAssignmentRepository.deleteById(id);
    }

    public record CreateStudentBody(
            @NotBlank String email,
            @NotBlank String password,
            @NotBlank String fullName,
            String studentIndex,
            @NotNull Long programYearId
    ) {
    }

    public record CreatedStudentResponse(long userId, String email) {
    }

    @PostMapping("/students")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public CreatedStudentResponse createStudent(
            @Valid @RequestBody CreateStudentBody body,
            HttpServletRequest request
    ) {
        String auth = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (auth == null || !auth.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        AuthClient.CreatedAuthUser created = authClient.createStudent(
                new AuthClient.CreateStudentPayload(
                        body.email().trim(),
                        body.password(),
                        body.fullName().trim(),
                        body.studentIndex() != null ? body.studentIndex().trim() : null
                ),
                auth
        );
        ProgramYear py = programYearRepository.findById(body.programYearId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        StudyProgram sp = py.getStudyProgram();
        StudentProfile p = new StudentProfile();
        p.setUserId(created.userId());
        p.setFullName(body.fullName().trim());
        p.setStudyProgram(sp);
        p.setProgramYear(py);
        studentProfileRepository.save(p);
        return new CreatedStudentResponse(created.userId(), created.email());
    }

    @GetMapping("/student-profiles")
    public List<StudentProfileView> listProfiles() {
        List<StudentProfile> list = studentProfileRepository.findAllByOrderByUserIdAsc();
        List<Long> missingNameIds = list.stream()
                .filter(p -> p.getFullName() == null || p.getFullName().isBlank())
                .map(StudentProfile::getUserId)
                .toList();
        Map<Long, String> fromAuth = authClient.resolveFullNames(missingNameIds);
        return list.stream()
                .map(p -> StudentProfileView.from(p, fromAuth.get(p.getUserId())))
                .toList();
    }

    public record UpdateProfileBody(@NotNull Long programYearId) {
    }

    @PutMapping("/student-profiles/{userId}")
    @Transactional
    public StudentProfile updateProfile(@PathVariable Long userId, @Valid @RequestBody UpdateProfileBody body) {
        StudentProfile p = studentProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        ProgramYear py = programYearRepository.findById(body.programYearId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        p.setStudyProgram(py.getStudyProgram());
        p.setProgramYear(py);
        return studentProfileRepository.save(p);
    }

    /**
     * Isti JSON kao {@link StudentProfile}, uz {@code fullName} dopunjen iz auth servisa ako je u bazi prazno.
     */
    public record StudentProfileView(
            long userId,
            String fullName,
            StudyProgram studyProgram,
            ProgramYear programYear
    ) {
        static StudentProfileView from(StudentProfile p, String resolvedFromAuth) {
            String fn = p.getFullName();
            if (fn == null || fn.isBlank()) {
                fn = resolvedFromAuth;
            }
            return new StudentProfileView(p.getUserId(), fn, p.getStudyProgram(), p.getProgramYear());
        }
    }
}
