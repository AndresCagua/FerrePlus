package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.publico.PostulacionRequestDTO;
import com.ferreplus.publico.dto.publico.PostulacionPublicaDTO;
import com.ferreplus.publico.dto.publico.ContactoRequestDTO;
import com.ferreplus.publico.dto.publico.ContactoPublicoDTO;
import com.ferreplus.publico.service.PublicacionService;
import com.ferreplus.publico.service.ContactoService;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.PostulacionService;
import com.ferreplus.publico.storage.MinioObjectStorage;
import com.ferreplus.publico.storage.ObjectStorage.StoredObject;
import com.ferreplus.publico.config.SafeDiagnosticLog;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.InputStreamResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/public")
public class PublicController {
    private static final Logger LOG = LoggerFactory.getLogger(PublicController.class);
    private final ConvocatoriaService convocatoriaService;
    private final PostulacionService postulacionService;
    private final PublicacionService publicacionService;
    private final ContactoService contactoService;
    private final MinioObjectStorage storage;

    @GetMapping("/ping") public Map<String, String> ping() { return Map.of("service", "public-api", "status", "ok"); }
    @GetMapping("/publicaciones") public Object publicaciones() { return publicacionService.publicas(); }
    @GetMapping("/publicaciones/{slug}") public Object publicacion(@PathVariable String slug) { return publicacionService.publica(slug); }
    @GetMapping("/media/{objectKey:.+}")
    public org.springframework.http.ResponseEntity<InputStreamResource> media(@PathVariable String objectKey) {
        if (!objectKey.matches("[0-9a-fA-F-]{36}\\.(jpg|png|webp)"))
            throw new com.ferreplus.publico.exception.PublicApiException(HttpStatus.NOT_FOUND, "Media no encontrada");
        final StoredObject object;
        try { object = storage.get(storage.mediaBucket(), objectKey); }
        catch (MinioObjectStorage.StorageException exception) {
            throw new com.ferreplus.publico.exception.PublicApiException(HttpStatus.NOT_FOUND, "Media no encontrada");
        }
        return org.springframework.http.ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(object.contentType()))
                .contentLength(object.size()).body(new InputStreamResource(object.stream()));
    }
    @GetMapping("/convocatorias") public List<?> convocatorias() { return convocatoriaService.publicas(); }
    @GetMapping("/convocatorias/{id}") public Object convocatoria(@PathVariable String id) { return convocatoriaService.publica(id); }

    @PostMapping(value = "/convocatorias/{id}/postulaciones", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public PostulacionPublicaDTO postulacion(@PathVariable String id,
            @RequestPart("data") @Valid PostulacionRequestDTO request,
            @RequestPart("cv") MultipartFile cv,
            @RequestHeader("Idempotency-Key") String idempotencyKey) {
        var result = postulacionService.create(id, request, cv, idempotencyKey);
        return new PostulacionPublicaDTO(result.getId(), result.getConvocatoriaId(), result.getEstado(), result.getCreatedAt());
    }

    @PostMapping("/contactos")
    @ResponseStatus(HttpStatus.CREATED)
    public ContactoPublicoDTO contacto(@Valid @RequestBody ContactoRequestDTO request,
            @RequestHeader("Idempotency-Key") String idempotencyKey,
            jakarta.servlet.http.HttpServletRequest httpRequest,
             @RequestHeader(value = "X-Fingerprint", required = false) String fingerprint) {
        LOG.info("contact.request.received correlationId={} emailDomain={} nameLength={} subjectLength={} messageLength={} hasPhone={} hasFingerprint={} idempotencyKey={}",
                SafeDiagnosticLog.correlationId("unknown"), SafeDiagnosticLog.emailDomain(request.email()),
                request.nombre().length(), request.asunto().length(), request.mensaje().length(),
                request.telefono() != null && !request.telefono().isBlank(), fingerprint != null && !fingerprint.isBlank(),
                SafeDiagnosticLog.opaque(idempotencyKey));
        var saved = contactoService.create(request, idempotencyKey, httpRequest, fingerprint);
        return new ContactoPublicoDTO(saved.getId(), saved.getEstado().name(), saved.getCreatedAt());
    }
}
