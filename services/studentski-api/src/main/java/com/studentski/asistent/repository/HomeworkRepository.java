package com.studentski.asistent.repository;

import com.studentski.asistent.entity.Homework;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeworkRepository extends JpaRepository<Homework, Long> {

    List<Homework> findAllByOrderByDueDateMsAsc();
}
