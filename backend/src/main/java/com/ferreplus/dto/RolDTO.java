package com.ferreplus.dto;

import java.util.ArrayList;
import java.util.List;

/**
 * Respuesta de rol: expone la matriz como array de códigos de permiso (R3).
 */
public class RolDTO {

    private Long id;
    private String nombre;
    private String descripcion;
    private List<String> permisos = new ArrayList<>();

    public RolDTO() {
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

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public List<String> getPermisos() {
        return permisos;
    }

    public void setPermisos(List<String> permisos) {
        this.permisos = permisos;
    }
}
