# Menu administrativo por modulos — Especificacion

## Proposito

Definir la navegacion jerarquica del frontend administrativo sin cambiar URLs, permisos ni guards. El mapa `RUTAS_POR_PERMISO` continuara siendo la fuente unica para menu, `getHomeRoute()` y `data.permissions`.

## Requisitos

### R1: Modulos principales y asignacion de rutas

El menu DEBE mostrar como maximo los cuatro grupos principales `Talento`, `Contabilidad`, `Bodega` y `Mantenimiento`, ademas de `Dashboard` como acceso directo. NO DEBE crear un grupo `Operaciones`.

La asignacion normativa es:

- **Talento**: Publicaciones, Convocatorias, Postulaciones y Destinatarios.
- **Contabilidad**: Contactos, Gastos, Ventas, Compras, Clientes, Precios y Reportes.
- **Bodega**: Productos, Categorias, Proveedores y Movimientos.
- **Mantenimiento**: Usuarios, Roles y Logs.

La asignacion depende del nodo del mapa, no del prefijo de la URL; por tanto `/talento/contactos` puede pertenecer a Contabilidad sin cambiar su URL. El orden relativo actual de las rutas dentro de cada grupo DEBE conservarse y Dashboard DEBE mantener la prioridad de inicio.

#### Scenario: Todas las rutas legacy quedan en un modulo confirmado

- GIVEN el mapa completo de rutas administrativas
- WHEN se valida la configuracion del menu
- THEN cada ruta distinta de Dashboard pertenece exactamente a uno de los cuatro grupos
- AND no existe un quinto grupo
- AND las URLs de las rutas no cambian

#### Scenario: Dashboard conserva acceso directo y prioridad

- GIVEN un usuario autenticado con `DASHBOARD_VER`
- WHEN se construye el menu y se calcula la ruta inicial
- THEN Dashboard aparece fuera de los grupos
- AND continua siendo la primera ruta elegible de `getHomeRoute()`

### R2: Filtrado RBAC recursivo

El filtrado DEBE calcular primero los descendientes visibles. Un modulo padre virtual puede tener `permissions` vacio y DEBE mostrarse si y solo si conserva al menos un descendiente visible. El permiso del padre NO DEBE ser requisito adicional para renderizar sus hijos. La visibilidad del menu NO reemplaza los guards ni la autorizacion backend.

#### Scenario: Padre visible por un hijo autorizado

- GIVEN un usuario con `BODEGA_PRODUCTOS_VER` pero sin permiso operativo del padre Bodega
- WHEN se filtra el mapa recursivamente
- THEN Bodega aparece
- AND Productos aparece como descendiente
- AND las rutas no autorizadas de Bodega no aparecen

#### Scenario: Padre sin descendientes visibles se elimina

- GIVEN un usuario sin permisos de ninguna ruta hija de Mantenimiento
- WHEN se filtra el mapa
- THEN Mantenimiento no aparece
- AND no se revela su nombre, icono ni rutas hijas

#### Scenario: Ruta hija conserva guard independiente

- GIVEN un usuario que ve un grupo por tener acceso a una ruta hermana
- WHEN intenta abrir directamente una ruta hija para la que no tiene permiso
- THEN `AuthGuard` rechaza o redirige la navegacion
- AND la existencia visible del grupo no concede acceso adicional

### R3: Expansion, contraccion y estado inicial

Cada grupo DEBE ser expandible y contraible mediante un control `<button>` real. El estado inicial DEBE ser cerrado para todos los grupos, excepto el grupo que contiene la ruta activa, que DEBE abrirse automaticamente despues de conocer la URL activa. Si la ruta activa cambia, el grupo activo tiene prioridad sobre la preferencia persistida. La expansion NO DEBE navegar por si misma.

#### Scenario: Grupo inicia cerrado sin ruta activa

- GIVEN el sidebar se monta en Dashboard o en una ruta directa sin grupo
- WHEN termina el primer render
- THEN los cuatro grupos inician cerrados
- AND sus descendientes no ocupan espacio ni reciben foco secuencial

