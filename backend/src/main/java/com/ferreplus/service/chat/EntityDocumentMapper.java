package com.ferreplus.service.chat;

import java.util.Map;

/** Convierte una entidad de negocio en un documento apto para busqueda semantica. */
public interface EntityDocumentMapper<T> {

    String entityType();

    Long entityId(T entity);

    String toContentText(T entity);

    Map<String, Object> metadata(T entity);
}
