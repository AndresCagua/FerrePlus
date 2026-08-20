# Especificacion — Aplicacion movil Flutter de Ferreplus

## Proposito

Este cambio crea una aplicacion movil Flutter 3+/Dart dentro del directorio `flutter/` que refleje las capacidades del frontend Angular y consuma el backend Spring Boot existente mediante su contrato REST JWT. La app respetara la autoridad por **permisos** (no por roles), persistira la sesion de forma segura y ofrecera una experiencia prioritaria en Android, sin duplicar reglas de negocio del backend.

## Alcance

### En scope

- Proyecto Flutter en `flutter/` con plataformas Android e iOS, Material 3, tema centralizado, `AGENTS.md`, `.gitignore` y `analysis_options.yaml` estricto.
- Autenticacion JWT: login, persistencia segura de token, logout ante 401, refresco de permisos via `GET /api/usuarios/me` y flujo de registro solo cuando el backend no tenga usuarios.
- Consumo de todos los grupos de endpoints de negocio: productos, categorias, proveedores, clientes, ventas POS, compras, movimientos de stock, gastos, precios, usuarios, roles, modulos/permisos, reportes, logs y chat.
- Navegacion declarativa con GoRouter, shell navegable y guards de permisos por modulo.
- Capa de red con Dio, interceptor JWT, manejo de 401 y URL base via `--dart-define`.
- Renderizado seguro de Markdown en el chat, visualizacion de fuentes y manejo de `conversationId`.
- Tests unitarios y widget por slice, con `flutter test` ejecutable en cada entrega.

### Fuera de alcance

- Cambios al backend, contrato REST, esquema PostgreSQL o pgvector.
- Notificaciones push (FCM) y sincronizacion offline de chat, autenticacion, catalogos, reportes o administracion fuera de la cache de listados comerciales (R66-R73).
- Registro de usuario como flujo normal (solo el caso de backend sin usuarios).
- Modificacion del frontend Angular, generacion automatica de clientes OpenAPI o nuevos endpoints.
- Markdown arbitrario con HTML ejecutable; el chat usa renderizado seguro limitado.

## Decisiones vinculantes

| # | Decision | Opcion elegida / Racional |
|---|----------|---------------------------|
| 1 | Directorio y stack | `flutter/` como app independiente; Android prioridad de validacion, iOS como objetivo secundario. |
| 2 | Arquitectura | Clean Architecture con capas `presentation/`, `domain/` y `data/`. CRUD simples sin caso de uso; auth, POS, compras, permisos y chat con casos de uso. |
| 3 | Estado | Riverpod para estado compartido e inyeccion de dependencias. |
| 4 | Navegacion | GoRouter con `MaterialApp.router`, shell navegable, `redirect` de autenticacion y guards de permisos. |
| 5 | Red | Dio con interceptor JWT por encima de `http`, dado el manejo de 401, retry controlado y errores normalizados. |
| 6 | Modelos | DTOs inmutables con `freezed` + `json_serializable`. |
| 7 | URL base | `--dart-define=API_BASE_URL=...`; desarrollo en emulator `http://10.0.2.2:<puerto>`; dispositivo fisico por IP LAN. |
| 8 | Seguridad UI | Cada ruta/accion se condiciona a permisos explicitos (`PRODUCTOS_VER`, `VENTAS_CREAR`, etc.), sin inferir permisos desde `rol`. |
| 9 | Chat | Renderizado seguro de Markdown (escapar HTML, listas, parrafos) y fuentes en acordeon; rebuild de indice solo con `CHAT_INDEX_REBUILD`. |
| 10 | Calidad | `analysis_options.yaml` con `strict-casts: true`, `strict-raw-types: true`, lints de const/tipos explicitos; tests unit + widget por slice. |

## Requisitos

### S1 — Scaffolding, configuracion y autenticacion

#### R1 [S1] Login con JWT

El sistema DEBE autenticar al usuario mediante `POST /api/auth/login` con `email` y `password`. Cuando el backend responde 200 con `token`, `email`, `nombre`, `rol`, `usuarioId` y `permisos[]`, el sistema DEBE almacenar el token y el conjunto de permisos de forma segura y redirigir al dashboard. El sistema NO DEBE iniciar sesion si falta algun campo critico.

##### Escenario: Login exitoso

- GIVEN un usuario activo con credenciales validas
- WHEN ingresa email y password en la pantalla de login y presiona "Ingresar"
- THEN se llama a `POST /api/auth/login`
- AND al recibir 200 con token y permisos, el sistema persiste la sesion y navega al dashboard

##### Escenario: Credenciales invalidas

- GIVEN un usuario con credenciales incorrectas
- WHEN intenta iniciar sesion
- THEN el backend responde 401
- AND el sistema muestra un mensaje de error controlado sin persistir token

##### Escenario: Respuesta de login incompleta

- GIVEN que el backend responde 200 pero sin campo `token`
- WHEN se procesa la respuesta
- THEN el sistema trata la respuesta como error de autenticacion
- AND no persiste la sesion

#### R2 [S1] Persistencia de sesion

El sistema DEBE persistir el token JWT y los permisos en almacenamiento seguro. Al iniciar la aplicacion, si existe un token y permisos validos, el sistema DEBE omitir la pantalla de login y mostrar el dashboard. Si el almacenamiento esta vacio o corrupto, el sistema DEBE redirigir a `/login`.

##### Escenario: Inicio con sesion activa

- GIVEN que el usuario cerro la app estando autenticado
- WHEN la app se abre nuevamente
- THEN el sistema lee el token y permisos del almacenamiento seguro
- AND navega directamente al dashboard

##### Escenario: Inicio sin sesion

- GIVEN que no existe token en almacenamiento
- WHEN la app se abre
- THEN el sistema muestra la pantalla de login

##### Escenario: Almacenamiento corrupto o ilegible

- GIVEN que el almacenamiento contiene datos que no se pueden parsear
- WHEN la app intenta recuperar la sesion
- THEN el sistema limpia el almacenamiento
- AND redirige a la pantalla de login

#### R3 [S1] Manejo de respuesta 401 y logout

Ante cualquier respuesta HTTP 401 del backend, el sistema DEBE limpiar la sesion almacenada y redirigir a `/login`. El usuario tambien DEBE poder cerrar sesion manualmente desde el menu, lo que limpiara el almacenamiento y lo devolvera al login.

##### Escenario: 401 en cualquier peticion autenticada

- GIVEN un usuario autenticado
- WHEN una llamada al backend responde 401
- THEN el sistema elimina el token y permisos
- AND redirige a `/login`

##### Escenario: Logout manual

- GIVEN un usuario autenticado
- WHEN selecciona "Cerrar sesion"
- THEN el sistema borra el token y permisos
- AND redirige a `/login`

#### R4 [S1] Refresco de permisos

El sistema DEBE poder refrescar los permisos efectivos del usuario llamando a `GET /api/usuarios/me`. Este refresco DEBE ejecutarse al recuperar la sesion y ante cambios relevantantes de navegacion, de modo que los permisos recien otorgados o revocados se reflejen sin necesidad de nuevo login.

##### Escenario: Refresco exitoso al iniciar

- GIVEN un usuario con sesion persistida
- WHEN la app se inicia
- THEN el sistema llama a `GET /api/usuarios/me`
- AND actualiza el conjunto de permisos locales

##### Escenario: Permisos actualizados sin re-login

- GIVEN un usuario autenticado cuyo rol fue modificado para agregar `PRODUCTOS_CREAR`
- WHEN la app refresca permisos
- THEN el boton "Nuevo producto" se vuelve visible

##### Escenario: Error al refrescar permisos

- GIVEN un usuario autenticado
- WHEN `GET /api/usuarios/me` responde 401
- THEN el sistema cierra la sesion y redirige al login

#### R5 [S1] Registro condicional cuando no hay usuarios

Si el backend indica que no existe ningun usuario (o expone un endpoint/respuesta que habilita el registro inicial), el sistema DEBE ofrecer un flujo de registro de administrador inicial. Tras un registro exitoso, el sistema DEBE redirigir al login. El registro NO DEBE estar disponible si ya existen usuarios.

##### Escenario: Backend sin usuarios habilita registro

- GIVEN que el backend no tiene usuarios registrados
- WHEN se accede a la app
- THEN el sistema muestra la opcion de "Registrar administrador"

##### Escenario: Registro inicial exitoso

- GIVEN la pantalla de registro inicial con datos validos
- WHEN se envia el formulario
- THEN se llama al endpoint de registro
- AND tras 200/201 se redirige al login

##### Escenario: Registro no disponible con usuarios existentes

- GIVEN que el backend ya tiene al menos un usuario
- WHEN se accede a la app
- THEN no se muestra la opcion de registro inicial

#### R6 [S1] Navegacion declarativa con GoRouter (modificado por app-movil-fixes-offline: R-M2)

El sistema DEBE usar GoRouter para la navegacion. La configuracion DEBE incluir un `redirect` que envie a `/login` a usuarios no autenticados y al dashboard a usuarios autenticados que intenten acceder a `/login`. El shell principal DEBE conservar estado entre pestanas mediante `StatefulShellRoute` o equivalente. La navegacion entre ramas DEBE ser explicita y determinista segun R-M2: un mapa inmutable `branchInitialRoutes` (`0→/`, `1→/productos`, `2→/ventas`, `3→/reportes`, `4→/mas`) y `goBranch` solo para cambios de rama.

##### Escenario: Usuario no autenticado accede a ruta protegida

- GIVEN un usuario sin sesion
- WHEN intenta navegar a `/productos`
- THEN GoRouter redirige a `/login`

##### Escenario: Usuario autenticado accede a login

- GIVEN un usuario autenticado
- WHEN intenta acceder a `/login`
- THEN GoRouter redirige al dashboard

##### Escenario: Navegacion entre pestanas del shell

- GIVEN un usuario autenticado en el shell
- WHEN cambia de pestana
- THEN el estado de la pestana previa se conserva

#### R7 [S1] Guards de permisos por modulo

Cada ruta funcional DEBE requerir un permiso especifico. Si el usuario no posee el permiso requerido, el sistema DEBE redirigirlo a una ruta permitida (dashboard o login). Los permisos DEBEN modelarse como un `Set<String>` y NUNCA inferirse desde el campo `rol`.

##### Escenario: Ruta permitida

- GIVEN un usuario autenticado con `PRODUCTOS_VER`
- WHEN navega a `/productos`
- THEN el sistema renderiza la lista de productos

##### Escenario: Ruta no permitida

- GIVEN un usuario autenticado sin `PRODUCTOS_VER`
- WHEN navega a `/productos`
- THEN el sistema redirige al dashboard

##### Escenario: Accion oculta sin permiso

- GIVEN un usuario autenticado con `PRODUCTOS_VER` pero sin `PRODUCTOS_CREAR`
- WHEN esta en `/productos`
- THEN el boton "Nuevo producto" no se muestra

#### R8 [S1] Shell navegable y dashboard inicial (modificado por ui-ux; app-movil-fixes-offline: R-M2)

El sistema DEBE presentar un shell navegable (bottom navigation bar) que liste las secciones permitidas segun permisos, con un maximo de cinco destinos: Dashboard, Productos, Ventas, Reportes y Mas (R55, R56). Las rutas secundarias permanecen accesibles desde la pagina `Mas` categorizada o por deep link; la NavigationBar de 15 destinos del estado anterior queda REMOVIDA. El dashboard DEBE mostrar los seis KPI, la grafica de ventas por periodo, las acciones rapidas y los estados compartidos descritos en R51-R54, y servir como punto de entrada. La navegacion del shell DEBE ser determinista: `ShellScaffold` DEBE usar un mapa explicito `branchIndex -> ruta inicial canonica` (`0→/`, `1→/productos`, `2→/ventas`, `3→/reportes`, `4→/mas`) y navegar explicitamente a la ruta canonica de la rama seleccionada. Las rutas secundarias como `/gastos`, `/compras` y `/movimientos` DEBEN resolverse correctamente sin depender de heuristicas de `StatefulShellRoute.indexedStack`. El estado por rama DEBE continuar preservandose.

