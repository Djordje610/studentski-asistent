package com.studentski.auth.service;

import com.studentski.auth.config.JwtProperties;
import com.studentski.auth.dto.AuthResponse;
import com.studentski.auth.dto.LoginRequest;
import com.studentski.auth.entity.User;
import com.studentski.auth.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthApplicationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;

    public AuthApplicationService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            JwtProperties jwtProperties
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
    }

    public AuthResponse login(LoginRequest req) {
        User u = userRepository.findByEmailIgnoreCase(req.email().trim().toLowerCase())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Pogrešan email ili lozinka"));
        if (!passwordEncoder.matches(req.password(), u.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Pogrešan email ili lozinka");
        }
        return buildResponse(u);
    }

    private AuthResponse buildResponse(User u) {
        String token = jwtService.generateToken(u.getId(), u.getEmail(), u.getRole().name());
        long expSec = Math.max(1L, jwtProperties.expirationMs() / 1000);
        return new AuthResponse(token, expSec, u.getId(), u.getEmail(), u.getFullName(), u.getRole().name());
    }
}
