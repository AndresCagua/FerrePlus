# Proposal: App movil fixes offline

## Title

`app-movil-fixes-offline` — Correcciones de navegacion, dashboard y UX, mas operacion offline automatica para Flutter.

## Summary

Corregir cuatro fallos de comportamiento y mejorar chat/formularios, incorporando una cola SQLite de sincronizacion automatica para ventas, gastos, compras y movimientos sin modificar backend ni frontend web.

## Intent

La app movil ya refleja el design system y la navegacion principal, pero presenta fallos que bloquean acciones comunes, una experiencia deficiente con teclado y formularios, y no puede registrar operaciones cuando la red falla. Este change debe elevar la confiabilidad operacional sin duplicar reglas de negocio ni alterar los contratos REST existentes.

## Problem

1. **FAB de chat no alterna** — `flutter/lib/presentation/shell/chat_floating_action_button.dart:81-88`: siempre ejecuta `context.go('/chat')`, incluso estando en chat; no cambia icono, tooltip ni permite cerrar.
2. **Navegacion Gastos → Ventas atascada** — `flutter/lib/presentation/shell/shell_scaffold.dart:20-28`: varias rutas comparten la rama 2 y `goBranch` usa `initialLocation` basado solo en el indice actual, dejando el `StatefulShellRoute` en una ubicacion incorrecta.
3. **Sin operacion offline** — `flutter/pubspec.yaml:30-47` no incluye persistencia SQLite, deteccion de red ni notificaciones locales; `flutter/lib/data/services/api_client.dart` solo soporta la llamada online con JWT. Las cuatro operaciones comerciales se pierden o fallan si no hay conectividad.
4. **Grafica del dashboard puede mostrar un solo dia** — `flutter/lib/presentation/features/dashboard/dashboard_provider.dart:25-41`: prioriza `dashboard.ventasPorDia` y solo consulta `reportSalesProvider(range)` si el resultado agrupado queda vacio, por lo que no garantiza el periodo seleccionado.
5. **Layout del Chat IA defectuoso** — `flutter/lib/presentation/features/chat/pages/chat_page.dart:104-189`: el indicador usa un `ListTile` que comprime el texto, el composer no considera `viewInsets`, no hay scroll automatico, el ancho maximo es fijo en 700 y el contador ocupa espacio innecesario.
6. **Superposicion y falta de ritmo en formularios** — `flutter/lib/presentation/features/commercial_pages.dart:273-421` (y el formulario de compras en `:741-901`): no hay separacion entre agregar linea, detalles y descuento. El mismo riesgo se extiende a Venta, Compra, Movimiento, Gasto, Productos, Categorias, Proveedores, Clientes, Usuarios y Roles.
7. **README incompleto para la app** — `README.md:192-227`: documenta backend/frontend, pero no stack, estructura, tests, comandos ni alcance de Flutter.

## Scope

### In Scope

- Corregir el toggle del FAB usando la ruta actual de GoRouter, retorno a la rama/ruta previa o dashboard, e icono/tooltip/semantics dinamicos; conservar el FAB arrastrable.
- Hacer determinista la navegacion del shell mediante un mapa de rama a ruta inicial y navegacion explicita, preservando las cinco ramas y su estado.
- Incorporar almacenamiento local SQLite y una cola durable de operaciones pendientes para **ventas, gastos, compras y movimientos de stock**. Persistir payload, endpoint, metodo, usuario, timestamp, estado, intentos y error sanitizado.
- Implementar sync automatico al recuperar red, procesamiento FIFO con retry/backoff y limites razonables, lectura/listado desde cache cuando corresponda y notificacion local de pendientes mediante `flutter_local_notifications`. No usar Firebase/FCM en este change.
- Mantener los contratos existentes: POST de las cuatro operaciones, GET de sus listados y PUT de anulacion de ventas/compras; conservar Dio/AuthInterceptor JWT y manejar expiracion sin perder la cola.
- Corregir el provider del dashboard para usar el periodo elegido y su fallback de reportes, sin cambiar backend ni frontend web.
- Rediseñar el layout del chat sin cambiar prompts, RAG, endpoints ni logica: indicador integrado debajo del ultimo mensaje del usuario, burbujas con constraints relativos, scroll automatico suave, composer compacto con scroll interno, SafeArea/teclado y contador discreto 0/1000; sin `Positioned` absoluto para resolver layout ni fuentes reducidas/FittedBox.
- Crear componentes reutilizables de formularios (`AppFormField`, `AppDropdownField`, `AppFormSection` o equivalentes), aplicar `AppSpacing`, labels accesibles y agrupacion semantica a las aproximadamente diez pantallas indicadas, manteniendo design system, validaciones, modelos, endpoints y logica de negocio.
- Actualizar `README.md` con la seccion Flutter: stack, arquitectura `presentation/domain/data`, comandos, tests y resumen de UX/offline.
- Agregar tests unitarios, de repositorio/provider y widget para cola, retry, estados offline/online, FAB, navegacion, dashboard, chat y componentes de formularios, sin romper los 77 tests existentes.

