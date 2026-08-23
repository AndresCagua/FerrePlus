package com.ferreplus.publico.ratelimit;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.filter.OncePerRequestFilter;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.ReadListener;
import java.io.ByteArrayInputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import jakarta.servlet.http.HttpServletRequestWrapper;

@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private static final int MAX_EMAIL_BODY_BYTES = 64 * 1024;
    private final RateLimitService limits; private final ObjectMapper mapper; private final ClientIpResolver clientIpResolver;
    private final String fingerprintSecret;
    public RateLimitFilter(RateLimitService limits, ObjectMapper mapper, ClientIpResolver clientIpResolver,
                           @Value("${app.rate-limit.fingerprint-hmac-secret:}") String fingerprintSecret) {
        if (fingerprintSecret == null || fingerprintSecret.isBlank()) {
            throw new IllegalStateException("RATE_LIMIT_FINGERPRINT_HMAC_SECRET must be configured");
        }
        this.limits = limits; this.mapper = mapper; this.clientIpResolver = clientIpResolver;
        this.fingerprintSecret = fingerprintSecret;
    }
    @Override protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return !"POST".equalsIgnoreCase(request.getMethod()) || path.startsWith("/api/internal/")
                || !(path.matches("/api/public/convocatorias/[^/]+/postulaciones") || path.equals("/api/public/contactos"));
    }
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String operation = request.getServletPath().contains("postulaciones") ? "application" : "contact";
        boolean multipart = request.getContentType() != null
                && request.getContentType().toLowerCase(java.util.Locale.ROOT).startsWith("multipart/");
        // Multipart requests can contain CVs. Never consume or buffer them in this filter.
        HttpServletRequest rateLimitedRequest = multipart || !isSmallJson(request)
                ? request : new CachedBodyRequest(request);
        String parameterEmail = multipart ? null : rateLimitedRequest.getParameter("email");
        String identity = clientIpResolver.resolve(rateLimitedRequest);
        String fingerprint = normalizeFingerprint(rateLimitedRequest.getHeader("X-Fingerprint"));
        String email = multipart ? null : normalizeEmail(rateLimitedRequest, parameterEmail);
        RateLimitService.Decision decision = limits.allow(operation, identity, fingerprint, email);
        if (!decision.allowed()) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setHeader("Retry-After", String.valueOf(decision.retryAfter()));
            response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
            mapper.writeValue(response.getOutputStream(), Map.of("title", "Too Many Requests", "status", 429,
                    "detail", "Limite de solicitudes excedido"));
            return;
        }
        chain.doFilter(rateLimitedRequest, response);
    }

    private boolean isSmallJson(HttpServletRequest request) {
        String contentType = request.getContentType();
        return contentType != null
                && contentType.toLowerCase(java.util.Locale.ROOT).startsWith(MediaType.APPLICATION_JSON_VALUE)
                && request.getContentLengthLong() >= 0
                && request.getContentLengthLong() <= MAX_EMAIL_BODY_BYTES;
    }

    private String normalizeFingerprint(String value) {
        if (value == null) return null;
        String normalized = value.trim().toLowerCase(java.util.Locale.ROOT);
        if (!normalized.matches("[a-z0-9_-]{8,128}")) return null;
        try {
            var mac = javax.crypto.Mac.getInstance("HmacSHA256");
            mac.init(new javax.crypto.spec.SecretKeySpec(
                    fingerprintSecret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256"));
            return java.util.HexFormat.of().formatHex(mac.doFinal(normalized.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (java.security.GeneralSecurityException exception) {
            return null;
        }
    }

    private String normalizeEmail(HttpServletRequest request, String parameterEmail) {
        String value = parameterEmail;
        if (value == null && request.getContentType() != null
                && request.getContentType().startsWith(MediaType.APPLICATION_JSON_VALUE)) {
            try {
                value = mapper.readTree(request.getInputStream()).path("email").textValue();
            } catch (IOException ignored) {
                return null;
            }
        }
        if (value == null) return null;
        String normalized = value.trim().toLowerCase(java.util.Locale.ROOT);
        return normalized.matches("^[^@\\s]{1,254}@[^@\\s]{1,254}$") ?
                java.util.HexFormat.of().formatHex(hash(normalized)) : null;
    }

    private byte[] hash(String value) {
        try {
            var digest = java.security.MessageDigest.getInstance("SHA-256");
            return digest.digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (java.security.NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 no disponible", exception);
        }
    }

    private static final class CachedBodyRequest extends HttpServletRequestWrapper {
        private final byte[] body;

        private CachedBodyRequest(HttpServletRequest request) throws IOException {
            super(request);
            this.body = request.getInputStream().readNBytes(MAX_EMAIL_BODY_BYTES);
        }

        @Override public ServletInputStream getInputStream() {
            ByteArrayInputStream input = new ByteArrayInputStream(body);
            return new ServletInputStream() {
                @Override public int read() { return input.read(); }
                @Override public boolean isFinished() { return input.available() == 0; }
                @Override public boolean isReady() { return true; }
                @Override public void setReadListener(ReadListener listener) { }
            };
        }

        @Override public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(getInputStream(), StandardCharsets.UTF_8));
        }
    }
}
