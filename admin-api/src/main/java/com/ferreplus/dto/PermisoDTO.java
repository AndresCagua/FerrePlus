package com.ferreplus.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Respuesta plana de {@code GET /api/permisos} (R2). También se usa anidada en
 * {@link ModuloDTO}, donde los campos de módulo quedan {@code null} y se omiten
 * en la serialización gracias a {@code @JsonInclude(NON_NULL)}.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PermisoDTO {

    private Long id;
    private String codigo;
    private String nombre;
    private String accion;
    private Long moduloId;
    private String moduloCodigo;
    private String moduloNombre;

    public PermisoDTO() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getAccion() {
        return accion;
    }

    public void setAccion(String accion) {
        this.accion = accion;
    }

    public Long getModuloId() {
        return moduloId;
    }

    public void setModuloId(Long moduloId) {
        this.moduloId = moduloId;
    }

    public String getModuloCodigo() {
        return moduloCodigo;
    }

    public void setModuloCodigo(String moduloCodigo) {
        this.moduloCodigo = moduloCodigo;
    }

    public String getModuloNombre() {
        return moduloNombre;
    }

    public void setModuloNombre(String moduloNombre) {
        this.moduloNombre = moduloNombre;
    }
}
