package com.ferreplus.service.chat;

import com.ferreplus.service.GeminiChatService;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class ChatIntentClassifier {

    private static final Pattern SIMPLE_INTENT = Pattern.compile(
            "^INTENT: (mas_vendidos|ventas_mes|stock_bajo|mayor_compra|mayor_gasto|proveedor_top|guia_catalogo|desconocido)$");
    private static final Pattern LAST_CHANGE_INTENT = Pattern.compile(
            "^INTENT: ultimo_cambio; ENTITY: (PRODUCTO|CLIENTE|PROVEEDOR|VENTA|COMPRA|GASTO|USUARIO)"
                    + "(?:; NAME: ?([^;\\r\\n]{0,200}))?$");
    private static final Set<ChatEntity> ENTITIES_ALLOWING_NAME = Set.of(
            ChatEntity.PRODUCTO, ChatEntity.CLIENTE, ChatEntity.PROVEEDOR, ChatEntity.USUARIO);

    private final GeminiChatService geminiChatService;

    public ChatIntentClassifier(GeminiChatService geminiChatService) {
        this.geminiChatService = geminiChatService;
    }

    public ChatIntentResult classify(String question) {
        try {
            return parse(geminiChatService.classify(question));
        } catch (RuntimeException exception) {
            return ChatIntentResult.unknown();
        }
    }

    public ChatIntentResult parse(String response) {
        if (response == null) {
            return ChatIntentResult.unknown();
        }

        String normalizedResponse = response.strip();
        Matcher simpleMatcher = SIMPLE_INTENT.matcher(normalizedResponse);
        if (simpleMatcher.matches()) {
            return new ChatIntentResult(simpleIntent(simpleMatcher.group(1)), null, Optional.empty());
        }

        Matcher lastChangeMatcher = LAST_CHANGE_INTENT.matcher(normalizedResponse);
        if (!lastChangeMatcher.matches()) {
            return ChatIntentResult.unknown();
        }

        ChatEntity entity = parseEntity(lastChangeMatcher.group(1));
        String name = Optional.ofNullable(lastChangeMatcher.group(2)).orElse("");
        if (!ENTITIES_ALLOWING_NAME.contains(entity) && !name.isEmpty()) {
            return ChatIntentResult.unknown();
        }
        if (!isSafeEntityName(name)) {
            return ChatIntentResult.unknown();
        }

        return new ChatIntentResult(ChatIntent.ULTIMO_CAMBIO, entity,
                name.isEmpty() ? Optional.empty() : Optional.of(name));
    }

    private ChatIntent simpleIntent(String token) {
        return switch (token) {
            case "mas_vendidos" -> ChatIntent.MAS_VENDIDOS;
            case "ventas_mes" -> ChatIntent.VENTAS_MES;
            case "stock_bajo" -> ChatIntent.STOCK_BAJO;
            case "mayor_compra" -> ChatIntent.MAYOR_COMPRA;
            case "mayor_gasto" -> ChatIntent.MAYOR_GASTO;
            case "proveedor_top" -> ChatIntent.PROVEEDOR_TOP;
            case "guia_catalogo" -> ChatIntent.GUIA_CATALOGO;
            case "desconocido" -> ChatIntent.DESCONOCIDO;
            default -> ChatIntent.DESCONOCIDO;
        };
    }

    private ChatEntity parseEntity(String token) {
        return switch (token) {
            case "PRODUCTO" -> ChatEntity.PRODUCTO;
            case "CLIENTE" -> ChatEntity.CLIENTE;
            case "PROVEEDOR" -> ChatEntity.PROVEEDOR;
            case "VENTA" -> ChatEntity.VENTA;
            case "COMPRA" -> ChatEntity.COMPRA;
            case "GASTO" -> ChatEntity.GASTO;
            case "USUARIO" -> ChatEntity.USUARIO;
            default -> throw new IllegalArgumentException("Entidad no permitida");
        };
    }

    private boolean isSafeEntityName(String name) {
        return !name.contains("--")
                && !name.contains("/*")
                && !name.contains("*/")
                && !name.contains(";");
    }
}
