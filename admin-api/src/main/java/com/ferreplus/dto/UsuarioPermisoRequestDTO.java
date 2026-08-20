package com.ferreplus.dto;

/**
 * Override de permiso por usuario en requests (R4): {@code permisoCodigo} +
 * {@code concedido} obligatorios.
 */
public class UsuarioPermisoRequestDTO {

    private String permisoCodigo;

    private boolean concedido;

    public UsuarioPermisoRequestDTO() {
    }

    public String getPermisoCodigo() {
        return permisoCodigo;
    }

    public void setPermisoCodigo(String permisoCodigo) {
        this.permisoCodigo = permisoCodigo;
    }

    public boolean isConcedido() {
        return concedido;
    }

    public void setConcedido(boolean concedido) {
        this.concedido = concedido;
    }
}
