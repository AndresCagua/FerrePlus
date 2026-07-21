package com.ferreplus.service;

import com.ferreplus.dto.CompraDTO;
import com.ferreplus.dto.DetalleCompraDTO;
import com.ferreplus.entity.*;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.CompraRepository;
import com.ferreplus.repository.DetalleCompraRepository;
import com.ferreplus.repository.ProductoRepository;
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
    private final PrecioService precioService;
    private final ProductoRepository productoRepository;

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

        // Calcular subtotal, iva, total si no vienen
        calcularMontos(dto);

        String numeroFactura = dto.getNumeroFactura() != null && !dto.getNumeroFactura().isBlank()
                ? dto.getNumeroFactura()
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

            BigDecimal detSubtotal = detalleDTO.getSubtotal() != null
                    ? detalleDTO.getSubtotal()
                    : detalleDTO.getPrecioUnitario().multiply(BigDecimal.valueOf(detalleDTO.getCantidad()));

            DetalleCompra detalle = DetalleCompra.builder()
                    .compra(compra)
                    .producto(producto)
                    .cantidad(detalleDTO.getCantidad())
                    .precioUnitario(detalleDTO.getPrecioUnitario())
                    .subtotal(detSubtotal)
                    .build();

            detalleCompraRepository.save(detalle);

            productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "ENTRADA");

            producto.setPrecioCompra(detalleDTO.getPrecioUnitario());
            productoRepository.save(producto);
            precioService.registrarHistorico(producto, detalleDTO.getPrecioUnitario(),
                    producto.getPrecioVenta(), "COMPRA", compra.getNumeroFactura(), null);
        }

        return compra;
    }

    private void calcularMontos(CompraDTO dto) {
        if (dto.getSubtotal() == null || dto.getIva() == null || dto.getTotal() == null) {
            BigDecimal calcSubtotal = BigDecimal.ZERO;
            for (DetalleCompraDTO det : dto.getDetalles()) {
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

    @Transactional
    public Compra update(Long id, CompraDTO dto) {
        Compra compra = getById(id);

        if ("ANULADA".equals(compra.getEstado())) {
            throw new BadRequestException("No se puede editar una compra anulada");
        }

        // 1. Revertir stock de los detalles actuales
        List<DetalleCompra> viejosDetalles = detalleCompraRepository.findByCompraId(id);
        for (DetalleCompra detalle : viejosDetalles) {
            productoService.actualizarStock(detalle.getProducto().getId(), detalle.getCantidad(), "SALIDA");
        }

        // 2. Calcular montos si no vienen
        calcularMontos(dto);

        // 3. Actualizar datos de la compra
        Proveedor proveedor = proveedorService.getById(dto.getProveedorId());
        compra.setProveedor(proveedor);
        compra.setNumeroFactura(dto.getNumeroFactura());
        compra.setSubtotal(dto.getSubtotal());
        compra.setDescuento(dto.getDescuento() != null ? dto.getDescuento() : BigDecimal.ZERO);
        compra.setIva(dto.getIva());
        compra.setTotal(dto.getTotal());
        compra.setObservaciones(dto.getObservaciones());
        compra.setFechaFactura(dto.getFechaFactura() != null ? dto.getFechaFactura() : LocalDate.now());

        // 4. Eliminar detalles viejos
        detalleCompraRepository.deleteAll(viejosDetalles);

        // 5. Crear nuevos detalles y aplicar stock
        for (DetalleCompraDTO detalleDTO : dto.getDetalles()) {
            Producto producto = productoService.getById(detalleDTO.getProductoId());

            BigDecimal subtotal = detalleDTO.getSubtotal() != null
                    ? detalleDTO.getSubtotal()
                    : detalleDTO.getPrecioUnitario().multiply(BigDecimal.valueOf(detalleDTO.getCantidad()));

            DetalleCompra detalle = DetalleCompra.builder()
                    .compra(compra)
                    .producto(producto)
                    .cantidad(detalleDTO.getCantidad())
                    .precioUnitario(detalleDTO.getPrecioUnitario())
                    .subtotal(subtotal)
                    .build();

            detalleCompraRepository.save(detalle);

            productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "ENTRADA");

            producto.setPrecioCompra(detalleDTO.getPrecioUnitario());
            productoRepository.save(producto);
            precioService.registrarHistorico(producto, detalleDTO.getPrecioUnitario(),
                    producto.getPrecioVenta(), "COMPRA", compra.getNumeroFactura(), null);
        }

        return compraRepository.save(compra);
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
