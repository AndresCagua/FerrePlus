package com.ferreplus.dto;

import java.math.BigDecimal;

public class PrecioProductoDTO {

    private Long id;
    private String nombre;
    private String codigoBarras;
    private BigDecimal precioCompra;
    private BigDecimal precioVenta;
    private BigDecimal ganancia;
    private Double margenPorcentaje;
    private String fechaActualizacion;

    public PrecioProductoDTO() {
    }

    public PrecioProductoDTO(Long id, String nombre, String codigoBarras,
                             BigDecimal precioCompra, BigDecimal precioVenta,
                             BigDecimal ganancia, Double margenPorcentaje,
                             String fechaActualizacion) {
        this.id = id;
        this.nombre = nombre;
        this.codigoBarras = codigoBarras;
        this.precioCompra = precioCompra;
        this.precioVenta = precioVenta;
        this.ganancia = ganancia;
        this.margenPorcentaje = margenPorcentaje;
        this.fechaActualizacion = fechaActualizacion;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getCodigoBarras() {
        return codigoBarras;
    }

    public void setCodigoBarras(String codigoBarras) {
        this.codigoBarras = codigoBarras;
    }

    public BigDecimal getPrecioCompra() {
        return precioCompra;
    }

    public void setPrecioCompra(BigDecimal precioCompra) {
        this.precioCompra = precioCompra;
    }

    public BigDecimal getPrecioVenta() {
        return precioVenta;
    }

    public void setPrecioVenta(BigDecimal precioVenta) {
        this.precioVenta = precioVenta;
    }

    public BigDecimal getGanancia() {
        return ganancia;
    }

    public void setGanancia(BigDecimal ganancia) {
        this.ganancia = ganancia;
    }

    public Double getMargenPorcentaje() {
        return margenPorcentaje;
    }

    public void setMargenPorcentaje(Double margenPorcentaje) {
        this.margenPorcentaje = margenPorcentaje;
    }

    public String getFechaActualizacion() {
        return fechaActualizacion;
    }

    public void setFechaActualizacion(String fechaActualizacion) {
        this.fechaActualizacion = fechaActualizacion;
    }
}
