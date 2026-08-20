package com.ferreplus.publico.service;

import com.ferreplus.publico.dto.publico.PostulacionRequestDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.CvMetadata;
import com.ferreplus.publico.model.EstadoPostulacion;
import com.ferreplus.publico.model.Postulacion;
import com.ferreplus.publico.repository.PostulacionRepository;
import com.ferreplus.publico.storage.CvFileValidator;
import com.ferreplus.publico.storage.MinioObjectStorage;
import com.ferreplus.publico.service.ObjectCleanupService;
import java.time.Instant;
import java.util.ArrayList;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.context.ApplicationEventPublisher;

@Service
@RequiredArgsConstructor
public class PostulacionService {
    private final PostulacionRepository repository;
    private final ConvocatoriaService convocatoriaService;
    private final CvFileValidator validator;
    private final MinioObjectStorage storage;
    private final ObjectCleanupService cleanup;
    private final PostulacionStateMachine stateMachine;
    private final ApplicationEventPublisher events;

    public Postulacion create(String convocatoriaId, PostulacionRequestDTO request, MultipartFile cv,
                              String idempotencyKey) {
        if (idempotencyKey == null || !idempotencyKey.matches("[A-Za-z0-9._-]{8,128}"))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "Idempotency-Key invalida");
        var previous = repository.findByConvocatoriaIdAndIdempotencyKey(convocatoriaId, idempotencyKey);
        if (previous.isPresent()) return previous.get();
        Convocatoria convocatoria = convocatoriaService.find(convocatoriaId);
        if (!convocatoriaService.estaAbierta(convocatoria))
            throw new PublicApiException(HttpStatus.CONFLICT, "La convocatoria esta cerrada");
        if (request.honeypot() != null && !request.honeypot().isBlank())
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "No fue posible procesar la postulacion");
        var valid = validator.validate(cv);
        String key = UUID.randomUUID() + "." + valid.extension();
        try {
            storage.put(storage.cvBucket(), key, cv.getInputStream(), valid.size(), valid.mimeType());
            Instant now = Instant.now();
            Postulacion item = new Postulacion();
            item.setConvocatoriaId(convocatoriaId); item.setNombres(request.nombres()); item.setApellidos(request.apellidos());
            item.setEmail(request.email()); item.setTelefono(request.telefono()); item.setCiudad(request.ciudad());
            item.setCv(new CvMetadata(key, valid.fileName(), valid.mimeType(), valid.size(), now));
            item.setEstado(EstadoPostulacion.RECEIVED); item.setIdempotencyKey(idempotencyKey);
            item.setHistorial(new ArrayList<>(java.util.List.of(new Postulacion.HistorialEstado("system", now, null, "RECEIVED"))));
            item.setCreatedAt(now); item.setUpdatedAt(now);
            Postulacion saved = repository.save(item);
            events.publishEvent(new com.ferreplus.publico.event.PostulacionReceivedEvent(
                    saved.getId(), saved.getEmail(), correlationId()));
            return saved;
        } catch (Exception exception) {
            cleanup.cleanup(storage.cvBucket(), key);
            if (exception instanceof PublicApiException apiException) throw apiException;
            throw new PublicApiException(HttpStatus.INTERNAL_SERVER_ERROR, "No fue posible registrar la postulacion");
        }
    }
    public java.util.List<Postulacion> byConvocatoria(String convocatoriaId) { return repository.findByConvocatoriaId(convocatoriaId); }
    public Postulacion find(String id) { return repository.findById(id).orElseThrow(() ->
            new PublicApiException(HttpStatus.NOT_FOUND, "Postulacion no encontrada")); }
    public Postulacion transition(String id, EstadoPostulacion target, String actor) {
        Postulacion item = find(id); stateMachine.validate(item.getEstado(), target);
        Instant now = Instant.now();
        item.getHistorial().add(new Postulacion.HistorialEstado(actor, now, item.getEstado().name(), target.name()));
        item.setEstado(target); item.setUpdatedAt(now); return repository.save(item);
    }
    private String correlationId() { String value = org.slf4j.MDC.get("correlationId"); return value == null ? "unknown" : value; }
}
