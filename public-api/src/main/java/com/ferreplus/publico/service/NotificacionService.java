package com.ferreplus.publico.service;

import com.ferreplus.publico.model.EstadoNotificacion;
import com.ferreplus.publico.model.Notificacion;
import com.ferreplus.publico.model.TipoDestinatario;
import com.ferreplus.publico.repository.NotificacionRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.ferreplus.publico.config.SafeDiagnosticLog;

@Service
@RequiredArgsConstructor
public class NotificacionService {
    private static final Logger LOG = LoggerFactory.getLogger(NotificacionService.class);
    private final NotificacionRepository repository;
    private final DestinatarioService destinatarios;

    public Notificacion pending(TipoDestinatario tipo, String referenciaId, String correlationId) {
        Notificacion item = new Notificacion(); item.setTipo(tipo); item.setReferenciaId(referenciaId);
        item.setDestinatarios(destinatarios.active(tipo).stream().map(d -> d.getEmail()).toList());
        item.setEstado(EstadoNotificacion.PENDING); item.setIntentos(0); item.setCorrelationId(correlationId);
        Instant now = Instant.now(); item.setCreatedAt(now); item.setUpdatedAt(now);
        var saved = repository.save(item);
        LOG.info("notification.created notificationId={} type={} status={} attemptCount={} recipientCount={} correlationId={}",
                saved.getId(), saved.getTipo(), saved.getEstado(), saved.getIntentos(), saved.getDestinatarios().size(),
                SafeDiagnosticLog.correlationId(correlationId));
        return saved;
    }
    public Notificacion pendingToRecipient(TipoDestinatario tipo, String referenciaId, String recipient, String correlationId) {
        Notificacion item = new Notificacion(); item.setTipo(tipo); item.setReferenciaId(referenciaId);
        item.setDestinatarios(recipient == null || recipient.isBlank() ? List.of() : List.of(recipient));
        item.setEstado(EstadoNotificacion.PENDING); item.setIntentos(0); item.setCorrelationId(correlationId);
        Instant now = Instant.now(); item.setCreatedAt(now); item.setUpdatedAt(now);
        var saved = repository.save(item);
        LOG.info("notification.created notificationId={} type={} status={} attemptCount={} recipientCount={} correlationId={}",
                saved.getId(), saved.getTipo(), saved.getEstado(), saved.getIntentos(), saved.getDestinatarios().size(),
                SafeDiagnosticLog.correlationId(correlationId));
        return saved;
    }
    public Notificacion save(Notificacion item) { item.setUpdatedAt(Instant.now()); return repository.save(item); }
    public Notificacion find(String id) { return repository.findById(id).orElseThrow(() ->
            new com.ferreplus.publico.exception.PublicApiException(org.springframework.http.HttpStatus.NOT_FOUND, "Notificacion no encontrada")); }
    public List<Notificacion> failedOrPending() { return repository.findByEstado(EstadoNotificacion.FAILED); }
    public List<Notificacion> dueForRetry(Instant now) {
        var states = List.of(EstadoNotificacion.PENDING, EstadoNotificacion.FAILED);
        var due = new java.util.ArrayList<>(repository.findTop20ByEstadoInAndNextAttemptAtLessThanEqualOrderByNextAttemptAtAsc(states, now));
        repository.findTop20ByEstadoInAndNextAttemptAtIsNullOrderByCreatedAtAsc(states).stream()
                .filter(item -> !due.stream().anyMatch(existing -> existing.getId().equals(item.getId())))
                .limit(Math.max(0, 20 - due.size())).forEach(due::add);
        return due;
    }
}
