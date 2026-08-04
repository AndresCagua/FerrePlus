package com.ferreplus.service;

import com.ferreplus.entity.Gasto;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.GastoRepository;
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
public class GastoService {

    private final GastoRepository gastoRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

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
        Gasto guardado = gastoRepository.save(gasto);
        auditService.registrarEvento("GASTO", guardado.getId(), "CREAR", jsonDetalle(guardado));
        return guardado;
    }

    public Gasto update(Long id, Gasto gastoActualizado) {
        Gasto gasto = getById(id);
        Map<String, Object> antes = snapshot(gasto);
        if (gastoActualizado.getDescripcion() != null) gasto.setDescripcion(gastoActualizado.getDescripcion());
        if (gastoActualizado.getMonto() != null) gasto.setMonto(gastoActualizado.getMonto());
        if (gastoActualizado.getCategoria() != null) gasto.setCategoria(gastoActualizado.getCategoria());
        if (gastoActualizado.getMetodoPago() != null) gasto.setMetodoPago(gastoActualizado.getMetodoPago());
        if (gastoActualizado.getNumeroComprobante() != null) gasto.setNumeroComprobante(gastoActualizado.getNumeroComprobante());
        if (gastoActualizado.getFechaGasto() != null) gasto.setFechaGasto(gastoActualizado.getFechaGasto());
        if (gastoActualizado.getObservaciones() != null) gasto.setObservaciones(gastoActualizado.getObservaciones());
        gasto.setUsuario(gastoActualizado.getUsuario());
        Gasto guardado = gastoRepository.save(gasto);
        auditService.registrarEvento("GASTO", guardado.getId(), "ACTUALIZAR",
                AuditDiff.toJson(objectMapper, AuditDiff.diff(antes, snapshot(guardado))));
        return guardado;
    }

    public void delete(Long id) {
        Gasto gasto = getById(id);
        gastoRepository.delete(gasto);
        auditService.registrarEvento("GASTO", id, "ELIMINAR", jsonDetalle(gasto));
    }

    private String jsonDetalle(Gasto gasto) {
        return jsonDetalle(detalleDe(gasto));
    }

    private Map<String, Object> detalleDe(Gasto gasto) {
        Map<String, Object> detalle = new HashMap<>();
        if (gasto.getDescripcion() != null) {
            detalle.put("descripcion", gasto.getDescripcion());
        }
        if (gasto.getMonto() != null) {
            detalle.put("monto", gasto.getMonto());
        }
        return detalle;
    }

    /**
     * Snapshot plano de campos escalares del gasto para el diff ANTES/DESPUÉS.
     */
    private Map<String, Object> snapshot(Gasto gasto) {
        Map<String, Object> data = new HashMap<>();
        data.put("descripcion", gasto.getDescripcion());
        data.put("monto", gasto.getMonto());
        data.put("categoria", gasto.getCategoria());
        data.put("metodoPago", gasto.getMetodoPago());
        data.put("numeroComprobante", gasto.getNumeroComprobante());
        data.put("fechaGasto", gasto.getFechaGasto());
        data.put("observaciones", gasto.getObservaciones());
        data.put("usuarioId", gasto.getUsuario() != null ? gasto.getUsuario().getId() : null);
        return data;
    }

    private String jsonDetalle(Map<String, Object> detalle) {
        try {
            return objectMapper.writeValueAsString(detalle);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }
}
