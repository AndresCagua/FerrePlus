package com.ferreplus.controller;

import com.ferreplus.entity.Producto;
import com.ferreplus.service.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/productos")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    @GetMapping
    public ResponseEntity<List<Producto>> list(
            @RequestParam(required = false) Long categoria,
            @RequestParam(required = false) String query) {

        if (query != null && !query.isBlank()) {
            return ResponseEntity.ok(productoService.buscar(query));
        }
        if (categoria != null) {
            return ResponseEntity.ok(productoService.listByCategoria(categoria));
        }
        return ResponseEntity.ok(productoService.list());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Producto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(productoService.getById(id));
    }

    @GetMapping("/stock-bajo")
    public ResponseEntity<List<Producto>> listStockBajo() {
        return ResponseEntity.ok(productoService.listStockBajo());
    }

    @PostMapping
    public ResponseEntity<Producto> create(@Valid @RequestBody Producto producto) {
        return ResponseEntity.ok(productoService.create(producto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Producto> update(@PathVariable Long id, @Valid @RequestBody Producto producto) {
        return ResponseEntity.ok(productoService.update(id, producto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        productoService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
