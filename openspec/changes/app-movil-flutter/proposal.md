# Proposal: Aplicacion movil Flutter de Ferreplus

## Intent

Crear una aplicacion movil Flutter para Android e iOS que permita operar Ferreplus desde dispositivos moviles, reflejando la funcionalidad del frontend Angular y consumiendo el contrato REST existente de Spring Boot. Android tendra prioridad de validacion y entrega, sin duplicar reglas de negocio del backend. La app debe conservar autenticacion JWT, autorizacion por **autoridades/permisos** (no por roles) y ofrecer el chat de IA con respuestas Markdown y fuentes.

## Scope

### In Scope

- Crear una aplicacion Flutter 3+/Dart en `flutter/`, con soporte Android+iOS y Material 3.
- Autenticacion: login, persistencia de sesion en almacenamiento seguro, logout ante 401, carga/refresco de permisos mediante `GET /api/usuarios/me` y manejo de la arista de registro solo cuando el backend no tenga usuarios.
- Consumir todos los endpoints de negocio: autenticacion (incluido register condicional); CRUD de productos, categorias, proveedores, clientes, gastos, usuarios y roles; catalogos de modulos/permisos; ventas POS y anulacion; compras y anulacion; movimientos de stock; gestion de precios e historial; dashboard, reportes de ventas/inventario/movimientos; logs paginados/filtrables y borrado por rango; chat y rebuild protegido del indice.
- Replicar las capacidades de Angular: dashboard con KPIs/grafica, busquedas y formularios CRUD, detalle de entidades, POS con detalles, compras, movimientos, precios, usuarios/permisos, roles, reportes, logs y widget/pantalla de chat.
- Mapear modelos tipados para Producto, Categoria, Proveedor, Cliente, Venta/DetalleVenta, Compra/DetalleCompra, MovimientoStock, Gasto, Usuario, Rol, Auditoria, precios, reportes y `ChatResponse` (`answer`, `sources`). Fechas, nulos y errores se normalizaran en la frontera de datos.
- Tests unitarios de modelos, mapeadores, cliente/repositorios y providers; widget tests de login, shell/permisos, CRUD representativo, POS y chat. Cada slice debe incluir un minimo ejecutable de tests y pasar `flutter test`.
- Configurar `AGENTS.md`, `.gitignore` Flutter (`build/`, `.dart_tool/`, etc.) y `analysis_options.yaml` con `strict-casts: true`, `strict-raw-types: true` y lints de const/tipos explicitos.

### Out of Scope

- Cambios al backend, contrato REST, esquema PostgreSQL o pgvector; pgvector no requiere dependencia movil.
- Notificaciones push nativas, sincronizacion offline, cache offline conflictiva, modo desconectado y edicion colaborativa; podran evaluarse como cambios posteriores.
- Registro de usuario como flujo normal: solo se cubre la condicion excepcional del backend cuando no existe ningun usuario.
- Sustituir o modificar el frontend Angular, generar clientes OpenAPI automaticamente o implementar endpoints no presentes.
- Markdown completo/arbitrario con HTML ejecutable; el chat usara renderizado seguro limitado al comportamiento web existente.

## Approach

### Arquitectura

Se usara Clean Architecture con dependencia hacia adentro:

```text
flutter/lib/
  presentation/  # features, paginas/widgets, providers Riverpod, estados de UI
  domain/        # entidades, contratos de repositorio y casos de uso complejos
  data/          # DTOs freezed/json_serializable, repositorios, cliente API y storage
```

Los CRUD simples omitiran casos de uso innecesarios; ventas POS, compras, autenticacion, permisos y chat tendran casos de uso cuando concentren reglas o coordinacion. Widgets pequenos, composicion, `const` siempre que sea posible y sin logica de negocio en la vista son obligatorios.

### Estado, navegacion y red

