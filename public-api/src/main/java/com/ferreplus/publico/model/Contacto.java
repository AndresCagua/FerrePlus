package com.ferreplus.publico.model;

import java.time.Instant;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("contactos")
public class Contacto {
    @Id private String id;
    private String nombre;
    private String email;
    private String telefono;
    private String asunto;
    private String mensaje;
    @Indexed private EstadoContacto estado;
    private String ip;
    private String fingerprint;
    @Indexed(unique = true) private String idempotencyKey;
    private Instant createdAt;
    private Instant updatedAt;

    public enum EstadoContacto { UNREAD, READ }
}
