# Design: Reorganizacion del menu por modulos y publicaciones editoriales

## Technical Approach

Mantener la arquitectura existente: Angular 22 con NgModules/Reactive Forms, `admin-api` como borde JWT/RBAC, `public-api` como propietario de MongoDB/publicaciones y Astro como consumidor publico. El cambio se implementa en slices encadenados: menu, publicaciones+slug, SEO, portal y verificacion.

## Architecture Decisions

| Decision | Choice | Alternative / rationale |
|---|---|---|
| Menu | Extender `RutaPorPermiso` con `module?: boolean`; padres virtuales tienen `permissions: []`. Filtrar hijos primero; el padre solo existe si conserva hijos. | No crear `menu-config.ts`: duplicaria permisos. No signals/standalone: contradice NgModules actuales. |
| Estado | `expandedGroups: Record<string, boolean>` en `SidebarComponent`; cerrado por defecto, grupo activo prevalece. Persistir `ferreplus_menu_v1` con ids de grupo y booleanos, tolerando `localStorage` ausente. | Backend o sessionStorage filtraria preferencias entre dispositivos o las perderia al cerrar. |
| Rutas | Mapeo normativo: Talento (publicaciones, convocatorias, postulaciones, destinatarios); Contabilidad (contactos, gastos, ventas, compras, clientes, precios, reportes); Bodega (productos, categorias, proveedores, movimientos); Mantenimiento (usuarios, roles, logs); Dashboard directo. | No se crea Operaciones; las URLs y `data.permissions` permanecen intactas. |
| Slug | `PublicacionService` normaliza titulo, propone `base`, `base-2`…`base-5`, conserva el slug si el titulo no cambia, guarda contra `@Indexed(unique=true)` y reintenta solo duplicate-key. | Timestamp/hash seria menos legible. El indice es la barrera de concurrencia; agotamiento devuelve `409 SLUG_UNAVAILABLE`. |
| IA | Nuevo caso de uso en `admin-api` reutiliza `GeminiClient`/`GeminiProperties` (mismo base URL, modelo, timeout y API key del chat), pero no `ChatService`, cuyo RAG/analitica tiene otro contrato. | Nuevo proveedor o llamada desde navegador viola ownership y seguridad. |
| Ownership | SEO entra por `POST /api/admin/talento/publicaciones/seo` con `@PreAuthorize` equivalente a editar publicaciones; no persiste. Guardado sigue proxy de `TalentoController` a `/api/internal/publicaciones`; `public-api` genera slug. | No conectar admin-api directamente a MongoDB ni trasladar publicaciones. |
| Portal | Estilos scoped a `.article`; columna `max-width:720px`, media `max-width:100%`, wrapper YouTube `aspect-ratio:16/9`, X centrado con `overflow-wrap:anywhere`; reserva de espacio y fallback existente. | No cambiar identidad/global layout ni introducir un CMS. |

## Data Flow

```text
Angular Sidebar -> RUTAS_POR_PERMISO -> AuthService/AuthGuard (mismos permisos)
Angular Form -> admin-api SEO -> GeminiClient -> DTO editable (sin guardar)
Angular Save -> admin-api TalentoController -> PublicApiClient -> public-api
                                                          -> MongoDB unique slug + media
Portal Astro -> public-api published slug -> SSR metadata + editorial render
```

SEO contract: request `{titulo, resumen?, descripcion}` con limites server-side; response `{title, description}` no vacios. `400` valida, `401/403` autentican/autorizan, `503` timeout/proveedor. Respuesta incompleta es `502` tipado; no se loguea prompt completo. La UI bloquea duplicados durante loading, solo reintenta por click y conserva Guardar habilitado.

## File Changes

| File | Action | Description |
|---|---|---|
| `frontend/src/app/core/rutas-por-permiso.ts`, `auth.service.ts` | Modify | Agrupacion completa, filtrado y home sobre descendientes sin cambiar URLs. |
| `frontend/src/app/shared/sidebar/*` | Modify | Accordion real, ARIA/foco/teclado, persistencia y responsive collapsed. |
| `frontend/src/app/talento/pages/publicaciones/{publicacion-list,publicacion-form}/*`, `talento.service.ts` | Modify | Quitar portada solo de tabla; slug readonly; SEO loading/error/retry editable. |
| `admin-api/.../controller/TalentoController.java`, `.../service/seo/`, `.../dto/`, tests | Create/modify | Endpoint autenticado, validacion, adapter Gemini y errores seguros. |
| `public-api/.../PublicacionService.java`, `PublicacionAdminDTO.java`, tests | Modify | Slug autoritativo, retry de colision y codigo `SLUG_UNAVAILABLE`; conservar portada. |
| `portal/src/styles/global.css`, `src/pages/publicaciones/[slug].astro`, `src/components/islands/PublicContent.ts` | Modify | Layout editorial aislado, embeds y fallback responsive. |

## Testing Strategy

Frontend Vitest/Angular: fixture de asignacion, RBAC recursivo, grupo activo, localStorage, Enter/Space, ARIA y foco; formulario/listado y no regresion de chat. Backend: Mockito para slug/SEO, `MockMvc` para 400/401/403/503, Testcontainers MongoDB para carrera/indice y contrato public-api. Portal: checks a 320/768/1440px, `scrollWidth`, 16:9, alt, drafts 404/no index y fallback de embeds.

## Migration / Rollout

No migracion masiva. Verificar el indice unico existente antes del rollout; cualquier reparacion de datos se entrega como script revisable, no se ejecuta automaticamente. PRs encadenados force-chained, cada uno compilable y reversible en orden inverso.

## Open Questions

- [x] Limites exactos de SEO confirmados por DTO: titulo maximo 200, resumen maximo 500 y descripcion maxima 5000; el timeout reutiliza la configuracion Gemini existente.
- [x] El endpoint SEO exige exactamente `TALENTO_PUBLICACIONES_EDITAR`, alineado con la autoridad de edicion existente.
