package com.studentski.auth.controller;

import com.studentski.auth.dto.CreateStudentRequest;
import com.studentski.auth.dto.CreatedUserResponse;
import com.studentski.auth.service.StudentRegistrationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final StudentRegistrationService studentRegistrationService;

    public AdminUserController(StudentRegistrationService studentRegistrationService) {
        this.studentRegistrationService = studentRegistrationService;
    }

    @PostMapping("/students")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public CreatedUserResponse createStudent(@Valid @RequestBody CreateStudentRequest req) {
        return studentRegistrationService.createStudent(req);
    }
}
