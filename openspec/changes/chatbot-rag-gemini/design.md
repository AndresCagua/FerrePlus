# Technical Design — chatbot-rag-gemini

## Decisiones de Diseño

### D1: Cliente Gemini
Se usara `RestClient` de Spring MVC contra la API REST de Gemini, encapsulado en `GeminiClient`. Se descarta Spring AI por agregar starters, abstracciones y configuracion innecesarios para un MVP con solo embeddings y generacion. `GeminiProperties` (`@ConfigurationProperties`) definira base URL, modelos, API key, timeout y limites; la clave vendra de `${GEMINI_API_KEY:}` y nunca se registrara en logs.

**Modelos verificados en pruebas de conexion (2026-08-13)**:
- **Embeddings**: `gemini-embedding-001` (768 dims) — FUNCIONA.
- **Chat**: `gemini-3.6-flash` — FUNCIONA (respondio correctamente).
- Deprecados/no disponibles para usuarios nuevos: `gemini-2.0-flash` (404), `gemini-2.5-flash` (no disponible). Configuracion en `application.yml`: `chat-model: gemini-3.6-flash`, `embedding-model: gemini-embedding-001`, ambos override por env var.

### D2: Indexacion y extensibilidad
`EmbeddingService` dependera de `GeminiClient` y `DocumentIndexService` de una lista de `EntityDocumentMapper`. Cada mapper entrega `entityType`, id, texto y metadatos. El hash SHA-256 evita llamadas repetidas; el upsert por `(entity_type, entity_id)` mantiene un solo documento. Agregar una entidad solo requiere mapper, proveedor de datos y registro.

### D3: Persistencia vectorial
Se usara PostgreSQL con pgvector y consulta exacta `<=>` (distancia coseno), top 5. Para el volumen demo no se crea indice ANN: el costo de escanear pocos documentos es menor que mantener IVFFlat/HNSW. Si crece el volumen, se agrega HNSW sin cambiar el contrato del repositorio. La extension y tablas se crean con migracion Flyway; no se depende de `ddl-auto: update` para produccion.

**Tests contra PostgreSQL real (2026-08-13)**: la suite de tests corre contra un contenedor `pgvector/pgvector:pg16` (puerto 5433) en vez de H2, para validar el tipo `vector(768)`, `JSONB` y el operador `<=>` de forma real. Los tests usan `@AutoConfigureTestDatabase(replace = NONE)` para respetar el datasource del perfil `test` (`application-test.properties`). Las columnas JSONB requieren `@JdbcTypeCode(SqlTypes.JSON)` en la entidad para que Hibernate bindee el String como JSON.

### D4: Rebuild
El rebuild sera sincrono y por lotes, adecuado para el dataset pequeno. Primero elimina documentos administrados y luego indexa entidades y guias; cada fallo se informa como error controlado. Actualizaciones normales llaman a `index(entity)` despues de guardar, con hash para no re-embebir contenido igual.

### D5: API REST agnostica del cliente (Angular + Flutter)
El backend expondra el chatbot como una API REST pura mediante `POST /api/chat`, con request `{"message": "..."}` y response `{"answer": "...", "sources": [...]}`. El contrato JSON sera estable y versionable, sin acoplamiento a tecnologias de presentacion. CORS se configurara para multiples origenes, incluyendo el servidor de desarrollo Angular y el futuro cliente Flutter/emulador.

Toda la logica RAG (embeddings, busqueda vectorial y generacion de respuestas) vivira en Spring Boot; los clientes solo enviaran el mensaje y pintaran la respuesta. Los DTOs `ChatRequest`, `ChatResponse` y `ChatSource` seran planos y serializables por cualquier cliente. La autenticacion reutilizara el mecanismo JWT existente mediante el header `Authorization: Bearer`, con el mismo comportamiento para Angular y Flutter.

## Arquitectura del Pipeline RAG

```text
ChatController -> ChatService -> EmbeddingService -> GeminiClient
                                      |                  |
                                      v                  v
                              VectorRepository     Gemini generate
                                      |
                                      v
                         top-5 contexto + fuentes
```

`ChatService` valida la pregunta, obtiene el vector de 768 dimensiones, busca por coseno, y si no supera un umbral configurable responde que no hay datos suficientes. Con resultados construye un prompt en espanol: solo usar contexto, no inventar rutas ni cifras, responder en espanol y citar `[TIPO:id]`. Luego solicita Gemini Flash y devuelve respuesta y fuentes. Timeouts de 10 s, un reintento exponencial solo para errores transitorios; 429 produce mensaje amigable y 503 para indisponibilidad.

## Modelo de Datos