##### Escenario: Menu filtrado por permisos

- GIVEN un usuario autenticado con permisos de productos y ventas
- WHEN se renderiza el shell
- THEN aparecen los items "Productos" y "Ventas"
- AND no aparecen items para modulos sin permiso

##### Escenario: Dashboard como ruta inicial

- GIVEN un usuario autenticado
- WHEN inicia sesion exitosamente
- THEN el sistema navega al dashboard

##### Escenario: El dashboard muestra el dashboard de FerrePlus

- GIVEN el usuario inicia sesion correctamente
- WHEN el dashboard se renderiza
- THEN muestra los seis KPIs, la grafica de ventas y las acciones rapidas segun R51-R54

##### Escenario: El shell muestra cinco pestanas

- GIVEN un usuario autenticado
- WHEN el shell se renderiza
- THEN la barra inferior muestra como maximo cinco items y las rutas restantes se alcanzan desde `Mas`

##### Escenario: Gastos -> Ventas navega correctamente

- GIVEN el usuario esta en `/gastos` dentro de la rama Ventas
- WHEN toca la pestana Ventas
- THEN la app navega a `/ventas`

##### Escenario: Deep link a ruta secundaria selecciona la rama correcta

- GIVEN la app recibe un deep link a `/compras`
- WHEN el shell se renderiza
- THEN la rama 2 esta seleccionada
- AND la pagina `/compras` se muestra

##### Escenario: Estado de la rama se preserva

- GIVEN el usuario hizo scroll en la lista de Productos y luego cambio a Dashboard
- WHEN vuelve a Productos
- THEN la lista permanece en la misma posicion de scroll

##### Escenario: Cinco ramas/tabs se mantienen

- GIVEN el shell se renderiza
- WHEN se inspecciona la barra de navegacion inferior
- THEN se muestran exactamente cinco destinos
- AND el mapeo de ramas cubre Dashboard, Productos, Ventas, Reportes y Mas

#### R9 [S1] Configuracion de URL base via dart-define

La URL base del backend DEBE resolverse exclusivamente mediante `--dart-define=API_BASE_URL=...`. El sistema NO DEBE contener URLs productivas hardcodeadas. El valor por defecto de desarrollo para Android emulator DEBE ser `http://10.0.2.2:<puerto>`.

##### Escenario: Compilacion con URL de emulator

- GIVEN un build de desarrollo con `--dart-define=API_BASE_URL=http://10.0.2.2:8080`
- WHEN la app realiza una peticion
- THEN se usa dicha URL base

##### Escenario: Dispositivo fisico con IP LAN

- GIVEN un build con `--dart-define=API_BASE_URL=http://192.168.1.50:8080`
- WHEN la app corre en un dispositivo fisico
- THEN se usa la IP LAN sin cambiar codigo fuente

#### R10 [S1] Calidad del proyecto y lints

El sistema DEBE incluir `analysis_options.yaml` con `strict-casts: true`, `strict-raw-types: true` y reglas que exijan `const` y tipado explicito. El proyecto DEBE pasar `flutter analyze` sin warnings al cierre de S1.

##### Escenario: flutter analyze limpio

- GIVEN el proyecto en S1
- WHEN se ejecuta `flutter analyze`
- THEN no se reportan warnings ni errores

##### Escenario: Estructura de capas respetada

- GIVEN una nueva clase de repositorio
- WHEN se revisa su ubicacion
- THEN reside en `lib/data/repositories/`
- AND no importa widgets de `lib/presentation/`

### S2 — Catalogos y CRUD core

#### R11 [S2] Listado de productos con busqueda y filtros

El sistema DEBE mostrar el listado de productos consumiendo `GET /api/productos`. Debe soportar busqueda por nombre o codigo y filtros segun el contrato del backend (categoria, stock, etc.). Las listas largas DEBEN usar builders y, si el backend lo soporta, paginacion.

##### Escenario: Listado con datos

- GIVEN productos registrados en el backend
- WHEN el usuario abre la seccion Productos
- THEN se muestra la lista con nombre, codigo, precio y stock

##### Escenario: Busqueda por nombre

- GIVEN productos con nombres distintos
- WHEN el usuario escribe "martillo" en el campo de busqueda
- THEN la lista se filtra para mostrar solo productos coincidentes

##### Escenario: Lista vacia

- GIVEN que no hay productos registrados
- WHEN se abre la seccion
- THEN se muestra un estado vacio con mensaje informativo

#### R12 [S2] CRUD de productos

El sistema DEBE permitir crear (`POST /api/productos`), editar (`PUT /api/productos/{id}`) y eliminar/desactivar (`DELETE /api/productos/{id}`) productos. Cada operacion DEBE estar disponible solo si el usuario posee `PRODUCTOS_CREAR`, `PRODUCTOS_EDITAR` o `PRODUCTOS_ELIMINAR`, respectivamente.

##### Escenario: Crear producto

- GIVEN un usuario con `PRODUCTOS_CREAR`
- WHEN completa el formulario y guarda
- THEN se envia `POST /api/productos`
- AND al recibir 201/200 se recarga el listado

##### Escenario: Editar producto

- GIVEN un usuario con `PRODUCTOS_EDITAR`
- WHEN modifica un campo y guarda
- THEN se envia `PUT /api/productos/{id}`
- AND el listado refleja el cambio

##### Escenario: Eliminar producto

- GIVEN un usuario con `PRODUCTOS_ELIMINAR`
- WHEN confirma la eliminacion
- THEN se envia `DELETE /api/productos/{id}`
- AND el producto desaparece del listado

##### Escenario: Sin permiso de crear

- GIVEN un usuario sin `PRODUCTOS_CREAR`
- WHEN esta en la lista de productos
- THEN el boton "Nuevo producto" no se renderiza

#### R13 [S2] CRUD de categorias

El sistema DEBE listar, crear, editar y eliminar categorias consumiendo los endpoints correspondientes, condicionando las acciones a `CATEGORIAS_CREAR`, `CATEGORIAS_EDITAR` y `CATEGORIAS_ELIMINAR`.

##### Escenario: CRUD completo de categoria

- GIVEN un usuario con permisos de categorias
- WHEN crea, edita y elimina una categoria
- THEN cada operacion llama al endpoint correcto y actualiza la UI

##### Escenario: Acciones ocultas sin permiso

- GIVEN un usuario solo con `CATEGORIAS_VER`
- WHEN esta en la lista
- THEN solo puede ver; no hay botones de editar ni eliminar

#### R14 [S2] CRUD de proveedores

El sistema DEBE listar, crear, editar y eliminar proveedores, protegiendo las acciones con `PROVEEDORES_CREAR`, `PROVEEDORES_EDITAR` y `PROVEEDORES_ELIMINAR`.

##### Escenario: Alta de proveedor

- GIVEN un usuario con `PROVEEDORES_CREAR`
- WHEN completa el formulario de proveedor
- THEN se envia `POST /api/proveedores`
- AND el proveedor aparece en el listado

##### Escenario: Sin permiso de escritura

- GIVEN un usuario sin permisos de escritura de proveedores
- WHEN ingresa a la seccion
- THEN no puede crear, editar ni eliminar

#### R15 [S2] CRUD de clientes

El sistema DEBE listar, crear, editar y eliminar clientes, protegiendo las acciones con `CLIENTES_CREAR`, `CLIENTES_EDITAR` y `CLIENTES_ELIMINAR`.

##### Escenario: Busqueda y edicion de cliente

- GIVEN un usuario con `CLIENTES_VER` y `CLIENTES_EDITAR`
- WHEN busca un cliente y modifica su telefono
- THEN se envia `PUT /api/clientes/{id}`
- AND el listado muestra el telefono actualizado

#### R16 [S2] Visibilidad de acciones en catalogos

En todas las pantallas de catalogo, el sistema DEBE ocultar o deshabilitar los botones de crear, editar y eliminar cuando el usuario no tenga el permiso correspondiente.

##### Escenario: Catalogo en modo solo lectura

- GIVEN un usuario con solo permisos `*_VER` en catalogos
- WHEN navega por productos, categorias, proveedores y clientes
- THEN no ve acciones de escritura en ninguna pantalla

### S3 — Operacion comercial

#### R17 [S3] Listado de ventas

El sistema DEBE mostrar el listado de ventas consumiendo `GET /api/ventas`. Debe permitir filtros por fecha, estado y cliente, y navegar al detalle de una venta.

##### Escenario: Listado de ventas con estados

- GIVEN ventas con estados `COMPLETADA` y `ANULADA`
- WHEN el usuario abre Ventas
- THEN se muestran las ventas con su estado y total

##### Escenario: Filtro por rango de fechas

- GIVEN ventas de distintas fechas
- WHEN se selecciona un rango
- THEN la lista solo muestra ventas dentro del rango

#### R18 [S3] Formulario POS de ventas con detalles y calculos (modificado por app-movil-fixes-offline: R-M5)

El sistema DEBE permitir crear ventas en formato POS. El usuario DEBE poder agregar lineas de detalle seleccionando producto, cantidad y precio unitario. El sistema DEBE calcular subtotal, descuento, iva y total, y enviar `POST /api/ventas` con el arreglo `detalles[]`. El formulario DEBE usar componentes compartidos (`AppFormField`, `AppDropdownField`, `AppFormSection` o equivalentes), aplicar `AppSpacing` de forma consistente, agrupar campos relacionados bajo titulos de seccion, mantenerse scrolleable con los botones en el flujo natural y garantizar labels legibles sin superposicion. Las validaciones existentes, la logica de negocio, los permisos, los modelos y los endpoints DEBEN permanecer sin cambios. Esta modificacion aplica a las ~10 pantallas de formulario: Venta, Compra, Movimiento, Gasto, Producto, Categoria, Proveedor, Cliente, Usuario y Rol.

##### Escenario: Venta con dos productos

- GIVEN productos "A" ($100) y "B" ($50)
- WHEN el usuario agrega 2 unidades de A y 1 de B
- THEN el subtotal es $250, el calculo de iva se aplica segun reglas del backend y el total se muestra correctamente

##### Escenario: Stock insuficiente

- GIVEN un producto con stock 1
- WHEN el usuario intenta vender 3 unidades
- THEN el sistema muestra un error de validacion antes de enviar

##### Escenario: Venta sin detalles

- GIVEN un formulario de venta vacio
- WHEN el usuario intenta guardar
- THEN el sistema muestra un mensaje indicando que debe agregar al menos un detalle

#### R19 [S3] Anulacion de ventas

El sistema DEBE permitir anular una venta mediante `PUT /api/ventas/{id}/anular`, previa confirmacion del usuario y solo si posee `VENTAS_ELIMINAR`. Tras la anulacion, el estado de la venta DEBE reflejarse en el listado.

##### Escenario: Anulacion exitosa

- GIVEN un usuario con `VENTAS_ELIMINAR` y una venta completada
- WHEN confirma la anulacion
- THEN se envia `PUT /api/ventas/{id}/anular`
- AND la venta cambia a estado anulado en la lista

##### Escenario: Sin permiso de anular

- GIVEN un usuario sin `VENTAS_ELIMINAR`
- WHEN esta en el detalle de una venta
- THEN no aparece la opcion de anular

#### R20 [S3] Reporte de ventas por fecha

El sistema DEBE mostrar el reporte de ventas por rango de fecha consumiendo `GET /api/reportes/ventas` (o endpoint equivalente del backend), mostrando totales y cantidad de ventas.

##### Escenario: Reporte con ventas en rango

- GIVEN ventas completadas dentro del rango seleccionado
- WHEN el usuario aplica el filtro
- THEN el sistema muestra el total de ventas y la cantidad

