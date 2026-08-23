package com.ferreplus.publico.security;

import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class KeyService {
    private final KeyResolver resolver;
    public KeyService(KeyResolver resolver) { this.resolver = resolver; }
    public void publish(String kid, String publicKey, Instant expiration) {
        if (kid == null || !kid.matches("[A-Za-z0-9._-]{1,64}") || expiration == null || expiration.isBefore(Instant.now()))
            throw new IllegalArgumentException("Clave S2S invalida");
        resolver.publish(kid, publicKey, expiration);
    }
}