Migracion `V1__chatbot_rag.sql`:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE TABLE document_embeddings (
 id BIGSERIAL PRIMARY KEY, entity_type VARCHAR(40) NOT NULL,
 entity_id BIGINT NOT NULL, content_text TEXT NOT NULL,
 content_hash CHAR(64) NOT NULL, metadata JSONB,
 embedding vector(768) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT now(),
 updated_at TIMESTAMP NOT NULL DEFAULT now(),
 UNIQUE(entity_type, entity_id)
);
CREATE INDEX idx_document_embeddings_type ON document_embeddings(entity_type);
CREATE TABLE guias_sistema (
 id BIGSERIAL PRIMARY KEY, modulo VARCHAR(60) NOT NULL, ruta VARCHAR(160) NOT NULL,
 titulo VARCHAR(160) NOT NULL, descripcion TEXT NOT NULL,
 pasos JSONB NOT NULL, keywords TEXT, UNIQUE(modulo, ruta, titulo)
);
```

El repositorio usa native query parametrizada para `<=>` y mapea proyeccion de resultados, evitando forzar soporte JPA para `vector`.

## Generacion de content_text por Entidad

| Entidad | Texto indexado |
|---|---|
| Producto | nombre, descripcion, codigo, categoria, ubicacion, stock, unidad y precios |
| Cliente | nombre, RUC, contacto y saldo pendiente |
| Proveedor | nombre, RUC, contacto, telefono, email y direccion |
| Venta | factura, cliente, fecha, estado, pago, total y resumen de detalles |
| Compra | factura, proveedor, fecha, estado, total y resumen de detalles |
| Gasto | descripcion, categoria, monto, fecha, pago y observaciones |
| GUIA | modulo, titulo, descripcion, ruta, pasos y keywords |

Se excluyen credenciales y datos internos no utiles. Los mappers cargaran detalles con consultas controladas para evitar N+1.

## API Design

- `POST /api/chat`, `@PreAuthorize("isAuthenticated()")`: request record `{ "question": "..." }` con `@NotBlank` y limite 1000. Respuesta `{answer, sources:[{entityType, entityId, title}]}`. 400 validacion, 401 JWT ausente, 429 cuota, 503 proveedor no disponible.
- `POST /api/chat/index/rebuild`, `@PreAuthorize("hasAuthority('...')")`: ADMIN sera autorizado mediante una nueva autoridad `CHAT_INDEX_REBUILD` sembrada en la matriz ADMIN; devuelve `{indexed, skipped, failed}`. Otros autenticados reciben 403.

Los DTOs del chat son client-agnostic: representan un contrato JSON plano, estable y versionable, serializable tanto por Angular como por Flutter. CORS permitira multiples origenes, incluyendo el servidor Angular en desarrollo y el futuro cliente Flutter/emulador, manteniendo JWT en `Authorization: Bearer`.

## Seguridad

Se conserva JWT, `@EnableMethodSecurity`, `JwtAuthenticationEntryPoint` y `JsonAccessDeniedHandler` existentes. La API key solo vive en backend/configuracion por entorno. No se enviaran preguntas, contexto completo ni secretos a logs; se registraran duracion y conteos. El prompt debe tratar el contexto como datos, no como instrucciones.

## Frontend

Crear feature NgModule `frontend/src/app/chat/` con `ChatService` (`HttpClient`), componente de mensajes Material, textarea Reactive Form, estado de carga/error y lista de fuentes. Ruta lazy `/chat` protegida por `AuthGuard`; agregarla al mapa `RUTAS_POR_PERMISO` sin exigir permiso adicional, pues cualquier usuario autenticado puede consultar. No se expone endpoint de rebuild en la UI normal.

El componente Angular sera solo un consumidor del contrato REST compartido; no contendra logica de embeddings, busqueda vectorial ni generacion. El mismo contrato JSON podra ser consumido por una futura aplicacion Flutter, que enviara el mensaje y renderizara `answer` y `sources` de la misma forma semantica.

## Estrategia de Tests

- Unitarios: Mockito para `GeminiClient`, `EmbeddingService`, mappers y `ChatService`; cubrir prompt, top-5, hash, sin contexto, 429, timeout y error.
- Repositorio: en H2 se mockea el repositorio vectorial; no se ejecuta `<=>` ni se mapea `vector`. `@WebMvcTest`/MockMvc verifica DTO, 400, 401 y 403.
- Integracion: perfil PostgreSQL opcional con Testcontainers + imagen pgvector para migracion y consulta real; los tests sustituyen `GeminiClient` por stub, sin red. Frontend prueba servicio y componente con HttpTestingController.

Archivos: `pom.xml`, `application*.yml`, migracion SQL, paquetes `entity/repository/service/controller/dto`, `DataSeeder`, `SecurityConfig` y feature Angular.
