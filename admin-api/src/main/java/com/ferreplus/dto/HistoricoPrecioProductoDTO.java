package com.ferreplus.dto;

import java.math.BigDecimal;

public class HistoricoPrecioProductoDTO {

    private Long id;
    private Long productoId;
    private BigDecimal precioCompra;
    private BigDecimal precioVenta;
    private String tipoCambio;
    private String referencia;
    private String fechaCambio;
    private String usuarioNombre;

    public HistoricoPrecioProductoDTO() {
    }

    public HistoricoPrecioProductoDTO(Long id, Long productoId,
                                      BigDecimal precioCompra, BigDecimal precioVenta,
                                      String tipoCambio, String referencia,
                                      String fechaCambio, String usuarioNombre) {
        this.id = id;
        this.productoId = productoId;
        this.precioCompra = precioCompra;
        this.precioVenta = precioVenta;
        this.tipoCambio = tipoCambio;
        this.referencia = referencia;
        this.fechaCambio = fechaCambio;
        this.usuarioNombre = usuarioNombre;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getProductoId() {
        return productoId;
    }

    public void setProductoId(Long productoId) {
        this.productoId = productoId;
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

    public String getTipoCambio() {
        return tipoCambio;
    }

    public void setTipoCambio(String tipoCambio) {
        this.tipoCambio = tipoCambio;
    }

    public String getReferencia() {
        return referencia;
    }

    public void setReferencia(String referencia) {
        this.referencia = referencia;
    }

    public String getFechaCambio() {
        return fechaCambio;
    }

    public void setFechaCambio(String fechaCambio) {
        this.fechaCambio = fechaCambio;
    }

    public String getUsuarioNombre() {
        return usuarioNombre;
    }

    public void setUsuarioNombre(String usuarioNombre) {
        this.usuarioNombre = usuarioNombre;
    }
}