- Riverpod sera el mecanismo de estado y de inyeccion de dependencias: providers asincronos para lecturas, notifiers para formularios/POS y un provider de sesion/permisos.
- GoRouter con `MaterialApp.router`, shell navegable y rutas declarativas. `redirect` exigira autenticacion; guards de permisos verificaran autoridades como `PRODUCTOS_VER`, `VENTAS_CREAR` o `REPORTES_VER`, sin inferir permisos desde el campo `rol`.
- Se elegira **Dio** sobre `http` porque el alcance requiere interceptores: agregar `Authorization: Bearer`, procesar 401 con limpieza de sesion/redireccion, normalizar errores, timeout y trazabilidad controlada. DTOs inmutables con `freezed` + `json_serializable`.
- `ApiConfig` resolvera la URL por `--dart-define=API_BASE_URL=...`, con valor de desarrollo para Android emulator `http://10.0.2.2:<puerto>`. Un dispositivo fisico usara la IP LAN del equipo servidor. Se podra incorporar una pantalla de configuracion de entorno solo para builds de desarrollo, nunca una URL productiva hardcodeada.
- Material 3, tema centralizado, strings/colores constantes y layouts adaptables a telefono; listas grandes usaran builders/paginacion donde el backend la soporte.

### Chat

Se implementara `POST /api/chat` con `question` y `conversationId` opcional. La respuesta Markdown se mostrara con el enfoque seguro compatible con web: escapar HTML, transformar listas y elementos soportados a representacion segura, y nunca inyectar HTML sin sanitizar. Las `sources` se mostraran en un acordeon, con estados de carga/error y conservacion de la conversacion en la sesion de UI. El endpoint de rebuild del indice queda disponible solo para una accion protegida por `CHAT_INDEX_REBUILD`, no como accion comun del usuario.

### Slices de entrega

Cada slice sera un PR encadenado, un commit o conjunto minimo de commits **independientemente compilable, testeable y revisable**. El usuario revisara el codigo y el mensaje de **cada commit** antes de continuar; no se acumularan cambios no revisados.

1. **S1 — Scaffolding, configuracion y auth**: proyecto `flutter/`, Android/iOS, AGENTS/lints/gitignore, tema Material 3, Dio/configuracion de URL, storage seguro, login, sesion, interceptor 401, `GET /usuarios/me`, GoRouter con redirect/permission guard, dashboard shell inicial. Tests de config, auth/interceptor y rutas.
2. **S2 — Catalogos y CRUD core**: productos, categorias, proveedores y clientes, incluyendo filtros, detalle, formularios y permisos. Tests de DTO/repository/provider y widgets de listado/formulario.
3. **S3 — Operacion comercial**: ventas POS con detalles y anulacion, compras con detalles y anulacion/edicion, movimientos de stock y gastos. Tests de calculos/validaciones, repositorios y widget tests de POS y formularios.
4. **S4 — Administracion, precios y analiticas**: gestion de precios/historial, usuarios, roles/permisos, dashboard completo, reportes e inventario. Logs con paginacion, filtros y borrado por rango, respetando `LOGS_VER`/`LOGS_ELIMINAR`. Tests de guards, tablas, filtros y estados de error.
5. **S5 — Chat y polish de entrega**: widget/pantalla chat, Markdown seguro, sources, manejo de errores, accesibilidad, rendimiento, icono/splash y validacion Android release; smoke tests del flujo autenticado y regresion de `flutter analyze`/`flutter test`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `flutter/` | New | Aplicacion Flutter completa, plataformas Android/iOS, `pubspec.yaml`, `lib/`, `test/` e `integration_test/` si se incorpora smoke test. |
| `flutter/lib/data/` | New | Cliente Dio, interceptores JWT, almacenamiento seguro, DTOs serializados y repositorios para todos los recursos REST. |
| `flutter/lib/domain/` | New | Entidades, contratos de repositorio y casos de uso de auth, ventas/compras, permisos y chat. |
| `flutter/lib/presentation/` | New | Rutas, shell, providers Riverpod, pantallas, formularios, tablas, POS, reportes, logs y chat. |
| `flutter/test/` | New | Tests unitarios y widget por slice; mocks/fakes de API sin depender del backend real. |
| `flutter/AGENTS.md` | New | Convenciones locales de Flutter, nombres, testing, comandos y limites de cambios. |
| `flutter/analysis_options.yaml` | New | Lints estrictos, casts/raw types estrictos y reglas de calidad Dart. |
| `flutter/.gitignore` | New | Artefactos Flutter/Android/iOS y archivos locales excluidos del control de versiones. |
| `openspec/changes/app-movil-flutter/` | New | Esta propuesta y los artefactos posteriores de spec, design, tasks y verificacion. |
| `backend/`, `frontend/` | None | Se consumen sus contratos existentes; no se modifican en este change. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Contrato real difiere del resumen: campos nullable, nombres, wrappers de pagina o fechas como strings | High | Confirmar respuestas con fixtures/entorno backend en S1, DTOs tolerantes y tests de deserializacion; no usar `dynamic` sin frontera explicita. |
| Android emulator no alcanza el backend | High | Documentar `10.0.2.2`, validar puerto/firewall y ofrecer `--dart-define`; probar tambien un dispositivo en LAN. |
| Guards confunden roles con permisos o permisos desactualizados | Med | Modelar autoridades como `Set<String>`, refrescar `/usuarios/me` en navegacion y probar 401/403/rutas ocultas. |
| POS/compras generan totales o payloads incompatibles | Med | Casos de uso con validacion tipada, fixtures del DTO exacto y pruebas de calculo antes de cada PR. |
| Markdown/chat permite HTML o rompe listas, fuentes y errores | Med | Parser seguro limitado, tests con HTML, listas, Markdown malformado, respuesta vacia y sources ausentes. |
| Alcance completo produce una app demasiado grande para un PR | High | PRs encadenados S1-S5, cada uno compilable y revisable; no avanzar sin aprobacion de cada commit. |
| Dependencias Flutter cambian o rompen el build iOS/Android | Med | Fijar versiones criticas, ejecutar `flutter analyze`, `flutter test` y build Android en cada slice; iOS se valida al cierre cuando exista toolchain. |

