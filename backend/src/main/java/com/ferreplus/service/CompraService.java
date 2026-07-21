package com.ferreplus.service;

import com.ferreplus.dto.CompraDTO;
import com.ferreplus.dto.DetalleCompraDTO;
import com.ferreplus.entity.*;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.CompraRepository;
import com.ferreplus.repository.DetalleCompraRepository;
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
public class CompraService {

    private final CompraRepository compraRepository;
    private final DetalleCompraRepository detalleCompraRepository;
    private final ProductoService productoService;
    private final ProveedorService proveedorService;
    private final UsuarioService usuarioService;

    @Transactional(readOnly = true)
    public List<Compra> list() {
        return compraRepository.findAllByOrderByFechaCreacionDesc();
    }

    @Transactional(readOnly = true)
    public Compra getById(Long id) {
        return compraRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Compra no encontrada con id: " + id));
    }

    public Compra create(CompraDTO dto) {
        Proveedor proveedor = proveedorService.getById(dto.getProveedorId());
        Usuario usuario = usuarioService.getById(dto.getUsuarioId());

        String numeroFactura = dto.getObservaciones() != null && dto.getObservaciones().contains("FACT:")
                ? dto.getObservaciones()
                : generarNumeroFactura();

        Compra compra = Compra.builder()
                .numeroFactura(numeroFactura)
                .proveedor(proveedor)
                .subtotal(dto.getSubtotal())
                .descuento(dto.getDescuento() != null ? dto.getDescuento() : BigDecimal.ZERO)
                .iva(dto.getIva())
                .total(dto.getTotal())
                .estado("COMPLETADA")
                .observaciones(dto.getObservaciones())
                .fechaFactura(dto.getFechaFactura() != null ? dto.getFechaFactura() : LocalDate.now())
                .usuario(usuario)
                .build();

        compra = compraRepository.save(compra);

        for (DetalleCompraDTO detalleDTO : dto.getDetalles()) {
            Producto producto = productoService.getById(detalleDTO.getProductoId());

            DetalleCompra detalle = DetalleCompra.builder()
                    .compra(compra)
                    .producto(producto)
                    .cantidad(detalleDTO.getCantidad())
                    .precioUnitario(detalleDTO.getPrecioUnitario())
                    .subtotal(detalleDTO.getSubtotal())
                    .build();

            detalleCompraRepository.save(detalle);

            productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "ENTRADA");
        }

        return compra;
    }

    public void anular(Long id) {
        Compra compra = getById(id);

        if ("ANULADA".equals(compra.getEstado())) {
            throw new BadRequestException("La compra ya está anulada");
        }

        List<DetalleCompra> detalles = detalleCompraRepository.findByCompraId(id);
        for (DetalleCompra detalle : detalles) {
            productoService.actualizarStock(detalle.getProducto().getId(), detalle.getCantidad(), "SALIDA");
        }

        compra.setEstado("ANULADA");
        compra.setFechaAnulacion(LocalDateTime.now());
        compraRepository.save(compra);
    }

    @Transactional(readOnly = true)
    public List<Compra> listByFecha(LocalDate inicio, LocalDate fin) {
        LocalDateTime desde = inicio.atStartOfDay();
        LocalDateTime hasta = fin.atTime(LocalTime.MAX);
        return compraRepository.findByFechaCreacionBetweenOrderByFechaCreacionDesc(desde, hasta);
    }

    private String generarNumeroFactura() {
        long count = compraRepository.count();
        String fecha = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        return "FC-" + fecha + "-" + String.format("%04d", count + 1);
    }
}
