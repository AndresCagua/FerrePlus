package com.ferreplus.exception;

import lombok.Getter;

@Getter
public class SeoSuggestionException extends RuntimeException {
    private final int statusCode;

    public SeoSuggestionException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public SeoSuggestionException(String message, int statusCode, Throwable cause) {
        super(message, cause);
        this.statusCode = statusCode;
    }
}