#### Scenario: Grupo activo se abre automaticamente

- GIVEN la URL activa es `/talento/publicaciones`
- WHEN el sidebar termina de calcular las rutas visibles
- THEN Talento queda expandido
- AND la ruta Publicaciones conserva el estado visual de activa

#### Scenario: Click alterna solo el grupo seleccionado

- GIVEN Talento y Bodega estan visibles y cerrados
- WHEN el usuario hace click en el boton de Talento
- THEN Talento se expande y Bodega permanece cerrado
- WHEN vuelve a hacer click en Talento
- THEN Talento se contrae sin cambiar la URL

### R4: Teclado, ARIA y foco

Cada control de modulo DEBE exponer nombre accesible, `aria-expanded` y `aria-controls` apuntando a un contenedor cuyo id sea estable y unico. Enter y Space DEBEN alternar el grupo; Space NO DEBE desplazar la pagina. El foco DEBE permanecer en el boton al alternar y mostrar un indicador visible WCAG AA. Tab DEBE recorrer solamente controles operables visibles; los descendientes ocultos NO DEBEN ser enfocables. En sidebar colapsado, el control DEBE conservar nombre accesible y permitir revelar el grupo sin depender de hover.

#### Scenario: Alternancia por teclado

- GIVEN el foco esta en el boton de Contabilidad
- WHEN se presiona Enter o Space
- THEN Contabilidad alterna su estado
- AND `aria-expanded` refleja el nuevo valor
- AND el foco permanece en el boton
- AND Space no hace scroll de la pagina

#### Scenario: Estado ARIA consistente

- GIVEN un grupo visible con id de contenido `menu-group-bodega`
- WHEN se inspecciona su boton
- THEN tiene `aria-controls="menu-group-bodega"`
- AND `aria-expanded="true"` solo cuando el contenido esta expuesto
- AND el contenido expuesto es semanticamente relacionable con el boton

#### Scenario: Sidebar colapsado sigue siendo operable

- GIVEN el sidebar esta en modo icon-only
- WHEN un usuario navega con Tab hasta el control de Talento y presiona Enter
- THEN el control se puede operar sin hover
- AND el usuario recibe un nombre accesible que incluye "Talento"
- AND no se muestran rutas a las que carece de permiso

### R5: Persistencia no sensible

El sistema DEBERIA persistir unicamente el estado expandido/contraido por usuario y dispositivo en `localStorage`, usando una clave versionada y no sensible. La clave NO DEBE contener permisos, roles, rutas secretas ni datos de negocio. La preferencia DEBE ignorarse si el grupo deja de tener hijos visibles; la ruta activa siempre prevalece. Si `localStorage` no esta disponible, el menu DEBE funcionar con estado en memoria.

#### Scenario: Preferencia se restaura sin revelar permisos

- GIVEN el usuario cerro Bodega y existe una preferencia local valida
- WHEN vuelve a cargar el frontend con los mismos hijos visibles
- THEN Bodega restaura el estado cerrado
- AND el valor almacenado solo contiene identificadores de grupo y booleanos
- AND no contiene codigos de permiso ni roles

#### Scenario: Preferencia obsoleta no revela un grupo

- GIVEN existe una preferencia local para un grupo que ahora no tiene hijos visibles
- WHEN se filtra el menu
- THEN el grupo no se renderiza
- AND la preferencia no fuerza su aparicion

## Fuera de alcance

- Cambiar URLs, nombres de permisos, roles, guards o reglas backend.
- Crear un modulo `Operaciones` o migrar Angular a standalone/signals/forms nuevos.
- Persistir preferencias en backend o sincronizarlas entre dispositivos.

## Criterios medibles

- Los cuatro grupos y Dashboard se detectan con una prueba de configuracion; ninguna ruta queda sin asignacion.
- La suite cubre al menos un caso de padre visible por descendiente, padre oculto, grupo activo y ruta directa bloqueada.
- Axe/inspeccion automatizada verifica `aria-expanded`, `aria-controls`, foco visible y operacion Enter/Space.
