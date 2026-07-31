package com.ferreplus.dto;

/**
 * Override de permiso por usuario en respuestas (R4).
 */
public class UsuarioPermisoDTO {

    private String permisoCodigo;

    private boolean concedido;

    public UsuarioPermisoDTO() {
    }

    public UsuarioPermisoDTO(String permisoCodigo, boolean concedido) {
        this.permisoCodigo = permisoCodigo;
        this.concedido = concedido;
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
