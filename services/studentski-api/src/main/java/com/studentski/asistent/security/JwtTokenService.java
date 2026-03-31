package com.studentski.asistent.security;

import com.studentski.asistent.config.JwtProperties;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@Service
public class JwtTokenService {

    private final SecretKey key;

    public JwtTokenService(JwtProperties jwtProperties) {
        this.key = Keys.hmacShaKeyFor(jwtProperties.secret().getBytes(StandardCharsets.UTF_8));
    }

    public Long parseUserId(String token) {
        return parsePrincipal(token).userId();
    }

    public JwtPrincipal parsePrincipal(String token) {
        var claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        Long userId = Long.parseLong(claims.getSubject());
        String role = normalizeRole(claims.get("role", String.class));
        return new JwtPrincipal(userId, role);
    }

    private static String normalizeRole(String raw) {
        if (raw == null || raw.isBlank()) {
            return "STUDENT";
        }
        String r = raw.trim().toUpperCase();
        if ("ADMIN".equals(r) || "STUDENT".equals(r)) {
            return r;
        }
        return "STUDENT";
    }
}
