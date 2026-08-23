package com.ferreplus.publico.config;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.regex.Pattern;
import org.slf4j.MDC;

public final class SafeDiagnosticLog {
    private static final Pattern EMAIL = Pattern.compile("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}");
    private static final Pattern SECRET = Pattern.compile("(?i)(secret|token|password|authorization)=([^&\\s]+)");

    private SafeDiagnosticLog() {}

    public static String correlationId(String fallback) {
        String value = MDC.get("correlationId");
        return value == null || value.isBlank() ? fallback : value;
    }

    public static String emailDomain(String email) {
        if (email == null || !email.contains("@")) return "unknown";
        return email.substring(email.lastIndexOf('@') + 1).toLowerCase();
    }

    public static String opaque(String value) {
        if (value == null || value.isBlank()) return "none";
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8))).substring(0, 16);
        } catch (Exception exception) {
            return "unavailable";
        }
    }

    public static String failure(Exception exception) {
        String message = exception.getMessage() == null ? "none" : exception.getMessage();
        message = SECRET.matcher(message).replaceAll("$1=[redacted]");
        message = EMAIL.matcher(message).replaceAll("[email-redacted]");
        String safe = (exception.getClass().getSimpleName() + ": " + message).replaceAll("[\\r\\n]", " ");
        return safe.substring(0, Math.min(500, safe.length()));
    }
}