##### Escenario: Reporte sin datos

- GIVEN un rango sin ventas
- WHEN el usuario aplica el filtro
- THEN el sistema muestra totales en cero y un mensaje de estado vacio

#### R21 [S3] Listado y CRUD de compras

El sistema DEBE listar compras y permitir crear una compra con detalles (`POST /api/compras`) y editar una compra existente (`PUT /api/compras/{id}`). Las acciones DEBEN respetar `COMPRAS_CREAR` y `COMPRAS_EDITAR`.

##### Escenario: Crear compra con detalles

- GIVEN un usuario con `COMPRAS_CREAR`
- WHEN selecciona proveedor y agrega productos con cantidades y precios
- THEN se envia `POST /api/compras` con `detalles[]`
- AND la compra aparece en el listado

##### Escenario: Editar compra

- GIVEN un usuario con `COMPRAS_EDITAR`
- WHEN modifica la cantidad de un detalle
- THEN se envia `PUT /api/compras/{id}`
- AND el listado refleja el cambio

#### R22 [S3] Anulacion de compras

El sistema DEBE permitir anular compras mediante `PUT /api/compras/{id}/anular`, con confirmacion y solo para usuarios con `COMPRAS_ELIMINAR`.

##### Escenario: Anulacion de compra

- GIVEN una compra completada y un usuario con `COMPRAS_ELIMINAR`
- WHEN confirma la anulacion
- THEN se envia `PUT /api/compras/{id}/anular`
- AND la compra pasa a estado anulado

#### R23 [S3] Reporte de compras por fecha

El sistema DEBE mostrar el reporte de compras por rango de fecha consumiendo el endpoint correspondiente, con totales y cantidad.

##### Escenario: Reporte de compras filtrado

- GIVEN compras en un rango de fechas
- WHEN el usuario aplica el filtro
- THEN el sistema muestra el total y cantidad de compras del periodo

#### R24 [S3] Movimientos de stock

El sistema DEBE listar movimientos de stock con filtros por producto, tipo y rango de fechas, y permitir crear un movimiento (`POST /api/movimientos-stock`).

##### Escenario: Listado filtrado por tipo

- GIVEN movimientos de entrada y salida
- WHEN el usuario filtra por tipo "ENTRADA"
- THEN solo se muestran movimientos de entrada

##### Escenario: Crear movimiento

- GIVEN un usuario con `MOVIMIENTOS_CREAR`
- WHEN registra un movimiento de ajuste con producto, cantidad y tipo
- THEN se envia `POST /api/movimientos-stock`
- AND el stock del producto se actualiza en el backend

#### R25 [S3] CRUD de gastos

El sistema DEBE listar, crear, editar y eliminar gastos, protegiendo las acciones con `GASTOS_CREAR`, `GASTOS_EDITAR` y `GASTOS_ELIMINAR`.

##### Escenario: Registrar gasto

- GIVEN un usuario con `GASTOS_CREAR`
- WHEN completa descripcion, monto y fecha
- THEN se envia `POST /api/gastos`
- AND el gasto aparece en el listado

##### Escenario: Eliminar gasto

- GIVEN un usuario con `GASTOS_ELIMINAR`
- WHEN confirma la eliminacion de un gasto
- THEN se envia `DELETE /api/gastos/{id}`
- AND el gasto desaparece del listado

#### R26 [S3] Permisos de operacion comercial

Las secciones de ventas, compras, movimientos y gastos DEBEN respetar sus permisos `VER`, `CREAR`, `EDITAR` y `ELIMINAR`. El sistema DEBE ocultar acciones no permitidas.

##### Escenario: Vendedor con permisos limitados

- GIVEN un usuario con `VENTAS_VER` y `VENTAS_CREAR` pero sin `VENTAS_ELIMINAR`
- WHEN esta en ventas
- THEN puede crear pero no anular

### S4 — Administracion, precios, analiticas y logs

#### R27 [S4] Gestion de precios e historial

El sistema DEBE mostrar el listado de precios (`GET /api/precios`) y el detalle de un producto con su historial de precios (`GET /api/precios/{id}/historial`).

##### Escenario: Listado de precios

- GIVEN productos con precio de venta
- WHEN el usuario abre Precios
- THEN se muestra el listado con precio actual

##### Escenario: Historial de precios

- GIVEN un producto con varios cambios de precio
- WHEN el usuario abre el detalle
- THEN se muestra el historial ordenado por fecha

#### R28 [S4] Actualizacion de precio de venta

El sistema DEBE permitir actualizar el precio de venta de un producto mediante `PUT /api/precios/{id}/venta`, enviando `nuevoPrecio` o `margenPorcentaje` segun elija el usuario. La accion DEBE estar protegida por `PRECIOS_EDITAR`.

##### Escenario: Actualizar por nuevo precio

- GIVEN un usuario con `PRECIOS_EDITAR`
- WHEN ingresa un nuevo precio de venta
- THEN se envia `PUT /api/precios/{id}/venta` con `nuevoPrecio`
- AND el listado muestra el precio actualizado

##### Escenario: Actualizar por margen

- GIVEN un usuario con `PRECIOS_EDITAR`
- WHEN ingresa un margen de ganancia del 20%
- THEN se envia `PUT /api/precios/{id}/venta` con `margenPorcentaje=20`
- AND el precio se recalcula en el backend

#### R29 [S4] CRUD de usuarios y cambio de contrasena

El sistema DEBE listar, crear, editar y eliminar usuarios (`/api/usuarios`), gestionar overrides de permisos y permitir cambiar la contrasena. Las acciones DEBEN respetar `USUARIOS_CREAR`, `USUARIOS_EDITAR`, `USUARIOS_ELIMINAR`.

##### Escenario: Crear usuario con rol

- GIVEN un administrador con `USUARIOS_CREAR`
- WHEN completa nombre, email, rol y contrasena
- THEN se envia `POST /api/usuarios`
- AND el usuario aparece en el listado

##### Escenario: Cambio de contrasena

- GIVEN un usuario editando su perfil o un administrador editando otro usuario
- WHEN ingresa una nueva contrasena valida
- THEN se envia la actualizacion correspondiente
- AND se notifica exito

##### Escenario: Override de permisos

- GIVEN un administrador con `USUARIOS_EDITAR`
- WHEN otorga o quita un permiso especifico a un usuario
- THEN el backend persiste el override
- AND los permisos efectivos se actualizan

#### R30 [S4] CRUD de roles y matriz de permisos

El sistema DEBE listar, crear, editar y eliminar roles (`/api/roles`). En el formulario de rol, el sistema DEBE mostrar una matriz de modulos y permisos obtenida de `/api/modulos` y `/api/permisos`, permitiendo marcar/desmarcar cada permiso.

##### Escenario: Crear rol con permisos

- GIVEN un administrador con `ROLES_CREAR`
- WHEN define nombre del rol y marca permisos de productos y ventas
- THEN se envia `POST /api/roles` con el arreglo `permisos[]`
- AND el rol aparece en el listado

##### Escenario: Editar matriz de permisos

- GIVEN un administrador con `ROLES_EDITAR`
- WHEN desmarca `PRODUCTOS_ELIMINAR` y guarda
- THEN se envia `PUT /api/roles/{id}` con la matriz actualizada
- AND los usuarios con ese rol pierden el permiso al refrescar

#### R31 [S4] Catalogo de modulos y permisos

El sistema DEBE poder consultar los modulos y permisos disponibles para construir la matriz de roles y validar permisos locales.

##### Escenario: Carga de catalogo de permisos

- GIVEN un administrador en la pantalla de roles
- WHEN se abre el formulario
- THEN se llaman `GET /api/modulos` y `GET /api/permisos`
- AND se renderiza la matriz completa

#### R32 [S4] Dashboard con KPIs (modificado por ui-ux)

El sistema DEBE mostrar el dashboard consumiendo `GET /api/reportes/dashboard` (o endpoint equivalente), presentando exactamente los mismos seis KPIs que el dashboard web (`totalProductos`, `productosStockBajo`, `ventasHoy`, `ventasMes`, `totalClientes`, `totalProveedores`) con las mismas asignaciones de icono, color y ruta; ademas DEBE incluir la grafica de ventas por periodo (semana/mes/ano) usando los datos existentes `ventasPorDia` o el endpoint `reportes/ventas`.

##### Escenario: Dashboard con datos

- GIVEN datos de ventas e inventario en el backend
- WHEN el usuario abre el dashboard
- THEN se muestran KPIs actualizados y una grafica resumen

##### Escenario: Dashboard con error de red

- GIVEN falla de conexion
- WHEN se carga el dashboard
- THEN se muestra un mensaje de error y un boton de reintentar

##### Escenario: Los KPIs del dashboard coinciden con la web

- GIVEN el backend devuelve datos del dashboard
- WHEN el dashboard movil se renderiza
- THEN los seis KPIs usan las mismas etiquetas, iconos, colores y rutas que `frontend/src/app/dashboard/dashboard/dashboard.component.ts`

##### Escenario: La grafica del dashboard coincide con los periodos web

- GIVEN el usuario cambia el selector de periodo
- WHEN la grafica se recarga
- THEN usa los mismos rangos de fecha y agrupacion (dia para semana/mes, mes para anio) que el dashboard web

#### R33 [S4] Reportes de ventas, inventario y movimientos

El sistema DEBE ofrecer pantallas de reportes para ventas, inventario y movimientos de stock, consumiendo los endpoints correspondientes y permitiendo filtros por fecha.

##### Escenario: Reporte de inventario

- GIVEN productos con stock actual y minimo
- WHEN el usuario abre el reporte de inventario
- THEN se muestra la lista con indicadores de stock bajo

##### Escenario: Reporte de movimientos

- GIVEN movimientos de stock en un rango
- WHEN el usuario selecciona fechas
- THEN el sistema consulta el endpoint y muestra el resumen

#### R34 [S4] Consulta paginada y filtrada de logs

El sistema DEBE mostrar logs de auditoria de forma paginada, consumiendo `GET /api/logs` con filtros de fecha, usuario, entidad y accion. La pantalla DEBE estar disponible solo para usuarios con `LOGS_VER`.

##### Escenario: Listado paginado de logs

- GIVEN un usuario con `LOGS_VER`
- WHEN abre Logs
- THEN se muestra una tabla paginada con entidad, accion, usuario, fecha y detalle

##### Escenario: Filtro por entidad y accion

- GIVEN registros de auditoria de distintas entidades
- WHEN se filtra por entidad `VENTA` y accion `CREAR`
- THEN solo se muestran esos registros

#### R35 [S4] Borrado de logs por rango

El sistema DEBE permitir borrar logs por rango de fechas mediante `DELETE /api/logs?desde=&hasta=`, previa confirmacion y solo para usuarios con `LOGS_ELIMINAR`. Tras el borrado, el listado DEBE recargarse.

##### Escenario: Borrado por rango exitoso

- GIVEN un usuario con `LOGS_ELIMINAR` y un rango de fechas con logs
- WHEN confirma el borrado
- THEN se envia `DELETE /api/logs`
- AND el sistema muestra la cantidad eliminada y recarga la lista

##### Escenario: Sin permiso de borrar logs

- GIVEN un usuario sin `LOGS_ELIMINAR`
- WHEN esta en Logs
- THEN no aparece el boton "Borrar por rango"

#### R36 [S4] Permisos de administracion y analiticas

Las secciones de precios, usuarios, roles, reportes y logs DEBEN respetar sus permisos correspondientes. El sistema DEBE ocultar rutas y acciones no autorizadas.

##### Escenario: Administrador completo

- GIVEN un usuario con todos los permisos de administracion
- WHEN navega la app
- THEN ve todas las secciones administrativas

##### Escenario: Usuario sin reportes

