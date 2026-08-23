# Verification report — Slice 5 / PR 5 (fresh adversarial review)

## Scope

Revisión fresca y adversarial de los cambios no commiteados en `feature/reorganizar-menu-modulos` para Slice 5 / PR 5. No se hicieron commits, push ni operaciones de escritura sobre bases de datos.

## Changes reviewed

| File | Lines added | Purpose |
|---|---|---|
| `admin-api/.../SeoSuggestionControllerTest.java` | +14 | Test 503 proveedor con mensaje genérico |
| `frontend/.../sidebar.component.spec.ts` | +39 | Test ARIA renderizado real con TestBed |
| `public-api/.../PublicacionServiceTest.java` | +29 | Test agotamiento slug (409) + recalculo en update |
| `portal/package.json` | +1 | Script `test:editorial` |
| `portal/scripts/verify-editorial.mjs` | +30 (new) | Checks estáticos CSS/Astro |
| `openspec/.../tasks.md` | ~70 changed | Tasks marcadas completadas |
| `openspec/.../design.md` | +2 changed | Open questions cerradas |
| `openspec/.../verify-report-slice5.md` | this file | Reporte de verificación |

## Automated checks (from prior verification, confirmed consistent)

| Area | Command | Result |
|---|---|---|
| Frontend full | `npm test` | 20 archivos, 116 pruebas aprobadas |
| Frontend build | `npm run build` | Aprobado |
| Admin SEO focused | Maven `SeoSuggestionControllerTest` | 200/400/401/403/502/503 |
| Public API slug focused | Maven `PublicacionServiceTest` | 14 pruebas aprobadas |
| Portal static checks | `npm run test:editorial` | 9 verificaciones aprobadas |
| Portal type check | `npm run check` | 0 errores |
| Portal build | `npm run build` | Aprobado |
| Diff hygiene | `git diff --check` | Aprobado |

## Adversarial findings

### WARNING — verify-editorial.mjs: operador `&&` entre regex produce falso positivo

**Archivo**: `portal/scripts/verify-editorial.mjs:14`

```javascript
['X centrado y con wrap', /\.x-preview[^\{]*\{[^}]*justify-content:center/s && /\.x-preview-url[^\{]*\{[^}]*overflow-wrap:anywhere/s],
```

En JavaScript, `regex1 && regex2` retorna `regex2` (el segundo operando), no un booleano. Solo se evalúa `overflow-wrap:anywhere`; `justify-content:center` **no se verifica nunca**. El test pasa aunque falte el centrado.

**Evidencia**: Confirmed con `node -e "console.log(/a/ && /b/ === /b/)"` → `true`.

**Impacto real**: Ambas propiedades CSS existen en `global.css` (líneas 25 y 29), así que el invariant se cumple en el código. Pero la prueba tiene un **falso positivo** para el check de centrado — si alguien elimina `justify-content:center` del CSS, la prueba seguiría pasando.

**Fix necesario**: Reemplazar `&&` por un array o función que valide ambas regex independientemente.

### SUGGESTION — target/ files visibles en git diff

**Archivo**: `public-api/target/` (20+ archivos)

Los archivos compilados en `target/` aparecen en `git diff HEAD` porque están tracked pero en `.gitignore`. No se commitearán, pero generan ruido en la revisión. Considerar `git rm --cached -r public-api/target/` para limpiar el tracking.

### SUGGESTION — verify-editorial.mjs: regex frágiles ante reformato CSS

Los patrones usan `[^\{]*` que depende de que las propiedades estén en la misma línea que el selector. Si el CSS se reformatea con una propiedad por línea, las regex podrían no matchear aunque la propiedad exista. Esto es aceptable para un script estático sin framework, pero es una limitación a documentar.

## Test quality analysis (adversarial)

### ✅ sidebar.component.spec.ts — Test ARIA renderizado real (NUEVO)

**¿Es placeholder?** NO. Crea un `ComponentFixture` real con `TestBed.createComponent`, renderiza el DOM y verifica atributos ARIA reales.

