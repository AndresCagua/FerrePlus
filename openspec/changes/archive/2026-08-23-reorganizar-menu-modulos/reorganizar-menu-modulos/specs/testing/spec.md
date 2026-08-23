# Pruebas y criterios de entrega — Especificacion

## Requisitos

### R1: Cobertura del menu y RBAC

DEBEN existir pruebas unitarias para asignacion completa de rutas, filtrado recursivo, padres virtuales, grupo activo, estado cerrado inicial, teclado, ARIA y persistencia no sensible. DEBE existir al menos una prueba de integracion que intente una URL hija sin permiso.

#### Scenario: Suite detecta padre calculado incorrectamente

- GIVEN un fixture con permiso solo para un descendiente
- WHEN se ejecuta la prueba de filtrado
- THEN la prueba exige que el padre aparezca con un solo hijo
- AND falla si el padre exige permiso propio o si expone hermanos no autorizados

#### Scenario: Suite verifica accesibilidad observable

- GIVEN el sidebar renderizado en estado abierto y cerrado
- WHEN se ejecuta la prueba de teclado/ARIA
- THEN verifica boton real, nombre, `aria-expanded`, `aria-controls`, foco y Enter/Space
- AND verifica que los descendientes colapsados no sean enfocables

### R2: Cobertura de publicaciones, slug y concurrencia

DEBEN existir pruebas de listado sin portada conservando portada en modelo/formulario, normalizacion de slug, fallback, limite, cambio de titulo, colisiones, actualizacion y carrera de unicidad. La prueba de carrera DEBE demostrar que nunca se guardan duplicados y que el error agotado es `409` controlado.

#### Scenario: Colision concurrente queda cubierta

- GIVEN dos operaciones concurrentes con el mismo titulo
- WHEN se ejecuta la prueba de persistencia
- THEN valida unicidad final en MongoDB
- AND valida sufijo o `409` segun disponibilidad
- AND falla si una excepcion de indice llega sin traduccion

### R3: Cobertura del endpoint IA y formulario

DEBEN existir pruebas de contrato y servicio para exito, `400`, `401`, `403`, timeout, error del proveedor, retry explicito y respuesta incompleta. La UI DEBE probar que una falla IA no bloquea Guardar y que una sugerencia queda editable.

#### Scenario: Retry no automatico duplica llamadas

- GIVEN un timeout de IA
- WHEN se muestra el error
- THEN no se realiza retry automatico
- WHEN el usuario pulsa Retry una vez
- THEN se realiza exactamente una nueva solicitud
- AND Guardar continua independiente de la IA

### R4: Cobertura responsive y portal

DEBEN existir verificaciones del portal en al menos 320px, 768px y 1440px para columna, espaciado, imagenes, YouTube, X y ausencia de scroll horizontal. DEBE verificarse que borradores no sean indexables y que un fallo de embed conserve fallback.

#### Scenario: Prueba movil no detecta overflow

- GIVEN una publicacion con URL X larga, imagen y YouTube
- WHEN se renderiza a 320px
- THEN `scrollWidth <= clientWidth`
- AND las imagenes y embeds respetan `max-width: 100%`
- AND el fallback X permanece accesible

### R5: Criterio de no regresion y entrega

El cambio no se considera completo hasta que pasan las suites frontend Vitest/Angular, backend Maven de `admin-api` y `public-api`, pruebas de contrato y checks del portal. Cada PR encadenado DEBE ser compilable y probar solo su fase; la verificacion final DEBE comprobar el conjunto de escenarios de este documento.

#### Scenario: Regresion de chat o RBAC bloquea entrega

- GIVEN una modificacion que hace fallar chat, guards, permisos o contratos existentes
- WHEN se ejecuta la verificacion de integracion
- THEN la entrega se marca fallida
- AND no se considera suficiente que pasen solo las pruebas nuevas

## Fuera de alcance

- Pruebas de carga masiva, penetration testing completo, migraciones de datos automaticas o cambios de infraestructura no definidos en la propuesta.

## Criterios medibles

- Cada requisito de menu, publicaciones, slug/SEO, portal y seguridad tiene al menos un escenario automatizable.
- Se cubren happy path, edge cases y errores `400/401/403/409/503` donde aplican.
- Ningun escenario requiere commits, operaciones destructivas de base de datos ni proveedor IA nuevo.
