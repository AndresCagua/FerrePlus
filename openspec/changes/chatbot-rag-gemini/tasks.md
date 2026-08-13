# Tasks: Chatbot RAG con Gemini y pgvector

> **Change**: `chatbot-rag-gemini`
> **Total tasks**: 19
> **Stacks**: 6 (DB → Gemini integration → Indexing/RAG → Controllers/Security → Frontend → Tests)
> **Specialists**: `springboot` para tareas backend; `angular` para tareas frontend. El especialista debe cargar sus skills obligatorias antes de implementar.
> **Nota de arquitectura frontend**: este proyecto conserva **NgModules + Reactive Forms + Angular Material** (ver `frontend/src/app/logs/`). Aunque el especialista Angular asume standalone por defecto, aquí se respeta la convención del repositorio: feature module `ChatModule`, componente declarado en el módulo, lazy-loading con `loadChildren`.

---

## ⚠️ ENTREGA POR STACKS

- La implementación avanza **por stacks**, no por PRs: primero STACK 1 → 2 → 3 → 4 (backend completo), luego STACK 5 (frontend), finalmente STACK 6 (verificación).
- El agente **no ejecuta operaciones git** (commit/push/PR) salvo que el usuario lo pida explícitamente.
- **Al completar cada stack y pasar su verificación, el agente se DETIENE y notifica al usuario** para review + commit manual antes del siguiente stack.

---

## STACK 1: DB + pgvector

> **Salida verificable**: extensión `vector` habilitada, tablas `document_embeddings` y `guias_sistema` creadas, entidades JPA + repositorios listos, guías sembradas.

### T1 — Migración SQL para pgvector y tablas RAG [x]
- **Files**: `backend/src/main/resources/db/V1__chatbot_rag.sql` (create)
- **Action**: Crear script Flyway con `CREATE EXTENSION IF NOT EXISTS vector;`, tablas `document_embeddings` (`id`, `entity_type`, `entity_id`, `content_text`, `content_hash`, `metadata jsonb`, `embedding vector(768)`, `created_at`, `updated_at`, UNIQUE `(entity_type, entity_id)`, índice por `entity_type`) y `guias_sistema` (`id`, `modulo`, `ruta`, `titulo`, `descripcion`, `pasos JSONB`, `keywords`).
- **Verification**: Script es válido PostgreSQL 16+ con pgvector; no se ejecuta automáticamente sin permiso del usuario (regla de BD del proyecto).

### T2 — Entidad `DocumentEmbedding` + repositorio vectorial [x]
- **Files**:
  - `backend/src/main/java/com/ferreplus/entity/DocumentEmbedding.java` (create)
  - `backend/src/main/java/com/ferreplus/repository/DocumentEmbeddingRepository.java` (create)
- **Action**: Mapear la entidad con `@Column(columnDefinition = "vector(768)")` para el embedding (usar `String` o tipo custom para evitar forzar soporte JPA nativo). Repositorio con native query parametrizada `ORDER BY embedding <=> :embedding LIMIT :limit` y proyección a DTO interno.
- **Verification**: Compila con `mvn compile`; la query nativa usa placeholder `:embedding` y no concatena SQL.

### T3 — Entidad `GuiaSistema` + repositorio [x]
- **Files**:
  - `backend/src/main/java/com/ferreplus/entity/GuiaSistema.java` (create)
  - `backend/src/main/java/com/ferreplus/repository/GuiaSistemaRepository.java` (create)
- **Action**: Entidad JPA con `pasos` mapeado como `Map<String, String>` o `List<String>` vía `JSONB`, índice único `(modulo, ruta, titulo)`. Repositorio Spring Data con `findByModulo` y `findAll`.
- **Verification**: Compila; repositorio responde sin N+1.

### T4 — Seed de guías de navegación en `DataSeeder` [x]
- **Files**: `backend/src/main/java/com/ferreplus/config/DataSeeder.java` (modify)
- **Action**: Agregar método `sembrarGuiasSistema()` que inserte guías idempotentes para módulos principales: Dashboard, Productos, Categorías, Proveedores, Clientes, Ventas, Compras, Precios, Movimientos, Gastos, Usuarios, Roles, Reportes, Logs. Cada guía incluye `modulo`, `ruta` (ej. `/productos`), `titulo`, `descripcion`, `pasos` JSON y `keywords`.
- **Verification**: Segunda ejecución del backend no duplica guías; al menos 10 guías quedan sembradas.

