package com.ferreplus.publico.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.security.PublicKey;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class S2sJwtFilter extends OncePerRequestFilter {
    private final KeyResolver keys;
    private final S2sJwtProperties properties;
    private final ObjectMapper mapper;

    public S2sJwtFilter(KeyResolver keys, S2sJwtProperties properties, ObjectMapper mapper) {
        this.keys = keys; this.properties = properties; this.mapper = mapper;
    }

    @Override protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getServletPath().startsWith("/api/internal/");
    }

    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                               FilterChain chain) throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) throw new SecurityFailure(HttpStatus.UNAUTHORIZED);
            String token = authorization.substring(7);
            String header = new String(java.util.Base64.getUrlDecoder().decode(token.substring(0, token.indexOf('.'))), java.nio.charset.StandardCharsets.UTF_8);
            String kid = mapper.readTree(header).path("kid").textValue();
            PublicKey key = keys.resolve(kid);
            if (key == null) throw new SecurityFailure(HttpStatus.UNAUTHORIZED);
            Jws<Claims> parsed = Jwts.parser().verifyWith(key).requireIssuer(properties.issuer())
                    .requireAudience(properties.audience()).clockSkewSeconds(properties.clockSkew().toSeconds())
                    .build().parseSignedClaims(token);
            Claims claims = parsed.getPayload();
            if (!"admin-api".equals(claims.getSubject()) || claims.getExpiration() == null
                    || claims.getExpiration().toInstant().isBefore(Instant.now())) throw new SecurityFailure(HttpStatus.UNAUTHORIZED);
            String scope = claims.get("scope", String.class);
            if (scope == null || java.util.Arrays.stream(scope.trim().split("\\s+"))
                    .noneMatch("public-api.internal"::equals)) throw new SecurityFailure(HttpStatus.FORBIDDEN);
            String actor = claims.get("actor", String.class);
            String authenticatedActor = actor == null || actor.isBlank() ? claims.getSubject() : actor;
            SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                    authenticatedActor, claims, java.util.Arrays.stream(scope.split(" "))
                            .map(value -> new org.springframework.security.core.authority.SimpleGrantedAuthority("SCOPE_" + value)).toList()));
            chain.doFilter(request, response);
        } catch (SecurityFailure failure) { reject(response, failure.status); }
          catch (Exception failure) { SecurityContextHolder.clearContext(); reject(response, HttpStatus.UNAUTHORIZED); }
        finally { SecurityContextHolder.clearContext(); }
    }

    private void reject(HttpServletResponse response, HttpStatus status) throws IOException {
        response.setStatus(status.value()); response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        mapper.writeValue(response.getOutputStream(), Map.of("type", "https://api.ferreplus.com/problems/" + status.value(),
                "title", status.getReasonPhrase(), "status", status.value(), "detail", "Autenticacion S2S rechazada"));
    }
    private static final class SecurityFailure extends RuntimeException { private final HttpStatus status; SecurityFailure(HttpStatus status) { this.status = status; } }
}
