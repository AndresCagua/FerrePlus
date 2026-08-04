package com.ferreplus.service;

import com.ferreplus.entity.MovimientoStock;
import com.ferreplus.entity.Producto;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.MovimientoStockRepository;
import com.ferreplus.repository.ProductoRepository;
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
public class ProductoService {

    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<Producto> list() {
        return productoRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Producto getById(Long id) {
        return productoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado con id: " + id));
    }

    public Producto create(Producto producto) {
        producto = productoRepository.save(producto);
        auditService.registrarEvento("PRODUCTO", producto.getId(), "CREAR", jsonDetalle(producto));
        return producto;
    }

    public Producto update(Long id, Producto productoActualizado) {
        Producto producto = getById(id);
        Map<String, Object> antes = snapshot(producto);
        producto.setNombre(productoActualizado.getNombre());
        producto.setDescripcion(productoActualizado.getDescripcion());
        producto.setCodigoBarras(productoActualizado.getCodigoBarras());
        producto.setUbicacion(productoActualizado.getUbicacion());
        producto.setStockMinimo(productoActualizado.getStockMinimo());
        producto.setStockMaximo(productoActualizado.getStockMaximo());
        producto.setPrecioCompra(productoActualizado.getPrecioCompra());
        producto.setPrecioVenta(productoActualizado.getPrecioVenta());
        producto.setUnidadMedida(productoActualizado.getUnidadMedida());
        producto.setImagen(productoActualizado.getImagen());
        // Preservar relaciones que el frontend puede no enviar (evita pisar con null).
        // El form de producto no incluye categoria/proveedor: si el request no las trae,
        // se conserva el valor actual en BD (data-loss guard, expuesto por el diff de auditoria).
        if (productoActualizado.getCategoria() != null) {
            producto.setCategoria(productoActualizado.getCategoria());
        }
        if (productoActualizado.getProveedor() != null) {
            producto.setProveedor(productoActualizado.getProveedor());
        }
        producto.setActivo(productoActualizado.isActivo());
        Producto guardado = productoRepository.save(producto);
        auditService.registrarEvento("PRODUCTO", guardado.getId(), "ACTUALIZAR",
                AuditDiff.toJson(objectMapper, AuditDiff.diff(antes, snapshot(guardado))));
        return guardado;
    }

    public void delete(Long id) {
        Producto producto = getById(id);
        producto.setActivo(false);
        productoRepository.save(producto);
        auditService.registrarEvento("PRODUCTO", producto.getId(), "ELIMINAR", jsonDetalleEliminar(producto));
    }

    @Transactional(readOnly = true)
    public List<Producto> listByCategoria(Long categoriaId) {
        return productoRepository.findByCategoriaId(categoriaId);
    }

    @Transactional(readOnly = true)
    public List<Producto> listStockBajo() {
        return productoRepository.findStockBajo();
    }

    public void actualizarStock(Long productoId, Integer cantidad, String tipo) {
        Producto producto = getById(productoId);
        int stockAnterior = producto.getStockActual();

        int nuevoStock;
        switch (tipo.toUpperCase()) {
            case "ENTRADA":
                nuevoStock = stockAnterior + cantidad;
                break;
            case "SALIDA":
                nuevoStock = stockAnterior - cantidad;
                break;
            case "AJUSTE":
                nuevoStock = cantidad; // cantidad representa el nuevo valor absoluto
                break;
            default:
                throw new BadRequestException("Tipo de movimiento no válido: " + tipo);
        }

        if (nuevoStock < 0) {
            throw new BadRequestException("Stock insuficiente. Stock actual: " + stockAnterior + ", intentando: " + (tipo.equals("SALIDA") ? cantidad : ""));
        }

        producto.setStockActual(nuevoStock);
        productoRepository.save(producto);

        MovimientoStock movimiento = MovimientoStock.builder()
                .producto(producto)
                .cantidad(tipo.equals("AJUSTE") ? nuevoStock - stockAnterior : cantidad)
                .tipo(tipo)
                .stockAnterior(stockAnterior)
                .stockPosterior(nuevoStock)
                .build();

        movimientoStockRepository.save(movimiento);
    }

    @Transactional(readOnly = true)
    public List<Producto> buscar(String query) {
        return productoRepository.findByNombreContainingIgnoreCaseOrCodigoBarrasContainingIgnoreCase(query, query);
    }

    private String jsonDetalle(Producto p) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", p.getNombre());
        if (p.getCodigoBarras() != null) {
            data.put("codigoBarras", p.getCodigoBarras());
        }
        return json(data);
    }

    /**
     * Snapshot plano de campos escalares del producto para el diff ANTES/DESPUÉS
     * (selección explícita — evita serializar relaciones/colecciones LAZY).
     */
    private Map<String, Object> snapshot(Producto p) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", p.getNombre());
        data.put("descripcion", p.getDescripcion());
        data.put("codigoBarras", p.getCodigoBarras());
        data.put("ubicacion", p.getUbicacion());
        data.put("stockMinimo", p.getStockMinimo());
        data.put("stockMaximo", p.getStockMaximo());
        data.put("precioCompra", p.getPrecioCompra());
        data.put("precioVenta", p.getPrecioVenta());
        data.put("unidadMedida", p.getUnidadMedida());
        data.put("imagen", p.getImagen());
        data.put("categoriaId", p.getCategoria() != null ? p.getCategoria().getId() : null);
        data.put("proveedorId", p.getProveedor() != null ? p.getProveedor().getId() : null);
        data.put("activo", p.isActivo());
        return data;
    }

    private String jsonDetalleEliminar(Producto p) {
        Map<String, Object> data = new HashMap<>();
        data.put("nombre", p.getNombre());
        data.put("activo", p.isActivo());
        return json(data);
    }

    private String json(Map<?, ?> data) {
        try {
            return objectMapper.writeValueAsString(data);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }
}
