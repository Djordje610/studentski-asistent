package com.studentski.auth.controller;

import com.studentski.auth.dto.UserMeResponse;
import com.studentski.auth.entity.User;
import com.studentski.auth.repository.UserRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@RestController
@RequestMapping("/auth")
public class MeController {

    private final UserRepository userRepository;

    public MeController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public UserMeResponse me(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        User u = userRepository.findById(userId).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
        return new UserMeResponse(
                u.getId(),
                u.getEmail(),
                u.getFullName(),
                u.getRole().name(),
                u.getStudentIndex()
        );
    }
}
