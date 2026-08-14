# Proposal: Chat de consultas analiticas seguras

## Intent

Permitir que el chat responda consultas analiticas del negocio, como "cual es el producto mas vendido?", usando agregaciones reales de ventas e inventario en lugar de depender exclusivamente de los cinco documentos semanticamente mas cercanos del RAG. La capacidad debe mantener una frontera de seguridad estricta: el texto del usuario y la salida del LLM nunca pueden convertirse en SQL ejecutable ni modificar la base de datos.

## Scope

### In Scope

- Incorporar clasificacion de intención del chat con un conjunto pequeño y cerrado de tokens: `mas_vendidos`, `ventas_mes`, `stock_bajo`, `guia_catalogo` y `desconocido`.
- Implementar routing por whitelist hacia metodos Java predefinidos de `ReporteService` o un servicio analitico dedicado, reutilizando la agregacion existente de productos mas vendidos.
- Exponer los resultados analiticos como DTOs seguros y permitir que `ChatService` los use para generar una respuesta clara con el contexto estructurado correspondiente.
- Validar y acotar cualquier parametro permitido antes de llegar a Spring Data JPA; usar exclusivamente queries fijas con bind parameters.
- Conservar el RAG actual para `guia_catalogo` y como fallback seguro para intenciones no reconocidas o no soportadas.
- Agregar pruebas unitarias y de integracion que demuestren el routing whitelist, la validacion de parametros y la neutralizacion de intentos como `DROP TABLE`, `INSERT`, `;` y comentarios SQL.

### Out of Scope

- Generacion de SQL, JPQL o codigo ejecutable por el LLM (ahora o como extension futura de este cambio).
- Consultas analiticas arbitrarias, filtros libres, ordenamiento dinamico o acceso general a tablas.
- Cambios de esquema, migraciones, reindexacion pgvector o modificacion del modelo de embeddings.
- Rediseño del widget de chat o cambios de frontend: el widget actual ya puede renderizar la respuesta y sus fuentes.
- Nuevos endpoints publicos de reportes si los endpoints existentes cubren las necesidades; cualquier reutilizacion de `ReporteController` debe mantener su contrato y autorizacion actuales.

## Approach

### Decision: arquitectura hibrida RAG + analitica determinista

El flujo sera hibrido y explicito:

1. `ChatService` solicita al LLM una clasificacion de la pregunta.
2. El clasificador solo puede devolver un token de una enumeracion cerrada. El prompt y el parser rechazaran texto adicional, SQL, JSON inesperado o tokens fuera de la whitelist.
3. Un router Java asigna cada token a un caso de uso conocido. No se usara reflexion, nombres de metodos provenientes del usuario ni dispatch dinamico.
4. Las intenciones analiticas invocan metodos de servicio con queries Spring Data JPA fijas. `mas_vendidos` reutilizara la logica de `ReporteService.getProductosMasVendidos()` haciendola accesible desde la capa de chat o extrayendola a un servicio cohesivo, sin duplicar la regla de negocio.
5. Los resultados se transforman a DTOs/records inmutables y se entregan al generador de respuesta como contexto confiable, separado del contexto RAG.
6. `guia_catalogo` usa el flujo RAG existente. `desconocido`, clasificacion invalida, error del clasificador o consulta no soportada no ejecutan ninguna operacion y responden con un fallback seguro.

### Modelo de seguridad anti-SQL-injection

- **Whitelist routing:** solo tokens predefinidos pueden seleccionar casos de uso; cualquier otro valor termina en `desconocido`.
- **Sin text-to-SQL:** el LLM nunca genera SQL, JPQL, nombres de tablas, expresiones, comandos ni texto ejecutable. Su salida tiene un contrato de clasificacion minimo y validado.
- **Queries fijas:** los repositories usaran metodos derivados o `@Query` estaticas de Spring Data JPA, sin concatenacion de strings ni SQL dinamico.
- **Bind parameters:** los valores autorizados se pasan como parametros tipados de JPA, nunca interpolados en una consulta.
- **Validacion previa:** fechas se parsean como `LocalDate`; limites se parsean como enteros, se acotan a un rango seguro y se rechazan ante formato invalido. El texto completo de la pregunta no llega al repository.
- **No mutaciones:** el caso de uso solo tendra operaciones de lectura (`@Transactional(readOnly = true)`); no existira camino de ejecucion para `INSERT`, `UPDATE`, `DELETE`, `DROP`, `TRUNCATE` ni procedimientos.
- **Evidencia en pruebas:** se probaran entradas con `DROP TABLE`, `INSERT`, punto y coma, comentarios SQL, intentos de alterar limites/fechas y prompt injection, verificando que se enrutan a fallback o a parametros tipados y que no se ejecutan mutaciones.

La implementacion seguira la arquitectura existente de Spring Boot: Controller delgado cuando aplique, Service para orquestacion y reglas, Repository Spring Data JPA, y DTOs sin exponer entidades. La autorizacion JWT y `@EnableMethodSecurity` se conservaran; no se abrira un bypass de seguridad para el chat.

## Affected Modules

