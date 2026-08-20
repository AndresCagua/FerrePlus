package com.ferreplus.service.chat;

import java.util.Optional;

public record ChatIntentResult(
        ChatIntent intent,
        ChatEntity entity,
        Optional<String> entityName) {

    public ChatIntentResult {
        if (intent == null) {
            throw new IllegalArgumentException("La intencion no puede ser nula");
        }
        entityName = entityName == null ? Optional.empty() : entityName;
    }

    public static ChatIntentResult unknown() {
        return new ChatIntentResult(ChatIntent.DESCONOCIDO, null, Optional.empty());
    }
}
