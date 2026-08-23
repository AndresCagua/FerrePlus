package com.ferreplus.publico.event;

public record PostulacionReceivedEvent(String postulacionId, String email, String correlationId) {}