- GIVEN un usuario sin `REPORTES_VER`
- WHEN esta en el shell
- THEN no aparece el item Reportes

### S5 — Chat y polish de entrega

#### R37 [S5] Pantalla de chat (modificado por app-movil-fixes-offline: R-M4)

El sistema DEBE incluir una pantalla de chat que envie preguntas a `POST /api/chat` con `question` y, opcionalmente, `conversationId`. El layout DEBE mostrar el indicador de carga como una burbuja de asistente colocada debajo del ultimo mensaje del usuario. Las burbujas de mensaje DEBEN usar un ancho relativo (aproximadamente el 85% del ancho disponible) en lugar de un ancho fijo de 700 dp. El composer DEBE respetar `MediaQuery.viewInsets`, tener una altura minima/maxima compacta, soportar scroll interno para texto largo, integrar el boton de enviar y mostrar un contador discreto `0/1000`. La lista de mensajes DEBE desplazarse suavemente al ultimo mensaje al enviar/recibir. El layout NO DEBE usar widgets `Positioned` absolutos, fuentes reducidas ni `FittedBox` para resolver el layout. La logica del chat, prompts, RAG y endpoints DEBEN permanecer sin cambios.

##### Escenario: Indicador de carga integrado al flujo

- GIVEN el usuario acaba de enviar una pregunta
- WHEN el asistente esta generando la respuesta
- THEN aparece una burbuja de carga directamente debajo del ultimo mensaje del usuario
- AND muestra un indicador animado

##### Escenario: Burbujas con ancho relativo

- GIVEN la app corre en un telefono angosto
- WHEN se renderiza una burbuja de chat
- THEN su ancho es aproximadamente el 85% del ancho disponible de la lista de mensajes
- AND no esta limitada a 700 dp fijos

##### Escenario: Scroll automatico suave

- GIVEN la lista de mensajes esta scrolleada hacia arriba
- WHEN se envia un nuevo mensaje del usuario o llega una respuesta del asistente
- THEN la lista se anima suavemente hasta el final

##### Escenario: Composer con teclado abierto

- GIVEN el teclado de software es visible
- WHEN el composer se renderiza
- THEN permanece por encima del teclado usando `viewInsets`
- AND ningun contenido queda oculto detras del teclado

##### Escenario: Composer compacto con contador discreto

- GIVEN el usuario escribe una pregunta larga
- WHEN el texto excede la altura del composer
- THEN el campo de texto hace scroll interno hasta la altura maxima
- AND un contador pequeno `0/1000` permanece visible

#### R38 [S5] Renderizado seguro de respuesta Markdown

El sistema DEBE renderizar la respuesta Markdown de forma segura: escapar HTML, transformar listas, negritas, cursivas y parrafos a widgets Flutter, y NUNCA ejecutar JavaScript ni inyectar HTML sin sanitizar.

##### Escenario: Respuesta con lista

- GIVEN una respuesta del backend que contiene una lista Markdown
- WHEN se renderiza
- THEN se muestra como lista de items visualmente ordenada

##### Escenario: Respuesta con HTML embebido

- GIVEN una respuesta que incluye `<script>alert(1)</script>`
- WHEN se renderiza
- THEN el texto se escapa y no se ejecuta codigo

##### Escenario: Markdown malformado

- GIVEN una respuesta con Markdown incompleto
- WHEN se renderiza
- THEN el sistema muestra el texto lo mas cercano posible sin crashear

#### R39 [S5] Visualizacion de fuentes

Si la respuesta incluye `sources[]`, el sistema DEBE mostrarlas en un acordeon que el usuario pueda expandir/contraer. Si no hay fuentes, el acordeon NO DEBE mostrarse.

##### Escenario: Respuesta con fuentes

- GIVEN una respuesta con dos fuentes
- WHEN se renderiza el mensaje
- THEN aparece un acordeon "Fuentes" que muestra las dos entradas

##### Escenario: Respuesta sin fuentes

- GIVEN una respuesta con `sources` vacio o nulo
- WHEN se renderiza el mensaje
- THEN no aparece la seccion de fuentes

#### R40 [S5] Manejo de conversationId y errores del chat (modificado por app-movil-fixes-offline: R-M4)

El sistema DEBE conservar el `conversationId` devuelto por el backend en la sesion de UI para reutilizarlo en siguientes mensajes. Ante errores de red o respuestas vacias, el sistema DEBE mostrar un mensaje de fallback sin perder el historial.

##### Escenario: Error de red en el chat

- GIVEN una pregunta enviada sin conexion
- WHEN el request falla
- THEN se muestra un mensaje de error amigable
- AND el historial de mensajes se conserva

##### Escenario: Respuesta vacia

- GIVEN una respuesta con `answer` vacio
- WHEN se renderiza
- THEN se muestra un mensaje de fallback indicando que no hay respuesta

#### R41 [S5] Reconstruccion del indice de chat

El sistema DEBE ofrecer la accion de reconstruir el indice del chat solo para usuarios con `CHAT_INDEX_REBUILD`, llamando al endpoint correspondiente. La accion DEBE estar oculta para usuarios sin ese permiso.

##### Escenario: Accion visible para admin

- GIVEN un usuario con `CHAT_INDEX_REBUILD`
- WHEN esta en la pantalla de chat
- THEN aparece la opcion de reconstruir indice

##### Escenario: Accion oculta para vendedor

- GIVEN un usuario sin `CHAT_INDEX_REBUILD`
- WHEN esta en la pantalla de chat
- THEN no aparece la opcion de reconstruir indice

#### R42 [S5] Accesibilidad, rendimiento y validacion Android

El sistema DEBE aplicar buenas practicas de accesibilidad (etiquetas, contraste, tamanos de touch), optimizar con `const` y `ListView.builder`, y generar un APK de release estable para Android que pase `flutter test` y `flutter analyze`.

##### Escenario: APK release en emulator

- GIVEN el proyecto en S5
- WHEN se ejecuta `flutter build apk --release` con `--dart-define` de desarrollo
- THEN el build completa sin errores

##### Escenario: Pruebas de accesibilidad basicas

- GIVEN widgets con semantic labels
- WHEN se ejecutan widget tests
- THEN los elementos interactivos tienen descripciones accesibles

#### R43 [S5] Icono, splash y tema (modificado por ui-ux)

El sistema DEBE configurar el icono de la app y la pantalla de splash para Android usando el motivo `hardware` de FerrePlus (no un icono Material generico ni el logo de Flutter), y aplicar el tema de Material 3 de forma consistente en toda la app. El tema DEBE incluir ColorSchemes claro y oscuro con los seeds aprobados (`#1565C0` claro, `#64B5F6` oscuro) y un selector de tema visible en `Mas > SISTEMA` (R49). El icono launcher generico de Flutter del estado anterior queda REMOVIDO y reemplazado por el motivo de marca.

##### Escenario: Icono y splash en Android

- GIVEN la app instalada en un dispositivo Android
- WHEN se lanza
- THEN se muestra el splash con el icono de Ferreplus
- AND el tema Material 3 se aplica en las pantallas principales

##### Escenario: El icono es de marca FerrePlus

- GIVEN los assets del icono de la app
- WHEN se inspeccionan
- THEN el asset fuente usa el motivo martillo/herramienta `hardware`

##### Escenario: El tema soporta selector visible

- GIVEN el sistema de tema
- WHEN el usuario abre `Mas > SISTEMA`
- THEN hay un selector de tema con Claro/Oscuro/Sistema disponible

### S6 — UI/UX: Design System, Dashboard, Navegacion y Accesibilidad

Este slice incorpora el cambio `app-movil-flutter-ui-ux` (archivado 2026-08-18): evoluciona la app de prototipo funcional a una experiencia movil profesional, accesible y visualmente consistente. Preserva la arquitectura existente (Clean Architecture, Riverpod, GoRouter `StatefulShellRoute`, fechas `DateTime` con converters ISO) y no modifica contratos del backend ni el frontend web.

#### R48 [S6] Design tokens de tres capas

El sistema DEBE exponer un Design System centralizado en `flutter/lib/presentation/theme/` con tres capas de tokens: primitiva, semantica y de componente. Los widgets DEBEN consumir tokens semanticos o de componente; NO DEBEN usar colores, spacing, tamanos tipograficos, radios, elevaciones ni tamanos de icono hardcodeados.

##### Escenario: Los tokens primitivos definen valores raw

- GIVEN la app necesita un color, spacing, radio, elevacion, tamano tipografico o tamano de icono
- WHEN un desarrollador inspecciona los archivos de tema
- THEN los tokens primitivos (ej. `AppColors.blue700`, `AppSpacing.space16`, `AppRadii.radiusM`) existen como fuente unica de verdad de los valores raw

##### Escenario: Los tokens semanticos se adaptan a claro/oscuro

- GIVEN la app corre en modo claro u oscuro
- WHEN un widget solicita un color semantico (ej. `AppColors.primary`, `AppColors.surface`, `AppColors.error`)
- THEN el valor se resuelve al primitivo correcto para el `ThemeMode` activo

##### Escenario: Los tokens de componente centralizan estilos reutilizables

- GIVEN la app renderiza Cards, AppBars, Botones, Inputs, NavigationBars, Dialogs, BottomSheets o SnackBars
- WHEN esos componentes se estilizan
- THEN usan tokens de nivel componente (ej. `AppComponentStyles.cardPadding`, `AppComponentStyles.buttonHeight`, `AppComponentStyles.appBarElevation`) en lugar de valores inline

##### Escenario: Sin estilos hardcodeados en widgets nuevos

- GIVEN un widget nuevo agregado durante este cambio
- WHEN `flutter analyze` corre y se realiza una auditoria de tokens
- THEN no aparecen colores hex raw, magic numbers de spacing, tamanos raw de `TextStyle` ni elevaciones hardcodeadas fuera de los archivos de tokens

---

#### R49 [S6] Selector de tema visible

El sistema DEBE ofrecer un selector de tema visible en `Mas > SISTEMA` con tres opciones: Claro, Oscuro y Seguir sistema. La seleccion por defecto DEBE seguir la preferencia del sistema. El modo seleccionado DEBE persistir entre reinicios usando un almacen local de preferencias (sin dependencia del backend).

##### Escenario: El default sigue al sistema

- GIVEN el dispositivo en modo oscuro y el usuario sin preferencia propia
- WHEN la app se lanza
- THEN la app renderiza en modo oscuro y el selector muestra "Seguir sistema"

##### Escenario: El usuario selecciona modo claro

- GIVEN el usuario abre `Mas > SISTEMA`
- WHEN selecciona "Claro"
- THEN la app cambia a modo claro inmediatamente y persiste la eleccion

##### Escenario: El usuario selecciona modo oscuro

- GIVEN el usuario abre `Mas > SISTEMA`
- WHEN selecciona "Oscuro"
- THEN la app cambia a modo oscuro inmediatamente y persiste la eleccion

##### Escenario: Retorno al default del sistema

- GIVEN el usuario selecciono previamente "Claro"
- WHEN selecciona "Seguir sistema"
- THEN la app vuelve al tema del dispositivo y limpia el override manual

---

#### R50 [S6] Icono de app y splash de FerrePlus

El sistema DEBE reemplazar el icono launcher y el splash por defecto de Flutter con el motivo `hardware` de FerrePlus, consistente con el sidebar/login web. El icono DEBE generarse con un metodo reproducible (`flutter_launcher_icons` a partir de un PNG fuente derivado de `Icons.hardware`, o mipmaps manuales generados desde la misma fuente si la herramienta falla). El splash DEBE mostrar el mismo motivo al iniciar.

##### Escenario: El icono launcher muestra el motivo hardware de FerrePlus

- GIVEN la app instalada en Android
- WHEN el usuario ve la pantalla de inicio o el launcher
- THEN el icono muestra el motivo martillo/herramienta, no el logo de Flutter

##### Escenario: El splash muestra el motivo hardware de FerrePlus

