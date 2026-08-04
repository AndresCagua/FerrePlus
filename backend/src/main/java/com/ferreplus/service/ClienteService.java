package com.ferreplus.service;

import com.ferreplus.entity.Cliente;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.ClienteRepository;
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
public class ClienteService {

    private final ClienteRepository clienteRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<Cliente> list() {
        return clienteRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Cliente getById(Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cliente no encontrado con id: " + id));
    }

    public Cliente create(Cliente cliente) {
        cliente = clienteRepository.save(cliente);
        auditService.registrarEvento("CLIENTE", cliente.getId(), "CREAR", jsonDetalle(cliente));
        return cliente;
    }

    public Cliente update(Long id, Cliente clienteActualizado) {
        Cliente cliente = getById(id);
        Map<String, Object> antes = snapshot(cliente);
        if (clienteActualizado.getNombre() != null) cliente.setNombre(clienteActualizado.getNombre());
        if (clienteActualizado.getRuc() != null) cliente.setRuc(clienteActualizado.getRuc());
        if (clienteActualizado.getTelefono() != null) cliente.setTelefono(clienteActualizado.getTelefono());
        if (clienteActualizado.getEmail() != null) cliente.setEmail(clienteActualizado.getEmail());
        if (clienteActualizado.getDireccion() != null) cliente.setDireccion(clienteActualizado.getDireccion());
        if (clienteActualizado.getSaldoPendiente() != null) cliente.setSaldoPendiente(clienteActualizado.getSaldoPendiente());
        cliente.setActivo(clienteActualizado.isActivo());
        Cliente guardado = clienteRepository.save(cliente);
        auditService.registrarEvento("CLIENTE", guardado.getId(), "ACTUALIZAR",
                AuditDiff.toJson(objectMapper, AuditDiff.diff(antes, snapshot(guardado))));
        return guardado;
    }

    public void delete(Long id) {
        Cliente cliente = getById(id);
        cliente.setActivo(false);
        Cliente guardado = clienteRepository.save(cliente);
        auditService.registrarEvento("CLIENTE", guardado.getId(), "ELIMINAR", jsonDetalle(guardado));
    }

    private String jsonDetalle(Cliente c) {
        try {
            Map<String, Object> detalle = new HashMap<>();
            detalle.put("nombre", c.getNombre());
            if (c.getRuc() != null) {
                detalle.put("ruc", c.getRuc());
            }
            return objectMapper.writeValueAsString(detalle);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private Map<String, Object> snapshot(Cliente c) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", c.getNombre());
        data.put("ruc", c.getRuc());
        data.put("telefono", c.getTelefono());
        data.put("email", c.getEmail());
        data.put("direccion", c.getDireccion());
        data.put("saldoPendiente", c.getSaldoPendiente());
        data.put("activo", c.isActivo());
        return data;
    }
}
