package com.ferreplus.controller;

import com.ferreplus.dto.MovimientoStockDTO;
import com.ferreplus.entity.MovimientoStock;
import com.ferreplus.service.MovimientoStockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/movimientos-stock")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class MovimientoStockController {

    private final MovimientoStockService movimientoStockService;

    @GetMapping
    public ResponseEntity<List<MovimientoStock>> list(
            @RequestParam(required = false) Long productoId,
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {

        if (productoId != null) {
            return ResponseEntity.ok(movimientoStockService.listByProducto(productoId));
        }
        if (tipo != null) {
            return ResponseEntity.ok(movimientoStockService.listByTipo(tipo));
        }
        if (desde != null && hasta != null) {
            return ResponseEntity.ok(movimientoStockService.listByFecha(desde, hasta));
        }
        return ResponseEntity.ok(movimientoStockService.listByFecha(LocalDate.now().minusMonths(1), LocalDate.now()));
    }

    @PostMapping
    public ResponseEntity<MovimientoStock> create(@Valid @RequestBody MovimientoStockDTO dto) {
        return ResponseEntity.ok(movimientoStockService.create(dto));
    }
}