---

## STACK 2: Gemini integration

> **Salida verificable**: `GeminiClient` funcional, `EmbeddingService` genera vectores, `GeminiChatService` genera respuestas; config externalizada y API key no hardcodeada.

### T5 — Cliente Gemini con `RestClient` [x]
- **Files**:
  - `backend/src/main/java/com/ferreplus/config/GeminiProperties.java` (create)
  - `backend/src/main/java/com/ferreplus/client/GeminiClient.java` (create)
  - `backend/src/main/resources/application.yml` (modify)
- **Action**: `GeminiProperties` como `@ConfigurationProperties(prefix = "app.gemini")` con `apiKey`, `baseUrl`, `embeddingModel`, `chatModel`, `timeoutSeconds`, `maxRetries`. `GeminiClient` usa `RestClient` para llamar `embedContent` (`gemini-embedding-001`, 768 dims) y `generateContent` (Flash configurable). La API key se lee de `${GEMINI_API_KEY:}` y nunca se loguea.
- **Verification**: Inyectar `GeminiClient` en un test vacío y verificar que carga contexto sin error con `GEMINI_API_KEY=dummy`.

### T6 — `EmbeddingService` [x]
- **Files**: `backend/src/main/java/com/ferreplus/service/EmbeddingService.java` (create)
- **Action**: Servicio que recibe `String content`, llama a `GeminiClient.embedContent`, normaliza/devuelve `float[]` de 768 dimensiones. Maneja errores de conexión, 429 (rate limit) y respuestas inesperadas con excepciones de dominio propias.
- **Verification**: Unit test con `GeminiClient` mockeado devuelve vector de 768 dims; lanza excepción controlada ante 429.

### T7 — `GeminiChatService` (generación de respuesta) [x]
- **Files**: `backend/src/main/java/com/ferreplus/service/GeminiChatService.java` (create)
- **Action**: Servicio que recibe `String prompt` (system + context + pregunta) y devuelve `String answer`. Usa `GeminiClient.generateContent`. Maneja timeout, errores 5xx, 429 y respuestas vacías.
- **Verification**: Unit test con cliente mockeado: prompt válido → respuesta; excepción → mensaje controlado sin stacktrace.

---

## STACK 3: Indexing + RAG

> **Salida verificable**: mappers de 6 entidades + GUIA, `IndexingService` hace upsert con hash, `RagService` recupera top-5, `ChatService` orquesta el flujo completo.

