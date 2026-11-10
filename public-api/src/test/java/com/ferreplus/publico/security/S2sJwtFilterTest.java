package com.ferreplus.publico.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Jwts;
import jakarta.servlet.FilterChain;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class S2sJwtFilterTest {
    private KeyPair pair;
    private KeyResolver resolver;
    private S2sJwtFilter filter;
    private FilterChain chain;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        pair = generator.generateKeyPair();
        resolver = mock(KeyResolver.class);
        when(resolver.resolve("test-key")).thenReturn(pair.getPublic());
        filter = new S2sJwtFilter(resolver,
                new S2sJwtProperties("ferreplus-admin-api", "ferreplus-public-api", "", "", Duration.ZERO),
                new ObjectMapper());
        chain = mock(FilterChain.class);
    }

    @Test
    void tokenValidoPermiteInternal() throws Exception {
        MockHttpServletResponse response = invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "public-api.internal"));
        verify(chain).doFilter(any(), any());
        assertThat(response.getStatus()).isEqualTo(200);
    }

    @Test
    void ausenciaFirmaExpiracionAudienciaKidYSscopeRechazan() throws Exception {
        assertThat(invoke(null).getStatus()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
        assertThat(invoke(token(Instant.now().plusSeconds(60), "wrong", "test-key", "public-api.internal")).getStatus()).isEqualTo(401);
        assertThat(invoke(token(Instant.now().minusSeconds(1), "ferreplus-public-api", "test-key", "public-api.internal")).getStatus()).isEqualTo(401);
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "unknown", "public-api.internal")).getStatus()).isEqualTo(401);
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "other")).getStatus()).isEqualTo(403);
    }

    @Test
    void scopeDebeCoincidirComoTokenCompleto() throws Exception {
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "public-api.internal.read")).getStatus())
                .isEqualTo(HttpStatus.FORBIDDEN.value());
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "admin-public-api.internal-tools")).getStatus())
                .isEqualTo(HttpStatus.FORBIDDEN.value());
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "other public-api.internal read")).getStatus())
                .isEqualTo(HttpStatus.OK.value());
    }

    @Test
    void claveAnteriorYActivaSeResuelvenPorKid() throws Exception {
        KeyPairGenerator generator;
        try { generator = KeyPairGenerator.getInstance("RSA"); generator.initialize(2048); }
        catch (Exception exception) { throw new AssertionError(exception); }
        KeyPair previous = generator.generateKeyPair();
        when(resolver.resolve("previous")).thenReturn(previous.getPublic());
        assertThat(invoke(token(Instant.now().plusSeconds(60), "ferreplus-public-api", "test-key", "public-api.internal")).getStatus()).isEqualTo(200);
        assertThat(invoke(token(previous, Instant.now().plusSeconds(60), "ferreplus-public-api", "previous", "public-api.internal")).getStatus()).isEqualTo(200);
    }

    private MockHttpServletResponse invoke(String token) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/internal/ping");
        request.setServletPath("/api/internal/ping");
        if (token != null) request.addHeader("Authorization", "Bearer " + token);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        return response;
    }

    private String token(Instant expiration, String audience, String kid, String scope) {
        return token(pair, expiration, audience, kid, scope);
    }
    private String token(KeyPair signingPair, Instant expiration, String audience, String kid, String scope) {
        Instant now = Instant.now();
        return Jwts.builder().issuer("ferreplus-admin-api").audience().add(audience).and().subject("admin-api")
                .issuedAt(Date.from(now)).expiration(Date.from(expiration)).id("runtime-test-jti")
                .claim("scope", scope).header().add("kid", kid).and().signWith(signingPair.getPrivate()).compact();
    }
}
