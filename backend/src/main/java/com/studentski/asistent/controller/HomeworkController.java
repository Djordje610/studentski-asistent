package com.studentski.asistent.controller;

import com.studentski.asistent.entity.Homework;
import com.studentski.asistent.repository.HomeworkRepository;
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
@RequestMapping("/api/homework")
public class HomeworkController {

    private final HomeworkRepository homeworkRepository;

    public HomeworkController(HomeworkRepository homeworkRepository) {
        this.homeworkRepository = homeworkRepository;
    }

    @GetMapping
    public List<Homework> list() {
        return homeworkRepository.findAllByOrderByDueDateMsAsc();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Homework create(@Valid @RequestBody Homework body) {
        body.setId(null);
        if (body.getCompleted() == null) {
            body.setCompleted(false);
        }
        return homeworkRepository.save(body);
    }

    @PutMapping("/{id}")
    public Homework update(@PathVariable Long id, @Valid @RequestBody Homework body) {
        Homework existing = homeworkRepository.findById(id).orElseThrow();
        existing.setSubjectId(body.getSubjectId());
        existing.setTitle(body.getTitle());
        existing.setMaxPoints(body.getMaxPoints());
        existing.setPoints(body.getPoints());
        existing.setDueDateMs(body.getDueDateMs());
        existing.setCompleted(body.getCompleted() != null ? body.getCompleted() : false);
        return homeworkRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        homeworkRepository.deleteById(id);
    }
}
