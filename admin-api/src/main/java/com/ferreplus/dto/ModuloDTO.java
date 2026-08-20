package com.ferreplus.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.ArrayList;
import java.util.List;

/**
 * Respuesta de {@code GET /api/modulos}: módulo con sus permisos agrupados (R2).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ModuloDTO {

    private Long id;
    private String nombre;
    private String codigo;
    private Integer orden;
    private List<PermisoDTO> permisos = new ArrayList<>();

    public ModuloDTO() {
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

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public Integer getOrden() {
        return orden;
    }

    public void setOrden(Integer orden) {
        this.orden = orden;
    }

    public List<PermisoDTO> getPermisos() {
        return permisos;
    }

    public void setPermisos(List<PermisoDTO> permisos) {
        this.permisos = permisos;
    }
}