### Out of Scope

- Cualquier cambio en `backend/`, contrato REST, base PostgreSQL, endpoints nuevos o frontend Angular.
- Firebase, FCM, push notifications, sincronizacion colaborativa o cambios de servidor para resolver conflictos.
- Offline para chat, autenticacion, catalogos, reportes o administracion fuera de la cache/listados estrictamente necesarios para visualizar el estado local.
- Reescritura de prompts/RAG/endpoints del chat, cambio de la navegacion de cinco ramas o eliminacion del FAB arrastrable.
- Cambios de reglas de negocio, calculos POS, validaciones, permisos, modelos API o design system existente.
- Sincronizacion destructiva silenciosa: anular, eliminar o sobrescribir datos del servidor fuera de las operaciones ya soportadas.

## Approach

### 1. Navegacion y FAB

Leer `GoRouterState.of(context).uri.path` para distinguir `/chat` del resto. El FAB sera un control accesible con accion de abrir/cerrar; al cerrar usara una ruta segura conocida (rama previa cuando sea posible, de lo contrario dashboard), sin romper deep links. Para el shell, centralizar un mapa `branchIndex → canonical initial route` y separar la seleccion de rama de la decision `initialLocation`; la navegacion a Gastos, Ventas y rutas secundarias sera explicita y testeable.

### 2. Offline-first acotado

Mantener Clean Architecture: contratos y estados en `domain`, implementaciones SQLite/sync en `data`, y providers Riverpod en `presentation`. Preferir **Drift** por esquema tipado, consultas declarativas y migraciones verificables; comparar contra `sqflite` durante design si el peso/compatibilidad de la aplicacion lo exige. Usar `connectivity_plus` como señal de disponibilidad, no como prueba unica de Internet: el worker confirmara conectividad mediante la peticion real.

Cada escritura offline se registrara primero en una transaccion local junto con su operacion de cola y un identificador idempotente local. Al volver la red, un sincronizador procesa FIFO con backoff acotado, evita duplicados, actualiza el registro local con la respuesta del backend y marca errores permanentes para intervencion controlada. La politica de conflicto sera last-write-wins para representaciones locales simples, con el servidor como autoridad para inventario y transacciones; un 409/validacion no se reintentara indefinidamente.

El sync en segundo plano se evaluara con `workmanager` y solo se habilitara si aporta cobertura real en Android/iOS sin wake-ups agresivos. En primer plano siempre se sincroniza al detectar red y al reanudar la app. `flutter_local_notifications` notificara pendientes/error persistente de forma agrupada, respetando permisos y sin contenido sensible. JWT expirado se tratara como estado `auth_required`: conservar la cola cifrada/minimamente expuesta, pausar retries y reanudar tras sesion valida; si el interceptor recibe 401, aplicar el logout existente sin descartar operaciones.

### 3. Dashboard

Determinar el `DateRange` una sola vez por periodo y obtener datos agrupables para todo el rango: usar `ventasPorDia` solo cuando cubra el rango, de lo contrario consultar `reportSalesProvider(range)` y agrupar por dia/mes. No se tocara el backend. Cubrir semana, mes, ano, vacio, error y cambio de periodo con tests.

