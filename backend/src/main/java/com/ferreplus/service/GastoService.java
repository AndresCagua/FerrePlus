package com.ferreplus.service;

import com.ferreplus.entity.Gasto;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.GastoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class GastoService {

    private final GastoRepository gastoRepository;

    @Transactional(readOnly = true)
    public List<Gasto> list() {
        return gastoRepository.findAllByOrderByFechaCreacionDesc();
    }

    @Transactional(readOnly = true)
    public Gasto getById(Long id) {
        return gastoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Gasto no encontrado con id: " + id));
    }

    public Gasto create(Gasto gasto) {
        return gastoRepository.save(gasto);
    }

    public Gasto update(Long id, Gasto gastoActualizado) {
        Gasto gasto = getById(id);
        gasto.setDescripcion(gastoActualizado.getDescripcion());
        gasto.setMonto(gastoActualizado.getMonto());
        gasto.setCategoria(gastoActualizado.getCategoria());
        gasto.setMetodoPago(gastoActualizado.getMetodoPago());
        gasto.setNumeroComprobante(gastoActualizado.getNumeroComprobante());
        gasto.setFechaGasto(gastoActualizado.getFechaGasto());
        gasto.setObservaciones(gastoActualizado.getObservaciones());
        gasto.setUsuario(gastoActualizado.getUsuario());
        return gastoRepository.save(gasto);
    }

    public void delete(Long id) {
        Gasto gasto = getById(id);
        gastoRepository.delete(gasto);
    }
}
