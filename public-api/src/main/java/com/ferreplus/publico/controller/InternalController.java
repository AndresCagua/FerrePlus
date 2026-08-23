package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.interno.ContactoAdminDTO;
import com.ferreplus.publico.dto.interno.ConvocatoriaAdminDTO;
import com.ferreplus.publico.dto.interno.DestinatarioDTO;
import com.ferreplus.publico.dto.interno.EstadoPostulacionRequest;
import com.ferreplus.publico.dto.interno.PublicacionAdminDTO;
import com.ferreplus.publico.dto.interno.PublicKeyRequest;
import com.ferreplus.publico.model.Contacto;
import com.ferreplus.publico.service.ContactoService;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.DestinatarioService;
import com.ferreplus.publico.service.PostulacionService;
import com.ferreplus.publico.service.PublicacionService;
import com.ferreplus.publico.mail.MailEventListener;
import com.ferreplus.publico.security.KeyService;
import com.ferreplus.publico.storage.MinioObjectStorage;
import com.ferreplus.publico.storage.ObjectStorage.StoredObject;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/internal")
public class InternalController {
    private final ConvocatoriaService convocatorias;
    private final PostulacionService postulaciones;
    private final MinioObjectStorage storage;
    private final PublicacionService publicaciones;
    private final ContactoService contactos;
    private final DestinatarioService destinatarios;
    private final MailEventListener mail;
    private final KeyService keys;

    @GetMapping("/ping") public Map<String, String> ping() { return Map.of("service", "public-api", "boundary", "internal", "status", "ok"); }
    @PostMapping("/keys") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void publishKey(@Valid @RequestBody PublicKeyRequest request) { keys.publish(request.kid(), request.publicKey(), request.expiration()); }

