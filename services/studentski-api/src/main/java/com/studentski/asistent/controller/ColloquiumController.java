package com.studentski.asistent.controller;

import com.studentski.asistent.entity.Colloquium;
import com.studentski.asistent.repository.ColloquiumRepository;
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
@RequestMapping("/api/colloquiums")
public class ColloquiumController {

    private final ColloquiumRepository colloquiumRepository;

    public ColloquiumController(ColloquiumRepository colloquiumRepository) {
        this.colloquiumRepository = colloquiumRepository;
    }

    @GetMapping
    public List<Colloquium> list() {
        return colloquiumRepository.findAllByOrderByDateMsDesc();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Colloquium create(@Valid @RequestBody Colloquium body) {
        body.setId(null);
        return colloquiumRepository.save(body);
    }

    @PutMapping("/{id}")
    public Colloquium update(@PathVariable Long id, @Valid @RequestBody Colloquium body) {
        Colloquium existing = colloquiumRepository.findById(id).orElseThrow();
        existing.setSubjectId(body.getSubjectId());
        existing.setTitle(body.getTitle());
        existing.setMaxPoints(body.getMaxPoints());
        existing.setPoints(body.getPoints());
        existing.setDateMs(body.getDateMs());
        return colloquiumRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        colloquiumRepository.deleteById(id);
    }
}
