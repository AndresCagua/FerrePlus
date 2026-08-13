package com.ferreplus.repository;

import com.ferreplus.entity.DocumentEmbedding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentEmbeddingRepository extends JpaRepository<DocumentEmbedding, Long> {

    @Query(value = "SELECT * FROM document_embeddings "
            + "ORDER BY embedding <=> CAST(:embedding AS vector) LIMIT :limit", nativeQuery = true)
    List<DocumentEmbedding> findNearest(@Param("embedding") String embedding, @Param("limit") int limit);

    Optional<DocumentEmbedding> findByEntityTypeAndEntityId(String entityType, Long entityId);

    @Transactional
    @Modifying
    long deleteByEntityType(String entityType);
}