### T8 — `EntityDocumentMapper` + mappers por entidad
- **Files**:
  - `backend/src/main/java/com/ferreplus/service/chat/EntityDocumentMapper.java` (create, interface)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/ProductoDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/ClienteDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/ProveedorDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/VentaDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/CompraDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/GastoDocumentMapper.java` (create)
  - `backend/src/main/java/com/ferreplus/service/chat/mapper/GuiaDocumentMapper.java` (create)
- **Action**: Interfaz `EntityDocumentMapper<T>` con métodos `String entityType()`, `Long entityId(T)`, `String toContentText(T)`, `Map<String,Object> metadata(T)`. Cada implementación genera texto plano en español siguiendo la tabla del design (producto: nombre/descripción/categoría/stock/precios; venta/compra: factura/cliente o proveedor/fecha/estado/total/detalles; guía: título/descripción/ruta/pasos/keywords).
- **Verification**: Tests unitarios para cada mapper verifican que `toContentText` no devuelve cadena vacía y excluye datos sensibles.

### T9 — `IndexingService`
- **Files**: `backend/src/main/java/com/ferreplus/service/chat/IndexingService.java` (create)
- **Action**: Servicio que itera la lista de `EntityDocumentMapper` + repositorios de datos, calcula hash SHA-256 del `content_text`, compara con `content_hash` almacenado y solo llama a `EmbeddingService` si cambió. Upsert por `(entity_type, entity_id)`. Métodos `indexAll()` y `indexEntity(T, mapper)`. Método de rebuild que borra documentos administrados y reindexa por lotes.
- **Verification**: Test unitario: mismo contenido → skipped; contenido cambiado → llamada a embed + save; entidad nueva → insert.

### T10 — `RagService`
- **Files**: `backend/src/main/java/com/ferreplus/service/chat/RagService.java` (create)
- **Action**: Servicio que: (1) embeddea la pregunta con `EmbeddingService`, (2) busca top-5 documentos por coseno en `DocumentEmbeddingRepository`, (3) construye contexto concatenando `content_text` y lista de fuentes `{entityType, entityId, title}`.
- **Verification**: Test con repositorio mockeado: pregunta "X" → top-5 devuelto; repositorio recibe vector de 768 dims.

### T11 — `ChatService` (orquestación RAG)
- **Files**: `backend/src/main/java/com/ferreplus/service/chat/ChatService.java` (create)
- **Action**: Orquesta: valida pregunta `@NotBlank`, llama a `RagService`, si no hay resultados relevantes (o score bajo umbral configurable) responde mensaje "no dispongo de datos suficientes". Con contexto, construye system prompt en español (anti-invención, usa solo contexto, cita `[TIPO:id]`) y llama a `GeminiChatService`. Devuelve `ChatResponse` con `answer` y `sources`.
- **Verification**: Tests unitarios cubren: (a) pregunta válida con contexto → respuesta con fuentes; (b) sin contexto → mensaje controlado; (c) error 429 Gemini → mensaje amigable; (d) prompt builder incluye instrucciones en español.

---

## STACK 4: Controllers + security

> **Salida verificable**: endpoints expuestos, DTOs validados, autenticación/autorización correcta, CORS multi-origen.

### T12 — `ChatController`
- **Files**: `backend/src/main/java/com/ferreplus/controller/ChatController.java` (create)
- **Action**: `POST /api/chat` con `@PreAuthorize("isAuthenticated()")`, recibe `ChatRequest`, devuelve `ResponseEntity<ChatResponse>`. `POST /api/chat/index/rebuild` con `@PreAuthorize("hasAuthority('CHAT_INDEX_REBUILD')")`, devuelve `{indexed, skipped, failed}`. Maneja validación `@Valid` → 400, 401, 403, 429, 503.
- **Verification**: `@WebMvcTest(ChatController.class)` verifica: 401 sin JWT, 403 rebuild sin ADMIN, 400 request vacío, 200 chat con JWT, 200 rebuild con ADMIN.

### T13 — DTOs `ChatRequest`/`ChatResponse` + CORS multi-origen
- **Files**:
  - `backend/src/main/java/com/ferreplus/dto/ChatRequest.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/ChatResponse.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/ChatSource.java` (create)
  - `backend/src/main/java/com/ferreplus/config/SecurityConfig.java` o CORS config existente (modify)
- **Action**: DTOs como `record` con validación (`@NotBlank`, `@Size(max=1000)`). `ChatResponse` con `String answer` y `List<ChatSource> sources`. Configurar CORS para múltiples orígenes (`http://localhost:4200`, futuro Flutter/emulador) manteniendo JWT en `Authorization`.
- **Verification**: Tests de serialización JSON y verificación de CORS con `MockMvc`/`@SpringBootTest`.

---

## STACK 5: Frontend Angular

> **Salida verificable**: módulo lazy `/chat`, entrada en sidebar, componente con UI de chat, servicio consume `POST /api/chat`.

### T14 — Feature module `ChatModule` + routing + sidebar
- **Files**:
  - `frontend/src/app/chat/chat.module.ts` (create)
  - `frontend/src/app/chat/chat-routing.module.ts` (create)
  - `frontend/src/app/chat/chat.service.ts` (create)
  - `frontend/src/app/chat/chat.component.ts` (create)
  - `frontend/src/app/chat/chat.component.html` (create)
  - `frontend/src/app/chat/chat.component.scss` (create)
  - `frontend/src/app/app-routing.module.ts` (modify)
  - `frontend/src/app/core/rutas-por-permiso.ts` (modify)
  - `frontend/src/app/shared/sidebar/sidebar.component.html` (modify si es necesario)
- **Action**: Crear feature NgModule `chat/` con ruta lazy `/chat` protegida por `AuthGuard` (sin permiso adicional: cualquier usuario autenticado). `ChatService` con `HttpClient` enviando `{question}` y recibiendo `{answer, sources}`. Agregar entrada al sidebar y a `RUTAS_POR_PERMISO`.
- **Verification**: `ng build` limpio; ruta `/chat` carga lazy; sidebar muestra ítem para usuario autenticado.

