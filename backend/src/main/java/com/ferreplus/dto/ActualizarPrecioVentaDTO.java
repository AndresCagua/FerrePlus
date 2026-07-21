package com.ferreplus.dto;

import java.math.BigDecimal;

public class ActualizarPrecioVentaDTO {

    private BigDecimal nuevoPrecio;
    private Double margenPorcentaje;
    private String referencia;

    public ActualizarPrecioVentaDTO() {
    }

    public ActualizarPrecioVentaDTO(BigDecimal nuevoPrecio, Double margenPorcentaje, String referencia) {
        this.nuevoPrecio = nuevoPrecio;
        this.margenPorcentaje = margenPorcentaje;
        this.referencia = referencia;
    }

    public BigDecimal getNuevoPrecio() {
        return nuevoPrecio;
    }

    public void setNuevoPrecio(BigDecimal nuevoPrecio) {
        this.nuevoPrecio = nuevoPrecio;
    }

    public Double getMargenPorcentaje() {
        return margenPorcentaje;
    }

    public void setMargenPorcentaje(Double margenPorcentaje) {
        this.margenPorcentaje = margenPorcentaje;
    }

    public String getReferencia() {
        return referencia;
    }

    public void setReferencia(String referencia) {
        this.referencia = referencia;
    }
}
