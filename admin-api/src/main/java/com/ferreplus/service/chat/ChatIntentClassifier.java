package com.ferreplus.service.chat;

import com.ferreplus.client.TypeSafeClient;
import org.springframework.stereotype.Service;

import java.util.Locale;
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

    private static final Pattern ENTITY_IN_QUESTION = Pattern.compile(
            "\\b(productos?|clientes?|proveedores?|ventas?|compras?|gastos?|usuarios?)\\b"
                    + "(?:\\s+(?:de|del|para)\\s+([^?.,;\\r\\n]{1,200}))?",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private final TypeSafeClient typeSafeClient;

    public ChatIntentClassifier(TypeSafeClient typeSafeClient) {
        this.typeSafeClient = typeSafeClient;
    }

    public ChatIntentResult classify(String question) {
        try {
            ChatIntent intent = simpleIntent(typeSafeClient.classify(question));
            if (intent != ChatIntent.ULTIMO_CAMBIO) {
                return new ChatIntentResult(intent, null, Optional.empty());
            }
            return extractLastChange(question);
        } catch (RuntimeException exception) {
            return ChatIntentResult.unknown();
        }
    }

    private ChatIntentResult extractLastChange(String question) {
        Matcher matcher = ENTITY_IN_QUESTION.matcher(question == null ? "" : question);
        if (!matcher.find()) return ChatIntentResult.unknown();
        ChatEntity entity = parseEntity(matcher.group(1).toLowerCase(Locale.ROOT));
        String name = Optional.ofNullable(matcher.group(2)).orElse("").strip();
        if (!ENTITIES_ALLOWING_NAME.contains(entity) && !name.isEmpty()) return ChatIntentResult.unknown();
        if (!isSafeEntityName(name)) return ChatIntentResult.unknown();
        return new ChatIntentResult(ChatIntent.ULTIMO_CAMBIO, entity,
                name.isEmpty() ? Optional.empty() : Optional.of(name));
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
        return switch (token == null ? "" : token.trim().toLowerCase(Locale.ROOT)) {
            case "mas_vendidos" -> ChatIntent.MAS_VENDIDOS;
            case "ventas_mes" -> ChatIntent.VENTAS_MES;
            case "stock_bajo" -> ChatIntent.STOCK_BAJO;
            case "mayor_compra" -> ChatIntent.MAYOR_COMPRA;
            case "mayor_gasto" -> ChatIntent.MAYOR_GASTO;
            case "proveedor_top" -> ChatIntent.PROVEEDOR_TOP;
            case "guia_catalogo" -> ChatIntent.GUIA_CATALOGO;
            case "ultimo_cambio" -> ChatIntent.ULTIMO_CAMBIO;
            case "desconocido" -> ChatIntent.DESCONOCIDO;
            default -> ChatIntent.DESCONOCIDO;
        };
    }

    private ChatEntity parseEntity(String token) {
        return switch (token.toUpperCase(Locale.ROOT)) {
            case "PRODUCTO", "PRODUCTOS" -> ChatEntity.PRODUCTO;
            case "CLIENTE", "CLIENTES" -> ChatEntity.CLIENTE;
            case "PROVEEDOR", "PROVEEDORES" -> ChatEntity.PROVEEDOR;
            case "VENTA", "VENTAS" -> ChatEntity.VENTA;
            case "COMPRA", "COMPRAS" -> ChatEntity.COMPRA;
            case "GASTO", "GASTOS" -> ChatEntity.GASTO;
            case "USUARIO", "USUARIOS" -> ChatEntity.USUARIO;
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
