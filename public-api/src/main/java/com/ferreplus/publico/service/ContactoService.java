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

@Service
@RequiredArgsConstructor
public class ContactoService {
    private final ContactoRepository repository;
    private final ApplicationEventPublisher events;

    public Contacto create(ContactoRequestDTO request, String key, String ip, String fingerprint) {
        validateKey(key);
        var previous = repository.findByIdempotencyKey(key);
        if (previous.isPresent()) return previous.get();
        if (request.honeypot() != null && !request.honeypot().isBlank())
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "No fue posible procesar el contacto");
        Instant now = Instant.now();
        Contacto item = new Contacto(); item.setNombre(request.nombre()); item.setEmail(request.email().trim().toLowerCase());
        item.setTelefono(request.telefono()); item.setAsunto(request.asunto()); item.setMensaje(request.mensaje());
        item.setEstado(Contacto.EstadoContacto.UNREAD); item.setIp(hash(ip)); item.setFingerprint(hash(fingerprint));
        item.setIdempotencyKey(key); item.setCreatedAt(now); item.setUpdatedAt(now);
        Contacto saved = repository.save(item);
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
