package com.ferreplus.publico.model;

import java.time.Instant;
import java.util.List;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("postulaciones")
@CompoundIndex(name = "convocatoria_idempotency_unique", def = "{'convocatoriaId': 1, 'idempotencyKey': 1}", unique = true)
public class Postulacion {
    @Id private String id;
    @Indexed private String convocatoriaId;
    private String nombres;
    private String apellidos;
    private String email;
    private String telefono;
    private String ciudad;
    private CvMetadata cv;
    @Indexed private EstadoPostulacion estado;
    private List<HistorialEstado> historial;
    private String idempotencyKey;
    private Instant createdAt;
    private Instant updatedAt;

    public record HistorialEstado(String actor, Instant fecha, String anterior, String nuevo) {}
}
