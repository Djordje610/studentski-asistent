package com.studentski.asistent.controller;

import com.studentski.asistent.entity.Attendance;
import com.studentski.asistent.repository.AttendanceRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private final AttendanceRepository attendanceRepository;

    public AttendanceController(AttendanceRepository attendanceRepository) {
        this.attendanceRepository = attendanceRepository;
    }

    @GetMapping("/by-subject/{subjectId}")
    public ResponseEntity<Attendance> getBySubject(@PathVariable Long subjectId) {
        return attendanceRepository
                .findBySubjectId(subjectId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping
    public Attendance upsert(@Valid @RequestBody Attendance body) {
        return attendanceRepository
                .findBySubjectId(body.getSubjectId())
                .map(existing -> {
                    existing.setPresent(body.getPresent());
                    existing.setTotal(body.getTotal());
                    return attendanceRepository.save(existing);
                })
                .orElseGet(() -> {
                    body.setId(null);
                    return attendanceRepository.save(body);
                });
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        attendanceRepository.deleteById(id);
    }
}
