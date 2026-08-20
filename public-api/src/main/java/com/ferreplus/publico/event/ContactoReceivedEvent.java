package com.ferreplus.publico.event;

public record ContactoReceivedEvent(String contactoId, String email, String correlationId) {}
