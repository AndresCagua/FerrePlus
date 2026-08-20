package com.ferreplus.controller;

import com.ferreplus.entity.Proveedor;
import com.ferreplus.service.ProveedorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/proveedores")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class ProveedorController {

    private final ProveedorService proveedorService;

    @GetMapping
    @PreAuthorize("hasAuthority('PROVEEDORES_VER')")
    public ResponseEntity<List<Proveedor>> list() {
        return ResponseEntity.ok(proveedorService.list());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('PROVEEDORES_VER')")
    public ResponseEntity<Proveedor> getById(@PathVariable Long id) {
        return ResponseEntity.ok(proveedorService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('PROVEEDORES_CREAR')")
    public ResponseEntity<Proveedor> create(@Valid @RequestBody Proveedor proveedor) {
        return ResponseEntity.ok(proveedorService.create(proveedor));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('PROVEEDORES_EDITAR')")
    public ResponseEntity<Proveedor> update(@PathVariable Long id, @Valid @RequestBody Proveedor proveedor) {
        return ResponseEntity.ok(proveedorService.update(id, proveedor));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('PROVEEDORES_ELIMINAR')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        proveedorService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