## Rollback Plan

El rollback es por slice: detener la cadena en el ultimo PR aprobado y revertir ese PR/commit; el backend y Angular permanecen intactos. Si ya existe `flutter/`, se elimina o se restaura unicamente el contenido del slice afectado, conservando los commits previamente aprobados. No hay migraciones ni datos persistidos en backend que revertir. Cualquier cambio de permisos o llamadas destructivas queda protegido por el backend y no se ejecuta durante el rollback. Las sesiones locales pueden invalidarse eliminando el storage seguro de la app.

## Dependencies

- Flutter SDK 3+ compatible con Dart del proyecto, Android SDK/emulator y Xcode para validacion iOS.
- Backend Spring Boot ejecutable y accesible desde emulator/dispositivo, con usuarios, permisos y datos de prueba.
- Paquetes: `flutter_riverpod`, `go_router`, `dio`, `freezed_annotation`, `json_annotation`, generadores `build_runner`/`freezed`/`json_serializable`, almacenamiento seguro y renderer Markdown seguro; versiones se fijaran en S1 tras verificar compatibilidad.
- Contratos y autenticacion JWT existentes; la app no requiere acceso directo a PostgreSQL/pgvector.
- Reglas de `openspec/config.yaml`: specs con Given/When/Then y RFC 2119, tareas jerarquicas y pruebas por fase.

## Success Criteria

- [ ] `flutter` compila para Android y `flutter analyze` no reporta warnings; `flutter test` pasa con cobertura minima acordada para cada slice.
- [ ] Un usuario puede iniciar sesion, conservar JWT de forma segura, ser redirigido ante 401 y ver solo rutas/acciones permitidas por autoridades.
- [ ] La app consume y representa todos los grupos de endpoints listados: auth, catalogos/CRUD, ventas POS, compras, stock, gastos, usuarios/roles, precios, reportes, logs y chat.
- [ ] Android emulator funciona con `10.0.2.2`; la URL cambia por `--dart-define` para dispositivo fisico/LAN sin recompilar codigo fuente.
- [ ] Ventas y compras envian DTOs con detalles y soportan anulacion; precios, reportes y logs reflejan filtros/permisos del backend.
- [ ] Chat muestra respuesta Markdown segura, no ejecuta HTML, y presenta/oculta `sources` correctamente.
- [ ] S1-S5 quedan como slices encadenados, cada uno compilable/testeable y con commits revisados por el usuario antes del siguiente.
- [ ] No se agregan notificaciones push, offline sync, cambios de backend ni acceso movil directo a pgvector.
