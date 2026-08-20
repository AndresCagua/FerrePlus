package com.ferreplus.publico.model;

import java.time.Instant;
import java.util.List;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("notificaciones")
public class Notificacion {
    @Id private String id;
    private TipoDestinatario tipo;
    private String referenciaId;
    private List<String> destinatarios;
    @Indexed private EstadoNotificacion estado;
    private int intentos;
    private String ultimoError;
    private Instant nextAttemptAt;
    private String correlationId;
    private Instant createdAt;
    private Instant updatedAt;
}
