-- Migracion manual del chatbot RAG. Revisar y ejecutar por el administrador de la base.
-- No se ejecuta automaticamente desde Spring Boot.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS document_embeddings (
    id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(40) NOT NULL,
    entity_id BIGINT NOT NULL,
    content_text TEXT NOT NULL,
    content_hash CHAR(64) NOT NULL,
    metadata JSONB,
    embedding vector(768) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_document_embeddings_entity UNIQUE (entity_type, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_document_embeddings_type
    ON document_embeddings (entity_type);

CREATE TABLE IF NOT EXISTS guias_sistema (
    id BIGSERIAL PRIMARY KEY,
    modulo VARCHAR(60) NOT NULL,
    ruta VARCHAR(160) NOT NULL,
    titulo VARCHAR(160) NOT NULL,
    descripcion TEXT NOT NULL,
    pasos JSONB NOT NULL,
    keywords TEXT,
    CONSTRAINT uk_guias_sistema UNIQUE (modulo, ruta, titulo)
);
