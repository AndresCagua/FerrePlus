package com.ferreplus.service.chat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.entity.*;
import com.ferreplus.repository.*;
import com.ferreplus.service.EmbeddingService;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class IndexingService {
    private final List<EntityDocumentMapper<?>> mappers;
    private final DocumentEmbeddingRepository documentRepository;
    private final GuiaSistemaRepository guiaRepository;
    private final ProductoRepository productoRepository;
    private final ClienteRepository clienteRepository;
    private final ProveedorRepository proveedorRepository;
    private final VentaRepository ventaRepository;
    private final CompraRepository compraRepository;
    private final GastoRepository gastoRepository;
    private final EmbeddingService embeddingService;
    private final ObjectMapper objectMapper;

    public IndexingService(List<EntityDocumentMapper<?>> mappers, DocumentEmbeddingRepository documentRepository,
                           GuiaSistemaRepository guiaRepository, ProductoRepository productoRepository, ClienteRepository clienteRepository,
                           ProveedorRepository proveedorRepository, VentaRepository ventaRepository, CompraRepository compraRepository,
                           GastoRepository gastoRepository, EmbeddingService embeddingService, ObjectMapper objectMapper) {
        this.mappers = mappers; this.documentRepository = documentRepository; this.guiaRepository = guiaRepository;
        this.productoRepository = productoRepository; this.clienteRepository = clienteRepository; this.proveedorRepository = proveedorRepository;
        this.ventaRepository = ventaRepository; this.compraRepository = compraRepository; this.gastoRepository = gastoRepository;
        this.embeddingService = embeddingService; this.objectMapper = objectMapper;
    }

    @Transactional
    public IndexResult index(String entityType, Long entityId) {
        return switch (entityType.toUpperCase(Locale.ROOT)) {
            case "PRODUCTO" -> indexFound(productoRepository.findById(entityId).orElse(null), mapper("PRODUCTO"));
            case "CLIENTE" -> indexFound(clienteRepository.findById(entityId).orElse(null), mapper("CLIENTE"));
            case "PROVEEDOR" -> indexFound(proveedorRepository.findById(entityId).orElse(null), mapper("PROVEEDOR"));
            case "VENTA" -> indexFound(ventaRepository.findById(entityId).orElse(null), mapper("VENTA"));
            case "COMPRA" -> indexFound(compraRepository.findById(entityId).orElse(null), mapper("COMPRA"));
            case "GASTO" -> indexFound(gastoRepository.findById(entityId).orElse(null), mapper("GASTO"));
            case "GUIA" -> indexFound(guiaRepository.findById(entityId).orElse(null), mapper("GUIA"));
            default -> throw new IllegalArgumentException("Tipo de entidad no soportado: " + entityType);
        };
    }

    @Transactional
    public RebuildResult rebuildAll() {
        mappers.forEach(mapper -> documentRepository.deleteByEntityType(mapper.entityType()));
        int indexed = 0;
        indexed += indexAll(productoRepository.findAll(), "PRODUCTO"); indexed += indexAll(clienteRepository.findAll(), "CLIENTE");
        indexed += indexAll(proveedorRepository.findAll(), "PROVEEDOR"); indexed += indexAll(ventaRepository.findAll(), "VENTA");
        indexed += indexAll(compraRepository.findAll(), "COMPRA"); indexed += indexAll(gastoRepository.findAll(), "GASTO");
        indexed += indexAll(guiaRepository.findAll(), "GUIA");
        return new RebuildResult(indexed, 0, 0);
    }

    @Transactional
    public void delete(String entityType, Long entityId) {
        documentRepository.findByEntityTypeAndEntityId(entityType.toUpperCase(Locale.ROOT), entityId).ifPresent(documentRepository::delete);
    }

    private <T> int indexAll(List<T> entities, String type) { int count = 0; for (T entity : entities) if (indexFound(entity, mapper(type)).indexed()) count++; return count; }
    @SuppressWarnings("unchecked") private <T> EntityDocumentMapper<T> mapper(String type) { return (EntityDocumentMapper<T>) mappers.stream().filter(item -> item.entityType().equals(type)).findFirst().orElseThrow(); }
    private <T> IndexResult indexFound(T entity, EntityDocumentMapper<T> mapper) {
        if (entity == null) return new IndexResult(false, false);
        String content = mapper.toContentText(entity); String hash = sha256(content);
        Optional<DocumentEmbedding> existing = documentRepository.findByEntityTypeAndEntityId(mapper.entityType(), mapper.entityId(entity));
        if (existing.isPresent() && hash.equals(existing.get().getContentHash())) return new IndexResult(false, true);
        DocumentEmbedding document = existing.orElseGet(DocumentEmbedding::new);
        document.setEntityType(mapper.entityType()); document.setEntityId(mapper.entityId(entity)); document.setContentText(content); document.setContentHash(hash);
        document.setMetadata(toJson(mapper.metadata(entity))); document.setEmbedding(embeddingService.embed(content)); document.setUpdatedAt(LocalDateTime.now());
        documentRepository.save(document); return new IndexResult(true, false);
    }
    private String toJson(Map<String, Object> metadata) { try { return objectMapper.writeValueAsString(metadata); } catch (JsonProcessingException e) { throw new IllegalStateException("No se pudieron serializar los metadatos", e); } }
    private String sha256(String content) { try { byte[] digest = MessageDigest.getInstance("SHA-256").digest(content.getBytes(StandardCharsets.UTF_8)); StringBuilder result = new StringBuilder(); for (byte item : digest) result.append(String.format("%02x", item)); return result.toString(); } catch (NoSuchAlgorithmException e) { throw new IllegalStateException("SHA-256 no disponible", e); } }

    public record IndexResult(boolean indexed, boolean skipped) {}
    public record RebuildResult(int indexed, int skipped, int failed) {}
}
