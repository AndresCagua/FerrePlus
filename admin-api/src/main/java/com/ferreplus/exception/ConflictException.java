package com.ferreplus.exception;

/**
 * Conflicto de estado (HTTP 409): p. ej. intento de eliminar un rol asignado a
 * usuarios activos (R3).
 */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
