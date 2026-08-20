package com.ferreplus.publico.exception;

import org.springframework.http.HttpStatus;

public class PublicApiException extends RuntimeException {
    private final HttpStatus status;

    public PublicApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }
}
