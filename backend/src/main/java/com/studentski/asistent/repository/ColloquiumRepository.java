package com.studentski.asistent.repository;

import com.studentski.asistent.entity.Colloquium;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ColloquiumRepository extends JpaRepository<Colloquium, Long> {

    List<Colloquium> findAllByOrderByDateMsDesc();
}
