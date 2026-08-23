package com.ferreplus.publico.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class SafeDiagnosticLogTest {
    @Test
    void sanitizaCorreoYSecretosDeErroresExternos() {
        String safe = SafeDiagnosticLog.failure(new IllegalStateException(
                "SMTP rejected user@example.com secret=abc123 token=private\nnext"));

        assertThat(safe).doesNotContain("user@example.com", "abc123", "private", "\n");
        assertThat(safe).contains("email-redacted", "[redacted]");
    }

    @Test
    void soloExponeDominioYLongitudesFueraDeLaDireccion() {
        assertThat(SafeDiagnosticLog.emailDomain("person@example.com")).isEqualTo("example.com");
        assertThat(SafeDiagnosticLog.opaque("Idempotency-Key-1")).hasSize(16);
    }
}
