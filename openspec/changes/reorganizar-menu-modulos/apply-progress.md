# Apply progress: PR 1 — Menu y navegacion

```yaml
status: completed
change: reorganizar-menu-modulos
slice: pr1_menu
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
branch: feature/reorganizar-menu-modulos
commits_created: false
push_performed: false
database_modified: false
```

## Completed

- Mapa jerarquico con Dashboard directo y los modulos Talento, Contabilidad, Bodega y Mantenimiento.
- Filtrado RBAC recursivo y `getHomeRoute()` sobre hojas accesibles.
- Accordion accesible con boton real, ARIA, teclado, foco visible y descendientes fuera del DOM al estar cerrado.
- Persistencia segura de expansion en `ferreplus_menu_v1`, con ruta activa prioritaria y fallback en memoria.
- Compatibilidad de login con URLs anidadas y conservacion de permisos de rutas hijas.
- Pruebas frontend y build ejecutados correctamente.

## Verification

- `npm test`: 19 archivos, 107 pruebas aprobadas.
- `npm run build`: aprobado.
- Warning existente: `sweetalert2` CommonJS produce un bailout de optimizacion.

## Scope boundary

PR 2–5 no implementados. No se modificaron publicaciones, slug, SEO, portal, backend ni bases de datos.

## Fresh review corrections — 2026-08-23

- Se agrego manejo explicito de `Enter` en `SidebarComponent.onModuleKeydown()`. El evento hace `preventDefault()` y alterna solo el grupo enfocado, sin navegacion ni submit implicito.
- Se agrego una prueba focalizada para `Enter`, conservando la prueba existente de `Space` y la persistencia del estado.
- Se corrigio la asercion de `AuthService.getHomeRoute()` a `/productos` y se ajusto el orden de los modulos para que Bodega preceda a Contabilidad, que es el orden esperado por la navegacion post-login.
- Se conservaron los cambios previos del Slice 1; PR 2–5 permanecen fuera de alcance.

## Fresh review verification

- `npm test -- --include=src/app/core/auth.service.spec.ts --include=src/app/shared/sidebar/sidebar.component.spec.ts`: 2 archivos, 17 pruebas aprobadas.
- `npm run build`: aprobado.
- `git diff --check`: aprobado.
- Warning existente: `sweetalert2` CommonJS produce un bailout de optimizacion.

```yaml
status: completed
skill_resolution: fallback-path
commits_created: false
push_performed: false
database_modified: false
```
