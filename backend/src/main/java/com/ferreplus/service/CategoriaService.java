package com.ferreplus.service;

import com.ferreplus.entity.Categoria;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.CategoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;

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
        return categoriaRepository.save(categoria);
    }

    public Categoria update(Long id, Categoria categoriaActualizada) {
        Categoria categoria = getById(id);
        categoria.setNombre(categoriaActualizada.getNombre());
        categoria.setDescripcion(categoriaActualizada.getDescripcion());
        return categoriaRepository.save(categoria);
    }

    public void delete(Long id) {
        Categoria categoria = getById(id);
        categoriaRepository.delete(categoria);
    }
}
