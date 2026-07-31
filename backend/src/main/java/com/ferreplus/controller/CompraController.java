package com.ferreplus.controller;

import com.ferreplus.dto.CompraDTO;
import com.ferreplus.entity.Compra;
import com.ferreplus.service.CompraService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/compras")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class CompraController {

    private final CompraService compraService;

    @GetMapping
    @PreAuthorize("hasAuthority('COMPRAS_VER')")
    public ResponseEntity<List<Compra>> list() {
        return ResponseEntity.ok(compraService.list());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('COMPRAS_VER')")
    public ResponseEntity<Compra> getById(@PathVariable Long id) {
        return ResponseEntity.ok(compraService.getById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('COMPRAS_EDITAR')")
    public ResponseEntity<Compra> update(@PathVariable Long id, @Valid @RequestBody CompraDTO dto) {
        return ResponseEntity.ok(compraService.update(id, dto));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('COMPRAS_CREAR')")
    public ResponseEntity<Compra> create(@Valid @RequestBody CompraDTO dto) {
        return ResponseEntity.ok(compraService.create(dto));
    }

    @PutMapping("/{id}/anular")
    @PreAuthorize("hasAuthority('COMPRAS_ELIMINAR')")
    public ResponseEntity<Void> anular(@PathVariable Long id) {
        compraService.anular(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/reportes/por-fecha")
    @PreAuthorize("hasAuthority('COMPRAS_VER')")
    public ResponseEntity<List<Compra>> listByFecha(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {
        return ResponseEntity.ok(compraService.listByFecha(desde, hasta));
    }
}
