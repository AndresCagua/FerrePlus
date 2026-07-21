package com.ferreplus.service;

import com.ferreplus.entity.Proveedor;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.ProveedorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ProveedorService {

    private final ProveedorRepository proveedorRepository;

    @Transactional(readOnly = true)
    public List<Proveedor> list() {
        return proveedorRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Proveedor getById(Long id) {
        return proveedorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor no encontrado con id: " + id));
    }

    public Proveedor create(Proveedor proveedor) {
        return proveedorRepository.save(proveedor);
    }

    public Proveedor update(Long id, Proveedor proveedorActualizado) {
        Proveedor proveedor = getById(id);
        proveedor.setNombre(proveedorActualizado.getNombre());
        proveedor.setRuc(proveedorActualizado.getRuc());
        proveedor.setContacto(proveedorActualizado.getContacto());
        proveedor.setTelefono(proveedorActualizado.getTelefono());
        proveedor.setEmail(proveedorActualizado.getEmail());
        proveedor.setDireccion(proveedorActualizado.getDireccion());
        proveedor.setActivo(proveedorActualizado.isActivo());
        return proveedorRepository.save(proveedor);
    }

    public void delete(Long id) {
        Proveedor proveedor = getById(id);
        proveedor.setActivo(false);
        proveedorRepository.save(proveedor);
    }
}
