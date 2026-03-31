package com.studentski.asistent.controller;

import com.studentski.asistent.entity.Exam;
import com.studentski.asistent.repository.ExamRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/exams")
public class ExamController {

    private final ExamRepository examRepository;

    public ExamController(ExamRepository examRepository) {
        this.examRepository = examRepository;
    }

    @GetMapping("/upcoming")
    public List<Exam> upcoming() {
        long now = System.currentTimeMillis();
        return examRepository.findByExamMsGreaterThanEqualOrderByExamMsAsc(now);
    }

    @GetMapping
    public List<Exam> all() {
        return examRepository.findAllByOrderByExamMsDesc();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Exam create(@Valid @RequestBody Exam body) {
        body.setId(null);
        return examRepository.save(body);
    }

    @PutMapping("/{id}")
    public Exam update(@PathVariable Long id, @Valid @RequestBody Exam body) {
        Exam existing = examRepository.findById(id).orElseThrow();
        existing.setSubjectId(body.getSubjectId());
        existing.setTitle(body.getTitle());
        existing.setExamMs(body.getExamMs());
        existing.setLocation(body.getLocation());
        existing.setNotes(body.getNotes());
        return examRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        examRepository.deleteById(id);
    }
}
