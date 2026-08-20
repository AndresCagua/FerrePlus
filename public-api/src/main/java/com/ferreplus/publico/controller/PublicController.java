package com.ferreplus.publico.controller;

import com.ferreplus.publico.dto.publico.ContactoRequestDTO;
import com.ferreplus.publico.dto.publico.PostulacionRequestDTO;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Validated
@RequestMapping("/api/public")
public class PublicController {
    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of("service", "public-api", "status", "ok");
    }

    @GetMapping("/publicaciones")
    public List<Object> publicaciones() {
        return List.of();
    }

    @GetMapping("/publicaciones/{slug}")
    public ResponseEntity<Void> publicacion(@PathVariable String slug) {
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/convocatorias")
    public List<Object> convocatorias() {
        return List.of();
    }

    @GetMapping("/convocatorias/{id}")
    public ResponseEntity<Void> convocatoria(@PathVariable String id) {
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/convocatorias/{id}/postulaciones")
    public ResponseEntity<Map<String, String>> postulacion(@PathVariable String id,
            @RequestBody @jakarta.validation.Valid PostulacionRequestDTO request) {
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(Map.of("status", "skeleton", "message", "Postulaciones disponibles en PR4"));
    }

    @PostMapping("/contactos")
    public ResponseEntity<Map<String, String>> contacto(
            @RequestBody @jakarta.validation.Valid ContactoRequestDTO request) {
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(Map.of("status", "skeleton", "message", "Contactos disponibles en PR5"));
    }
}
