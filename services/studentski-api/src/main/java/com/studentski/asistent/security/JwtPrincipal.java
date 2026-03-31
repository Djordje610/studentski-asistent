package com.studentski.asistent.security;

public record JwtPrincipal(Long userId, String role) {
}
