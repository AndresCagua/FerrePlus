package com.ferreplus.config;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
@Component
public class CorrelationIdFilter extends OncePerRequestFilter {
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        String id = request.getHeader("X-Correlation-ID"); if (id == null || !id.matches("[A-Za-z0-9._:-]{1,128}")) id = UUID.randomUUID().toString();
        response.setHeader("X-Correlation-ID", id); MDC.put("correlationId", id);
        try { chain.doFilter(request, response); } finally { MDC.remove("correlationId"); }
    }
}
