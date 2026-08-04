package com.ferreplus.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDateTime;

/**
 * Respuesta de {@code GET /api/logs} (R2). Exponer la entidad JPA {@code Auditoria}
 * está prohibido; el DTO oculta la relación LAZY y deja {@code detalle} tal cual
 * (texto o JSON crudo — edge case 9). {@code usuarioId}/{@code usuarioNombre} se
 * omiten cuando son {@code null} (eventos de sistema/seed, edge case 5).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AuditoriaDTO {

    private Long id;
    private String entidad;
    private Long entidadId;
    private String accion;
    private Long usuarioId;
    private String usuarioNombre;
    private LocalDateTime fecha;
    private String detalle;

    public AuditoriaDTO() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEntidad() {
        return entidad;
    }

    public void setEntidad(String entidad) {
        this.entidad = entidad;
    }

    public Long getEntidadId() {
        return entidadId;
    }

    public void setEntidadId(Long entidadId) {
        this.entidadId = entidadId;
    }

    public String getAccion() {
        return accion;
    }

    public void setAccion(String accion) {
        this.accion = accion;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getUsuarioNombre() {
        return usuarioNombre;
    }

    public void setUsuarioNombre(String usuarioNombre) {
        this.usuarioNombre = usuarioNombre;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public String getDetalle() {
        return detalle;
    }

    public void setDetalle(String detalle) {
        this.detalle = detalle;
    }
}
