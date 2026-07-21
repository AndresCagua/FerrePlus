package com.ferreplus.service;

import com.ferreplus.entity.MovimientoStock;
import com.ferreplus.entity.Producto;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.MovimientoStockRepository;
import com.ferreplus.repository.ProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ProductoService {

    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;

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
        return productoRepository.save(producto);
    }

    public Producto update(Long id, Producto productoActualizado) {
        Producto producto = getById(id);
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
        producto.setCategoria(productoActualizado.getCategoria());
        producto.setProveedor(productoActualizado.getProveedor());
        producto.setActivo(productoActualizado.isActivo());
        return productoRepository.save(producto);
    }

    public void delete(Long id) {
        Producto producto = getById(id);
        producto.setActivo(false);
        productoRepository.save(producto);
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
}
