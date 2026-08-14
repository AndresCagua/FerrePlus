# Proposal: Chatbot RAG con Gemini y pgvector

## Intent

Incorporar un chatbot en español sobre datos de FerrePlus mediante recuperacion semantica en PostgreSQL y Google Gemini, sin IA local.

## Scope

### In Scope
- Backend RAG, Gemini, pgvector e indexacion de Producto, Cliente, Proveedor, Venta, Compra y Gasto.
- Tabla `guias_sistema`, entidad `GuiaSistema.java`, seeding de guías de navegación e indexacion como `entity_type = 'GUIA'`.
- Chat y tests.

### Out of Scope
- Fine-tuning, streaming, memoria, agentes/SQL, IA local y otras 12 entidades.

## Capabilities

### New Capabilities
- `business-data-chat`: consulta autenticada en español fundamentada en datos recuperados.
- `business-data-indexing`: generacion y busqueda de embeddings por entidad.

### Modified Capabilities
- None.

## Approach

- `POST /api/chat`: `{question}` -> `{answer,sources}` para usuarios JWT; `POST /api/chat/index/rebuild` solo ADMIN.
- `GeminiProperties` lee `${GEMINI_API_KEY:}` y modelos/base URL desde YAML. Cliente HTTP: `gemini-embedding-001` (768) y `gemini-3.6-flash` para chat (modelo verificado funcional con la API key en pruebas de conexión; `gemini-2.0-flash` y `gemini-2.5-flash` están deprecados/no disponibles para usuarios nuevos); la clave nunca llega al frontend.
- Tabla `document_embeddings`: `id`, `entity_type`, `entity_id`, `content_text`, `content_hash`, `metadata jsonb`, `embedding vector(768)`, `updated_at`; UNIQUE `(entity_type,entity_id)`. Script habilita `vector`; busqueda coseno exacta `<=>`, top 5. HNSW queda opcional para mayor volumen.
- `EntityDocumentMapper<T>` genera: Producto (descripcion, categoria, stock/precios); Cliente/Proveedor (identidad/contacto); Venta/Compra (factura, contraparte, fecha, estado, totales/detalles); Gasto (descripcion, categoria, monto, fecha/pago). Otra entidad exige mapper y registro.
- Tabla `guias_sistema` (`id`, `modulo`, `ruta`, `titulo`, `descripcion`, `pasos JSON`, `keywords TEXT`) y entidad `GuiaSistema.java`. Se siembran guías para los módulos principales en el `DataSeeder` y se indexan en `document_embeddings` con `entity_type = 'GUIA'`; el `content_text` se compone de título + descripción + pasos + keywords.
- Rebuild por lotes y upsert post-cambio; `content_hash` evita llamadas repetidas. Flujo: embedding pregunta -> top 5 -> contexto/fuentes -> prompt español anti-invencion -> Gemini.
- Frontend conserva NgModule, Material y `AuthGuard`.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `backend/pom.xml`, `resources/application*.yml`, `resources/db/` | Modified/New | Gemini y pgvector |
| `backend/.../{controller,service,repository,dto}/chat*` | New | API, RAG y mappers |
| `backend/.../entity/GuiaSistema.java`, repositorio y seeder | New/Modified | Guías de navegación e indexación GUIA |
| Servicios de 6 entidades | Modified | Sincronizacion |
| `frontend/src/app/chat/`, routing/sidebar, tests | New/Modified | Chat y validacion |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Cuotas free tier variables (RPM/TPM/RPD) y 429 | High | Verificar AI Studio; timeout, backoff y lotes/hash |
| Free tier puede usar datos para mejorar Google | Medium | Solo datos demo; minimizar contexto |
| API key filtrada | Medium | Variable de entorno y logs redactados |
| Staleness o alucinaciones | Medium | Upsert, rebuild, fuentes y “datos insuficientes” |

## Rollback Plan

Deshabilitar ruta/configuracion, revertir modulos y retirar manualmente tabla/extension solo si no tienen otros consumidores.

## Dependencies

- Gemini API y `GEMINI_API_KEY`; PostgreSQL con pgvector.

## Success Criteria

- [ ] Usuario autenticado consulta en español con fuentes top 5; anonimo recibe 401.
- [ ] Las seis entidades se indexan/reindexan sin duplicados y cambios relevantes refrescan su embedding.
- [ ] Las guías de navegación se siembran, indexan como `entity_type = 'GUIA'` y responden preguntas de ruta/pasos.
- [ ] Sin contexto suficiente, cuota o Gemini caido se responde de forma controlada.
- [ ] Tests y builds backend/frontend pasan.

## Effort

MVP: 5-7 dias (BD/config 1, backend 2-3, pipeline 1, frontend 1, tests 1).
