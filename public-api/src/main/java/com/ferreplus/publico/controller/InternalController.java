package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.interno.ConvocatoriaAdminDTO;
import com.ferreplus.publico.dto.interno.EstadoPostulacionRequest;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.Postulacion;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.PostulacionService;
import com.ferreplus.publico.storage.MinioObjectStorage;
import com.ferreplus.publico.storage.ObjectStorage.StoredObject;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/internal")
public class InternalController {
    private final ConvocatoriaService convocatoriaService;
    private final PostulacionService postulacionService;
    private final MinioObjectStorage storage;

    @GetMapping("/ping") public Map<String, String> ping() { return Map.of("service", "public-api", "boundary", "internal", "status", "ok"); }
    @GetMapping("/convocatorias") public List<Convocatoria> allConvocatorias() { return convocatoriaService.todas(); }
    @PostMapping("/convocatorias") @ResponseStatus(HttpStatus.CREATED)
    public Convocatoria createConvocatoria(@Valid @RequestBody ConvocatoriaAdminDTO request) { return convocatoriaService.crear(request); }
    @PutMapping("/convocatorias/{id}") public Convocatoria updateConvocatoria(@PathVariable String id, @Valid @RequestBody ConvocatoriaAdminDTO request) { return convocatoriaService.actualizar(id, request); }
    @DeleteMapping("/convocatorias/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteConvocatoria(@PathVariable String id) { convocatoriaService.eliminar(id); }
    @PostMapping("/convocatorias/{id}/publicar") public Convocatoria publish(@PathVariable String id) { return convocatoriaService.publicar(id); }
    @PostMapping("/convocatorias/{id}/despublicar") public Convocatoria unpublish(@PathVariable String id) { return convocatoriaService.despublicar(id); }
    @PostMapping("/convocatorias/{id}/cerrar") public Convocatoria close(@PathVariable String id) { return convocatoriaService.cerrar(id); }
    @GetMapping("/convocatorias/{id}/postulaciones") public List<Postulacion> applications(@PathVariable String id) { return postulacionService.byConvocatoria(id); }
    @PatchMapping("/postulaciones/{id}") public Postulacion transition(@PathVariable String id, @Valid @RequestBody EstadoPostulacionRequest request, @RequestHeader(value = "X-Actor", defaultValue = "admin-api:placeholder") String actor) { return postulacionService.transition(id, request.estado(), actor); }
    @GetMapping("/postulaciones/{id}/cv")
    public ResponseEntity<InputStreamResource> cv(@PathVariable String id) {
        Postulacion item = postulacionService.find(id);
        final StoredObject object;
        try {
            object = storage.get(storage.cvBucket(), item.getCv().objectKey());
        } catch (MinioObjectStorage.StorageException exception) {
            throw new com.ferreplus.publico.exception.PublicApiException(HttpStatus.NOT_FOUND, "CV no encontrado");
        }
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(item.getCv().mimeType()))
                .contentLength(object.size()).header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(item.getCv().fileName()).build().toString())
                .body(new InputStreamResource(object.stream()));
    }
}