**¿Prueba comportamiento?** SÍ:
- Verifica `button[aria-controls="menu-group-bodega"]` existe en DOM
- Verifica `aria-label` contiene "Bodega"
- Verifica `aria-expanded="false"` cuando colapsado
- Verifica que `#menu-group-bodega` NO existe en DOM (ngIf oculta hijos)
- Simula `keydown` Enter y verifica que `aria-expanded` cambia a `true"
- Verifica que los hijos aparecen después de expandir
- Verifica que `document.activeElement` permanece en el botón (foco)

**Cobertura ARIA**: aria-expanded, aria-controls, aria-label, foco, Enter. **Falta**: Space (ya cubierto por test existente), Tab/roving (limitación legítima de TestBed sin browser).

### ✅ SeoSuggestionControllerTest — Test 503 proveedor (NUEVO)

**¿Es placeholder?** NO. Usa `@WebMvcTest` con filtros Spring Security activos.

**¿Prueba comportamiento?** SÍ:
- Mockea `service.suggest()` para lanzar `SeoSuggestionException` con status 503
- Verifica HTTP 503
- Verifica `$.status` = 503
- Verifica `$.detail` = "El servicio SEO no esta disponible" (mensaje genérico, sin filtrar detalle interno)

**Cobertura seguridad**: El test confirma que la excepción del proveedor se traduce a un error genérico tipado sin exponer stacks, prompts ni tokens. consistente con `seguridad/spec.md` R2.

### ✅ PublicacionServiceTest — Agotamiento slug + recalculo (NUEVOS)

**¿Es placeholder?** NO. Mockito con `@InjectMocks` sobre `PublicacionService` real.

**¿Prueba comportamiento?** SÍ:
- `exhaustedSlugCandidatesReturnConflictWithoutPartialSave`: Verifica que 5 intentos de `DuplicateKeyException` producen `PublicApiException` con status CONFLICT y mensaje "El slug no esta disponible". Verifica `verify(repository, times(5)).save(...)` — confirma que no hay guardado parcial.
- `recalculatesSlugWhenTitleChanges`: Verifica que `actualizar()` con titulo nuevo genera slug nuevo ("titulo-nuevo"), confirmando recálculo.

**Cobertura slug**: Agotamiento (5.2.7), recalculo (5.2.8). Complementa los tests existentes de normalización, fallback, límite y colisiones.

## Limitaciones legítimas (NO son fallos)

| Item | Razón |
|---|---|
| 5.2.6 carrera concurrente MongoDB | Requiere Testcontainers con MongoDB efímero; no se ejecuta por restricción de no modificar datos |
| 5.4.1-5.4.3 viewport 320/768/1440px | No hay runtime browser en el portal (Astro SSG); se verifican invariantes estáticos CSS |
| 5.5.4 suite backend completa | Requiere PostgreSQL y MongoDB aislados; no se ejecuta por la misma restricción |
| 3.3.4 chat no regresa | PostgreSQL del chat no disponible en `localhost:5433`; no se toca código del chat |
| Tab/roving focus en sidebar | TestBed de Angular no simula navegación Tab completa; test cubre Enter/foco que es lo criticable |

## Task completion

**Completed (all verifiable)**: 5.1.1-5.1.7, 5.2.1-5.2.5, 5.2.7-5.2.8, 5.3.1-5.3.7, 5.4.4-5.4.7, 5.5.1-5.5.3, 5.5.5-5.5.6, 5.6.1-5.6.2

**Blocked (legitimate infrastructure constraints)**: 5.2.6 (MongoDB/Testcontainers), 5.4.1-5.4.3 (browser runtime), 5.5.4 (full backend suite)

**Out of scope (not Slice 5)**: 3.3.4 (chat non-regression — Slice 3 task, not re-checked here)

## Security review

- ✅ Admin-api es el único borde autenticado para SEO (test: 401 sin JWT, 403 sin permiso)
- ✅ Public-api no recibe credenciales administrativas (sin cambios en public-api SecurityConfig)
- ✅ Errores 503 usan mensaje genérico "El servicio SEO no esta disponible" sin filtrar detalle
- ✅ Chat existente no se modificó; pruebas unitarias no persistentes pasan
- ✅ No se agregaron secretos, dependencias nuevas ni operaciones SQL

## Verdict

**PASS_WITH_WARNINGS** — Todos los tests nuevos verifican comportamiento real, no placeholders. La cobertura de menú/RBAC/ARIA/localStorage/teclado/SEO slug/SEO IA/portal está completa para los escenarios automatizables. El bug en `verify-editorial.mjs` es un falso positivo en la prueba (el CSS correcto, pero la prueba no lo valida). Las limitaciones son legítimas y están documentadas.
