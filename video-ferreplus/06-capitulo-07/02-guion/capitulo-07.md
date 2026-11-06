# Capítulo 7 — Chat IA, embeddings y RAG

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** No mostrar credenciales, tokens, API keys, secretos, datos personales ni respuestas sensibles.

## Objetivo

Mostrar el flujo real del asistente IA de FerrePlus: widget autenticado, clasificación de intención, rutas analíticas y RAG, embeddings, búsqueda pgvector, contexto, fuentes y fallback seguro.

## Alcance

La explicación de persistencia general ya fue cubierta. Este capítulo se concentra en el flujo del chat, sin exponer prompts privados, tokens, respuestas personales ni datos de clientes.

## Fuentes visuales

- Widget real del chat dentro del panel Angular.
- POST real y autenticado a `/api/chat`, mostrando únicamente status.
- Diagrama explicativo de clasificación y rutas.
- Código real de la migración vectorial y consulta pgvector.
- Código real de construcción de contexto, fuentes y fallback.
- Panel administrativo con la integración visible del chat.

## Evidencia de implementación

- `admin-api/src/main/java/com/ferreplus/controller/ChatController.java`
- `admin-api/src/main/java/com/ferreplus/service/chat/ChatService.java`
- `admin-api/src/main/java/com/ferreplus/service/chat/ChatIntentClassifier.java`
- `admin-api/src/main/java/com/ferreplus/service/chat/RagService.java`
- `admin-api/src/main/java/com/ferreplus/repository/DocumentEmbeddingRepository.java`
- `admin-api/src/main/resources/db/V1__chatbot_rag.sql`
- `frontend/src/app/chat/chat.component.ts`

## Reglas de verificación

- Usar credenciales solo mediante variables de entorno.
- No imprimir JWTs, API keys, prompts internos ni datos personales.
- No ejecutar reconstrucción del índice durante la captura.
- Capturar a 1920×1080.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada MKV con decode estricto.
- Normalizar cada escena a la duración de su audio antes de ensamblar.
