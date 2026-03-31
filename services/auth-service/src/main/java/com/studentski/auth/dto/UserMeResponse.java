package com.studentski.auth.dto;

public record UserMeResponse(
        long userId,
        String email,
        String fullName,
        String role,
        String studentIndex
) {
}
