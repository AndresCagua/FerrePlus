package com.ferreplus.dto;

import java.util.Map;

public record ChatSource(
        String entityType,
        Long entityId,
        String excerpt,
        Map<String, Object> metadata
) {
}
