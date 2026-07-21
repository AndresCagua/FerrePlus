# Migración Angular 18 → 22 (Julio 2026)

> Lecciones aprendidas durante la migración de FerrePlus de Angular 18 a Angular 22.0.7

---

## 1. Node.js y Angular CLI

### Requisito de Node

Angular 22 requiere **Node.js `^22.22.3 || ^24.15.0 || >=26.0.0`**.

| Versión Node | Compatible |
|---|---|
| v22.16.x | ❌ |
| v22.22.3+ | ✅ (LTS Jod) |
| v24.15.0+ | ✅ (LTS Krypton) |

```bash
# Con nvm:
nvm install 22.22.3   # mínimo
nvm install 22.23.1    # latest LTS Jod
nvm alias default 22.23.1
```

### ⚠️ npm baja de versión

Al cambiar de Node, npm también cambia:
- Node v22.16.0 → npm 11.14.1
- Node v22.23.1 → npm 10.9.8

Esto no debería romper nada, pero el lockfile se regenera.

---

## 2. Dependencias obsoletas (BREAKING CHANGES)

### 2.1 Build system: Webpack → esbuild/Vite

| Paquete | Estado | Reemplazo |
|---------|--------|-----------|
| `@angular-devkit/build-angular` | ❌ Deprecado | `@angular/build` |
| `@ngtools/webpack` | ❌ Deprecado | `@angular/build` |
| `@angular/build` | ✅ Nuevo | Vite dev server + esbuild bundler |

**angular.json**: cambiar builder de `@angular-devkit/build-angular:application` a `@angular/build:application`.

**package.json**: agregar `"@angular/build": "^22.0.0"` en devDependencies, remover `@angular-devkit/build-angular`.

### 2.2 platform-browser-dynamic deprecado

```typescript
// ❌ ANTES
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
platformBrowserDynamic().bootstrapModule(AppModule);

// ✅ DESPUÉS
import { platformBrowser } from '@angular/platform-browser';
platformBrowser().bootstrapModule(AppModule);
```

Remover `@angular/platform-browser-dynamic` del package.json.

### 2.3 @angular/animations deprecado

Angular 22 deprecó `@angular/animations`. Reemplazar con animaciones nativas (`animate.enter` / `animate.leave` con View Transitions API). Si no se usan animaciones, directamente remover el paquete.

### 2.4 ng2-charts v10 — API changes

| Versión anterior | v10+ |
|-----------------|------|
| `NgChartsModule` | ❌ Eliminado |
| `BaseChartDirective` | ✅ Standalone, importar directamente |
| `provideCharts(withDefaultRegisterables())` | ✅ Nuevo provider |

```typescript
// imports en NgModule
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';

@NgModule({
  imports: [BaseChartDirective],
  providers: [provideCharts(withDefaultRegisterables())]
})
```

---

## 3. Cambios en el framework Angular 22

### 3.1 standalone: true es el DEFAULT

**¡Esto rompe proyectos con NgModules!**

En Angular 22, el default de la propiedad `standalone` en `@Component` cambió de `false` a `true`. Cualquier componente sin `standalone: false` explícito será tratado como standalone y NO puede declararse en `declarations` de un `NgModule`.

```typescript
@Component({
  selector: 'app-mi-componente',
  standalone: false,  // ← OBLIGATORIO si usas NgModules
  templateUrl: './mi-componente.html'
})
```

### 3.2 ChangeDetectionStrategy.Eager

