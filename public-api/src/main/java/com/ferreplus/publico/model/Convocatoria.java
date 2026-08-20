package com.ferreplus.publico.model;

import java.time.Instant;
import java.util.List;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("convocatorias")
public class Convocatoria {
    @Id private String id;
    private String titulo;
    private String descripcion;
    private List<String> requisitos;
    private String ubicacion;
    private String modalidad;
    @Indexed private Instant fechaApertura;
    @Indexed private Instant fechaCierre;
    @Indexed private EstadoConvocatoria estado;
    private Instant createdAt;
    private Instant updatedAt;
}
