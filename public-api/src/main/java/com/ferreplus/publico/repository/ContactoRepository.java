package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.Contacto;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ContactoRepository extends MongoRepository<Contacto, String> {
    Optional<Contacto> findByIdempotencyKey(String idempotencyKey);
}
