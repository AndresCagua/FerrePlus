package com.ferreplus.publico.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.ferreplus.publico.model.KeyDocument;
import com.ferreplus.publico.repository.KeyDocumentRepository;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class KeyResolverTest {
    private KeyDocumentRepository repository;
    private KeyResolver resolver;
    private KeyDocument document;
    private String pem;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        KeyPair pair = generator.generateKeyPair();
        pem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getMimeEncoder(64, new byte[] {'\n'}).encodeToString(pair.getPublic().getEncoded())
                + "\n-----END PUBLIC KEY-----";
        repository = mock(KeyDocumentRepository.class);
        document = new KeyDocument();
        document.setKid("test-key");
        document.setPublicKey(pem);
        document.setActiva(true);
        document.setExpiracion(Instant.now().plusSeconds(30));
        when(repository.findByKidAndActivaTrue("test-key")).thenReturn(Optional.of(document));
        resolver = new KeyResolver(repository,
                new S2sJwtProperties("issuer", "audience", "", "", Duration.ZERO),
                Duration.ofMinutes(5), Duration.ZERO);
    }

    @Test
    void cachedKeyIsRejectedAfterPersistedExpiration() throws Exception {
        assertThat(resolver.resolve("test-key")).isNotNull();
        document.setExpiracion(Instant.now().minusSeconds(1));
        when(repository.findByKidAndActivaTrue("test-key")).thenReturn(Optional.empty());

        assertThat(resolver.resolve("test-key")).isNull();
        verify(repository, times(2)).findByKidAndActivaTrue("test-key");
    }

    @Test
    void cachedKeyIsRejectedWhenPersistedKeyIsDeactivated() {
        assertThat(resolver.resolve("test-key")).isNotNull();
        when(repository.findByKidAndActivaTrue("test-key")).thenReturn(Optional.empty());

        assertThat(resolver.resolve("test-key")).isNull();
        verify(repository, times(2)).findByKidAndActivaTrue("test-key");
    }
}
