package com.ferreplus.publico.model;

import java.time.Instant;
import java.util.List;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("publicaciones")
@CompoundIndex(name = "estado_fecha_publicacion_idx", def = "{'estado': 1, 'fechaPublicacion': -1}")
@CompoundIndex(name = "estado_fecha_vencimiento_idx", def = "{'estado': 1, 'fechaVencimiento': 1}")
public class Publicacion {
    @Id private String id;
    @Indexed(unique = true) private String slug;
    private String titulo;
    private String resumen;
    private String descripcion;
    private ImagenMedia portada;
    private List<ImagenMedia> galeria;
    private String videoUrl;
    private List<String> enlacesX;
    private String categoria;
    private EstadoPublicacion estado;
    private Instant fechaPublicacion;
    private Instant fechaVencimiento;
    private Autor autor;
    private MetadataSEO metadataSEO;
    private String contenidoEnriquecido;
    private Instant createdAt;
    private Instant updatedAt;

    public record Autor(String sub, String nombre) {}
}
