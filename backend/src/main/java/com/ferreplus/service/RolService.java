package com.ferreplus.service;

import com.ferreplus.entity.Rol;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.RolRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class RolService {

    private final RolRepository rolRepository;

    @Transactional(readOnly = true)
    public List<Rol> list() {
        return rolRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Rol getById(Long id) {
        return rolRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rol no encontrado con id: " + id));
    }

    public Rol create(Rol rol) {
        return rolRepository.save(rol);
    }

    public Rol update(Long id, Rol rolActualizado) {
        Rol rol = getById(id);
        rol.setNombre(rolActualizado.getNombre());
        rol.setDescripcion(rolActualizado.getDescripcion());
        return rolRepository.save(rol);
    }

    public void delete(Long id) {
        Rol rol = getById(id);
        rolRepository.delete(rol);
    }
}
