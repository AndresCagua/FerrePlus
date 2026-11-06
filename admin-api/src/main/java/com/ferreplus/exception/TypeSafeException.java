package com.ferreplus.exception;

import lombok.Getter;

@Getter
public class TypeSafeException extends RuntimeException {
    private final int statusCode;

    public TypeSafeException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public TypeSafeException(String message, int statusCode, Throwable cause) {
        super(message, cause);
        this.statusCode = statusCode;
    }
}
