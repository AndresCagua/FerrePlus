package com.ferreplus.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Catálogo de módulos del sistema (R1). Cada módulo agrupa un conjunto de
 * permisos ({@link Permiso}) referenciados por FK. El catálogo es dato, no
 * código: se siembra con {@code DataSeeder} y puede administrarse sin deploy.
 */
@Entity
@Table(name = "modulos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Modulo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String nombre;

    @Column(nullable = false, unique = true, length = 30)
    private String codigo;

    @Column(nullable = false)
    private Integer orden;

    @OneToMany(mappedBy = "modulo", fetch = FetchType.LAZY)
    @JsonIgnoreProperties("modulo")
    @Builder.Default
    private List<Permiso> permisos = new ArrayList<>();
}