    @GetMapping("/convocatorias") public List<InternalResponseMapper.ConvocatoriaResponse> allConvocatorias() { return convocatorias.todas().stream().map(InternalResponseMapper::convocatoria).toList(); }
    @GetMapping("/convocatorias/{id}")
    public InternalResponseMapper.ConvocatoriaResponse convocatoria(@PathVariable String id) {
        return InternalResponseMapper.convocatoria(convocatorias.find(id));
    }
    @PostMapping("/convocatorias") @ResponseStatus(HttpStatus.CREATED)
    public InternalResponseMapper.ConvocatoriaResponse createConvocatoria(@Valid @RequestBody ConvocatoriaAdminDTO request) { return InternalResponseMapper.convocatoria(convocatorias.crear(request)); }
    @PutMapping("/convocatorias/{id}") public InternalResponseMapper.ConvocatoriaResponse updateConvocatoria(@PathVariable String id, @Valid @RequestBody ConvocatoriaAdminDTO request) { return InternalResponseMapper.convocatoria(convocatorias.actualizar(id, request)); }
    @DeleteMapping("/convocatorias/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteConvocatoria(@PathVariable String id) { convocatorias.eliminar(id); }
    @PostMapping("/convocatorias/{id}/publicar") public InternalResponseMapper.ConvocatoriaResponse publish(@PathVariable String id) { return InternalResponseMapper.convocatoria(convocatorias.publicar(id)); }
    @PostMapping("/convocatorias/{id}/despublicar") public InternalResponseMapper.ConvocatoriaResponse unpublish(@PathVariable String id) { return InternalResponseMapper.convocatoria(convocatorias.despublicar(id)); }
    @PostMapping("/convocatorias/{id}/cerrar") public InternalResponseMapper.ConvocatoriaResponse close(@PathVariable String id) { return InternalResponseMapper.convocatoria(convocatorias.cerrar(id)); }
    @GetMapping("/convocatorias/{id}/postulaciones") public List<InternalResponseMapper.PostulacionResponse> applications(@PathVariable String id) { return postulaciones.byConvocatoria(id).stream().map(InternalResponseMapper::postulacion).toList(); }
    @GetMapping("/postulaciones") public List<InternalResponseMapper.PostulacionResponse> allApplications(@RequestParam(required = false) String convocatoriaId) { return (convocatoriaId == null ? postulaciones.all() : postulaciones.byConvocatoria(convocatoriaId)).stream().map(InternalResponseMapper::postulacion).toList(); }
    @GetMapping("/postulaciones/{id}") public InternalResponseMapper.PostulacionResponse application(@PathVariable String id) { return InternalResponseMapper.postulacion(postulaciones.find(id)); }

    @GetMapping("/publicaciones") public List<InternalResponseMapper.PublicacionResponse> allPublicaciones() { return publicaciones.todas().stream().map(InternalResponseMapper::publicacion).toList(); }
    @GetMapping("/publicaciones/{id}")
    public InternalResponseMapper.PublicacionResponse publicacion(@PathVariable String id) {
        return InternalResponseMapper.publicacion(publicaciones.find(id));
    }
    @PostMapping("/publicaciones") @ResponseStatus(HttpStatus.CREATED)
    public InternalResponseMapper.PublicacionResponse createPublicacion(@Valid @RequestBody PublicacionAdminDTO request) { return InternalResponseMapper.publicacion(publicaciones.crear(request)); }
    @PostMapping(value = "/publicaciones", consumes = MediaType.MULTIPART_FORM_DATA_VALUE) @ResponseStatus(HttpStatus.CREATED)
    public InternalResponseMapper.PublicacionResponse createPublicacionWithMedia(@Valid @RequestPart("data") PublicacionAdminDTO request, @RequestPart(value = "portada", required = false) MultipartFile portada, @RequestPart(value = "galeria", required = false) List<MultipartFile> galeria) { return InternalResponseMapper.publicacion(publicaciones.crear(request, portada, galeria)); }
    @PutMapping("/publicaciones/{id}") public InternalResponseMapper.PublicacionResponse updatePublicacion(@PathVariable String id, @Valid @RequestBody PublicacionAdminDTO request) { return InternalResponseMapper.publicacion(publicaciones.actualizar(id, request)); }
    @PutMapping(value = "/publicaciones/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public InternalResponseMapper.PublicacionResponse updatePublicacionWithMedia(@PathVariable String id, @Valid @RequestPart("data") PublicacionAdminDTO request, @RequestPart(value = "portada", required = false) MultipartFile portada, @RequestPart(value = "galeria", required = false) List<MultipartFile> galeria) { return InternalResponseMapper.publicacion(publicaciones.actualizar(id, request, portada, galeria)); }
    @DeleteMapping("/publicaciones/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deletePublicacion(@PathVariable String id) { publicaciones.eliminar(id); }
    @PostMapping("/publicaciones/{id}/publicar") public InternalResponseMapper.PublicacionResponse publishPublicacion(@PathVariable String id) { return InternalResponseMapper.publicacion(publicaciones.publicar(id)); }
    @PostMapping("/publicaciones/{id}/despublicar") public InternalResponseMapper.PublicacionResponse unpublishPublicacion(@PathVariable String id) { return InternalResponseMapper.publicacion(publicaciones.despublicar(id)); }

    @GetMapping("/contactos") public List<InternalResponseMapper.ContactoResponse> allContactos(@RequestParam(required = false) Contacto.EstadoContacto estado) { return contactos.all(estado).stream().map(InternalResponseMapper::contacto).toList(); }
    @PatchMapping("/contactos/{id}") public InternalResponseMapper.ContactoResponse updateContacto(@PathVariable String id, @Valid @RequestBody ContactoAdminDTO request) { return InternalResponseMapper.contacto(contactos.update(id, request)); }
    @GetMapping("/destinatarios") public List<InternalResponseMapper.DestinatarioResponse> allDestinatarios() { return destinatarios.all().stream().map(InternalResponseMapper::destinatario).toList(); }
    @PostMapping("/destinatarios") @ResponseStatus(HttpStatus.CREATED) public InternalResponseMapper.DestinatarioResponse createDestinatario(@Valid @RequestBody DestinatarioDTO request) { return InternalResponseMapper.destinatario(destinatarios.create(request)); }
    @PutMapping("/destinatarios/{id}") public InternalResponseMapper.DestinatarioResponse updateDestinatario(@PathVariable String id, @Valid @RequestBody DestinatarioDTO request) { return InternalResponseMapper.destinatario(destinatarios.update(id, request)); }
    @DeleteMapping("/destinatarios/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteDestinatario(@PathVariable String id) { destinatarios.delete(id); }
    @PostMapping("/notificaciones/{id}/reintentar") @ResponseStatus(HttpStatus.ACCEPTED) public void retryNotification(@PathVariable String id) { mail.retry(id); }
    @PatchMapping("/postulaciones/{id}") public InternalResponseMapper.PostulacionResponse transition(@PathVariable String id, @Valid @RequestBody EstadoPostulacionRequest request) { return InternalResponseMapper.postulacion(postulaciones.transition(id, request.estado(), actor())); }

    @GetMapping("/postulaciones/{id}/cv")
    public ResponseEntity<InputStreamResource> cv(@PathVariable String id) {
        var item = postulaciones.find(id);
        final StoredObject object;
        try { object = storage.get(storage.cvBucket(), item.getCv().objectKey()); }
        catch (MinioObjectStorage.StorageException exception) { throw new com.ferreplus.publico.exception.PublicApiException(HttpStatus.NOT_FOUND, "CV no encontrado"); }
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(item.getCv().mimeType())).contentLength(object.size())
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(item.getCv().fileName()).build().toString())
                .body(new InputStreamResource(object.stream()));
    }

    private String actor() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication == null || authentication.getName() == null || authentication.getName().isBlank()
                ? "admin-api" : authentication.getName();
    }
}
