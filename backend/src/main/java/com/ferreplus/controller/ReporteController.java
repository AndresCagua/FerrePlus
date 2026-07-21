package com.ferreplus.controller;

import com.ferreplus.dto.ReporteDTO;
import com.ferreplus.entity.Venta;
import com.ferreplus.service.ReporteService;
import com.ferreplus.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/reportes")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class ReporteController {

    private final ReporteService reporteService;
    private final VentaService ventaService;

    @GetMapping("/dashboard")
    public ResponseEntity<ReporteDTO> dashboard() {
        return ResponseEntity.ok(reporteService.getDashboardMetrics());
    }

    @GetMapping("/ventas")
    public ResponseEntity<List<Venta>> ventas(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {
        return ResponseEntity.ok(ventaService.listByFecha(desde, hasta));
    }

    @GetMapping("/inventario")
    public ResponseEntity<ReporteDTO> inventario() {
        return ResponseEntity.ok(reporteService.getDashboardMetrics());
    }

    @GetMapping("/movimientos")
    public ResponseEntity<ReporteDTO> movimientos() {
        return ResponseEntity.ok(reporteService.getDashboardMetrics());
    }
}
