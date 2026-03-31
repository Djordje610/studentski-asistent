package com.studentski.asistent.controller;

import com.studentski.asistent.entity.ScheduleEntry;
import com.studentski.asistent.repository.ScheduleEntryRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/schedule")
public class ScheduleEntryController {

    private final ScheduleEntryRepository scheduleEntryRepository;

    public ScheduleEntryController(ScheduleEntryRepository scheduleEntryRepository) {
        this.scheduleEntryRepository = scheduleEntryRepository;
    }

    @GetMapping
    public List<ScheduleEntry> byDay(@RequestParam("dayOfWeek") int dayOfWeek) {
        return scheduleEntryRepository.findByDayOfWeekOrderByStartTimeAsc(dayOfWeek);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ScheduleEntry create(@Valid @RequestBody ScheduleEntry body) {
        body.setId(null);
        return scheduleEntryRepository.save(body);
    }

    @PutMapping("/{id}")
    public ScheduleEntry update(@PathVariable Long id, @Valid @RequestBody ScheduleEntry body) {
        ScheduleEntry existing = scheduleEntryRepository.findById(id).orElseThrow();
        existing.setDayOfWeek(body.getDayOfWeek());
        existing.setTitle(body.getTitle());
        existing.setActivityType(body.getActivityType());
        existing.setStartTime(body.getStartTime());
        existing.setEndTime(body.getEndTime());
        existing.setRoom(body.getRoom());
        existing.setNotes(body.getNotes());
        return scheduleEntryRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        scheduleEntryRepository.deleteById(id);
    }
}
