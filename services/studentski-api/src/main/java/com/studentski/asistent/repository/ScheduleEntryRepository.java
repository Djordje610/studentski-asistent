package com.studentski.asistent.repository;

import com.studentski.asistent.entity.ScheduleEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ScheduleEntryRepository extends JpaRepository<ScheduleEntry, Long> {

    List<ScheduleEntry> findByUserIdAndDayOfWeekOrderByStartTimeAsc(Long userId, int dayOfWeek);
}
