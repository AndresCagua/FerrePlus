package com.ferreplus.publico.model;

/**
 * Nombre de contrato historico del estado de postulacion. El agregado usa
 * {@link EstadoPostulacion} como tipo persistido para mantener una unica fuente
 * de verdad en el skeleton.
 */
@Deprecated(forRemoval = false)
public enum PostulacionEstado { RECEIVED, UNDER_REVIEW, ACCEPTED, REJECTED }
