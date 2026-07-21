package com.ferreplus.controller;

import com.ferreplus.dto.ActualizarPrecioVentaDTO;
import com.ferreplus.dto.HistoricoPrecioProductoDTO;
import com.ferreplus.dto.PrecioProductoDTO;
import com.ferreplus.entity.Usuario;
import com.ferreplus.service.PrecioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/precios")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class PrecioController {

    private final PrecioService precioService;

    @GetMapping
    public ResponseEntity<List<PrecioProductoDTO>> listarPrecios() {
        return ResponseEntity.ok(precioService.listarPrecios());
    }

    @GetMapping("/{id}")
    public ResponseEntity<PrecioProductoDTO> obtenerPrecio(@PathVariable Long id) {
        return ResponseEntity.ok(precioService.obtenerPrecio(id));
    }

    @GetMapping("/{id}/historial")
    public ResponseEntity<List<HistoricoPrecioProductoDTO>> obtenerHistorial(@PathVariable Long id) {
        return ResponseEntity.ok(precioService.obtenerHistorial(id));
    }

    @PutMapping("/{id}/venta")
    public ResponseEntity<PrecioProductoDTO> actualizarPrecioVenta(
            @PathVariable Long id,
            @Valid @RequestBody ActualizarPrecioVentaDTO dto,
            @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(precioService.actualizarPrecioVenta(id, dto, usuario));
    }
}
