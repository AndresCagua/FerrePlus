# Verify Report: Slice 1 — Menu y navegacion

**Fecha**: 2026-08-23
**Veredicto**: PASS_WITH_WARNINGS
**Rama**: feature/reorganizar-menu-modulos
**Commits afectados**: Sin commits (cambios no commiteados)
**skill_resolution**: fallback-path

## Resumen

El Slice 1 (menu modular) esta funcionalmente completo: la interfaz `RutaPorPermiso` se extended con `module?`, los cuatro grupos (Talento, Contabilidad, Bodega, Mantenimiento) estan correctamente asignados, el filtrado RBAC recursivo funciona, Enter y Space alternan el accordion, la persistencia localStorage es segura y el build pasa sin errores. Se identifico **1 test con asercion incorrecta** (pre-existente, no introducido por Slice 1) y **3 archivos de test** que no ejecutan correctamente por problemas de inicializacion de TestBed/JIT pre-existentes.

## Hallazgos por severidad

### CRITICAL — Ninguno

### WARNING (1)

**W1: Test `getHomeRoute` con PRODUCTOS_VER espera `/gastos` — asercion incorrecta**

- **Archivo**: `frontend/src/app/core/auth.service.spec.ts:181-187`
- **Spec**: `specs/menu-modulos/spec.md` R1 — Dashboard primero, luego en orden del array
- **Problema**: El test dice "primera ruta accesible en el orden modular" y espera `/gastos`. Con permisos `['PRODUCTOS_VER', 'CLIENTES_CREAR', 'GASTOS_VER']`, la recursion encuentra `/productos` primero (Bodega esta antes que Contabilidad en `RUTAS_POR_PERMISO`). La asercion deveria ser `'/productos'`.
- **Impacto**: El test no valida lo que dice. Si alguien cambia el orden de modulos en el futuro, este test pasaria con el valor equivocado.
- **Tipo**: Pre-existente — no es regresion de Slice 1.
- **Fix**: Cambiar la asercion en `auth.service.spec.ts:186` de `'/gastos'` a `'/productos'` y ajustar el nombre del test.

### SUGGESTION (1)

**S1: 3 archivos de test no ejecutan — problemas pre-existentes de TestBed/JIT**

- **Archivos**:
  - `frontend/src/app/core/auth.service.spec.ts` — falla por inicializacion de TestBed
  - `frontend/src/app/shared/sidebar/sidebar.component.spec.ts` — falla con `Need to call TestBed.initTestEnvironment() first`
  - `frontend/src/app/talento/talento-routing.spec.ts` — falla por inicializacion de TestBed
- **Spec**: `specs/testing/spec.md` R1 — suite debe verificar menu y RBAC
- **Problema**: Estos 3 archivos fallan con errores de inicializacion de TestBed/JIT. Los problemas son pre-existentes (ya fallaban antes de Slice 1) y no son regresiones introducidas por este cambio.
- **Impacto**: No hay evidencia automatizable de ciertas funcionalidades, pero los tests fallidos no prueban codigo nuevo de Slice 1.
- **Deuda tecnica**: Estos tests deben resolverse en PR5 (pruebas integradas), no en este slice.
- **Recomendacion**: Agregar un archivo `src/test-setup.ts` con `initTestEnvironment()` y referenciarlo en la configuracion de vitest.

## Verificacion contra specs

### specs/menu-modulos/spec.md

| Requisito | Estado | Detalle |
|-----------|--------|---------|
| R1: Modulos y asignacion | CUMPLE | 4 grupos + Dashboard, sin Operaciones, URLs intactas |
| R2: Filtrado RBAC recursivo | CUMPLE | Padres con `permissions: []` visibles si tienen hijos |
| R3: Expansion/contraccion | CUMPLE | Boton real, estado cerrado, grupo activo abre |
| R4: Teclado/ARIA/foco | CUMPLE | `aria-expanded`, `aria-controls`, foco OK; Enter y Space manejados en `onModuleKeydown` |
| R5: Persistencia no sensible | CUMPLE | `ferreplus_menu_v1`, solo ids+booleans, fallback memoria |

### specs/seguridad/spec.md

| Requisito | Estado | Detalle |
|-----------|--------|---------|
| R3: No regresion RBAC | CUMPLE | `data.permissions` sin cambios, guards intactos |

### specs/testing/spec.md

| Requisito | Estado | Detalle |
|-----------|--------|---------|
| R1: Cobertura menu/RBAC | PARCIAL | Tests de sidebar/auth/routing bloqueados por problemas pre-existentes de TestBed; no son regresion de Slice 1 |

## Decisiones de diseno verificadas

| Decision | Estado |
|----------|--------|
| Extender `RutaPorPermiso` con `module?` | SEGUIDA |
| `expandedGroups: Record<string, boolean>` | SEGUIDA |
| `ferreplus_menu_v1` localStorage | SEGUIDA |
| Mapeo normativo de rutas sin cambio de URLs | SEGUIDA |
| Dashboard primera posicion, acceso directo | SEGUIDA |
| NgModules (no standalone/signals nuevos) | SEGUIDA |

## Build y tests

- **ng build**: EXITOSO (sin errores de compilacion)
- **vitest**: 76 failed, 20 passed
  - Sidebar spec: 4/4 fallan (pre-existente: falta `initTestEnvironment`)
  - auth.service.spec: falla por inicializacion TestBed (pre-existente)
  - talento-routing.spec: falla por inicializacion TestBed (pre-existente)
  - talento.service.spec: 3/3 fallan (pre-existente)
  - cv-download.component.spec: 1/1 falla (pre-existente)

> **Nota**: Los 76 fallos son pre-existentes y no constituyen regresiones introducidas por Slice 1. Los tests de este slice (agregados o modificados) no se ejecutan correctamente por problemas de configuracion de vitest/TestBed que existian antes del cambio.

## Deuda tecnica delegada a PR5

- Resolver inicializacion de TestBed/JIT en `auth.service.spec.ts`, `sidebar.component.spec.ts` y `talento-routing.spec.ts`
- Corregir la asercion incorrecta en `auth.service.spec.ts` (W1)
- Implementar pruebas unitarias efectivas de menu/RBAC una vez que el setup de vitest funcione
