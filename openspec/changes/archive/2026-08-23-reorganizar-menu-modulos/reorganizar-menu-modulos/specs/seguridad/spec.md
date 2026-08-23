# Seguridad, ownership y no regresion — Especificacion

## Requisitos

### R1: Separacion de responsabilidades entre APIs

`admin-api` DEBE ser el unico borde autenticado para la sugerencia SEO y DEBE reutilizar la autenticacion/RBAC existente. `public-api` DEBE conservar la propiedad de publicaciones, MongoDB y el indice unico de slug. NO se permite exponer credenciales IA al navegador ni crear una conexion de datos cruzada entre APIs.

#### Scenario: Usuario sin permiso no genera SEO

- GIVEN una solicitud sin JWT o con JWT sin permiso de publicaciones
- WHEN llega al endpoint SEO
- THEN responde 401 o 403 segun corresponda
- AND no consulta Gemini ni modifica publicacion

#### Scenario: API publica no recibe credenciales administrativas

- GIVEN el bundle del portal y sus solicitudes de red
- WHEN se inspeccionan variables y headers
- THEN no contienen API keys, tokens administrativos ni secretos de MongoDB

### R2: Validacion y errores seguros

Todos los DTOs de slug/SEO DEBEN validar tipos, longitudes y campos permitidos. Los errores DEBEN usar ProblemDetail o el formato vigente, con mensajes accionables pero sin stack traces, consultas, prompts, tokens o detalles de infraestructura. `409` se reserva para conflicto de unicidad; `503` para dependencia IA/infraestructura no disponible.

#### Scenario: Entrada excedida se rechaza antes de IA

- GIVEN contenido que supera el limite contractual
- WHEN se solicita SEO
- THEN responde `400`
- AND no se invoca el proveedor IA
- AND no se registra el contenido completo

#### Scenario: Error interno no filtra secretos

- GIVEN Gemini o MongoDB devuelve una excepcion interna
- WHEN el endpoint responde
- THEN el cliente recibe un error generico tipado
- AND la respuesta no contiene stack trace, URI, credencial ni prompt

### R3: No regresion de RBAC y guards

El cambio DEBE mantener `data.permissions`, `AuthGuard`, `@PreAuthorize`, autenticacion JWT y autorizacion server-side para todas las rutas existentes. Ocultar una ruta o grupo en el menu NO DEBE modificar las autoridades efectivas.

#### Scenario: Ruta directa continua protegida

- GIVEN un usuario autenticado sin el permiso de una ruta hija
- WHEN solicita la URL directamente
- THEN recibe el mismo bloqueo 403/redirect definido por la aplicacion
- AND no se ejecuta el caso de uso protegido

#### Scenario: Permisos de chat no cambian

- GIVEN el endpoint y flujo de chat existentes
- WHEN se despliega la funcionalidad SEO
- THEN el chat conserva autenticacion, contrato y proveedor configurado
- AND no comparte accidentalmente el prompt SEO ni modifica su autorizacion

## Fuera de alcance

- Cambiar roles/permisos, algoritmo general de JWT, CORS global, rate limits globales o proveedor IA.
