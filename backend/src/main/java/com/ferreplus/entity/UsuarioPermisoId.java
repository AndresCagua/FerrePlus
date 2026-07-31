package com.ferreplus.entity;

import java.io.Serializable;
import java.util.Objects;

/**
 * Clase de clave primaria compuesta de {@link UsuarioPermiso}.
 * Los tipos deben coincidir con los ids de las entidades referenciadas
 * ({@code Long}); equals/hashCode correctos o Hibernate falla en merge/removal.
 */
public class UsuarioPermisoId implements Serializable {

    private Long usuario;
    private Long permiso;

    public UsuarioPermisoId() {
    }

    public UsuarioPermisoId(Long usuario, Long permiso) {
        this.usuario = usuario;
        this.permiso = permiso;
    }

    public Long getUsuario() {
        return usuario;
    }

    public void setUsuario(Long usuario) {
        this.usuario = usuario;
    }

    public Long getPermiso() {
        return permiso;
    }

    public void setPermiso(Long permiso) {
        this.permiso = permiso;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UsuarioPermisoId that = (UsuarioPermisoId) o;
        return Objects.equals(usuario, that.usuario) && Objects.equals(permiso, that.permiso);
    }

    @Override
    public int hashCode() {
        return Objects.hash(usuario, permiso);
    }
}
