package com.ferreplus.publico.model;

import java.time.Instant;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document("keys")
@CompoundIndex(name = "activa_expiracion_idx", def = "{'activa': 1, 'expiracion': 1}")
public class KeyDocument {
    @Id private String id;
    @Indexed(unique = true) private String kid;
    private String publicKey;
    private Instant expiracion;
    private boolean activa;
}