Angular 22 cambió el default de `ChangeDetectionStrategy` a `OnPush`. Para mantener el comportamiento legacy (verificar todos los cambios), usar:

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.Eager  // antes era Default
})
```

### 3.3 TypeScript 6.0 — strictness extra

TypeScript 6.0 (requerido por Angular 22) es más estricto:

- **`baseUrl` y `downlevelIteration` deprecados** en tsconfig.json — removerlos. Con `moduleResolution: "bundler"` no son necesarios.
- **Paths relativos se resuelven correctamente** — si tenías paths incorrectos que funcionaban por el `baseUrl: "./"`, ahora fallan.
- **Null safety reforzada** — variables que antes se pasaban sin chequeo ahora obligan a optional chaining (`?.`) o null coalescing (`??`).
- **`@HostListener` estricto** — `@HostListener('window:resize', ['$event'])` falla si el handler no recibe argumentos.
- **FormArray.controls** devuelve `AbstractControl[]`, no `FormGroup[]` — puede requerir casts.

### 3.4 Template checking más estricto (strictTemplates)

Angular 22 con `strictTemplates: true` detecta:
- Propiedades que no existen en modelos (`items` → `detalles`, `codigo` → `codigoBarras`)
- Métodos que no existen en componentes
- Bindings inválidos en directivas

---

## 4. Problemas comunes de migración

### 4.1 Paths de environment

Con `moduleResolution: "bundler"` y sin `baseUrl`, los paths relativos se resuelven estrictamente desde la ubicación del archivo:

```
src/app/productos/producto.service.ts
  → ../../environments/environment    ✅ correcto (sube a src/)
  → ../../../environments/environment  ❌ incorrecto (sube fuera del proyecto)
```

### 4.2 Modelos desincronizados

Migrar templates a los nombres reales de los modelos:

| Template (viejo) | Modelo real |
|-----------------|-------------|
| `producto.codigo` | `producto.codigoBarras` |
| `producto.stock` | `producto.stockActual` |
| `venta.createdAt` | `venta.fechaCreacion` |
| `venta.items` | `venta.detalles` |
| `venta.clienteNombre` | `venta.cliente?.nombre` |
| `venta.usuarioNombre` | `venta.usuario?.nombre` |
| `compra.createdAt` | `compra.fechaCreacion` |
| `compra.numeroOrden` | `compra.numeroFactura` |
| `compra.proveedorNombre` | `compra.proveedor?.nombre` |
| `compra.items` | `compra.detalles` |
| `movimiento.createdAt` | `movimiento.fecha` |
| `movimiento.productoNombre` | `movimiento.producto?.nombre` |
| `usuario.rol` | `usuario.rolNombre` |

### 4.4 Módulos de Angular Material

Con standalone: false, los componentes heredan los imports del NgModule que los declara. Pero Angular Material requiere importar cada módulo. Verificar que todos los módulos de Material estén en los imports correctos (`MatDividerModule` es común de olvidar).

---

## 5. Seguridad en npm (project-level .npmrc)

Configuración por proyecto para evitar riesgos de supply chain:

```ini
# .npmrc (project-level, no afecta otros proyectos)
min-release-age=1          # 1 día ≈ 1440 minutos antes de aceptar un paquete
allow-git=none             # Bloquear dependencias desde repos git
allow-remote=none           # Bloquear dependencias desde URLs directas
```

Alternativa con pnpm (más granular):
```yaml
# pnpm-workspace.yaml
blockExoticSubdeps: true
minimumReleaseAge: 1440    # en minutos
```

---

## 6. Flujo de migración recomendado

```
1. Verificar versión de Node requerida → instalar con nvm
2. Actualizar package.json (Angular 22, TypeScript 6, @angular/build)
3. npm install
4. Agregar standalone: false a TODOS los componentes legacy
5. Agregar ChangeDetectionStrategy.Eager
6. ng build → iterar errores:
   a. Corregir paths de environment
   b. Corregir tsconfig (remover baseUrl, downlevelIteration)
   c. Alinear modelos con templates
   d. Corregir null safety
   e. Agregar módulos de Material faltantes
7. Repetir hasta BUILD SUCCESS
```

---

## 7. Skills útiles

Instalados en el proyecto (`skills-lock.json`):

- **angular-developer**: Guías de componentes, signals, forms, DI, routing, testing
- **angular-new-app**: Creación de proyectos Angular con CLI

```bash
# Ver skills disponibles desde angular/angular
https://github.com/angular/angular/tree/main/skills/dev-skills
```
