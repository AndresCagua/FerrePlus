package com.ferreplus.service;

import com.ferreplus.dto.ActualizarPrecioVentaDTO;
import com.ferreplus.dto.HistoricoPrecioProductoDTO;
import com.ferreplus.dto.PrecioProductoDTO;
import com.ferreplus.entity.HistoricoPrecioProducto;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.HistoricoPrecioProductoRepository;
import com.ferreplus.repository.ProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
public class PrecioService {

    private final ProductoRepository productoRepository;
    private final HistoricoPrecioProductoRepository historicoRepository;

    @Transactional(readOnly = true)
    public List<PrecioProductoDTO> listarPrecios() {
        return productoRepository.findAll().stream()
                .filter(Producto::isActivo)
                .map(this::mapToPrecioProductoDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PrecioProductoDTO obtenerPrecio(Long id) {
        Producto producto = productoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado con id: " + id));

        if (!producto.isActivo()) {
            throw new ResourceNotFoundException("Producto no encontrado con id: " + id);
        }

        return mapToPrecioProductoDTO(producto);
    }

    @Transactional(readOnly = true)
    public List<HistoricoPrecioProductoDTO> obtenerHistorial(Long id) {
        productoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado con id: " + id));

        return historicoRepository.findByProductoIdOrderByFechaCambioDesc(id).stream()
                .map(this::mapToHistoricoDTO)
                .collect(Collectors.toList());
    }

    public PrecioProductoDTO actualizarPrecioVenta(Long id, ActualizarPrecioVentaDTO dto, Usuario usuario) {
        if (dto.getNuevoPrecio() != null && dto.getMargenPorcentaje() != null) {
            throw new BadRequestException("Debe proporcionar solo el nuevo precio o el margen porcentual, no ambos");
        }
        if (dto.getNuevoPrecio() == null && dto.getMargenPorcentaje() == null) {
            throw new BadRequestException("Debe proporcionar el nuevo precio o el margen porcentual");
        }

        Producto producto = productoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado con id: " + id));

        if (!producto.isActivo()) {
            throw new ResourceNotFoundException("Producto no encontrado con id: " + id);
        }

        BigDecimal precioVenta;
        if (dto.getMargenPorcentaje() != null) {
            if (producto.getPrecioCompra().compareTo(BigDecimal.ZERO) <= 0) {
                throw new BadRequestException("No se puede calcular el margen porque el producto no tiene precio de compra registrado.");
            }

            BigDecimal factor = BigDecimal.ONE.add(
                    BigDecimal.valueOf(dto.getMargenPorcentaje()).divide(new BigDecimal("100"), 10, RoundingMode.HALF_UP)
            );
            precioVenta = producto.getPrecioCompra().multiply(factor)
                    .setScale(2, RoundingMode.HALF_UP);
        } else {
            precioVenta = dto.getNuevoPrecio();
        }

        producto.setPrecioVenta(precioVenta);
        productoRepository.save(producto);

        registrarHistorico(producto, producto.getPrecioCompra(), producto.getPrecioVenta(),
                "ACTUALIZACION_VENTA", dto.getReferencia(), usuario);

        return mapToPrecioProductoDTO(producto);
    }

    public void registrarHistorico(Producto producto, BigDecimal precioCompra, BigDecimal precioVenta,
                                    String tipoCambio, String referencia, Usuario usuario) {
        HistoricoPrecioProducto historico = HistoricoPrecioProducto.builder()
                .producto(producto)
                .precioCompra(precioCompra)
                .precioVenta(precioVenta)
                .tipoCambio(tipoCambio)
                .referencia(referencia)
                .usuario(usuario)
                .build();

        historicoRepository.save(historico);
    }

    private PrecioProductoDTO mapToPrecioProductoDTO(Producto producto) {
        PrecioProductoDTO dto = new PrecioProductoDTO();
        dto.setId(producto.getId());
        dto.setNombre(producto.getNombre());
        dto.setCodigoBarras(producto.getCodigoBarras());
        dto.setPrecioCompra(producto.getPrecioCompra());
        dto.setPrecioVenta(producto.getPrecioVenta());

        BigDecimal precioCompra = producto.getPrecioCompra();
        if (precioCompra != null && precioCompra.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal ganancia = producto.getPrecioVenta().subtract(precioCompra);
            dto.setGanancia(ganancia);

            Double margen = ganancia.divide(precioCompra, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .doubleValue();
            dto.setMargenPorcentaje(margen);
        } else {
            dto.setGanancia(null);
            dto.setMargenPorcentaje(null);
        }

        if (producto.getFechaActualizacion() != null) {
            dto.setFechaActualizacion(
                    producto.getFechaActualizacion().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
            );
        }

        return dto;
    }

    private HistoricoPrecioProductoDTO mapToHistoricoDTO(HistoricoPrecioProducto historico) {
        HistoricoPrecioProductoDTO dto = new HistoricoPrecioProductoDTO();
        dto.setId(historico.getId());
        dto.setProductoId(historico.getProducto().getId());
        dto.setPrecioCompra(historico.getPrecioCompra());
        dto.setPrecioVenta(historico.getPrecioVenta());
        dto.setTipoCambio(historico.getTipoCambio());
        dto.setReferencia(historico.getReferencia());

        if (historico.getFechaCambio() != null) {
            dto.setFechaCambio(
                    historico.getFechaCambio().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
            );
        }

        if (historico.getUsuario() != null) {
            dto.setUsuarioNombre(historico.getUsuario().getNombre());
        }

        return dto;
    }
}