### 4. Chat IA

Conservar `ChatState`, provider, markdown seguro, fuentes y `conversationId`. Separar lista/composer en widgets pequenos; usar un `ScrollController` con dispose y desplazamiento al ultimo mensaje despues de insertar mensajes o el indicador. El indicador sera una burbuja de asistente con animacion de puntos/skeleton respetando reduced motion. El composer usara `MediaQuery.viewInsets`, `SafeArea`, altura minima/maxima, multilinea con scroll interno y contador discreto.

### 5. Formularios

Extraer componentes de campo/seccion sobre el tema actual, con spacing consistente, estados de error inline y targets de al menos 48 dp. En cada formulario organizar secciones como datos principales, producto/detalles y resumen/observaciones; usar `ListView`/`SingleChildScrollView` con teclado y botones dentro del flujo natural. El refactor sera mecanico de presentacion: no mover calculos, validaciones, providers, permisos ni requests.

### 6. Calidad y documentacion

Aplicar convenciones Flutter locales: `const`, tipado estricto, Riverpod para estado compartido, repositorios sin imports de UI y widgets pequenos. Validar por cortes con `flutter analyze`, `flutter test` y build Android debug; auditar memoria/bateria del sync y layout en telefono estrecho, landscape, teclado, escala de texto y Android/iOS cuando exista entorno.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `flutter/lib/presentation/shell/chat_floating_action_button.dart` | Modified | Toggle de abrir/cerrar, icono, tooltip y semantics dinamicos. |
| `flutter/lib/presentation/shell/shell_scaffold.dart` y router | Modified | Mapa de rutas canonicas y navegacion explicita entre ramas. |
| `flutter/lib/data/services/api_client.dart` | Modified | Integracion con la capa offline sin romper Dio/AuthInterceptor. |
| `flutter/lib/data/services/`, `data/repositories/`, `domain/` | New/Modified | Base SQLite, cola, modelos de operacion, sync, retry y mapeos de las cuatro transacciones. |
| `flutter/lib/presentation/features/dashboard/dashboard_provider.dart` | Modified | Fallback y agrupacion correcta por periodo. |
| `flutter/lib/presentation/features/chat/pages/chat_page.dart` y `chat/widgets/` | Modified | Layout responsive, composer, indicador y scroll automatico. |
| `flutter/lib/presentation/features/commercial_pages.dart` y `features/{productos,categorias,proveedores,clientes,admin,gastos,compras,movimientos}/` | Modified | Refactor de los formularios y uso de componentes compartidos. |
| `flutter/lib/presentation/shared/widgets/` | New/Modified | Componentes de formulario y tokens/spacing solo si falta una abstraccion compatible. |
| `flutter/pubspec.yaml`, `android/`, `ios/` | Modified | Dependencias y configuracion de SQLite, red, notificaciones y tareas background. |
| `flutter/test/` | New/Modified | Tests unitarios, provider, repositorio y widget; baseline de 77 tests preservado. |
| `README.md` | Modified | Documentacion de Flutter, comandos, estructura, tests y offline. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| JWT expirado deja operaciones pendientes o provoca reintentos inutiles | High | Estado `auth_required`, pausa de cola, no descartar payloads, reanudar tras autenticacion; confirmar durante design si existe refresh endpoint. |
| Conflictos o duplicados en transacciones offline | High | UUID/idempotency local, FIFO, respuesta del servidor como autoridad para stock, backoff y estados terminales; documentar last-write-wins donde aplique. |
| Crecimiento excesivo de la base local | Med | Retencion por estado/edad, limites de cola, limpieza de respuestas sincronizadas y metrica de tamano; no cachear todo el catalogo. |
| Consumo de bateria/memoria por listeners, notificaciones o background work | High | Sin polling continuo, debounce de conectividad, batches pequenos, limites de retry, dispose de subscriptions y `workmanager` opcional solo con evidencia. |
| Complejidad y regresiones en `StatefulShellRoute` | Med | Mapa unico de rutas, pruebas de branch/deep link y no cambiar el numero de ramas. |
| Refactor masivo de formularios rompe validaciones o flujo de negocio | High | Cambios solo de composicion, tests existentes y tests por formulario; migracion por grupos con `flutter analyze` despues de cada corte. |
| Chat o formularios vuelven a ocultar contenido bajo teclado/safe area | Med | Pruebas con teclado abierto, landscape, ancho estrecho y escala de texto; evitar posiciones absolutas y alturas rigidas. |
| Dependencias nativas de SQLite/notificaciones fallan en Android o iOS | Med | Versiones compatibles con Flutter 3.38/Dart 3.10, configuracion reproducible, build Android y smoke tests en dispositivo; iOS queda validado cuando haya entorno macOS. |
| Los 77 tests existentes dejan de pasar | High | Ejecutar suite completa antes/despues de cada fase, conservar APIs publicas y priorizar tests de regresion de FAB, shell y formularios. |

