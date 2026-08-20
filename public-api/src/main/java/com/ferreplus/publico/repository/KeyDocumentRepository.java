package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.KeyDocument;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface KeyDocumentRepository extends MongoRepository<KeyDocument, String> {
    Optional<KeyDocument> findByKidAndActivaTrue(String kid);
}
