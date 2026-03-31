package com.studentski.asistent.controller;

import com.studentski.asistent.entity.ScheduleEntry;
import com.studentski.asistent.repository.ScheduleEntryRepository;
import com.studentski.asistent.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
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

import static org.springframework.http.HttpStatus.FORBIDDEN;

@RestController
@RequestMapping("/api/schedule")
public class ScheduleEntryController {

    private final ScheduleEntryRepository scheduleEntryRepository;
    private final CurrentUser currentUser;

    public ScheduleEntryController(ScheduleEntryRepository scheduleEntryRepository, CurrentUser currentUser) {
        this.scheduleEntryRepository = scheduleEntryRepository;
        this.currentUser = currentUser;
    }

    @GetMapping
    public List<ScheduleEntry> byDay(@RequestParam("dayOfWeek") int dayOfWeek) {
        return scheduleEntryRepository.findByUserIdAndDayOfWeekOrderByStartTimeAsc(currentUser.id(), dayOfWeek);
    }

    public record ScheduleEntryBody(
            @jakarta.validation.constraints.NotNull Integer dayOfWeek,
            @jakarta.validation.constraints.NotBlank String title,
            @jakarta.validation.constraints.NotBlank String activityType,
            @jakarta.validation.constraints.NotBlank String startTime,
            @jakarta.validation.constraints.NotBlank String endTime,
            String room,
            String notes
    ) {
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ScheduleEntry create(@Valid @RequestBody ScheduleEntryBody body) {
        ScheduleEntry entry = new ScheduleEntry();
        entry.setUserId(currentUser.id());
        entry.setDayOfWeek(body.dayOfWeek());
        entry.setTitle(body.title());
        entry.setActivityType(body.activityType());
        entry.setStartTime(body.startTime());
        entry.setEndTime(body.endTime());
        entry.setRoom(body.room());
        entry.setNotes(body.notes());
        return scheduleEntryRepository.save(entry);
    }

    @PutMapping("/{id}")
    public ScheduleEntry update(@PathVariable Long id, @Valid @RequestBody ScheduleEntryBody body) {
        ScheduleEntry existing = scheduleEntryRepository.findById(id).orElseThrow();
        if (!existing.getUserId().equals(currentUser.id())) {
            throw new ResponseStatusException(FORBIDDEN);
        }
        existing.setDayOfWeek(body.dayOfWeek());
        existing.setTitle(body.title());
        existing.setActivityType(body.activityType());
        existing.setStartTime(body.startTime());
        existing.setEndTime(body.endTime());
        existing.setRoom(body.room());
        existing.setNotes(body.notes());
        return scheduleEntryRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        ScheduleEntry existing = scheduleEntryRepository.findById(id).orElseThrow();
        if (!existing.getUserId().equals(currentUser.id())) {
            throw new ResponseStatusException(FORBIDDEN);
        }
        scheduleEntryRepository.deleteById(id);
    }
}
