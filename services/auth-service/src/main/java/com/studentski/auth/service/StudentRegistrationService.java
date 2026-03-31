package com.studentski.auth.service;

import com.studentski.auth.dto.CreateStudentRequest;
import com.studentski.auth.dto.CreatedUserResponse;
import com.studentski.auth.entity.User;
import com.studentski.auth.entity.UserRole;
import com.studentski.auth.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.CONFLICT;

@Service
public class StudentRegistrationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public StudentRegistrationService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public CreatedUserResponse createStudent(CreateStudentRequest req) {
        if (userRepository.existsByEmailIgnoreCase(req.email())) {
            throw new ResponseStatusException(CONFLICT, "Email već postoji");
        }
        User u = new User();
        u.setEmail(req.email().trim().toLowerCase());
        u.setPasswordHash(passwordEncoder.encode(req.password()));
        u.setFullName(req.fullName().trim());
        u.setStudentIndex(req.studentIndex() != null && !req.studentIndex().isBlank()
                ? req.studentIndex().trim()
                : null);
        u.setRole(UserRole.STUDENT);
        u = userRepository.save(u);
        return new CreatedUserResponse(u.getId(), u.getEmail());
    }
}
