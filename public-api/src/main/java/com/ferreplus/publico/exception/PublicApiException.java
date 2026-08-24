package com.ferreplus.publico.exception;

import org.springframework.http.HttpStatus;
import java.util.Map;

public class PublicApiException extends RuntimeException {
    private final HttpStatus status;
    private final String code;
    private final Map<String, String> errors;

    public PublicApiException(HttpStatus status, String message) {
        this(status, message, null);
    }

    public PublicApiException(HttpStatus status, String message, String code) {
        this(status, message, code, Map.of());
    }

    public PublicApiException(HttpStatus status, String message, String code, Map<String, String> errors) {
        super(message);
        this.status = status;
        this.code = code;
        this.errors = errors == null ? Map.of() : Map.copyOf(errors);
    }

    public HttpStatus status() {
        return status;
    }

    public String errorCode() { return code; }
    public Map<String, String> errors() { return errors; }
}
