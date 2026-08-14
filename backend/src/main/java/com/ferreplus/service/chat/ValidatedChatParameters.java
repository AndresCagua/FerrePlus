package com.ferreplus.service.chat;

import java.util.Objects;
import java.util.Optional;

public record ValidatedChatParameters(Optional<DateRange> dateRange, int limit) {
    public ValidatedChatParameters {
        dateRange = Objects.requireNonNull(dateRange, "El rango de fechas es obligatorio");
        if (limit < 1 || limit > 50) {
            throw new IllegalArgumentException("El limite debe estar entre 1 y 50");
        }
    }
}
