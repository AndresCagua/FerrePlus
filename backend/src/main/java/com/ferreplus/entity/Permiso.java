package com.ferreplus.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

/**
 * Acción granular dentro de un módulo (R1). El {@code codigo} sigue el patrón
 * {@code <MODULO>_<ACCION>} (ej. {@code VENTAS_VER}) y es único globalmente.
 */
@Entity
@Table(name = "permisos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Permiso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String codigo;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(nullable = false, length = 20)
    private String accion;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JsonIgnoreProperties("permisos")
    @JoinColumn(name = "modulo_id", nullable = false)
    private Modulo modulo;
}
