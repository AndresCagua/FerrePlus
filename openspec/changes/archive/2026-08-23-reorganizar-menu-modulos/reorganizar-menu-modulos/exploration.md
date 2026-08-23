# Exploration: Reorganización del Menú del Sistema con Módulos y Submenús

## Current State

### Arquitectura del Menú Actual

El sidebar es una lista **plana** de 15 items top-level. Solo **Talento** tiene `children` (5 sub-items). No existe agrupación por módulo.

**Fuente única de verdad**: `frontend/src/app/core/rutas-por-permiso.ts`
- Interfaz `RutaPorPermiso` con `label`, `icon`, `route`, `permissions[]`, `children?`
- Función `filtrarRutasPorPermiso()` filtra por permisos del usuario
- Función `permisosDeRuta()` extrae permisos de una ruta

**Sidebar**: `frontend/src/app/shared/sidebar/sidebar.component.ts`
- Lee `RUTAS_POR_PERMISO` directamente
- Renderiza items planos con submenu colapsable para children
- Soporta modo collapsed (icon-only) y expandido

**Auth Guard**: `frontend/src/app/core/auth.guard.ts`
- Valida permisos por ruta desde `route.data.permissions`
- Redirect a primera ruta permitida si no tiene acceso

**Rutas**: `frontend/src/app/app-routing.module.ts`
- Cada módulo es lazy-loaded con `canActivate: [AuthGuard]` y `data: { permissions: permisosDeRuta('/path') }`
- Rutas de Talento ya usan permisos por sub-ruta

### Estado Actual de Talento (requerimientos funcionales)

**Modelo** (`frontend/src/app/talento/models/publicacion.ts`):
- `portada?: MediaImage | null` — campo existe en el modelo
- `slug: string` — ya existe, editable manualmente en el formulario
- `metadataSEO?: MetadataSeo` — ya existe con `title`, `description`, `canonical`, `openGraph`

**Formulario** (`publicacion-form.component.html`):
- Campo slug visible y editable con validación regex `^[a-z0-9-]+$`
- Campos SEO: `seoTitle` y `seoDescription` como inputs manuales
- Campo portada: upload de imagen con preview
- No hay generación automática de slug ni de SEO

**Listado** (`publicacion-list.component.html`):
- Columna `portada` en la tabla con thumbnail
- Función `portadaUrl()` para construir URL de imagen
- Fallback visual "Sin portada"

**Backend** (`admin-api` TalentoController.java):
- Proxy genérico a `public-api` via `PublicApiClient`
- Multipart para portada y galería
- Slug se persiste tal cual se envía desde el frontend

**Backend** (`public-api` Publicacion.java — MongoDB):
- `@Indexed(unique = true) private String slug;`
- Campo `portada` tipo `ImagenMedia`
- Campo `metadataSEO` tipo `MetadataSEO`

**Portal Astro** (`portal/src/pages/publicaciones/[slug].astro`):
- Ruta dinámica `[slug]` para SEO-friendly
- Rendering de portada, galería, YouTube, X embeds
- Estilos en `global.css`: `.article { max-width: 780px }`, `.article > img { width:min(100%,680px) }`

### Áreas Afectadas

| Archivo | Razón |
|---------|-------|
| `frontend/src/app/core/rutas-por-permiso.ts` | Reestructurar array con grupos de módulo |
| `frontend/src/app/shared/sidebar/sidebar.component.html` | Renderizar módulos colapsables con submenús |
| `frontend/src/app/shared/sidebar/sidebar.component.ts` | Lógica de expandir/colapsar módulos |
| `frontend/src/app/shared/sidebar/sidebar.component.scss` | Estilos para grupos de módulo |
| `frontend/src/app/app-routing.module.ts` | Mantener rutas existentes (ya son correctas) |
| `frontend/src/app/talento/pages/publicaciones/publicacion-list.component.html` | Eliminar columna portada |
| `frontend/src/app/talento/pages/publicaciones/publicacion-list.component.ts` | Eliminar lógica portadaUrl/portadaFailed |
| `frontend/src/app/talento/pages/publicaciones/publicacion-form/publicacion-form.component.ts` | Auto-generar slug, integrar IA para SEO |
| `frontend/src/app/talento/pages/publicaciones/publicacion-form/publicacion-form.component.html` | UI para slug auto-gen y SEO IA |
| `frontend/src/app/talento/models/publicacion.ts` | Mantener (portada se mantiene en modelo pero se oculta en listado) |
| `portal/src/styles/global.css` | Ajustar max-width de article a ~720px |
| `portal/src/components/islands/PublicContent.ts` | Revisar alineación de embeds |
| Backend `public-api` | API endpoint para generación IA de SEO (nuevo) |

