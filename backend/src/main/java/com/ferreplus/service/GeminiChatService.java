package com.ferreplus.service;

import com.ferreplus.client.GeminiClient;
import com.ferreplus.exception.GeminiException;
import org.springframework.stereotype.Service;

@Service
public class GeminiChatService {

    private static final String SYSTEM_PROMPT = "Eres el asistente de FerrePlus. "
            + "Responde siempre en espanol, usa unicamente el contexto proporcionado, "
            + "no inventes datos ni rutas y cita las fuentes con el formato [TIPO:id].\n\n";

    private final GeminiClient geminiClient;

    public GeminiChatService(GeminiClient geminiClient) {
        this.geminiClient = geminiClient;
    }

    public String generate(String prompt) {
        try {
            return geminiClient.generate(SYSTEM_PROMPT + prompt);
        } catch (GeminiException exception) {
            if (exception.isRateLimited()) {
                throw new GeminiException("Se alcanzo el limite de consultas. Intenta nuevamente mas tarde.", 429,
                        exception);
            }
            throw new GeminiException("El servicio de respuestas no esta disponible. Intenta nuevamente mas tarde.",
                    503, exception);
        } catch (RuntimeException exception) {
            throw new GeminiException("El servicio de respuestas no esta disponible. Intenta nuevamente mas tarde.",
                    503, exception);
        }
    }
}
