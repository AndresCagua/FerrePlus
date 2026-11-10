package com.ferreplus.publico.security;

import com.ferreplus.publico.model.KeyDocument;
import com.ferreplus.publico.repository.KeyDocumentRepository;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class KeyResolver {
    private final KeyDocumentRepository repository;
    private final S2sJwtProperties properties;
    private final Map<String, CachedKey> cache = new ConcurrentHashMap<>();
    private final Duration cacheTtl;
    private final Duration revalidationInterval;

    @Autowired
    public KeyResolver(KeyDocumentRepository repository, S2sJwtProperties properties,
                       @Value("${app.s2s.key-cache-ttl:5m}") Duration cacheTtl,
                       @Value("${app.s2s.key-cache-revalidation:30s}") Duration revalidationInterval) {
        this.repository = repository;
        this.properties = properties;
        this.cacheTtl = cacheTtl;
        this.revalidationInterval = revalidationInterval;
    }

    public KeyResolver(KeyDocumentRepository repository, S2sJwtProperties properties, Duration cacheTtl) {
        this(repository, properties, cacheTtl, Duration.ofSeconds(30));
    }

    public PublicKey resolve(String kid) {
        if (kid == null || kid.isBlank()) return null;
        Instant now = Instant.now();
        CachedKey cached = cache.get(kid);
        if (cached != null && cached.isUsable(now) && !cached.needsRevalidation(now)) return cached.key();

        KeyDocument document = repository.findByKidAndActivaTrue(kid).orElse(null);
        if (document != null && document.getExpiracion() != null && document.getExpiracion().isAfter(now)) {
            cached = cache.get(kid);
            if (cached != null && cached.validFor(document.getPublicKey(), document.getExpiracion(), now)) {
                cache.put(kid, cached.revalidated(now, revalidationInterval));
                return cached.key();
            }
            PublicKey key = parse(document.getPublicKey());
            cache.put(kid, new CachedKey(key, now.plus(cacheTtl), now.plus(revalidationInterval),
                    document.getExpiracion(), document.getPublicKey()));
            return key;
        }
        // Bootstrap is deliberately keyed by an external kid and never stores private material.
        if ("bootstrap".equals(kid) && ((properties.bootstrapPublicKey() != null && !properties.bootstrapPublicKey().isBlank())
                || (properties.bootstrapPublicKeyFile() != null && !properties.bootstrapPublicKeyFile().isBlank()))) {
            String pem = loadBootstrapKey();
            cached = cache.get(kid);
            if (cached != null && cached.isUsable(now) && !cached.needsRevalidation(now)
                    && cached.material().equals(pem)) return cached.key();
            PublicKey key = parse(pem);
            cache.put(kid, new CachedKey(key, now.plus(cacheTtl), now.plus(revalidationInterval), null, pem));
            return key;
        }
        cache.remove(kid);
        return null;
    }

    public void publish(String kid, String pem, Instant expiration) {
        PublicKey key = parse(pem);
        KeyDocument document = new KeyDocument();
        document.setKid(kid);
        document.setPublicKey(pem);
        document.setExpiracion(expiration);
        document.setActiva(true);
        repository.save(document);
        Instant now = Instant.now();
        cache.put(kid, new CachedKey(key, now.plus(cacheTtl), now.plus(revalidationInterval), expiration, pem));
    }

    private String loadBootstrapKey() {
        if (properties.bootstrapPublicKeyFile() != null && !properties.bootstrapPublicKeyFile().isBlank()) {
            try { return java.nio.file.Files.readString(java.nio.file.Path.of(properties.bootstrapPublicKeyFile())); }
            catch (java.io.IOException exception) { throw new IllegalStateException("No se pudo leer la public key S2S", exception); }
        }
        return properties.bootstrapPublicKey();
    }

    private PublicKey parse(String pem) {
        try {
            String normalized = pem.replace("-----BEGIN PUBLIC KEY-----", "")
                    .replace("-----END PUBLIC KEY-----", "")
                    .replaceAll("\\s", "");
            return KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(
                    Base64.getDecoder().decode(normalized.getBytes(StandardCharsets.US_ASCII))));
        } catch (Exception exception) {
            throw new IllegalArgumentException("Public key S2S invalida", exception);
        }
    }

    private record CachedKey(PublicKey key, Instant cacheUntil, Instant revalidateAt,
                             Instant persistedExpiration, String material) {
        boolean isUsable(Instant now) {
            return cacheUntil.isAfter(now)
                    && (persistedExpiration == null || persistedExpiration.isAfter(now));
        }
        boolean needsRevalidation(Instant now) { return !revalidateAt.isAfter(now); }
        boolean validFor(String currentMaterial, Instant currentExpiration, Instant now) {
            return isUsable(now) && material.equals(currentMaterial) && currentExpiration.equals(persistedExpiration);
        }
        CachedKey revalidated(Instant now, Duration interval) {
            return new CachedKey(key, cacheUntil, now.plus(interval), persistedExpiration, material);
        }
    }
}
