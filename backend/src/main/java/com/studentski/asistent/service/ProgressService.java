package com.studentski.asistent.service;

import com.studentski.asistent.dto.ProgressSummary;
import com.studentski.asistent.entity.Subject;
import com.studentski.asistent.repository.SubjectRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ProgressService {

    private final SubjectRepository subjectRepository;

    public ProgressService(SubjectRepository subjectRepository) {
        this.subjectRepository = subjectRepository;
    }

    public ProgressSummary compute() {
        List<Subject> subjects = subjectRepository.findAll();
        int totalEspb = 0;
        double weightedSum = 0;
        int weightedEspb = 0;
        List<Double> grades = new ArrayList<>();

        for (Subject s : subjects) {
            totalEspb += s.getEspb();
            if (s.getFinalGrade() != null) {
                weightedSum += s.getFinalGrade() * s.getEspb();
                weightedEspb += s.getEspb();
                grades.add(s.getFinalGrade());
            }
        }

        Double weightedAvg = weightedEspb > 0 ? weightedSum / weightedEspb : null;
        Double simpleAvg = grades.isEmpty()
                ? null
                : grades.stream().mapToDouble(Double::doubleValue).average().orElse(0);

        return new ProgressSummary(
                totalEspb,
                weightedEspb,
                weightedAvg,
                simpleAvg,
                grades.size()
        );
    }
}
