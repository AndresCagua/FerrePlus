package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.publico.PostulacionRequestDTO;
import com.ferreplus.publico.dto.publico.PostulacionPublicaDTO;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.PostulacionService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/public")
public class PublicController {
    private final ConvocatoriaService convocatoriaService;
    private final PostulacionService postulacionService;

    @GetMapping("/ping") public Map<String, String> ping() { return Map.of("service", "public-api", "status", "ok"); }
    @GetMapping("/publicaciones") public List<Object> publicaciones() { return List.of(); }
    @GetMapping("/publicaciones/{slug}") public Object publicacion(@PathVariable String slug) { throw new com.ferreplus.publico.exception.PublicApiException(HttpStatus.NOT_FOUND, "Publicacion no encontrada"); }
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
}
