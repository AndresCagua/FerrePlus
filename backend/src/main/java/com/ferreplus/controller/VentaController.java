package com.ferreplus.controller;

import com.ferreplus.dto.VentaDTO;
import com.ferreplus.entity.Venta;
import com.ferreplus.service.VentaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/ventas")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class VentaController {

    private final VentaService ventaService;

    @GetMapping
    public ResponseEntity<List<Venta>> list() {
        return ResponseEntity.ok(ventaService.list());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Venta> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ventaService.getById(id));
    }

    @PostMapping
    public ResponseEntity<Venta> create(@Valid @RequestBody VentaDTO dto) {
        return ResponseEntity.ok(ventaService.create(dto));
    }

    @PutMapping("/{id}/anular")
    public ResponseEntity<Void> anular(@PathVariable Long id) {
        ventaService.anular(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/reportes/por-fecha")
    public ResponseEntity<List<Venta>> listByFecha(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {
        return ResponseEntity.ok(ventaService.listByFecha(desde, hasta));
    }
}
