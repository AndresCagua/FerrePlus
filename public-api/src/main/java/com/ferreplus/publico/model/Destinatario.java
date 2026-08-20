package com.ferreplus.publico.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("destinatarios")
@CompoundIndex(name = "tipo_email_unique", def = "{'tipo': 1, 'email': 1}", unique = true)
public class Destinatario {
    @Id private String id;
    private TipoDestinatario tipo;
    private String email;
    private boolean activo;
}
