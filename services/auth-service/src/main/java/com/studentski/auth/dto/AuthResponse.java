package com.studentski.auth.dto;

public record AuthResponse(
        String accessToken,
        long expiresInSeconds,
        long userId,
        String email,
        String fullName,
        String role
) {
}
