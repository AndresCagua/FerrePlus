package com.ferreplus.service;

import com.ferreplus.entity.Categoria;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.CategoriaRepository;
import com.ferreplus.util.AuditDiff;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional
@RequiredArgsConstructor
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<Categoria> list() {
        return categoriaRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Categoria getById(Long id) {
        return categoriaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoría no encontrada con id: " + id));
    }

    public Categoria create(Categoria categoria) {
        categoria = categoriaRepository.save(categoria);
        auditService.registrarEvento("CATEGORIA", categoria.getId(), "CREAR", jsonDetalle(categoria));
        return categoria;
    }

    public Categoria update(Long id, Categoria categoriaActualizada) {
        Categoria categoria = getById(id);
        Map<String, Object> antes = snapshot(categoria);
        categoria.setNombre(categoriaActualizada.getNombre());
        categoria.setDescripcion(categoriaActualizada.getDescripcion());
        Categoria guardada = categoriaRepository.save(categoria);
        auditService.registrarEvento("CATEGORIA", guardada.getId(), "ACTUALIZAR",
                AuditDiff.toJson(objectMapper, AuditDiff.diff(antes, snapshot(guardada))));
        return guardada;
    }

    public void delete(Long id) {
        Categoria categoria = getById(id);
        categoriaRepository.delete(categoria);
        auditService.registrarEvento("CATEGORIA", id, "ELIMINAR", jsonDetalle(categoria));
    }

    private String jsonDetalle(Categoria c) {
        try {
            return objectMapper.writeValueAsString(Map.of("nombre", c.getNombre()));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private Map<String, Object> snapshot(Categoria c) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", c.getNombre());
        data.put("descripcion", c.getDescripcion());
        return data;
    }
}
