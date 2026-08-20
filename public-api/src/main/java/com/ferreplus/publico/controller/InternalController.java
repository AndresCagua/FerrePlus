package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.interno.ConvocatoriaAdminDTO;
import com.ferreplus.publico.dto.interno.PublicacionAdminDTO;
import com.ferreplus.publico.dto.interno.ContactoAdminDTO;
import com.ferreplus.publico.dto.interno.DestinatarioDTO;
import com.ferreplus.publico.model.Contacto;
import com.ferreplus.publico.model.Destinatario;
import com.ferreplus.publico.model.Publicacion;
import com.ferreplus.publico.dto.interno.EstadoPostulacionRequest;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.Postulacion;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.PostulacionService;
import com.ferreplus.publico.service.PublicacionService;
import com.ferreplus.publico.service.ContactoService;
import com.ferreplus.publico.service.DestinatarioService;
import com.ferreplus.publico.mail.MailEventListener;
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
    private final PublicacionService publicacionService;
    private final ContactoService contactoService;
    private final DestinatarioService destinatarioService;
    private final MailEventListener mailEventListener;

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
    @GetMapping("/publicaciones") public List<Publicacion> publicaciones() { return publicacionService.todas(); }
    @PostMapping("/publicaciones") @ResponseStatus(HttpStatus.CREATED)
    public Publicacion createPublicacion(@Valid @RequestBody PublicacionAdminDTO request) { return publicacionService.crear(request); }
    @PostMapping(value = "/publicaciones", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Publicacion createPublicacionWithMedia(@Valid @RequestPart("data") PublicacionAdminDTO request,
            @RequestPart(value = "portada", required = false) org.springframework.web.multipart.MultipartFile portada,
            @RequestPart(value = "galeria", required = false) List<org.springframework.web.multipart.MultipartFile> galeria) {
        return publicacionService.crear(request, portada, galeria);
    }
    @PutMapping("/publicaciones/{id}") public Publicacion updatePublicacion(@PathVariable String id, @Valid @RequestBody PublicacionAdminDTO request) { return publicacionService.actualizar(id, request); }
    @PutMapping(value = "/publicaciones/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Publicacion updatePublicacionWithMedia(@PathVariable String id, @Valid @RequestPart("data") PublicacionAdminDTO request,
            @RequestPart(value = "portada", required = false) org.springframework.web.multipart.MultipartFile portada,
            @RequestPart(value = "galeria", required = false) List<org.springframework.web.multipart.MultipartFile> galeria) {
        return publicacionService.actualizar(id, request, portada, galeria);
    }
    @DeleteMapping("/publicaciones/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deletePublicacion(@PathVariable String id) { publicacionService.eliminar(id); }
    @PostMapping("/publicaciones/{id}/publicar") public Publicacion publishPublicacion(@PathVariable String id) { return publicacionService.publicar(id); }
    @PostMapping("/publicaciones/{id}/despublicar") public Publicacion unpublishPublicacion(@PathVariable String id) { return publicacionService.despublicar(id); }
    @GetMapping("/contactos") public List<Contacto> contactos(@RequestParam(required = false) Contacto.EstadoContacto estado) { return contactoService.all(estado); }
    @PatchMapping("/contactos/{id}") public Contacto updateContacto(@PathVariable String id, @Valid @RequestBody ContactoAdminDTO request) { return contactoService.update(id, request); }
    @GetMapping("/destinatarios") public List<Destinatario> destinatarios() { return destinatarioService.all(); }
    @PostMapping("/destinatarios") @ResponseStatus(HttpStatus.CREATED)
    public Destinatario createDestinatario(@Valid @RequestBody DestinatarioDTO request) { return destinatarioService.create(request); }
    @PutMapping("/destinatarios/{id}") public Destinatario updateDestinatario(@PathVariable String id, @Valid @RequestBody DestinatarioDTO request) { return destinatarioService.update(id, request); }
    @DeleteMapping("/destinatarios/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteDestinatario(@PathVariable String id) { destinatarioService.delete(id); }
    @PostMapping("/notificaciones/{id}/reintentar") @ResponseStatus(HttpStatus.ACCEPTED)
    public void retryNotification(@PathVariable String id) { mailEventListener.retry(id); }
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
