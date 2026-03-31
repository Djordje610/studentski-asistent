package com.studentski.asistent.integration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AuthClient {

    private static final String INTERNAL_TOKEN_HEADER = "X-Internal-Token";

    private final WebClient webClient;
    private final String internalServiceToken;

    public AuthClient(
            @Value("${auth.service.base-url}") String baseUrl,
            @Value("${internal.service.token:}") String internalServiceToken
    ) {
        this.webClient = WebClient.builder().baseUrl(baseUrl).build();
        this.internalServiceToken = internalServiceToken;
    }

    public record CreateStudentPayload(String email, String password, String fullName, String studentIndex) {
    }

    public record CreatedAuthUser(long userId, String email) {
    }

    private record UserIdFullNameRow(long userId, String fullName) {
    }

    /**
     * Ime i prezime iz auth baze (batch), za studente bez {@code full_name} u studentski bazi.
     */
    public Map<Long, String> resolveFullNames(List<Long> userIds) {
        if (!StringUtils.hasText(internalServiceToken) || userIds == null || userIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Long> distinct = userIds.stream().distinct().toList();
        List<UserIdFullNameRow> rows = webClient.post()
                .uri("/auth/internal/users/by-ids")
                .contentType(MediaType.APPLICATION_JSON)
                .header(INTERNAL_TOKEN_HEADER, internalServiceToken)
                .bodyValue(distinct)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<List<UserIdFullNameRow>>() {
                })
                .block();
        if (rows == null || rows.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<Long, String> out = new HashMap<>();
        for (UserIdFullNameRow r : rows) {
            out.put(r.userId(), r.fullName());
        }
        return out;
    }

    /**
     * Ako je podešen env {@code INTERNAL_SERVICE_TOKEN}, koristi se servis-servis poziv (bez JWT na auth).
     * Inače se prosleđuje Authorization sa admin JWT (za lokalni razvoj bez Docker env-a).
     */
    public CreatedAuthUser createStudent(CreateStudentPayload payload, String authorizationHeader) {
        if (StringUtils.hasText(internalServiceToken)) {
            return webClient.post()
                    .uri("/auth/internal/students")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header(INTERNAL_TOKEN_HEADER, internalServiceToken)
                    .bodyValue(payload)
                    .retrieve()
                    .bodyToMono(CreatedAuthUser.class)
                    .block();
        }
        return webClient.post()
                .uri("/auth/admin/students")
                .contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.AUTHORIZATION, authorizationHeader)
                .bodyValue(payload)
                .retrieve()
                .bodyToMono(CreatedAuthUser.class)
                .block();
    }
}
