package com.ferreplus.publico.service;

import com.ferreplus.publico.dto.interno.ContactoAdminDTO;
import com.ferreplus.publico.dto.publico.ContactoRequestDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.Contacto;
import com.ferreplus.publico.repository.ContactoRepository;
import com.ferreplus.publico.event.ContactoReceivedEvent;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import jakarta.servlet.http.HttpServletRequest;
import com.ferreplus.publico.ratelimit.ClientIpResolver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.ferreplus.publico.config.SafeDiagnosticLog;

@Service
@RequiredArgsConstructor
public class ContactoService {
    private static final Logger LOG = LoggerFactory.getLogger(ContactoService.class);
    private final ContactoRepository repository;
    private final ApplicationEventPublisher events;
    private final CaptchaVerificationService captcha;
    private final ClientIpResolver clientIpResolver;

    public Contacto create(ContactoRequestDTO request, String key, HttpServletRequest httpRequest, String fingerprint) {
        validateKey(key);
        var previous = repository.findByIdempotencyKey(key);
        if (previous.isPresent()) {
            LOG.info("contact.persisted outcome=idempotent_replay contactId={} correlationId={} idempotencyKey={}",
                    previous.get().getId(), SafeDiagnosticLog.correlationId("unknown"), SafeDiagnosticLog.opaque(key));
            return previous.get();
        }
        if (request.honeypot() != null && !request.honeypot().isBlank())
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "No fue posible procesar el contacto");
        captcha.verify(request.captchaToken());
        Instant now = Instant.now();
        Contacto item = new Contacto(); item.setNombre(request.nombre()); item.setEmail(request.email().trim().toLowerCase());
        item.setTelefono(request.telefono()); item.setAsunto(request.asunto()); item.setMensaje(request.mensaje());
        item.setEstado(Contacto.EstadoContacto.UNREAD); item.setIp(hash(clientIpResolver.resolve(httpRequest))); item.setFingerprint(hash(fingerprint));
        item.setIdempotencyKey(key); item.setCreatedAt(now); item.setUpdatedAt(now);
        final Contacto saved;
        try {
            saved = repository.save(item);
        } catch (org.springframework.dao.DuplicateKeyException duplicate) {
            var concurrent = repository.findByIdempotencyKey(key).orElseThrow(() -> duplicate);
            LOG.info("contact.persisted outcome=idempotent_race contactId={} correlationId={} idempotencyKey={}",
                    concurrent.getId(), SafeDiagnosticLog.correlationId("unknown"), SafeDiagnosticLog.opaque(key));
            return concurrent;
        }
        LOG.info("contact.persisted outcome=created contactId={} correlationId={} emailDomain={} messageLength={}",
                saved.getId(), SafeDiagnosticLog.correlationId("unknown"), SafeDiagnosticLog.emailDomain(saved.getEmail()), saved.getMensaje().length());
        events.publishEvent(new ContactoReceivedEvent(saved.getId(), saved.getEmail(), currentCorrelationId()));
        return saved;
    }
    public List<Contacto> all(Contacto.EstadoContacto estado) {
        return estado == null ? repository.findAllByOrderByCreatedAtDesc() : repository.findByEstadoOrderByCreatedAtDesc(estado);
    }
    public Contacto update(String id, ContactoAdminDTO dto) {
        Contacto item = repository.findById(id).orElseThrow(() -> notFound());
        item.setEstado(dto.estado()); item.setUpdatedAt(Instant.now()); return repository.save(item);
    }
    private void validateKey(String key) {
        if (key == null || !key.matches("[A-Za-z0-9._-]{8,128}"))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "Idempotency-Key invalida");
    }
    private String hash(String value) { if (value == null || value.isBlank()) return null; try {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) { throw new IllegalStateException("No fue posible proteger el identificador", e); } }
    private String currentCorrelationId() { String value = org.slf4j.MDC.get("correlationId"); return value == null ? "unknown" : value; }
    private PublicApiException notFound() { return new PublicApiException(HttpStatus.NOT_FOUND, "Contacto no encontrado"); }
}
