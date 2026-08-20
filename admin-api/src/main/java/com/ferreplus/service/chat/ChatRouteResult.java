package com.ferreplus.service.chat;

public record ChatRouteResult(ChatIntent intent, Object result, boolean fallback) {
    public static ChatRouteResult safeFallback() {
        return new ChatRouteResult(ChatIntent.DESCONOCIDO, null, true);
    }
}
