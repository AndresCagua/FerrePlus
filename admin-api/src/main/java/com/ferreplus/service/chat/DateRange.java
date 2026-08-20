package com.ferreplus.service.chat;

import java.time.LocalDate;
import java.util.Objects;

public record DateRange(LocalDate from, LocalDate to) {
    public DateRange {
        Objects.requireNonNull(from, "La fecha inicial es obligatoria");
        Objects.requireNonNull(to, "La fecha final es obligatoria");
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("El rango de fechas es invalido");
        }
    }
}