- GIVEN el usuario lanza la app
- WHEN el splash es visible
- THEN el splash muestra el mismo motivo hardware de FerrePlus

##### Escenario: Generacion de icono reproducible como fallback

- GIVEN `flutter_launcher_icons` falla en el entorno local
- WHEN un desarrollador compila la app
- THEN los mipmaps se generan manualmente desde la misma fuente PNG/vectorial `hardware` para que el icono instalado siga siendo consistente

---

#### R51 [S6] Seis tarjetas KPI del dashboard web

El sistema DEBE renderizar seis tarjetas KPI en el dashboard usando la misma data y semantica que el dashboard web:

1. **Total Productos** — `inventory_2`, `#1565C0`, ruta `/productos`
2. **Stock Bajo** — `warning_amber`, `#c62828`, ruta `/productos`
3. **Ventas Hoy** — `today`, `#2e7d32`, ruta `/ventas`
4. **Ventas del Mes** — `date_range`, `#FF8F00`, ruta `/ventas` (#FF8F00 falla contraste 4.5:1 en claro; implementado con kpiAmberAccessible #B45309 por R63)
5. **Total Clientes** — `people`, `#6a1b9a`, ruta `/clientes`
6. **Proveedores** — `local_shipping`, `#00838f`, ruta `/proveedores`

Cada tarjeta KPI DEBE mostrar un icono Material, una etiqueta y un valor. El color semantico DEBE aplicarse solo al icono o a un badge pequeno; el fondo de la tarjeta DEBE permanecer neutral. El texto del valor DEBE tener mayor peso visual que la etiqueta. Tocar una tarjeta DEBE navegar a su ruta asociada.

##### Escenario: El dashboard renderiza los seis KPIs

- GIVEN el backend devuelve un `ReporteDashboard` con todos los campos poblados
- WHEN el usuario abre el dashboard
- THEN aparecen las seis tarjetas KPI con el icono, la etiqueta y el valor correctos

##### Escenario: Los colores KPI son semanticos y contenidos

- GIVEN el dashboard renderizado
- WHEN se inspecciona una tarjeta KPI
- THEN solo el icono (o un badge pequeno) usa el color semantico; la superficie de la tarjeta usa el color de superficie del tema

##### Escenario: Tocar un KPI navega a su ruta

- GIVEN el usuario en el dashboard
- WHEN toca "Total Clientes"
- THEN la app navega a `/clientes`

##### Escenario: El valor KPI es mas prominente que la etiqueta

- GIVEN el dashboard renderizado
- WHEN se inspecciona una tarjeta KPI
- THEN el valor numerico usa un estilo tipografico mayor/pesado que la etiqueta

---

#### R52 [S6] Grafica de ventas por periodo (modificado por app-movil-fixes-offline: R-M3)

El sistema DEBE renderizar una grafica simple de barras de ventas por periodo en el dashboard. El selector DEBE ofrecer tres periodos: "Esta Semana", "Este Mes" y "Este Año". El provider DEBE calcular el rango de fechas completo del periodo seleccionado y garantizar datos para cada intervalo de ese rango. DEBE usar `ventasPorDia` solo cuando cubre todo el rango; en caso contrario DEBE hacer fallback a `reportSalesProvider(range)`. La semana y el mes DEBEN agruparse por dia; el año DEBE agruparse por mes. La grafica DEBE renderizar las barras usando solo widgets built-in de Flutter (`CustomPaint`, `Row` de `Container`, o similar). NO SE PUEDE agregar ninguna dependencia nueva de graficas, ni modificar el backend ni el frontend Angular.

##### Escenario: Semana con datos parciales usa el fallback

- GIVEN el `ventasPorDia` del dashboard solo contiene datos de hoy
- WHEN el usuario selecciona "Esta Semana"
- THEN la app consulta `reportes/ventas` para el rango completo de la semana
- AND la grafica muestra una barra por dia desde el lunes hasta hoy

##### Escenario: Mes agrupado por dia

- GIVEN `ventasPorDia` esta vacio para el mes actual
- WHEN el usuario selecciona "Este Mes"
- THEN la app usa el endpoint de reportes
- AND la grafica agrupa las ventas por dia del mes

##### Escenario: Año agrupado por mes

- GIVEN el usuario selecciona "Este Año"
- WHEN la grafica carga
- THEN los datos se agrupan por mes
- AND el rango cubre desde el 1 de enero hasta hoy

##### Escenario: Nunca muestra un solo dia

- GIVEN cualquier selector de periodo activo
- WHEN la grafica se renderiza
- THEN todos los intervalos del rango calculado estan representados, incluso si su valor es cero

##### Escenario: Web y backend no se modifican

- GIVEN el cambio se aplica solo a `flutter/`
- WHEN se inspecciona el dashboard web Angular
- THEN su comportamiento y los endpoints del backend permanecen sin cambios

---

#### R53 [S6] Acciones rapidas condicionadas por permiso

El sistema DEBE renderizar una seccion "Acciones rápidas" en el dashboard con hasta cuatro acciones: "+ Nueva venta" (`/ventas/nuevo`), "+ Nuevo producto" (`/productos/nuevo`), "+ Registrar gasto" (`/gastos/nuevo`) y "+ Registrar compra" (`/compras/nuevo`). Cada accion DEBE ser visible solo si el usuario autenticado tiene el permiso `CREAR` correspondiente. Tocar una accion DEBE navegar a su ruta de creacion.

##### Escenario: Todos los permisos de creacion presentes

- GIVEN un usuario con `VENTAS_CREAR`, `PRODUCTOS_CREAR`, `GASTOS_CREAR` y `COMPRAS_CREAR`
- WHEN el dashboard carga
- THEN las cuatro acciones rapidas son visibles

##### Escenario: Faltan algunos permisos de creacion

- GIVEN un usuario solo con `VENTAS_CREAR` y `PRODUCTOS_CREAR`
- WHEN el dashboard carga
- THEN solo aparecen "+ Nueva venta" y "+ Nuevo producto"

##### Escenario: Tocar una accion rapida navega

- GIVEN el usuario ve "+ Nueva venta"
- WHEN la toca
- THEN la app navega a `/ventas/nuevo`

---

#### R54 [S6] Estados loading, empty y error del dashboard

El sistema DEBE manejar los estados `loading`, `empty` y `error` en el dashboard sin inventar datos. Mientras carga, DEBE mostrar un skeleton o shimmer donde sea valioso. Ante un error, DEBE mostrar un mensaje de error y un CTA de reintento. Ante un `ReporteDashboard` vacio (todos los valores en cero/vacio), DEBE mostrar un estado vacio con un mensaje y, si el permiso lo permite, un CTA para crear datos iniciales.

##### Escenario: Dashboard cargando

- GIVEN la peticion del dashboard en vuelo
- WHEN el dashboard se renderiza
- THEN se muestra un placeholder skeleton/shimmer para KPIs y grafica

##### Escenario: Error del dashboard con reintento

- GIVEN la peticion del dashboard falla
- WHEN el dashboard se renderiza
- THEN aparece un mensaje de error junto con un boton "Intentar nuevamente"

##### Escenario: Dashboard vacio

- GIVEN el backend devuelve un `ReporteDashboard` con todos los contadores en cero y sin datos de grafica
- WHEN el dashboard se renderiza
- THEN aparece un estado vacio (ej. "Bienvenido a FerrePlus — los datos de tu negocio aparecerán aquí")
- AND no se muestran datos falsos

---

#### R55 [S6] NavigationBar de maximo cinco destinos (modificado por app-movil-fixes-offline: R-M2)

El sistema DEBE reducir la `NavigationBar` del shell a un maximo de cinco destinos: Dashboard, Productos, Ventas, Reportes y Mas. La NavigationBar de 15 destinos del estado anterior queda REMOVIDA; la barra NO DEBE contener mas de cinco destinos y todas las rutas previamente alcanzables siguen accesibles via `Mas` o deep links. La pestana seleccionada DEBE reflejar la rama actual del `StatefulShellRoute` usando el mapeo canonico `branchIndex -> ruta inicial` de R-M2, y el estado por rama DEBE preservarse.

##### Escenario: Cinco pestanas visibles

- GIVEN un usuario autenticado con todos los permisos relevantes
- WHEN el shell se renderiza
- THEN se muestran exactamente cinco NavigationDestinations

##### Escenario: Estado de pestana preservado

- GIVEN el usuario en la pestana Productos con una lista scrolleada
- WHEN cambia a Ventas y vuelve a Productos
- THEN la lista de Productos mantiene la misma posicion de scroll y estado

##### Escenario: La rama 0 es Dashboard

- GIVEN el usuario toca la pestana Dashboard
- THEN el indice de rama activo es `0` y la ruta es `/` o `/dashboard`

---

#### R56 [S6] Pagina Mas categorizada con todas las rutas secundarias

El sistema DEBE agregar una pagina `Mas` (`/mas`) accesible desde el quinto tab. La pagina DEBE agrupar los destinos restantes en secciones categorizadas: OPERACIONES (Compras, Movimientos, Gastos), CATALOGOS (Categorias, Proveedores, Clientes, Precios), ADMINISTRACION (Usuarios, Roles) y SISTEMA (Logs, Chat). Cada item DEBE ser visible solo si el usuario tiene el permiso `VER` correspondiente. Tocar un item DEBE navegar a su ruta canonica. Los deep links y guards de permisos de todas esas rutas DEBEN seguir funcionando sin cambios.

##### Escenario: La pagina Mas lista items categorizados

- GIVEN un usuario con todos los permisos
- WHEN abre `Mas`
- THEN la pagina muestra las cuatro categorias con sus items correspondientes

##### Escenario: Items de Mas filtrados por permiso

- GIVEN un usuario sin `USUARIOS_VER` ni `ROLES_VER`
- WHEN abre `Mas`
- THEN la categoria ADMINISTRACION se oculta o no muestra items

##### Escenario: Un item de Mas navega a su ruta canonica

- GIVEN el usuario toca "Compras" en `Mas`
- WHEN el toque se completa
- THEN la app navega a `/compras` usando las ramas/rutas existentes

##### Escenario: Deep link a ruta secundaria sigue funcionando

- GIVEN un usuario con `COMPRAS_VER`
- WHEN la app recibe un deep link a `/compras`
- THEN la ruta se renderiza y el guard de permiso permite el acceso

---

#### R57 [S6] Chat accesible via FAB flotante (modificado por app-movil-fixes-offline: R-M1)

El sistema DEBE conservar el `ChatFloatingActionButton` existente como via principal de acceso al chat y DEBE comportarse como un toggle. Cuando la ruta actual no es `/chat`, el FAB DEBE navegar a `/chat` y mostrar un icono de cerrar con tooltip/etiqueta semantica "Cerrar chat". Cuando la ruta actual es `/chat`, el FAB DEBE cerrar el chat y volver a la rama anterior cuando este disponible, o al dashboard como fallback seguro. El comportamiento arrastrable de `DraggableChatFab` DEBE preservarse. El FAB DEBE ser visible para cualquier usuario autenticado y NO DEBE mostrarse en la pantalla de login.

##### Escenario: Abrir chat desde el dashboard

- GIVEN el usuario esta en `/dashboard` y ve el FAB de chat
- WHEN toca el FAB
- THEN la app navega a `/chat`
- AND el icono del FAB cambia a `close` y el tooltip se vuelve "Cerrar chat"

##### Escenario: Cerrar chat vuelve a la rama anterior

- GIVEN el usuario abrio `/chat` desde la rama Ventas
- WHEN toca el FAB nuevamente
- THEN la app vuelve a `/ventas`
- AND el icono del FAB vuelve a `chat_bubble_outline`

##### Escenario: Cerrar chat sin rama anterior cae al dashboard

- GIVEN el usuario abrio `/chat` directamente via deep link sin rama previa
- WHEN toca el FAB para cerrar
- THEN la app navega a `/dashboard`

##### Escenario: Semantica y tooltip dinamicos

- GIVEN la ruta actual es `/chat`
- WHEN un lector de pantalla enfoca el FAB
- THEN anuncia "Cerrar chat"
- AND el tooltip coincide con la etiqueta

---

#### R58 [S6] AppBar contextual

El sistema DEBE ofrecer una `AppBar` contextual en las pantallas del shell con altura, spacing y un titulo acorde a la pantalla actual. La AppBar PUEDE incluir un area de acciones minima (placeholder de notificaciones o avatar segun decision del usuario), pero NO DEBE introducir UI bloqueante ni reducir el area de contenido accesible por debajo de las guias de Material.

##### Escenario: El titulo de la AppBar coincide con la pantalla

- GIVEN el usuario en la lista de Productos
- WHEN la AppBar se renderiza
- THEN el titulo dice "Productos" (o equivalente) usando el token tipografico para titulos de AppBar

##### Escenario: La AppBar respeta safe area y spacing

- GIVEN la app corre en un dispositivo con notch o barra de estado
- WHEN la pantalla se renderiza
- THEN la AppBar evita la safe area y usa el padding del token de componente

---

#### R59 [S6] Widget de loading compartido

El sistema DEBE ofrecer un widget de loading compartido (`AppLoadingIndicator` o equivalente) usado en todas las pantallas basadas en API. DEBE usar shimmer/skeleton cuando sea significativo; en caso contrario, DEBE mostrar un `CircularProgressIndicator` consistente con semantica accesible.

##### Escenario: Loading compartido en el dashboard

- GIVEN el dashboard cargando
- WHEN el widget de loading se renderiza
- THEN usa el widget de loading compartido, no un indicador ad-hoc inline

##### Escenario: Loading compartido en pantallas de lista

- GIVEN cualquier pantalla de lista obtiene datos
- WHEN el widget de loading se renderiza
- THEN usa el mismo widget de loading compartido que el dashboard

---

#### R60 [S6] Widget de empty state compartido

El sistema DEBE ofrecer un widget de empty state compartido (`AppEmptyState` o equivalente) usado en todas las pantallas que pueden devolver sin datos. El widget DEBE mostrar un icono, un titulo, un subtitulo y un CTA opcional.

##### Escenario: Lista de productos vacia

- GIVEN la lista de productos sin items
- WHEN la lista se renderiza
- THEN aparece el widget de empty state compartido con icono, titulo y subtitulo

##### Escenario: Grafica vacia

- GIVEN la grafica del dashboard sin datos
- WHEN el area de la grafica se renderiza
- THEN se usa el widget de empty state compartido o un empty state especifico de grafica consistente con el

---

#### R61 [S6] Widget de error/reintento compartido

El sistema DEBE ofrecer un widget de error compartido (`AppErrorView` o equivalente) usado en todas las pantallas basadas en API. El widget DEBE mostrar un icono de error, un mensaje y un boton "Intentar nuevamente" que dispare la accion de reintento provista por el llamador.

##### Escenario: Error en el dashboard con reintento

- GIVEN la peticion del dashboard falla
- WHEN el widget de error se renderiza
- THEN muestra el widget de error compartido con un boton de reintento que invalida el provider del dashboard

##### Escenario: Error en pantalla de lista con reintento

- GIVEN una peticion de lista falla
- WHEN el widget de error se renderiza
- THEN usa el mismo widget de error compartido con un boton de reintento

---

#### R62 [S6] Layout responsive sin overflow

El sistema DEBE usar `LayoutBuilder` y/o `MediaQuery` para adaptar los layouts. El grid de KPIs del dashboard DEBE renderizar dos columnas cuando el ancho lo permite y una columna en telefonos angostos. Los layouts landscape y tablet DEBEN ser utilizables sin scroll horizontal, overflow de `RenderFlex` ni texto recortado.

##### Escenario: Grid de KPIs de dos columnas en telefono ancho

- GIVEN un telefono en portrait con ancho >= 360 dp
- WHEN el dashboard se renderiza
- THEN el grid de KPIs muestra dos columnas

##### Escenario: Grid de KPIs de una columna en telefono angosto

- GIVEN un telefono con ancho < 360 dp
- WHEN el dashboard se renderiza
- THEN el grid de KPIs muestra una columna

##### Escenario: Sin overflow en landscape

- GIVEN el telefono rota a landscape
- WHEN el dashboard se renderiza
- THEN no ocurren errores de overflow `RenderFlex` y todo el contenido permanece dentro de los limites

##### Escenario: Sin scroll horizontal

- GIVEN el usuario en cualquier pantalla del shell
- WHEN interactua con la pantalla
- THEN el contenido no hace scroll horizontal salvo diseno explicito (ej. una tabla de datos)

---

#### R63 [S6] Cumplimiento de accesibilidad

El sistema DEBE cumplir los siguientes requisitos de accesibilidad: ratio de contraste de al menos 4.5:1 para texto e iconos; touch targets de al menos 48 dp para todos los controles interactivos; labels semanticos (`Semantics` o `tooltip`) para todos los botones solo-icono; soporte de escala de texto del sistema sin texto recortado; y que ninguna informacion se transmita solo por color.

##### Escenario: El contraste cumple el minimo

- GIVEN la app corre en modo claro u oscuro
- WHEN se mide el texto/iconos en primer plano contra su fondo
- THEN el ratio de contraste es de al menos 4.5:1

##### Escenario: Los touch targets cumplen el minimo

- GIVEN un control interactivo (boton, icon button, list tile, chip)
- WHEN se mide su area de toque
- THEN es de al menos 48 dp x 48 dp

##### Escenario: Los botones de icono tienen labels

- GIVEN un boton solo-icono (ej. accion de AppBar, FAB)
- WHEN un lector de pantalla lo enfoca
- THEN anuncia una descripcion significativa

##### Escenario: Soporte de escala de texto

- GIVEN la escala de texto del dispositivo en el ajuste accesible maximo
- WHEN el dashboard se renderiza
- THEN el texto se envuelve o scrollea en lugar de desbordar o recortarse

##### Escenario: El color no es el unico indicador

- GIVEN un indicador de estado que usa color
- WHEN el indicador se ve en escala de grises
- THEN una segunda pista visual (icono, texto, patron) sigue comunicando el significado

---

#### R64 [S6] Extraccion de componentes reutilizables

El sistema DEBE extraer widgets reutilizables del dashboard y de los estados compartidos: `MetricCard`, `SalesChart`, `QuickActions`, `DashboardEmpty`, `AppLoadingIndicator`, `AppEmptyState` y `AppErrorView`. Ningun archivo de widget DEBE superar las 300 lineas; los widgets DEBEN componerse de piezas mas pequenas.

##### Escenario: MetricCard reutilizado

- GIVEN cualquier KPI que necesita mostrarse
- WHEN el dashboard se renderiza
- THEN usa el widget compartido `MetricCard`

##### Escenario: SalesChart reutilizado

- GIVEN el dashboard renderiza la grafica de ventas
- WHEN el area de la grafica se construye
- THEN usa el widget compartido `SalesChart`

##### Escenario: Sin widgets gigantes

- GIVEN un widget nuevo agregado
- WHEN se revisa su archivo
- THEN tiene menos de 300 lineas y se compone de widgets mas pequenos

---

#### R65 [S6] Verificacion por fase y tests (modificado por app-movil-fixes-offline: R-M7)

El sistema DEBE pasar `flutter analyze` con cero issues por fase. Los tests existentes DEBEN permanecer verdes (52 al cierre de S6, 77 como baseline previo a R-M7, 107 al cierre del cambio app-movil-fixes-offline). Los nuevos widget tests DEBEN cubrir el dashboard (KPIs, grafica, estados empty/error/loading, acciones rapidas por permiso), la navegacion (5 tabs, items de Mas por permiso, deep links) y el selector de tema/presencia del icono. Adicionalmente, los tests DEBEN cubrir la cola offline, retry/backoff, transiciones online/offline, manejo de expiracion JWT, toggle del FAB, navegacion del shell, agrupacion de la grafica del dashboard, layout del chat/composer y los componentes compartidos de formulario. `flutter analyze` DEBE permanecer limpio.

##### Escenario: flutter analyze limpio

- GIVEN una fase completada
- WHEN `flutter analyze` corre
- THEN reporta cero errores y cero warnings

##### Escenario: Los tests existentes permanecen verdes

- GIVEN los 52 tests existentes
- WHEN `flutter test` corre
- THEN los 52 tests pasan

##### Escenario: Nuevos widget tests del dashboard

- GIVEN los nuevos widgets del dashboard
- WHEN los tests del dashboard corren
- THEN verifican renderizado de KPIs, renderizado de la grafica, estados empty/error/loading y visibilidad de acciones rapidas por permiso

##### Escenario: Nuevos widget tests de navegacion

- GIVEN el nuevo shell y la pagina Mas
- WHEN los tests de navegacion corren
- THEN verifican cinco tabs, items de Mas filtrados por permiso y routing por deep link

##### Escenario: Test del selector de tema

- GIVEN el widget del selector de tema
- WHEN sus tests corren
- THEN verifican las tres opciones y que la seleccion actualiza el tema activo

##### Escenario: Test del icono de la app

- GIVEN la configuracion del launcher icon
- WHEN el build corre
- THEN los assets generados referencian el motivo hardware de FerrePlus y no el logo de Flutter

---

### S7 — Offline-first y fixes de la app movil

Este slice incorpora el cambio `app-movil-fixes-offline` (archivado 2026-08-20): agrega una capa offline-first para las cuatro operaciones comerciales (ventas, gastos, compras y movimientos de stock), con cola durable cifrada, sincronizacion FIFO con backoff y jitter, manejo de JWT expirado, cache de listados persistida, notificaciones locales agrupadas y politica de conflictos last-write-wins. Tambien corrige la navegacion del shell, convierte el FAB de chat en toggle, ajusta la grafica del dashboard por periodo, rediseña el layout del chat, refactoriza los formularios con componentes compartidos y documenta la app Flutter en el README. No modifica contratos del backend, logica de negocio ni el frontend Angular.

#### R66 [OFFLINE-QUEUE] Cola durable de operaciones offline

El sistema DEBE persistir cada operacion comercial de escritura (ventas, gastos, compras, movimientos de stock) y sus anulaciones cuando el dispositivo esta offline. Cada operacion encolada DEBE almacenar el payload, el endpoint de destino, el metodo HTTP, el identificador de usuario, la clave de idempotencia local, el timestamp de creacion, el estado, el contador de intentos y un mensaje de error sanitizado. El sistema NO DEBE descartar operaciones encoladas cuando la app se reinicia ni cuando la sesion cierra sesion.

##### Escenario: Crear una venta sin conectividad

- GIVEN un usuario completa un formulario de venta mientras el dispositivo no tiene conectividad
- WHEN toca "Guardar"
- THEN la app almacena la operacion en una cola local durable con estado `pending`
- AND la app muestra una confirmacion de que la venta se registro localmente

##### Escenario: Crear un gasto sin conectividad

- GIVEN un usuario completa un formulario de gasto mientras esta offline
- WHEN lo guarda
- THEN la operacion se encola localmente con metodo `POST`, endpoint `/api/gastos` y el payload completo
- AND el gasto aparece en la lista local inmediatamente

##### Escenario: Anular una compra sin conectividad

- GIVEN un usuario con `COMPRAS_ELIMINAR` confirma la anulacion de una compra mientras esta offline
- WHEN se solicita la anulacion
- THEN la app encola una operacion `PUT /api/compras/{id}/anular`
- AND la lista local refleja el estado anulado

##### Escenario: La cola sobrevive al reinicio de la app

- GIVEN hay operaciones pendientes en la cola local
- WHEN la app se cierra y se reabre
- THEN todas las operaciones encoladas permanecen disponibles con su payload y estado originales

##### Escenario: Operacion online no deja registro pendiente innecesario

- GIVEN el dispositivo esta online y el backend acepta la solicitud
- WHEN una operacion comercial se envia y confirma
- THEN no queda un registro pendiente duplicado en la cola local

---

#### R67 [OFFLINE-SYNC] Sincronizacion automatica al recuperar la red

El sistema DEBE escuchar los eventos de conectividad y, cuando este online, procesar las operaciones pendientes en orden FIFO. El sync DEBE reintentar las operaciones fallidas con backoff exponencial acotado y jitter. Despues de un maximo configurable de intentos, el sistema DEBE marcar la operacion como fallida de forma terminal y mostrarla mediante una notificacion local. El sistema DEBE suprimir duplicados usando la clave de idempotencia local y DEBE actualizar los registros locales con la respuesta del backend (ID de servidor, timestamps, estado final).

##### Escenario: Sincronizacion al recuperar conectividad

- GIVEN hay operaciones pendientes y el dispositivo recupera conectividad
- WHEN el worker de sync corre
- THEN las operaciones se envian al backend en el mismo orden en que fueron encoladas
- AND las operaciones exitosas se marcan como `completed` localmente

##### Escenario: Reintento con backoff ante error transitorio

- GIVEN una operacion pendiente falla con 5xx o timeout
- WHEN el worker de sync reintenta
- THEN cada reintento espera mas que el intento anterior hasta un maximo de retraso

##### Escenario: Maximo de intentos marca error terminal

- GIVEN una operacion pendiente falla repetidamente
- WHEN el contador de intentos excede el maximo configurado
- THEN la operacion se marca como `error`
- AND una notificacion local informa al usuario que se requiere revision manual

##### Escenario: Idempotencia evita duplicados

- GIVEN una operacion encolada se reintenta despues de un timeout de red
- WHEN la misma clave de idempotencia local llega al backend dos veces
- THEN la operacion se aplica solo una vez y el estado local refleja la unica respuesta del servidor

##### Escenario: Actualizacion del registro local con respuesta del servidor

- GIVEN una venta encolada se sincroniza exitosamente
- WHEN el backend devuelve la venta creada con su ID de servidor y timestamps
- THEN el registro local se actualiza con esos valores
- AND la lista local muestra la venta como sincronizada

---

#### R68 [OFFLINE-AUTH] JWT expirado durante la sincronizacion

El sistema DEBE detectar una respuesta HTTP 401 durante la sincronizacion y transicionar la cola a un estado `auth_required`. Mientras esta en ese estado, el sistema DEBE pausar los reintentos automaticos, preservar todas las operaciones pendientes de forma segura y reanudar la sincronizacion solo despues de restaurar una sesion valida. El sistema NO DEBE descartar operaciones encoladas cuando el `AuthInterceptor` existente dispara un logout por 401.

##### Escenario: 401 durante la sincronizacion pausa la cola

- GIVEN el token de autenticacion ha expirado mientras existen operaciones pendientes
- WHEN el worker de sync recibe HTTP 401 del backend
- THEN la cola transiciona a `auth_required`
- AND los reintentos automaticos se pausan

##### Escenario: Logout por 401 conserva las operaciones pendientes

- GIVEN existen operaciones pendientes y el interceptor recibe un 401
- WHEN la app limpia la sesion y redirige a `/login`
- THEN la cola local permanece intacta y cifrada/exposicion minima

##### Escenario: Reanudacion tras nuevo login

- GIVEN la cola esta en estado `auth_required`
- WHEN el usuario inicia sesion nuevamente y obtiene un token valido
- THEN el worker de sync se reanuda automaticamente
- AND las operaciones pendientes se envian en orden FIFO

##### Escenario: Sin perdida de datos tras dias offline

- GIVEN el dispositivo ha estado offline varios dias y el token ha expirado
- WHEN el usuario abre la app e inicia sesion nuevamente
- THEN todas las operaciones encoladas siguen presentes
- AND la sincronizacion comienza sin requerir que el usuario recree ninguna operacion

---

#### R69 [OFFLINE-BATTERY] Eficiencia de bateria y memoria

El sistema NO DEBE depender de polling agresivo para detectar conectividad. DEBE escuchar los eventos de conectividad de la plataforma con debounce. La sincronizacion DEBE procesar las operaciones pendientes en lotes pequenos y DEBE disponer las suscripciones cuando no se necesiten. El sistema DEBE podar las operaciones completadas mas antiguas que una ventana de retencion configurable y DEBE limitar el tamano total de la cola local. El sync en segundo plano via workmanager/background tasks PUEDE usarse solo si aporta valor medible y se configura con restricciones de red y bateria.

##### Escenario: Sin polling continuo

- GIVEN la app esta inactiva sin cambios de conectividad
- WHEN pasan varios minutos
- THEN ningun timer periodico se dispara solo para verificar conectividad

##### Escenario: Debounce de cambios de conectividad

- GIVEN la senal de conectividad oscila rapidamente entre offline y online
- WHEN la senal se estabiliza
- THEN la sincronizacion corre solo una vez, no en cada fluctuacion

##### Escenario: Procesamiento por lotes

- GIVEN hay muchas operaciones pendientes
- WHEN la sincronizacion corre
- THEN el sistema envia operaciones en lotes pequenos
- AND no carga toda la cola en memoria a la vez

##### Escenario: Dispose de subscriptions

- GIVEN un listener de sync activo
- WHEN el usuario cierra sesion o el ciclo de vida de la app dispone el listener
- THEN todas las suscripciones de conectividad se cancelan

##### Escenario: Limpieza de operaciones sincronizadas antiguas

- GIVEN existen operaciones completadas mas antiguas que la ventana de retencion
- WHEN la limpieza corre
- THEN esos registros se eliminan del almacen local

##### Escenario: Background sync opcional con restricciones

- GIVEN el background sync esta habilitado
- WHEN se configura
- THEN corre solo bajo restricciones de red y bateria que eviten wake-ups agresivos

---

#### R70 [OFFLINE-CONFLICTS] Politica de conflictos offline

El sistema DEBE adoptar una politica `last-write-wins` para las operaciones locales encoladas contra el estado cacheado del servidor. Para los conflictos que afectan inventario, la respuesta del backend DEBE tratarse como autoritativa. Las respuestas HTTP 409/422 de validacion o conflicto NO DEBEN reintentarse indefinidamente; el sistema DEBE transicionar la operacion a un estado de error terminal y presentar un mensaje claro y accionable al usuario.

##### Escenario: Last-write-wins para operacion local

- GIVEN una venta local encolada difiere del ultimo estado conocido del servidor
- WHEN la operacion se sincroniza exitosamente
- THEN el servidor refleja el payload creado localmente
- AND el registro local se actualiza en consecuencia

##### Escenario: Conflicto de stock no reintenta indefinidamente

- GIVEN una venta es rechazada por el backend por stock insuficiente (409/422)
- WHEN el worker de sync procesa la respuesta
- THEN la operacion se marca como error terminal
- AND el usuario ve un mensaje que explica la falla

##### Escenario: Idempotencia local previene duplicados

- GIVEN la misma clave de idempotencia se envia dos veces debido a un reintento
- WHEN el backend procesa la solicitud
- THEN solo se crea un recurso
- AND el estado local almacena la unica respuesta del servidor

---

#### R71 [OFFLINE-SCHEMA] Esquema SQLite versionado

El sistema DEBE usar un esquema SQLite local versionado con migraciones incrementales. La version del esquema DEBE estar codificada en el codigo de la aplicacion. Las migraciones DEBEN preservar las operaciones encoladas y los datos de cache local a traves de las actualizaciones de la app.

##### Escenario: Version de esquema visible

- GIVEN el modulo offline esta construido
- WHEN un desarrollador inspecciona la configuracion de la base de datos
- THEN se define una version de esquema mayor que cero

##### Escenario: Migracion conserva datos

- GIVEN existen operaciones pendientes en la version de esquema N
- WHEN la app se actualiza a la version de esquema N+1
- THEN el esquema se migra
- AND todas las operaciones encoladas y los datos de listas en cache permanecen intactos

---

#### R72 [OFFLINE-NOTIFICATIONS] Notificaciones locales de sincronizacion

El sistema DEBE mostrar una notificacion local agrupada cuando existen operaciones pendientes o cuando ocurre un error terminal de sync. Las notificaciones NO DEBEN incluir datos comerciales sensibles (nombres de clientes, montos, detalles de productos) y DEBEN respetar los permisos de notificacion de la plataforma. El sistema DEBE degradarse correctamente si el permiso es denegado.

##### Escenario: Notificacion de operaciones pendientes

- GIVEN hay operaciones pendientes
- WHEN la app esta en primer o segundo plano
- THEN una notificacion local muestra el conteo y un mensaje generico como "Operaciones pendientes de sincronizar"

##### Escenario: Notificacion de error terminal sin datos sensibles

- GIVEN una operacion alcanza el maximo de reintentos
- WHEN el error terminal se registra
- THEN aparece una notificacion local con un titulo generico como "Error de sincronizacion"
- AND no expone detalles del payload

##### Escenario: Permiso denegado no crashea

- GIVEN el usuario deniega el permiso de notificacion
- WHEN la app intenta mostrar una notificacion
- THEN la app sigue funcionando sin crashear
- AND las operaciones pendientes permanecen en la cola

---

#### R73 [OFFLINE-LIST] Lectura offline de listados

El sistema DEBE cachear los datos de listado de los cuatro modulos comerciales para que las pantallas de lista puedan mostrar los ultimos datos conocidos cuando estan offline. Al mostrar datos en cache, el sistema DEBE mostrar un indicador offline visible. Si no existe cache y el dispositivo esta offline, el sistema DEBE mostrar un estado vacio con un mensaje especifico de offline.

##### Escenario: Listado de ventas desde cache offline

- GIVEN la lista de ventas se cargo previamente mientras estaba online
- WHEN el usuario abre Ventas mientras esta offline
- THEN se muestra la ultima lista conocida con un indicador offline

##### Escenario: Cache se invalida tras sincronizacion

- GIVEN existen datos de listado en cache
- WHEN se sincronizan nuevos datos desde el backend
- THEN la cache se refresca con los datos mas recientes del servidor

##### Escenario: Sin cache y sin red

- GIVEN el dispositivo esta offline y no existen datos de listado en cache
- WHEN el usuario abre una lista comercial
- THEN se muestra un estado vacio con un mensaje de offline

---

#### R-M6 [README] Seccion de la app Flutter en el README

El `README.md` DEBE incluir una seccion de la app Flutter que describa el stack movil, la estructura del directorio `flutter/`, como ejecutar los tests, los comandos de build comunes y un resumen de las nuevas funcionalidades de UX/offline.

##### Escenario: Seccion Flutter presente

- GIVEN se abre el archivo `README.md`
- WHEN se localiza la seccion Flutter
- THEN explica el proposito del directorio `flutter/`

##### Escenario: Comandos documentados

- GIVEN la seccion Flutter del README
- WHEN se leen los comandos
- THEN `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk` estan listados con el ejemplo de `--dart-define` requerido

##### Escenario: Offline y redisenos documentados

- GIVEN la seccion Flutter del README
- WHEN se leen las funcionalidades
- THEN resume la cola/sync offline, las notificaciones locales, el rediseno del layout de chat y el refactor de formularios

---

### Requisitos transversales

#### R44 [Cross-cutting] Manejo de errores, estados vacios y de carga

El sistema DEBE manejar errores de red (timeout, sin conexion, 5xx), mostrar estados de carga en operaciones asincronicas y presentar estados vacios cuando no haya datos. El usuario DEBE poder reintentar operaciones fallidas.

##### Escenario: Timeout de red

- GIVEN una llamada que excede el timeout configurado
- WHEN la peticion falla
- THEN se muestra un mensaje de error de red y un boton "Reintentar"

##### Escenario: Estado vacio

- GIVEN una lista sin elementos
- WHEN se renderiza
- THEN se muestra una illustracion/mensaje de estado vacio

##### Escenario: Estado de carga

- GIVEN una peticion en curso
- WHEN se renderiza la pantalla
- THEN se muestra un indicador de carga

#### R45 [Cross-cutting] Formato de fechas consistente

Todas las fechas mostradas en la app DEBEN usar un formato consistente (por ejemplo, `dd/MM/yyyy HH:mm` o segun locale del dispositivo). Las fechas enviadas al backend DEBEN respetar el formato ISO esperado por el contrato.

##### Escenario: Fecha en listado de ventas

- GIVEN una venta con fecha `2026-08-15T14:30:00`
- WHEN se muestra en la lista
- THEN se renderiza como `15/08/2026 14:30`

##### Escenario: Fecha en filtro enviada al backend

- GIVEN un filtro de fecha seleccionado
- WHEN se consulta al backend
- THEN la fecha se envia en formato ISO 8601

#### R46 [Cross-cutting] Visibilidad de UI basada en permisos

El sistema DEBE ocultar o deshabilitar cualquier boton, menu, ruta o accion que el usuario no tenga permiso de ejecutar. El sistema NO DEBE depender del campo `rol` para decidir visibilidad.

##### Escenario: Boton condicionado por permiso

- GIVEN un usuario sin `GASTOS_EDITAR`
- WHEN esta en el detalle de un gasto
- THEN el boton "Editar" no se renderiza

##### Escenario: Ruta condicionada por permiso

- GIVEN un usuario sin `USUARIOS_VER`
- WHEN intenta navegar a `/usuarios`
- THEN el sistema redirige a una ruta permitida

#### R47 [Cross-cutting] Calidad de codigo y tests por slice (modificado por app-movil-fixes-offline: R-M7)

Cada slice DEBE incluir tests unitarios (modelos, mapeadores, repositorios, providers) y widget tests representativos. El proyecto DEBE mantener `flutter analyze` sin warnings y una cobertura minima acordada por slice. Los 77 tests existentes al iniciar el cambio `app-movil-fixes-offline` DEBEN permanecer verdes; los tests nuevos DEBEN cubrir la cola offline, retry/backoff, transiciones online/offline, manejo de JWT expirado, toggle del FAB, navegacion del shell, agrupacion de la grafica del dashboard, layout del chat/composer y los componentes compartidos de formulario. El cierre del cambio alcanza 107 tests verdes y `flutter analyze` limpio.

##### Escenario: Tests de S1

- GIVEN los tests de autenticacion, interceptor y routing
- WHEN se ejecuta `flutter test`
- THEN todos los tests de S1 pasan

##### Escenario: Tests de S3

- GIVEN los tests de calculos POS, repositorios y widgets de formulario
- WHEN se ejecuta `flutter test`
- THEN todos los tests de S3 pasan

## Criterios de aceptacion

- [ ] La app compila para Android y `flutter analyze` no reporta warnings.
- [ ] `flutter test` pasa en cada slice con los tests unitarios y widget definidos.
- [ ] Un usuario puede iniciar sesion, conservar JWT de forma segura, ser redirigido ante 401 y ver solo rutas/acciones permitidas por autoridades.
- [ ] La app consume y representa todos los grupos de endpoints: auth, catalogos, ventas POS, compras, stock, gastos, usuarios, roles, precios, reportes, logs y chat.
- [ ] Android emulator funciona con `10.0.2.2`; la URL cambia por `--dart-define` para dispositivo fisico/LAN.
- [ ] Ventas y compras envian DTOs con detalles y soportan anulacion; precios, reportes y logs reflejan filtros/permisos del backend.
- [ ] Chat muestra respuesta Markdown segura, no ejecuta HTML, y presenta/oculta `sources` correctamente.
- [ ] S1-S5 quedan como slices encadenados, cada uno compilable/testeable y con commits revisados.
- [ ] La app presenta el Design System de tres capas (tokens primitivos/semanticos/componente), dashboard con seis KPIs + grafica de ventas por periodo, navegacion de cinco tabs + pagina `Mas` categorizada, selector de tema visible en `Mas > SISTEMA`, icono/splash con motivo `hardware` FerrePlus y cumplimiento de accesibilidad (contraste 4.5:1, targets 48dp, semantic labels, escala de texto).
- [ ] No se agregan notificaciones push, offline sync, cambios de backend ni acceso movil directo a pgvector.

## Summary

### Resumen de requisitos

| # | Requisito | Slice | Escenarios |
|---|-----------|-------|------------|
| R1 | Login con JWT | S1 | 3 |
| R2 | Persistencia de sesion | S1 | 3 |
| R3 | Manejo de 401 y logout | S1 | 2 |
| R4 | Refresco de permisos | S1 | 3 |
| R5 | Registro condicional | S1 | 3 |
| R6 | Navegacion con GoRouter | S1 | 3 |
| R7 | Guards de permisos | S1 | 3 |
| R8 | Shell navegable y dashboard | S1 | 4 |
| R9 | URL base via dart-define | S1 | 2 |
| R10 | Calidad y lints | S1 | 2 |
| R11 | Listado de productos | S2 | 3 |
| R12 | CRUD de productos | S2 | 4 |
| R13 | CRUD de categorias | S2 | 2 |
| R14 | CRUD de proveedores | S2 | 2 |
| R15 | CRUD de clientes | S2 | 1 |
| R16 | Visibilidad en catalogos | S2 | 1 |
| R17 | Listado de ventas | S3 | 2 |
| R18 | Formulario POS de ventas | S3 | 3 |
| R19 | Anulacion de ventas | S3 | 2 |
| R20 | Reporte de ventas por fecha | S3 | 2 |
| R21 | CRUD de compras | S3 | 2 |
| R22 | Anulacion de compras | S3 | 1 |
| R23 | Reporte de compras por fecha | S3 | 1 |
| R24 | Movimientos de stock | S3 | 2 |
| R25 | CRUD de gastos | S3 | 2 |
| R26 | Permisos de operacion comercial | S3 | 1 |
| R27 | Gestion de precios e historial | S4 | 2 |
| R28 | Actualizacion de precio de venta | S4 | 2 |
| R29 | CRUD de usuarios y contrasena | S4 | 3 |
| R30 | CRUD de roles y matriz | S4 | 2 |
| R31 | Catalogo de modulos/permisos | S4 | 1 |
| R32 | Dashboard con KPIs | S4 | 4 |
| R33 | Reportes de ventas/inventario/movimientos | S4 | 2 |
| R34 | Logs paginados/filtrados | S4 | 2 |
| R35 | Borrado de logs por rango | S4 | 2 |
| R36 | Permisos de administracion | S4 | 2 |
| R37 | Pantalla de chat | S5 | 2 |
| R38 | Renderizado Markdown seguro | S5 | 3 |
| R39 | Visualizacion de fuentes | S5 | 2 |
| R40 | conversationId y errores | S5 | 2 |
| R41 | Reconstruccion de indice | S5 | 2 |
| R42 | Accesibilidad, rendimiento y Android | S5 | 2 |
| R43 | Icono, splash y tema | S5 | 3 |
| R44 | Manejo de errores/vacios/carga | Cross | 3 |
| R45 | Formato de fechas consistente | Cross | 2 |
| R46 | Visibilidad por permisos | Cross | 2 |
| R47 | Calidad y tests por slice | Cross | 2 |
| R48 | Design tokens de tres capas | S6 | 4 |
| R49 | Selector de tema visible | S6 | 4 |
| R50 | Icono y splash de FerrePlus | S6 | 3 |
| R51 | Seis KPI del dashboard web | S6 | 4 |
| R52 | Grafica de ventas por periodo | S6 | 5 |
| R53 | Acciones rapidas por permiso | S6 | 3 |
| R54 | Estados loading/empty/error del dashboard | S6 | 3 |
| R55 | NavigationBar de maximo cinco destinos | S6 | 3 |
| R56 | Pagina Mas categorizada | S6 | 4 |
| R57 | Chat accesible via FAB | S6 | 3 |
| R58 | AppBar contextual | S6 | 2 |
| R59 | Widget de loading compartido | S6 | 2 |
| R60 | Widget de empty state compartido | S6 | 2 |
| R61 | Widget de error/reintento compartido | S6 | 2 |
| R62 | Layout responsive sin overflow | S6 | 4 |
| R63 | Cumplimiento de accesibilidad | S6 | 5 |
| R64 | Extraccion de componentes reutilizables | S6 | 3 |
| R65 | Verificacion por fase y tests | S6 | 6 |
| R66 | Cola durable de operaciones offline | S7 | 5 |
| R67 | Sincronizacion automatica al recuperar red | S7 | 5 |
| R68 | JWT expirado durante sincronizacion | S7 | 4 |
| R69 | Eficiencia de bateria y memoria | S7 | 6 |
| R70 | Politica de conflictos offline | S7 | 3 |
| R71 | Esquema SQLite versionado | S7 | 2 |
| R72 | Notificaciones locales de sincronizacion | S7 | 3 |
| R73 | Lectura offline de listados | S7 | 3 |
| R-M6 | Seccion de la app Flutter en el README | S7 | 3 |

### Conteo por slice

| Slice | Requisitos | Escenarios |
|-------|------------|------------|
| S1 | 10 | 28 |
| S2 | 6 | 13 |
| S3 | 10 | 18 |
| S4 | 10 | 22 |
| S5 | 7 | 16 |
| Cross-cutting | 4 | 9 |
| S6 | 18 | 62 |
| S7 | 9 | 34 |
| **Total** | **74** | **202** |

> Nota: el cambio `app-movil-flutter-ui-ux` (archivado 2026-08-18) agrego 18 requisitos (R48-R65), modifico 3 (R8, R32, R43) y removio 2 implementaciones previas (NavigationBar de 15 destinos e icono launcher generico de Flutter). El conteo base fue normalizado a su contenido real (47 requisitos / 100 escenarios; el resumen previo declaraba 46/96 por un error de conteo en S3 y S4).
>
> Nota: el cambio `app-movil-fixes-offline` (archivado 2026-08-20) agrego 8 requisitos (R66-R73) mas la seccion README (R-M6), modifico 7 (R6, R8, R55, R57, R52, R37, R40, R18, R47, R65 via deltas R-M1..R-M7) y no removio requisitos. Los deltas R-M1..R-M7 documentan la trazabilidad: R-M1 modifica R57 (FAB toggle), R-M2 modifica R6/R8/R55 (navegacion determinista), R-M3 modifica R52 (dashboard por periodo), R-M4 modifica R37/R40 (layout chat), R-M5 modifica R18 y formularios (~10 pantallas), R-M6 agrega seccion README, R-M7 modifica R47/R65 (tests).

### Cobertura

- **Happy paths**: cubiertos (login, CRUDs, POS, reportes, chat, logs).
- **Edge cases**: cubiertos (sesion corrupta, lista vacia, venta sin detalles, respuesta vacia, markdown malformado, rango de logs vacio).
- **Error states**: cubiertos (401, 403, timeout, red fallida, validaciones de permisos).
- **UI/UX (S6)**: cubiertos (tokens light/dark, selector de tema persistente, seis KPIs + grafica por periodo, acciones por permiso, loading/empty/error, cinco tabs + Mas, deep links, responsive, contraste 4.5:1, targets 48dp, semantic labels, escala de texto, icono de marca).

### Next step

Los tres cambios de la app movil (`app-movil-flutter`, `app-movil-flutter-ui-ux` y `app-movil-fixes-offline`) estan implementados, verificados y archivados. Este spec es la fuente de verdad consolidada para `flutter/`. Nuevos cambios deberan usar deltas sobre este spec.