## Approaches

### 1. **Reorganización Jerárquica del Menú** — Agrupar rutas por módulo en `RUTAS_POR_PERMISO`

**Descripción**: Transformar el array plano en una estructura anidada donde cada módulo (Talento, Contabilidad, Bodega, Mantenimiento) es un grupo colapsable con sus sub-rutas.

```
RUTAS_POR_PERMISO = [
  { label: 'Dashboard', ... },  // Sin módulo, acceso directo
  { label: 'Talento', icon: 'work', module: true, children: [
    { label: 'Publicaciones', route: '/talento/publicaciones' },
    { label: 'Convocatorias', route: '/talento/convocatorias' },
    ...
  ]},
  { label: 'Contabilidad', icon: 'account_balance', module: true, children: [
    { label: 'Contactos', route: '/talento/contactos' },
    ...
  ]},
  ...
]
```

- **Pros**: Fuente única de verdad se mantiene; sidebar, guard y permisos comparten el mismo mapa; escalable para nuevos módulos
- **Cons**: Requiere cambiar `RutaPorPermiso` interface (agregar `module?: boolean`); sidebar necesita lógica de expand/collapse por grupo
- **Effort**: Medium

### 2. **Separación de Configuración de Menú** — Nuevo archivo `menu-config.ts` separado de permisos

**Descripción**: Crear un archivo dedicado para la configuración visual del menú que consuma `RUTAS_POR_PERMISO` pero agregue agrupación visual.

- **Pros**: Separación de concerns; permisos no se contaminan con UI
- **Cons**: Duplicación de estructura; dos fuentes de verdad potenciales
- **Effort**: Medium

### 3. **Mantenimiento del Modelo Actual con Children Anidados** — Usar la estructura existente

**Descripción**: La interfaz `RutaPorPermiso` ya soporta `children`. Simplemente reagrupar los items existentes bajo módulos padre, usando el campo `children` que ya existe.

- **Pros**: Menor cambio; la interfaz ya soporta la estructura; sidebar ya renderiza children
- **Cons**: Los items de módulo necesitarían permisos propios; la lógica de filtrado recursivo ya existe pero puede necesitar ajustes
- **Effort**: Low

## Recommendation

**Approach 3: Mantenimiento del Modelo Existente con Children Anidados**

Es la más eficiente porque:
1. La interfaz `RutaPorPermiso` **ya tiene `children?: RutaPorPermiso[]`**
2. La función `filtrarRutasPorPermiso()` **ya es recursiva** y maneja jerarquías
3. El sidebar **ya renderiza sub-items** cuando `item.children?.length > 0`
4. Solo necesitamos reagrupar los items existentes bajo padres de módulo

**Implementación**:
1. En `RUTAS_POR_PERMISO`, crear items padre por módulo con permisos aggregados
2. Mover los items actuales como children de sus módulos correspondientes
3. Agregar `module: boolean` a la interfaz para distinguir visualmente los headers de módulo
4. Ajustar el sidebar para renderizar módulos como secciones colapsables con estilo diferente
5. Ajustar `navigationRoute()` para que los módulos naveguen al primer child accessible

## Risks

1. **Riesgo RBAC**: Reagrupar rutas puede romper permisos existentes si un usuario tiene permiso de un sub-item pero no del padre. Mitigación: el guard ya valida permisos por ruta individual, no por grupo.

2. **Riesgo de Breaking Change en Menú**: Usuarios acostumbrados al orden actual pueden confiarse. Mitigación: mantener el mismo orden relativo de items dentro de cada módulo.

3. **Riesgo de Sidebar Overflow**: Con más grupos, el sidebar puede necesitar scroll. Mitigación: ya tiene `overflow-y: auto` en `.sidebar-nav`.

4. **Riesgo en Portal Astro**: Cambiar max-width de article de 780px a 720px puede afectar legibilidad. Mitigación: 720px es estándar para lectura (Medium, Substack usan ~680-720px).

5. **Riesgo de Slug Auto-generado**: Si el backend no valida unicidad, pueden haber colisiones. Mitigación: el slug ya tiene `@Indexed(unique = true)` en MongoDB.

6. **Riesgo de SEO IA**: Integrar generación IA requiere endpoint nuevo en backend. Mitigación: puede ser un servicio externo o interno, pero el frontend solo necesita un botón que llame a un endpoint.

