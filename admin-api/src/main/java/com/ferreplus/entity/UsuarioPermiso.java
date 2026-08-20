package com.ferreplus.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

/**
 * Override de permiso por usuario (R4): agrega o quita un permiso individual
 * respecto del rol base. PK compuesta {@code (usuario_id, permiso_id)} impide
 * más de un override por (usuario, permiso). {@code concedido=true} agrega,
 * {@code concedido=false} quita.
 */
@Entity
@Table(name = "usuario_permisos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(UsuarioPermisoId.class)
public class UsuarioPermiso {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JsonIgnoreProperties({"rol", "overrides"})
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JsonIgnoreProperties("modulo")
    @JoinColumn(name = "permiso_id", nullable = false)
    private Permiso permiso;

    @Column(nullable = false)
    private boolean concedido;
}
