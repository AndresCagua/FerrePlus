package com.ferreplus.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "guias_sistema", uniqueConstraints = @UniqueConstraint(
        name = "uk_guias_sistema", columnNames = {"modulo", "ruta", "titulo"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GuiaSistema {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String modulo;

    @Column(nullable = false, length = 160)
    private String ruta;

    @Column(nullable = false, length = 160)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "JSONB")
    private String pasos;

    @Column(columnDefinition = "TEXT")
    private String keywords;
}
