package com.ferreplus.service;

import com.ferreplus.dto.VentaDTO;
import com.ferreplus.dto.DetalleVentaDTO;
import com.ferreplus.entity.*;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.DetalleVentaRepository;
import com.ferreplus.repository.VentaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class VentaService {

    private final VentaRepository ventaRepository;
    private final DetalleVentaRepository detalleVentaRepository;
    private final ProductoService productoService;
    private final ClienteService clienteService;
    private final UsuarioService usuarioService;

    @Transactional(readOnly = true)
    public List<Venta> list() {
        return ventaRepository.findAllByOrderByFechaCreacionDesc();
    }

    @Transactional(readOnly = true)
    public Venta getById(Long id) {
        return ventaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Venta no encontrada con id: " + id));
    }

    public Venta create(VentaDTO dto) {
        Usuario usuario = usuarioService.getById(dto.getUsuarioId());
        Cliente cliente = null;
        if (dto.getClienteId() != null) {
            cliente = clienteService.getById(dto.getClienteId());
        }

        // Calcular montos si no vienen
        calcularMontos(dto);

        String numeroFactura = generarNumeroFactura();

        Venta venta = Venta.builder()
                .numeroFactura(numeroFactura)
                .cliente(cliente)
                .subtotal(dto.getSubtotal())
                .descuento(dto.getDescuento() != null ? dto.getDescuento() : BigDecimal.ZERO)
                .iva(dto.getIva())
                .total(dto.getTotal())
                .metodoPago(dto.getMetodoPago())
                .estado("COMPLETADA")
                .observaciones(dto.getObservaciones())
                .usuario(usuario)
                .build();

        venta = ventaRepository.save(venta);

        for (DetalleVentaDTO detalleDTO : dto.getDetalles()) {
            Producto producto = productoService.getById(detalleDTO.getProductoId());

            if (producto.getStockActual() < detalleDTO.getCantidad()) {
                throw new BadRequestException(
                        "Stock insuficiente para el producto: " + producto.getNombre() +
                        ". Stock actual: " + producto.getStockActual() +
                        ", solicitado: " + detalleDTO.getCantidad()
                );
            }

            BigDecimal detSubtotal = detalleDTO.getSubtotal() != null
                    ? detalleDTO.getSubtotal()
                    : detalleDTO.getPrecioUnitario().multiply(BigDecimal.valueOf(detalleDTO.getCantidad()));

            DetalleVenta detalle = DetalleVenta.builder()
                    .venta(venta)
                    .producto(producto)
                    .cantidad(detalleDTO.getCantidad())
                    .precioUnitario(detalleDTO.getPrecioUnitario())
                    .subtotal(detSubtotal)
                    .build();

            detalleVentaRepository.save(detalle);

            productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "SALIDA");
        }

        return venta;
    }

    private void calcularMontos(VentaDTO dto) {
        if (dto.getSubtotal() == null || dto.getIva() == null || dto.getTotal() == null) {
            BigDecimal calcSubtotal = BigDecimal.ZERO;
            for (DetalleVentaDTO det : dto.getDetalles()) {
                BigDecimal detSubtotal = det.getSubtotal() != null
                        ? det.getSubtotal()
                        : det.getPrecioUnitario().multiply(BigDecimal.valueOf(det.getCantidad()));
                calcSubtotal = calcSubtotal.add(detSubtotal);
            }
            dto.setSubtotal(calcSubtotal);
            if (dto.getIva() == null) {
                dto.setIva(calcSubtotal.multiply(new BigDecimal("0.15")));
            }
            if (dto.getTotal() == null) {
                dto.setTotal(calcSubtotal.add(dto.getIva()));
            }
        }
    }

    public void anular(Long id) {
        Venta venta = getById(id);

        if ("ANULADA".equals(venta.getEstado())) {
            throw new BadRequestException("La venta ya está anulada");
        }

        List<DetalleVenta> detalles = detalleVentaRepository.findByVentaId(id);
        for (DetalleVenta detalle : detalles) {
            productoService.actualizarStock(detalle.getProducto().getId(), detalle.getCantidad(), "ENTRADA");
        }

        venta.setEstado("ANULADA");
        venta.setFechaAnulacion(LocalDateTime.now());
        ventaRepository.save(venta);
    }

    @Transactional(readOnly = true)
    public List<Venta> listByFecha(LocalDate inicio, LocalDate fin) {
        LocalDateTime desde = inicio.atStartOfDay();
        LocalDateTime hasta = fin.atTime(LocalTime.MAX);
        return ventaRepository.findByFechaCreacionBetweenOrderByFechaCreacionDesc(desde, hasta);
    }

    private String generarNumeroFactura() {
        long count = ventaRepository.count();
        String fecha = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        return "FV-" + fecha + "-" + String.format("%04d", count + 1);
    }
}
