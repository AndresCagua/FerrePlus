package com.ferreplus.service;

import com.ferreplus.entity.Cliente;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.ClienteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository clienteRepository;

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
        return clienteRepository.save(cliente);
    }

    public Cliente update(Long id, Cliente clienteActualizado) {
        Cliente cliente = getById(id);
        cliente.setNombre(clienteActualizado.getNombre());
        cliente.setRuc(clienteActualizado.getRuc());
        cliente.setTelefono(clienteActualizado.getTelefono());
        cliente.setEmail(clienteActualizado.getEmail());
        cliente.setDireccion(clienteActualizado.getDireccion());
        cliente.setSaldoPendiente(clienteActualizado.getSaldoPendiente());
        cliente.setActivo(clienteActualizado.isActivo());
        return clienteRepository.save(cliente);
    }

    public void delete(Long id) {
        Cliente cliente = getById(id);
        cliente.setActivo(false);
        clienteRepository.save(cliente);
    }
}
