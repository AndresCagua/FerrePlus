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
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private final RateLimitService limits; private final ObjectMapper mapper;
    public RateLimitFilter(RateLimitService limits, ObjectMapper mapper) { this.limits = limits; this.mapper = mapper; }
    @Override protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return !"POST".equalsIgnoreCase(request.getMethod()) || path.startsWith("/api/internal/")
                || !(path.matches("/api/public/convocatorias/[^/]+/postulaciones") || path.equals("/api/public/contactos"));
    }
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String operation = request.getServletPath().contains("postulaciones") ? "application" : "contact";
        String identity = request.getRemoteAddr() + ":" + fingerprint(request.getHeader("X-Fingerprint"));
        RateLimitService.Decision decision = limits.allow(operation, identity);
        if (!decision.allowed()) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setHeader("Retry-After", String.valueOf(decision.retryAfter()));
            response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
            mapper.writeValue(response.getOutputStream(), Map.of("title", "Too Many Requests", "status", 429,
                    "detail", "Limite de solicitudes excedido"));
            return;
        }
        chain.doFilter(request, response);
    }
    private String fingerprint(String value) { return value == null || value.length() > 128 ? "none" : value.replaceAll("[^A-Za-z0-9._:-]", "_"); }
}
