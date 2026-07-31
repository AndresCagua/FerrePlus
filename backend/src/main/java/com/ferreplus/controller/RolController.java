package com.ferreplus.controller;

import com.ferreplus.dto.RolDTO;
import com.ferreplus.dto.RolRequestDTO;
import com.ferreplus.service.RolService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class RolController {

    private final RolService rolService;

    @GetMapping
    @PreAuthorize("hasAuthority('ROLES_VER')")
    public ResponseEntity<List<RolDTO>> list() {
        return ResponseEntity.ok(rolService.listDTO());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLES_VER')")
    public ResponseEntity<RolDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(rolService.getDTO(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ROLES_EDITAR')")
    public ResponseEntity<RolDTO> create(@Valid @RequestBody RolRequestDTO dto) {
        return ResponseEntity.ok(rolService.create(dto));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLES_EDITAR')")
    public ResponseEntity<RolDTO> update(@PathVariable Long id, @Valid @RequestBody RolRequestDTO dto) {
        return ResponseEntity.ok(rolService.update(id, dto));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLES_EDITAR')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        rolService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