## Detailed Findings

### Menú: Módulos Propuestos

| Módulo | Items Actuales | Nuevos Items |
|--------|---------------|--------------|
| **Talento** | Publicaciones, Convocatorias, Postulaciones | — |
| **Contabilidad** | Contactos, Gastos | — |
| **Bodega** | Productos, Categorías, Proveedores, Movimientos | — |
| **Mantenimiento** | Usuarios, Roles, Logs | — |
| **Operaciones** | Ventas, Compras, Clientes, Precios, Reportes | — |
| **Dashboard** | (acceso directo) | — |

### Talento: Análisis de Requerimientos

**RF1 — Eliminar "portada" del listado**:
- Campo `portada` existe en tabla del listado (columna `portada`)
- Funciones `portadaUrl()`, `portadaFailed()`, `failedPortadas` en el componente
- Campo se mantiene en modelo y formulario (solo se oculta del listado)
- **Esfuerzo**: Bajo — eliminar columna de tabla y funciones auxiliares

**RF2 — Auto-generar slug**:
- Slug ya existe como campo editable con validación `^[a-z0-9-]+$`
- No hay generación automática actualmente
- **Opción A**: Solo frontend — generar slug desde título al escribir (sin backend)
- **Opción B**: Backend genera slug único con timestamp/hash
- **Recomendación**: Opción A (frontend) + backend valida unicidad (ya lo hace con `@Indexed(unique=true)`)
- **Esfuerzo**: Bajo

**RF3 — SEO IA**:
- Campos SEO ya existen como inputs manuales
- No hay integración con IA actualmente
- **Opción A**: Llamar a un endpoint `/api/admin/talento/seo/generate` que use IA
- **Opción B**: Usar un servicio externo (OpenAI, etc.) desde el frontend
- **Recomendación**: Opción A (backend) por seguridad y control de costos
- **Esfuerzo**: Medio — requiere nuevo endpoint + servicio IA

**RF4 — Layout portal**:
- `.article { max-width: 780px }` → cambiar a `~720px`
- `.article > img { width:min(100%,680px) }` → alinear con 720px
- YouTube embed ya responsive con `16:9`
- X embed ya tiene fallback y observer
- Espaciado consistente: verificar `gap` y `margin` en `.article-content`
- **Esfuerzo**: Bajo — ajustes CSS puntuales

### Dependencias entre Módulos

```
Dashboard (acceso directo)
  └── No depende de ningún módulo

Talento
  └── Publicaciones → portal Astro (SEO, slug)
  └── Postulaciones → Convocatorias (dependencia)
  └── Contactos → Contabilidad (cruce de permisos)

Contabilidad
  └── Contactos ← Talento (mismo recurso, diferente permiso)
  └── Gastos (independiente)

Bodega
  └── Productos → Categorías, Proveedores
  └── Movimientos → Productos

Mantenimiento
  └── Usuarios → Roles
  └── Logs (independiente, solo lectura)

Operaciones
  └── Ventas → Productos, Clientes
  └── Compras → Proveedores, Productos
```

### Orden de Implementación Recomendado

1. **Fase 1 — Menú y Navegación** (sin dependencias backend)
   - Reagrupar `RUTAS_POR_PERMISO` por módulos
   - Actualizar sidebar para renderizar módulos colapsables
   - Ajustar estilos del sidebar
   - Verificar que permisos siguen funcionando

2. **Fase 2 — Talento: Portada y Slug** (solo frontend)
   - Eliminar columna portada del listado
   - Implementar auto-generación de slug en formulario
   - Agregar toggle para edición manual de slug

3. **Fase 3 — Talento: SEO IA** (requiere backend)
   - Crear endpoint de generación IA en `public-api`
   - Integrar botón "Generar con IA" en formulario de publicación
   - Mantener campos editables después de generación

4. **Fase 4 — Layout Portal** (solo CSS/HTML)
   - Ajustar max-width de `.article` a ~720px
   - Verificar alineación de imágenes y embeds
   - Probar responsive en móvil
   - Verificar espaciado consistente 20-32px

## Ready for Proposal

**Sí** — La exploración es suficiente para proceder a `sdd-propose`.

**Información adicional necesaria para la propuesta**:
1. Confirmar la agrupación exacta de módulos (¿Operaciones separado o unir con Bodega?)
2. Definir si el slug se genera solo en frontend o también en backend
3. Definir qué servicio IA se usará para generación de SEO
4. Confirmar si "portada" se elimina completamente o solo del listado (el modelo la conserva)
