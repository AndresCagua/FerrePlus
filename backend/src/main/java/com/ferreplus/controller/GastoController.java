package com.ferreplus.controller;

import com.ferreplus.entity.Gasto;
import com.ferreplus.service.GastoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/gastos")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class GastoController {

    private final GastoService gastoService;

    @GetMapping
    public ResponseEntity<List<Gasto>> list() {
        return ResponseEntity.ok(gastoService.list());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Gasto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(gastoService.getById(id));
    }

    @PostMapping
    public ResponseEntity<Gasto> create(@Valid @RequestBody Gasto gasto) {
        return ResponseEntity.ok(gastoService.create(gasto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Gasto> update(@PathVariable Long id, @Valid @RequestBody Gasto gasto) {
        return ResponseEntity.ok(gastoService.update(id, gasto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        gastoService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
