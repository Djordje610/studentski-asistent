package com.studentski.asistent.config;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.reactive.function.client.WebClientResponseException;

/**
 * Prosleđuje HTTP status i telo odgovora sa auth servisa (npr. 403) umesto generičkog 500.
 */
@RestControllerAdvice
public class WebClientExceptionAdvice {

    @ExceptionHandler(WebClientResponseException.class)
    public ResponseEntity<String> handleWebClient(WebClientResponseException e) {
        String body = e.getResponseBodyAsString();
        return ResponseEntity.status(e.getStatusCode())
                .body(body != null && !body.isEmpty() ? body : e.getMessage());
    }
}
