package com.ferreplus.controller;

import com.ferreplus.dto.AuditoriaDTO;
import com.ferreplus.dto.LogsEliminadosDTO;
import com.ferreplus.dto.UsuarioOpcionDTO;
import com.ferreplus.service.LogService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Módulo de Logs (R2/R3). {@code GET} consulta paginada/filtrada con {@code LOGS_VER};
 * {@code DELETE} borrado por rango {@code [desde, hasta]} con {@code LOGS_ELIMINAR}.
 * NO existe borrado por fila individual (solo por rango, R3).
 */
@RestController
@RequestMapping("/api/logs")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class LogController {

    private final LogService logService;

    @GetMapping
    @PreAuthorize("hasAuthority('LOGS_VER')")
    public ResponseEntity<Page<AuditoriaDTO>> consultar(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String fechaDesde,
            @RequestParam(required = false) String fechaHasta,
            @RequestParam(required = false) Long usuarioId,
            @RequestParam(required = false) String entidad,
            @RequestParam(required = false) String accion,
            @RequestParam(required = false) String usuarioNombre) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "fecha"));
        return ResponseEntity.ok(
                logService.consultar(fechaDesde, fechaHasta, usuarioId, entidad, accion, usuarioNombre, pageable));
    }

    /**
     * Opciones del selector de usuarios del filtro (R7 refinamiento). Protegido por
     * {@code LOGS_VER} (NO {@code USUARIOS_VER}): un revisor de logs con solo el
     * permiso del módulo debe poder ver la lista de usuarios con actividad. Expone
     * únicamente {@code id} y {@code nombre}.
     */
    @GetMapping("/usuarios")
    @PreAuthorize("hasAuthority('LOGS_VER')")
    public ResponseEntity<List<UsuarioOpcionDTO>> usuariosConActividad() {
        return ResponseEntity.ok(logService.listarUsuariosConActividad());
    }

    @DeleteMapping
    @PreAuthorize("hasAuthority('LOGS_ELIMINAR')")
    public ResponseEntity<LogsEliminadosDTO> eliminarLogs(
            @RequestParam String desde,
            @RequestParam String hasta) {
        return ResponseEntity.ok(new LogsEliminadosDTO(logService.eliminarPorRango(desde, hasta)));
    }
}