### T15 — UI de chat
- **Files**:
  - `frontend/src/app/chat/chat.component.ts` (modify)
  - `frontend/src/app/chat/chat.component.html` (modify)
  - `frontend/src/app/chat/chat.component.scss` (modify)
- **Action**: Componente con: lista de mensajes (usuario/assistant), textarea con Reactive Form, botón enviar, estado de carga (spinner), renderizado de `sources` como chips/lista, manejo de errores amigable. Sin lógica de embeddings ni búsqueda vectorial.
- **Verification**: `npm test` pasa; test de componente verifica que al enviar pregunta se llama al servicio y se renderiza respuesta + fuentes.

---

## STACK 6: Tests + verification

> **Salida verificable**: cobertura de lógica pura, servicios mockeados, controladores con auth, builds/test verdes.

### T16 — Unit tests de helpers puros
- **Files**:
  - `backend/src/test/java/com/ferreplus/service/chat/PromptBuilderTest.java` (create)
  - `backend/src/test/java/com/ferreplus/service/chat/ContentTextBuilderTest.java` (create)
- **Action**: Tests para el builder de prompt (system + context + pregunta) y para `toContentText` de al menos Producto, Venta y Guia. Verificar idioma español, inclusión de fuentes y anti-invención.
- **Verification**: `mvn test -Dtest=PromptBuilderTest,ContentTextBuilderTest` verde.

### T17 — Service tests con Gemini mockeado
- **Files**:
  - `backend/src/test/java/com/ferreplus/service/chat/EmbeddingServiceTest.java` (create)
  - `backend/src/test/java/com/ferreplus/service/chat/GeminiChatServiceTest.java` (create)
  - `backend/src/test/java/com/ferreplus/service/chat/RagServiceTest.java` (create)
  - `backend/src/test/java/com/ferreplus/service/chat/ChatServiceTest.java` (create)
- **Action**: Tests con Mockito: `EmbeddingService` (vector dims, errores 429), `GeminiChatService` (respuesta/error), `RagService` (top-5/contexto), `ChatService` (flujo completo incluyendo sin contexto).
- **Verification**: `mvn test -Dtest=*Chat*Test,*Rag*Test,*Embedding*Test` verde.

### T18 — Controller integration tests
- **Files**: `backend/src/test/java/com/ferreplus/controller/ChatControllerTest.java` (create)
- **Action**: `@WebMvcTest(ChatController.class)` con `MockMvc` y JWT de `spring-security-test`: 401 anónimo, 200 autenticado en `/api/chat`, 403 usuario normal en `/api/chat/index/rebuild`, 200 ADMIN en rebuild, 400 pregunta vacía.
- **Verification**: Test pasa; cubre R1, R3, R9, R12 escenarios.

### T19 — Full suite verification
- **Files**: N/A (ejecutar comandos)
- **Action**: Ejecutar `mvn test` en backend y `npm test` en frontend. Verificar que tests preexistentes siguen pasando.
- **Verification**: Ambos comandos terminan con BUILD SUCCESS / test verdes.

---

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1.200–1.600 (backend: entidades, repositorios, servicios, cliente, controllers, tests, migración, seeder; frontend: módulo, componente, servicio, routing, sidebar, tests) |
| 400-line budget risk | **High** |
| Chained PRs recommended | **Yes** |
| Suggested split | PR 1: STACK 1+2 (DB + Gemini client); PR 2: STACK 3 (indexing + RAG); PR 3: STACK 4 (controllers + security); PR 4: STACK 5+6 (frontend + tests) |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | DB + pgvector + Gemini client | PR 1 | Base `main`; incluye migración, entidades, repositorios, `GeminiProperties`, `GeminiClient`, `EmbeddingService`, `GeminiChatService` y tests unitarios. |
| 2 | Indexing + RAG pipeline | PR 2 | Base `main` tras merge PR 1; mappers, `IndexingService`, `RagService`, `ChatService`, tests de servicio. |
| 3 | Controllers + security + DTOs | PR 3 | Base `main` tras merge PR 2; `ChatController`, DTOs, CORS, permiso `CHAT_INDEX_REBUILD`, `ChatControllerTest`. |
| 4 | Frontend + verificación final | PR 4 | Base `main` tras merge PR 3; feature Angular, tests, full suite `mvn test` + `npm test`. |

> **Recomendación**: dado el tamaño, usar **feature-branch-chain** o **stacked-to-main**. El orchestrator debe preguntar al usuario antes de `sdd-apply`.
