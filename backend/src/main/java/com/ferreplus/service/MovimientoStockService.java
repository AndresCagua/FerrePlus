package com.ferreplus.service;

import com.ferreplus.dto.MovimientoStockDTO;
import com.ferreplus.entity.MovimientoStock;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.MovimientoStockRepository;
import com.ferreplus.repository.ProductoRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

@Service
@Transactional
@RequiredArgsConstructor
public class MovimientoStockService {

    private final MovimientoStockRepository movimientoStockRepository;
    private final ProductoService productoService;
    private final ProductoRepository productoRepository;
    private final UsuarioService usuarioService;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<MovimientoStock> listByProducto(Long productoId) {
        return movimientoStockRepository.findByProductoIdOrderByFechaDesc(productoId);
    }

    @Transactional(readOnly = true)
    public List<MovimientoStock> listByFecha(LocalDate inicio, LocalDate fin) {
        LocalDateTime desde = inicio.atStartOfDay();
        LocalDateTime hasta = fin.atTime(LocalTime.MAX);
        return movimientoStockRepository.findByFechaBetweenOrderByFechaDesc(desde, hasta);
    }

    @Transactional(readOnly = true)
    public List<MovimientoStock> listByTipo(String tipo) {
        return movimientoStockRepository.findByTipoOrderByFechaDesc(tipo);
    }

    public MovimientoStock create(MovimientoStockDTO dto) {
        Producto producto = productoService.getById(dto.getProductoId());
        Usuario usuario = null;
        if (dto.getUsuarioId() != null) {
            usuario = usuarioService.getById(dto.getUsuarioId());
        }

        int stockAnterior = producto.getStockActual();
        int cantidad = dto.getCantidad();
        int nuevoStock;

        switch (dto.getTipo().toUpperCase()) {
            case "ENTRADA":
                nuevoStock = stockAnterior + cantidad;
                break;
            case "SALIDA":
                nuevoStock = stockAnterior - cantidad;
                if (nuevoStock < 0) {
                    throw new BadRequestException("Stock insuficiente. Stock actual: " + stockAnterior);
                }
                break;
            case "AJUSTE":
                nuevoStock = cantidad;
                cantidad = nuevoStock - stockAnterior;
                break;
            default:
                throw new BadRequestException("Tipo de movimiento no válido: " + dto.getTipo());
        }

        producto.setStockActual(nuevoStock);
        productoRepository.save(producto);

        MovimientoStock movimiento = movimientoStockRepository.save(
                MovimientoStock.builder()
                        .producto(producto)
                        .cantidad(cantidad)
                        .tipo(dto.getTipo().toUpperCase())
                        .referencia(dto.getReferencia())
                        .motivo(dto.getMotivo())
                        .precioUnitario(dto.getPrecioUnitario())
                        .usuario(usuario)
                        .stockAnterior(stockAnterior)
                        .stockPosterior(nuevoStock)
                        .build());

        auditService.registrarEvento("MOVIMIENTO", movimiento.getId(), "CREAR",
                jsonDetalle(movimiento));
        return movimiento;
    }

    private String jsonDetalle(MovimientoStock movimiento) {
        try {
            return objectMapper.writeValueAsString(Map.of(
                    "productoId", movimiento.getProducto().getId(),
                    "tipo", movimiento.getTipo(),
                    "cantidad", movimiento.getCantidad(),
                    "stockPosterior", movimiento.getStockPosterior()));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }
}