| Modulo / ruta | Impacto | Descripcion |
|---|---|---|
| `backend/src/main/java/com/ferreplus/service/chat/ChatService.java` | Modificado | Clasificacion, routing seguro, seleccion entre analitica y RAG, y generacion de respuesta con contexto confiable. |
| `backend/src/main/java/com/ferreplus/service/chat/RagService.java` | Modificado | Mantenerlo como ruta de guia/catalogo y fallback; no usarlo como fuente de agregaciones. |
| `backend/src/main/java/com/ferreplus/service/ReporteService.java` | Modificado | Exponer o extraer de forma controlada los casos analiticos existentes, especialmente productos mas vendidos, con lectura transaccional. |
| `backend/src/main/java/com/ferreplus/repository/` | Modificado | Agregar solo metodos/querys JPA fijas necesarias para cada categoria analitica, con bind parameters. |
| `backend/src/main/java/com/ferreplus/dto/` | Modificado/Nuevo | DTOs o records para clasificacion interna, parametros validados y resultados analiticos; no exponer entidades JPA. |
| `backend/src/main/java/com/ferreplus/controller/ReporteController.java` | Revisar | Reutilizar endpoints existentes si corresponde; no agregar un endpoint de SQL libre ni alterar contratos sin necesidad. |
| `backend/src/test/java/com/ferreplus/service/chat/` | Nuevo/Modificado | Unit tests de categorias, fallback, salida invalida del LLM y router whitelist. |
| `backend/src/test/java/com/ferreplus/service/` y repositories | Nuevo/Modificado | Tests de agregacion, validacion, queries de solo lectura y ataques de inyeccion. H2 sera la base minima; Testcontainers/PostgreSQL+pgvector se evaluara para integracion real. |
| Frontend Angular 22 | Sin cambios esperados | El widget de chat ya renderiza respuestas y fuentes; solo se modificaria si el contrato backend exige un campo visual nuevo, lo cual queda fuera del alcance inicial. |

## Acceptance Criteria

- [ ] Una pregunta equivalente a "cual es el producto mas vendido?" se clasifica como `mas_vendidos` y responde con datos provenientes de la agregacion de ventas, no de los cinco documentos RAG.
- [ ] Cada categoria soportada tiene un mapping Java explicito y probado; tokens desconocidos, salida invalida del LLM y errores de clasificacion no ejecutan queries analiticas.
- [ ] Ningun texto de usuario ni salida LLM llega como SQL/JPQL; todas las consultas son fijas y usan bind parameters tipados.
- [ ] Fechas y limites se validan y acotan antes de acceder al repository; valores invalidos producen fallback o error controlado sin ejecutar la consulta.
- [ ] Tests cubren `DROP TABLE`, `INSERT`, `DELETE`, `;`, comentarios SQL y prompt injection, demostrando que no se ejecuta ninguna operacion mutante ni se altera el esquema.
- [ ] El flujo `guia_catalogo` conserva el RAG existente y el frontend no requiere cambios funcionales.
- [ ] El backend mantiene autenticacion JWT, method security, DTOs y transacciones de solo lectura, y los tests existentes continuan pasando.

## Risks

| Riesgo | Probabilidad | Mitigacion |
|---|---|---|
| El LLM clasifica mal una pregunta | Media | Enumeracion cerrada, prompt estricto, parser fail-closed, ejemplos de prueba y fallback a RAG o respuesta segura. |
| Latencia adicional por una llamada de clasificacion | Media | Prompt corto, token de salida minimo, medir tiempos y evitar clasificacion duplicada; definir timeout y fallback. |
| Respuesta analitica inconsistente con el reporte actual | Baja | Reutilizar la regla existente de `getProductosMasVendidos()`, cubrirla con tests y mantener una sola fuente de verdad. |
| Configuracion de tests con PostgreSQL/pgvector | Media | Unit tests sin infraestructura externa, H2 para queries compatibles y perfil opcional con Testcontainers para validar PostgreSQL cuando el entorno lo permita. |
| Fuga accidental de una ruta dinamica al repository | Baja, impacto alto | Revisar contrato de seguridad, tests negativos, queries estaticas, solo lectura transaccional y revision de diff antes de aplicar. |

## Rollback Plan

1. Deshabilitar el routing analitico mediante la configuracion/feature flag definida durante el diseno, dejando `ChatService` en el flujo RAG actual.
2. Revertir los cambios de `ChatService`, router, DTOs, `ReporteService`, repositories y tests introducidos por este cambio; no requiere migracion ni rollback de esquema porque el alcance es de lectura.
3. Mantener los endpoints existentes de reportes sin cambios y verificar con `mvn test` que el chat y los reportes regresan al comportamiento anterior.
4. Si se detecta cualquier duda de seguridad, el comportamiento seguro por defecto sera responder que la consulta no puede resolverse, sin ejecutar ninguna query analitica.

## Dependencies

- `ReporteService` y sus repositories actuales deben conservar la logica de agregacion de ventas.
- Cliente Gemini y configuracion existente del chatbot RAG.
- Spring Data JPA, JWT/method security y la infraestructura de pruebas definida en `openspec/config.yaml`.

## Success Criteria

- [ ] El caso de uso de productos mas vendidos responde correctamente con agregacion real y mantiene el formato de respuesta del chat.
- [ ] El conjunto de pruebas de seguridad demuestra que las entradas de inyeccion son neutralizadas sin mutaciones.
- [ ] El flujo RAG de guia/catalogo y el widget Angular siguen funcionando sin cambios de frontend.
- [ ] La solucion queda limitada a backend y es reversible sin cambios de base de datos.
