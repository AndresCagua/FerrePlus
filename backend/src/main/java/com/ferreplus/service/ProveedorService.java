package com.ferreplus.service;

import com.ferreplus.entity.Proveedor;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.ProveedorRepository;
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
public class ProveedorService {

    private final ProveedorRepository proveedorRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

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
        proveedor = proveedorRepository.save(proveedor);
        auditService.registrarEvento("PROVEEDOR", proveedor.getId(), "CREAR", jsonDetalle(proveedor));
        return proveedor;
    }

    public Proveedor update(Long id, Proveedor proveedorActualizado) {
        Proveedor proveedor = getById(id);
        Map<String, Object> antes = snapshot(proveedor);
        proveedor.setNombre(proveedorActualizado.getNombre());
        proveedor.setRuc(proveedorActualizado.getRuc());
        proveedor.setContacto(proveedorActualizado.getContacto());
        proveedor.setTelefono(proveedorActualizado.getTelefono());
        proveedor.setEmail(proveedorActualizado.getEmail());
        proveedor.setDireccion(proveedorActualizado.getDireccion());
        proveedor.setActivo(proveedorActualizado.isActivo());
        Proveedor guardado = proveedorRepository.save(proveedor);
        auditService.registrarEvento("PROVEEDOR", guardado.getId(), "ACTUALIZAR",
                AuditDiff.toJson(objectMapper, AuditDiff.diff(antes, snapshot(guardado))));
        return guardado;
    }

    public void delete(Long id) {
        Proveedor proveedor = getById(id);
        proveedor.setActivo(false);
        proveedorRepository.save(proveedor);
        auditService.registrarEvento("PROVEEDOR", proveedor.getId(), "ELIMINAR", jsonDetalle(proveedor));
    }

    private String jsonDetalle(Proveedor p) {
        try {
            return objectMapper.writeValueAsString(Map.of("nombre", p.getNombre()));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private Map<String, Object> snapshot(Proveedor p) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", p.getNombre());
        data.put("ruc", p.getRuc());
        data.put("contacto", p.getContacto());
        data.put("telefono", p.getTelefono());
        data.put("email", p.getEmail());
        data.put("direccion", p.getDireccion());
        data.put("activo", p.isActivo());
        return data;
    }
}
