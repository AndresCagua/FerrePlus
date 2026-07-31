package com.ferreplus.controller;

import com.ferreplus.dto.ModuloDTO;
import com.ferreplus.dto.PermisoDTO;
import com.ferreplus.service.CatalogoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Catálogo dinámico de módulos y permisos (R2). Protegido para los dos flujos
 * de UI que lo consumen: roles y usuarios.
 */
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class CatalogoController {

    private final CatalogoService catalogoService;

    @GetMapping("/modulos")
    @PreAuthorize("hasAnyAuthority('ROLES_VER', 'USUARIOS_VER')")
    public ResponseEntity<List<ModuloDTO>> modulos() {
        return ResponseEntity.ok(catalogoService.getModulosConPermisos());
    }

    @GetMapping("/permisos")
    @PreAuthorize("hasAnyAuthority('ROLES_VER', 'USUARIOS_VER')")
    public ResponseEntity<List<PermisoDTO>> permisos() {
        return ResponseEntity.ok(catalogoService.getPermisos());
    }
}
