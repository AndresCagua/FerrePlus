package com.ferreplus.dto;

/**
 * Opción de usuario para el selector del filtro de logs (R7 refinamiento).
 * Expone solo {@code id} y {@code nombre} — nunca email/password/overrides.
 * No debe usarse para listados de usuarios del módulo USUARIOS (allí va UsuarioDTO).
 */
public class UsuarioOpcionDTO {

    private Long id;
    private String nombre;

    public UsuarioOpcionDTO() {
    }

    public UsuarioOpcionDTO(Long id, String nombre) {
        this.id = id;
        this.nombre = nombre;
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
}
