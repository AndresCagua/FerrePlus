# Slug y SEO asistido — Especificacion

## Proposito

Definir la autoridad backend del slug y la sugerencia SEO generada por el cliente de IA existente, manteniendo edicion manual y guardado explicito.

## Requisitos

### R1: Slug derivado y normalizado

El backend DEBE ignorar cualquier slug enviado por el cliente como autoridad final y generar el slug desde el titulo vigente. La normalizacion DEBE: transliterar acentos, convertir a minusculas, conservar solo letras ASCII, numeros y guion, colapsar guiones, quitar guiones extremos y limitar el resultado a 100 caracteres sin cortar un token a medias. Si el titulo no produce caracteres validos, DEBE usar la base `publicacion`.

El frontend DEBE mostrar una previsualizacion de solo lectura; NO DEBE exigir entrada manual. Si cambia el titulo antes de guardar, el valor enviado no puede impedir el recalculo backend.

#### Scenario: Titulo con acentos produce slug normalizado

- GIVEN el titulo `Talento: Niño Técnico / Bogotá`
- WHEN se crea la publicacion
- THEN el slug resultante es `talento-nino-tecnico-bogota`
- AND no contiene mayusculas, acentos, espacios, barras ni guiones consecutivos

#### Scenario: Titulo sin caracteres validos usa fallback

- GIVEN un titulo compuesto solo por simbolos
- WHEN el backend genera el slug
- THEN usa la base `publicacion`
- AND el resultado cumple las mismas reglas de longitud y caracteres permitidos

### R2: Unicidad concurrente y reintentos

El backend DEBE garantizar unicidad mediante restriccion unica de MongoDB y un candidato determinista legible: base, `base-2`, `base-3`, etc. Ante una colision por carrera DEBE reintentar el siguiente candidato hasta 5 intentos totales dentro de la misma operacion. Una actualizacion que cambie el titulo DEBE recalcular; una actualizacion que no cambie el titulo DEBE conservar el slug existente salvo reparacion necesaria de unicidad.

Si todos los intentos fallan por colision, DEBE devolver `409 Conflict` con codigo seguro `SLUG_UNAVAILABLE`; no DEBE guardar una publicacion parcial ni revelar detalles de MongoDB. Un error transitorio de infraestructura DEBE devolver `503` y no simular exito.

#### Scenario: Colision secuencial usa sufijo determinista

- GIVEN ya existe `talento-nino`
- WHEN se crea otra publicacion con el mismo titulo
- THEN se persiste `talento-nino-2`
- AND la respuesta identifica el slug final

#### Scenario: Dos creaciones concurrentes no duplican slug

- GIVEN dos solicitudes validas con el mismo titulo llegan concurrentemente
- WHEN ambas intentan persistir
- THEN exactamente una obtiene el slug base
- AND la otra obtiene un sufijo disponible o un `409` controlado
- AND nunca existen dos documentos con el mismo slug

#### Scenario: Reintento agotado devuelve conflicto

- GIVEN los cinco candidatos deterministas estan ocupados
- WHEN se intenta crear una publicacion
- THEN responde `409 Conflict` con `SLUG_UNAVAILABLE`
- AND no se persiste el documento

### R3: API de sugerencia SEO con IA existente

El sistema DEBE exponer desde `admin-api` un caso de uso administrativo autenticado que reutilice el cliente/configuracion Gemini del chat existente. La entrada DEBE limitar titulo/contenido a los limites definidos por el contrato y la salida DEBE ser un DTO estricto con `title` y `description`. La IA NO DEBE recibir credenciales del navegador, y el prompt completo sensible NO DEBE aparecer en logs.

El endpoint DEBE usar `401` para ausencia de autenticacion, `403` para falta de permiso de escritura de publicaciones, `400` para entrada invalida y `503` para timeout/falla del proveedor. La sugerencia NO DEBE persistirse automaticamente.

#### Scenario: Generacion SEO exitosa

- GIVEN un editor autenticado con permiso de editar publicaciones y contenido valido
- WHEN solicita una sugerencia SEO
- THEN `admin-api` reutiliza la integracion IA existente
- AND responde `200` con titulo y descripcion no vacios
- AND no guarda cambios en la publicacion

#### Scenario: Acceso no autorizado

- GIVEN un usuario autenticado sin permiso de editar publicaciones
- WHEN solicita SEO
- THEN recibe `403`
- AND no se invoca el proveedor IA

### R4: UI editable y resiliente

El formulario DEBE mostrar estados loading, error, retry y respuesta incompleta. Mientras carga, el control de generacion DEBE impedir solicitudes duplicadas y anunciar el estado. La sugerencia DEBE rellenar campos editables sin sobrescribir cambios posteriores del usuario sin una accion explicita. El boton Guardar DEBE continuar disponible si la IA falla, sujeto a validaciones ordinarias.

#### Scenario: Editor modifica la sugerencia antes de guardar

- GIVEN la IA devuelve titulo y descripcion SEO
- WHEN el formulario los presenta y el editor cambia ambos campos
- THEN los valores editados permanecen
- AND Guardar persiste solo tras la accion manual del editor

#### Scenario: Timeout permite continuar manualmente

- GIVEN la solicitud IA excede el timeout
- WHEN la UI recibe el error
- THEN muestra mensaje accionable y control Retry
- AND conserva el formulario editable
- AND Guardar no queda bloqueado por la falla IA

#### Scenario: Respuesta incompleta se valida

- GIVEN la IA devuelve solo `title` o texto fuera del DTO
- WHEN se procesa la respuesta
- THEN la UI marca la sugerencia como incompleta y no la trata como valida
- AND permite reintentar o editar manualmente

## Fuera de alcance

- Nuevo proveedor, nueva API key, entrenamiento, auto-publicacion o auto-guardado.
- Edicion libre obligatoria del slug, migracion masiva de documentos o cambio de URLs.
