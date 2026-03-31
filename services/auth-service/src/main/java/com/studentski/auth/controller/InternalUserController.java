package com.studentski.auth.controller;

import com.studentski.auth.dto.CreateStudentRequest;
import com.studentski.auth.dto.CreatedUserResponse;
import com.studentski.auth.dto.UserIdFullName;
import com.studentski.auth.repository.UserRepository;
import com.studentski.auth.service.StudentRegistrationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

/**
 * Poziv samo iz studentski-api (Docker mreža) uz zajednički tajni token.
 * Zaobilazi problem kada JWT na auth servisu ne prođe @PreAuthorize, a studentski-api je već potvrdio ADMIN.
 */
@RestController
@RequestMapping("/auth/internal")
public class InternalUserController {

    public static final String INTERNAL_TOKEN_HEADER = "X-Internal-Token";

    private final StudentRegistrationService studentRegistrationService;
    private final UserRepository userRepository;
    private final String expectedInternalToken;

    public InternalUserController(
            StudentRegistrationService studentRegistrationService,
            UserRepository userRepository,
            @Value("${internal.service.token:}") String expectedInternalToken
    ) {
        this.studentRegistrationService = studentRegistrationService;
        this.userRepository = userRepository;
        this.expectedInternalToken = expectedInternalToken;
    }

    @PostMapping("/students")
    @ResponseStatus(HttpStatus.CREATED)
    public CreatedUserResponse createStudent(HttpServletRequest request, @Valid @RequestBody CreateStudentRequest req) {
        requireValidInternalToken(request);
        return studentRegistrationService.createStudent(req);
    }

    /**
     * Batch: userId → fullName za prikaz u studentski-api kada lokalna kolona full_name još nije popunjena.
     */
    @PostMapping("/users/by-ids")
    public List<UserIdFullName> usersByIds(HttpServletRequest request, @RequestBody List<Long> userIds) {
        requireValidInternalToken(request);
        if (userIds == null || userIds.isEmpty()) {
            return List.of();
        }
        return userRepository.findAllByIdIn(userIds.stream().distinct().toList()).stream()
                .map(u -> new UserIdFullName(u.getId(), u.getFullName()))
                .toList();
    }

    private void requireValidInternalToken(HttpServletRequest request) {
        if (!StringUtils.hasText(expectedInternalToken)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        String provided = request.getHeader(INTERNAL_TOKEN_HEADER);
        if (provided == null || !expectedInternalToken.trim().equals(provided.trim())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }
}
