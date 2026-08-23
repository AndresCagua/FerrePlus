package com.ferreplus.publico.exception;

import org.springframework.http.HttpStatus;

public class PublicApiException extends RuntimeException {
    private final HttpStatus status;
    private final String code;

    public PublicApiException(HttpStatus status, String message) {
        this(status, message, null);
    }

    public PublicApiException(HttpStatus status, String message, String code) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus status() {
        return status;
    }

    public String errorCode() { return code; }
}