## Open Questions

- ¿El backend dispone de un endpoint de refresh JWT o solo invalida por 401? La implementacion debe confirmar esto antes de definir reautenticacion automatica.
- ¿Se requiere sincronizacion background estricta con la app cerrada en iOS/Android, o basta sincronizar al recuperar red mientras la app esta activa y al reanudar? Esto decide si se incorpora `workmanager`.
- ¿Se aprueba Drift como opcion final frente a sqflite despues de revisar tamano del binario, soporte de migraciones y restricciones de despliegue?
- ¿Las notificaciones de pendientes deben ser una unica notificacion agrupada por usuario/dispositivo y con que politica de permisos/quiet hours?

## Rollback Plan

1. Revertir el change completo por commits/fases, empezando por las configuraciones nativas y dependencias, sin tocar backend ni datos del servidor.
2. Mantener la base SQLite versionada; si se desactiva offline, dejar la migracion compatible y detener el sincronizador antes de eliminar tablas en una entrega posterior.
3. Deshabilitar el sync/background worker y las notificaciones mediante un feature flag local de emergencia, preservando el flujo online existente.
4. Si el refactor visual causa regresiones, restaurar cada formulario al widget previo de forma aislada; los componentes nuevos no deben cambiar contratos publicos ni modelos.

## Dependencies

- Paquetes Flutter a evaluar/incorporar: `drift` (o `sqflite`), `connectivity_plus`, `flutter_local_notifications` y `workmanager` solo si se confirma necesidad.
- Contratos existentes de `POST/GET /api/ventas`, `/api/gastos`, `/api/compras`, `/api/movimientos-stock` y `PUT` de anulacion para ventas/compras.
- Flutter 3.38.1, Dart 3.10.0, Dio 5.9.0, Riverpod 3.0.3, GoRouter 16.2.4 y `AGENTS.md` local.
- Validacion Android con Java 21; validacion iOS requiere entorno macOS para plugins y build nativo.

## Success Criteria

- [ ] El FAB abre y cierra el chat correctamente, con estado accesible y sin romper el arrastre.
- [ ] Gastos → Ventas y el resto de rutas secundarias navegan a su destino canonico sin atasco de `StatefulShellRoute`; las cinco ramas conservan estado.
- [ ] Ventas, gastos, compras y movimientos se guardan localmente sin red y se sincronizan automaticamente al volver la conectividad, con retry acotado, notificacion local y manejo seguro de JWT.
- [ ] La grafica respeta semana/mes/ano y agrupacion correspondiente sin cambios en backend/web.
- [ ] Chat funciona con teclado abierto, scroll automatico, burbuja de consulta, constraints relativos y contador compacto sin alterar logica IA.
- [ ] Las diez familias de formularios tienen spacing, secciones, labels, scroll y botones sin superposicion; validaciones, permisos y endpoints permanecen iguales.
- [ ] README documenta Flutter y offline; `flutter analyze` queda limpio y `flutter test` mantiene verdes los 77 tests existentes mas la cobertura nueva.
- [ ] Se verifica build Android y se documentan pruebas de bateria/memoria, offline, escala de texto, safe areas, landscape y accesibilidad.
