package com.ferreplus.client.publico;

import io.jsonwebtoken.Jwts;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.time.Duration;
import java.util.Base64;
import java.util.Date;
import java.util.Objects;
import java.util.UUID;
import java.net.http.HttpClient;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.http.MediaType;
import org.springframework.http.HttpEntity;
import org.springframework.core.io.Resource;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

@Service
@EnableConfigurationProperties(S2sJwtProperties.class)
public class PublicApiClient {
    private final RestClient client; private final S2sJwtProperties properties;
    private volatile CachedSigningKey cachedSigningKey;

    @Autowired
    public PublicApiClient(RestClient.Builder builder, S2sJwtProperties properties) {
        this.client = builder.requestFactory(requestFactory()).baseUrl(properties.publicApiUrl()).build(); this.properties = properties;
        this.cachedSigningKey = loadSigningKey(keySource());
    }
    PublicApiClient(RestClient client, S2sJwtProperties properties) {
        this.client = client; this.properties = properties;
        this.cachedSigningKey = loadSigningKey(keySource());
    }

    static ClientHttpRequestFactory requestFactory() {
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(1))
                .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofSeconds(3));
        return factory;
    }
    public <T> T exchange(HttpMethod method, String path, Object body, Class<T> responseType, String correlationId) {
        var request = client.method(method).uri(path).header(HttpHeaders.AUTHORIZATION, "Bearer " + token())
                .header("X-Correlation-ID", correlationId == null ? UUID.randomUUID().toString() : correlationId);
        try {
            if (body == null) return request.retrieve().body(responseType);
            return request.body(body).retrieve().body(responseType);
        } catch (HttpClientErrorException.Conflict exception) {
            throw new PublicApiConflictException("Conflicto en public-api", exception);
        } catch (HttpClientErrorException.BadRequest exception) {
            throw new PublicApiValidationException("Solicitud invalida en public-api", exception);
        } catch (HttpClientErrorException exception) {
            throw new PublicApiHttpException(exception.getStatusCode(), "Respuesta rechazada por public-api", exception);
        } catch (HttpServerErrorException exception) {
            throw new PublicApiUnavailableException("public-api no disponible", exception);
        } catch (RestClientException exception) {
            throw new PublicApiUnavailableException("public-api no disponible", exception);
        }
    }

    public <T> T exchangeMultipart(HttpMethod method, String path, String json, MultipartFile portada,
                                    List<MultipartFile> galeria, Class<T> responseType, String correlationId) {
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        HttpHeaders dataHeaders = new HttpHeaders(); dataHeaders.setContentType(MediaType.APPLICATION_JSON);
        form.add("data", new HttpEntity<>(json, dataHeaders));
        addFile(form, "portada", portada);
        if (galeria != null) galeria.forEach(file -> addFile(form, "galeria", file));
        var request = client.method(method).uri(path).header(HttpHeaders.AUTHORIZATION, "Bearer " + token())
                .header("X-Correlation-ID", correlationId == null ? UUID.randomUUID().toString() : correlationId)
                .contentType(MediaType.MULTIPART_FORM_DATA);
        try {
            return request.body(form).retrieve().body(responseType);
        } catch (HttpClientErrorException.BadRequest exception) {
            throw new PublicApiValidationException("Solicitud invalida en public-api", exception);
        } catch (HttpClientErrorException exception) {
            throw new PublicApiHttpException(exception.getStatusCode(), "Respuesta rechazada por public-api", exception);
        } catch (RestClientException exception) {
            throw new PublicApiUnavailableException("public-api no disponible", exception);
        }
    }

    private void addFile(MultiValueMap<String, Object> form, String name, MultipartFile file) {
        if (file == null || file.isEmpty()) return;
        HttpHeaders headers = new HttpHeaders();
        headers.setContentDispositionFormData(name, file.getOriginalFilename());
        headers.setContentType(file.getContentType() == null ? MediaType.APPLICATION_OCTET_STREAM : safeMediaType(file.getContentType()));
        form.add(name, new HttpEntity<Resource>(file.getResource(), headers));
    }

    private MediaType safeMediaType(String value) {
        try { return MediaType.parseMediaType(value); }
        catch (IllegalArgumentException exception) { return MediaType.APPLICATION_OCTET_STREAM; }
    }
    private String token() {
        try {
            PrivateKey key = signingKey();
            Instant now = Instant.now();
            return Jwts.builder().issuer(properties.issuer()).audience().add(properties.audience()).and().subject(properties.subject())
                    .id(UUID.randomUUID().toString()).issuedAt(Date.from(now)).expiration(Date.from(now.plus(properties.tokenLifetime())))
                    .claim("scope", "public-api.internal")
                    .claim("actor", actor())
                    .header().add("kid", properties.keyId()).and().signWith(key).compact();
        } catch (Exception exception) { throw new PublicApiUnavailableException("No se pudo firmar la solicitud interna", exception); }
    }

    private String actor() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication == null || authentication.getName() == null || authentication.getName().isBlank()
                ? "admin-api" : authentication.getName();
    }

    /** Invalida la clave cacheada despues de una rotacion de secretos inline. */
    public void refreshSigningKey() { cachedSigningKey = null; }

    private PrivateKey signingKey() {
        KeySource source = keySource();
        CachedSigningKey current = cachedSigningKey;
        if (current != null && current.matches(source, properties.keyId())) return current.key();
        synchronized (this) {
            current = cachedSigningKey;
            if (current == null || !current.matches(source, properties.keyId())) {
                current = loadSigningKey(source);
                cachedSigningKey = current;
            }
            return current.key();
        }
    }

    private KeySource keySource() {
        if (properties.privateKeyFile() == null || properties.privateKeyFile().isBlank()) return KeySource.inline();
        try {
            Path path = Path.of(properties.privateKeyFile());
            return new KeySource(path, Files.getLastModifiedTime(path), Files.size(path));
        } catch (Exception exception) { throw new PublicApiUnavailableException("No se pudo inspeccionar la clave interna", exception); }
    }

    private CachedSigningKey loadSigningKey(KeySource source) {
        try {
            String pem = source.path() == null ? properties.privateKey() : Files.readString(source.path());
            String normalized = pem.replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "").replaceAll("\\s", "");
            PrivateKey key = KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(normalized)));
            return new CachedSigningKey(source, properties.keyId(), key);
        } catch (Exception exception) { throw new PublicApiUnavailableException("No se pudo cargar la clave interna", exception); }
    }

    private record KeySource(Path path, FileTime modifiedAt, long size) {
        static KeySource inline() { return new KeySource(null, null, -1); }
    }

    private record CachedSigningKey(KeySource source, String keyId, PrivateKey key) {
        boolean matches(KeySource candidate, String candidateKeyId) {
            return Objects.equals(keyId, candidateKeyId) && source.equals(candidate);
        }
    }
    public static class PublicApiUnavailableException extends RuntimeException { public PublicApiUnavailableException(String message, Throwable cause) { super(message, cause); } }
    public static class PublicApiValidationException extends RuntimeException { public PublicApiValidationException(String message, Throwable cause) { super(message, cause); } }
    public static class PublicApiConflictException extends RuntimeException { public PublicApiConflictException(String message, Throwable cause) { super(message, cause); } }
    public static class PublicApiHttpException extends RuntimeException {
        private final org.springframework.http.HttpStatusCode status;
        public PublicApiHttpException(org.springframework.http.HttpStatusCode status, String message, Throwable cause) { super(message, cause); this.status = status; }
        public org.springframework.http.HttpStatusCode status() { return status; }
    }
}
