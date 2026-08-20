package com.ferreplus.dto;

import java.util.List;

public record ChatResponse(
        String answer,
        List<ChatSource> sources,
        Object guia
) {
    public ChatResponse(String answer, List<ChatSource> sources) {
        this(answer, sources, null);
    }
}
