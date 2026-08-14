package com.ferreplus.service.chat;

import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class ChatRouter {
    private final AnalyticalChatService analyticalChatService;

    public ChatRouter(AnalyticalChatService analyticalChatService) {
        this.analyticalChatService = analyticalChatService;
    }

    public ChatRouteResult route(
            ChatIntentResult intentResult,
            ValidatedChatParameters parameters,
            String originalQuestion) {
        if (intentResult == null || intentResult.intent() == null || parameters == null) {
            return ChatRouteResult.safeFallback();
        }
        if (intentResult.intent() == ChatIntent.ULTIMO_CAMBIO
                && !isValidLastChangeTarget(intentResult)) {
            return ChatRouteResult.safeFallback();
        }

        return switch (intentResult.intent()) {
            case MAS_VENDIDOS -> new ChatRouteResult(
                    ChatIntent.MAS_VENDIDOS, analyticalChatService.productosMasVendidos(parameters), false);
            case VENTAS_MES -> new ChatRouteResult(
                    ChatIntent.VENTAS_MES, analyticalChatService.ventasMes(parameters), false);
            case STOCK_BAJO -> new ChatRouteResult(
                    ChatIntent.STOCK_BAJO, analyticalChatService.stockBajo(parameters), false);
            case ULTIMO_CAMBIO -> new ChatRouteResult(
                    ChatIntent.ULTIMO_CAMBIO,
                    analyticalChatService.ultimoCambio(intentResult.entity(), intentResult.entityName()), false);
            case MAYOR_COMPRA -> new ChatRouteResult(
                    ChatIntent.MAYOR_COMPRA, analyticalChatService.compraMasCara(parameters), false);
            case MAYOR_GASTO -> new ChatRouteResult(
                    ChatIntent.MAYOR_GASTO, analyticalChatService.mayorGasto(parameters), false);
            case PROVEEDOR_TOP -> new ChatRouteResult(
                    ChatIntent.PROVEEDOR_TOP, analyticalChatService.proveedorTop(parameters), false);
            case GUIA_CATALOGO, DESCONOCIDO -> ChatRouteResult.safeFallback();
        };
    }

    private boolean isValidLastChangeTarget(ChatIntentResult intentResult) {
        if (intentResult.entity() == null) {
            return false;
        }
        return intentResult.entityName().isEmpty()
                || switch (intentResult.entity()) {
                    case PRODUCTO, CLIENTE, PROVEEDOR, USUARIO -> true;
                    case VENTA, COMPRA, GASTO -> false;
                };
    }
}
