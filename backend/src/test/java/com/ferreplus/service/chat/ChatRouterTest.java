package com.ferreplus.service.chat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChatRouterTest {
    @Mock
    private AnalyticalChatService analyticalChatService;

        private final ValidatedChatParameters parameters = new ValidatedChatParameters(
            Optional.of(new DateRange(LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 14))), 5);

    @Test
    void routesEveryAnalyticalIntentToItsExplicitUseCase() {
        when(analyticalChatService.productosMasVendidos(parameters)).thenReturn(List.of());
        when(analyticalChatService.ventasMes(parameters)).thenReturn(null);
        when(analyticalChatService.stockBajo(parameters)).thenReturn(List.of());
        when(analyticalChatService.ultimoCambio(ChatEntity.PRODUCTO, Optional.empty())).thenReturn(Optional.empty());
        when(analyticalChatService.compraMasCara(parameters)).thenReturn(Optional.empty());
        when(analyticalChatService.mayorGasto(parameters)).thenReturn(Optional.empty());
        when(analyticalChatService.proveedorTop(parameters)).thenReturn(Optional.empty());

        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.MAS_VENDIDOS, null, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.VENTAS_MES, null, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.STOCK_BAJO, null, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.ULTIMO_CAMBIO, ChatEntity.PRODUCTO, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.MAYOR_COMPRA, null, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.MAYOR_GASTO, null, Optional.empty()), parameters, "");
        new ChatRouter(analyticalChatService).route(
                new ChatIntentResult(ChatIntent.PROVEEDOR_TOP, null, Optional.empty()), parameters, "");

        verify(analyticalChatService).productosMasVendidos(parameters);
        verify(analyticalChatService).ventasMes(parameters);
        verify(analyticalChatService).stockBajo(parameters);
        verify(analyticalChatService).ultimoCambio(ChatEntity.PRODUCTO, Optional.empty());
        verify(analyticalChatService).compraMasCara(parameters);
        verify(analyticalChatService).mayorGasto(parameters);
        verify(analyticalChatService).proveedorTop(parameters);
    }

    @Test
    void unknownAndGuideReturnSafeFallbackWithoutAnalyticalInteraction() {
        ChatRouter router = new ChatRouter(analyticalChatService);

        ChatRouteResult unknown = router.route(ChatIntentResult.unknown(), parameters, "DELETE FROM auditoria");
        ChatRouteResult guide = router.route(
                new ChatIntentResult(ChatIntent.GUIA_CATALOGO, null, Optional.empty()), parameters, "guia");

        assertThat(unknown.fallback()).isTrue();
        assertThat(guide.fallback()).isTrue();
        verifyNoInteractions(analyticalChatService);
    }
}
