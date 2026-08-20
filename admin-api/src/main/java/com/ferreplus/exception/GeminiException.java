package com.ferreplus.exception;

import lombok.Getter;

@Getter
public class GeminiException extends RuntimeException {

    private final int statusCode;

    public GeminiException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public GeminiException(String message, int statusCode, Throwable cause) {
        super(message, cause);
        this.statusCode = statusCode;
    }

    public boolean isRateLimited() {
        return statusCode == 429;
    }
}
