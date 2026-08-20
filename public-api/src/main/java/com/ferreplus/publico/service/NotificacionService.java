package com.ferreplus.publico.service;

import com.ferreplus.publico.model.EstadoNotificacion;
import com.ferreplus.publico.model.Notificacion;
import com.ferreplus.publico.model.TipoDestinatario;
import com.ferreplus.publico.repository.NotificacionRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificacionService {
    private final NotificacionRepository repository;
    private final DestinatarioService destinatarios;

    public Notificacion pending(TipoDestinatario tipo, String referenciaId, String correlationId) {
        Notificacion item = new Notificacion(); item.setTipo(tipo); item.setReferenciaId(referenciaId);
        item.setDestinatarios(destinatarios.active(tipo).stream().map(d -> d.getEmail()).toList());
        item.setEstado(EstadoNotificacion.PENDING); item.setIntentos(0); item.setCorrelationId(correlationId);
        Instant now = Instant.now(); item.setCreatedAt(now); item.setUpdatedAt(now); return repository.save(item);
    }
    public Notificacion save(Notificacion item) { item.setUpdatedAt(Instant.now()); return repository.save(item); }
    public Notificacion find(String id) { return repository.findById(id).orElseThrow(() ->
            new com.ferreplus.publico.exception.PublicApiException(org.springframework.http.HttpStatus.NOT_FOUND, "Notificacion no encontrada")); }
    public List<Notificacion> failedOrPending() { return repository.findByEstado(EstadoNotificacion.FAILED); }
}
