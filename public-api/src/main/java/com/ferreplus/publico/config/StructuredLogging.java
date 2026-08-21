package com.ferreplus.publico.config;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.slf4j.Logger; import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
@Component
public class StructuredLogging extends OncePerRequestFilter {
    private static final Logger LOG = LoggerFactory.getLogger(StructuredLogging.class);
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        long started = System.nanoTime();
        try { chain.doFilter(request, response); }
        finally { LOG.info("{{\"service\":\"public-api\",\"event\":\"http.request\",\"correlationId\":\"{}\",\"route\":\"{}\",\"status\":{},\"durationMs\":{}}}", correlationId(), request.getRequestURI(), response.getStatus(), (System.nanoTime()-started)/1_000_000); }
    }

    private String correlationId() {
        String value = MDC.get("correlationId");
        return value == null ? "unknown" : value;
    }
}
