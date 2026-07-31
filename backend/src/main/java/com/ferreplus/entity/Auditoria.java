package com.ferreplus.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Registro genérico de auditoría (R10). Diseñada para todo el sistema:
 * {@code entidad}/{@code entidad_id} permiten extenderla a VENTA, COMPRA, etc.
 * sin migración. {@code usuario_id} es nullable (eventos de sistema/seed).
 */
@Entity
@Table(name = "auditoria")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Auditoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String entidad;

    @Column(name = "entidad_id")
    private Long entidadId;

    @Column(nullable = false, length = 20)
    private String accion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @Column(nullable = false, updatable = false)
    private LocalDateTime fecha;

    @Column(columnDefinition = "TEXT")
    private String detalle;

    @PrePersist
    protected void onCreate() {
        fecha = LocalDateTime.now();
    }
}
