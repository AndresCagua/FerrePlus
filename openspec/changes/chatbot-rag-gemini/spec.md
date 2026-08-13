# Delta Spec — chatbot-rag-gemini

## Requisitos

- **R1 — Autenticación obligatoria para chat**: El sistema DEBE (MUST) exigir que el usuario esté autenticado para enviar una pregunta al chatbot; las peticiones anónimas DEBERÁN (SHALL) recibir una respuesta HTTP 401.

- **R2 — Idioma español**: El sistema DEBE (MUST) aceptar preguntas formuladas en español y generar respuestas en español.

- **R3 — Validación de la pregunta**: El sistema DEBE (MUST) validar que la pregunta no esté vacía ni compuesta únicamente por espacios en blanco, devolviendo un error 400 cuando no cumpla la validación.

- **R4 — Pipeline RAG**: El sistema DEBE (MUST) ejecutar un pipeline de recuperación aumentada por generación: transformar la pregunta en un embedding semántico, recuperar los cinco documentos más relevantes mediante similitud coseno, inyectarlos como contexto y generar una respuesta natural que cite las fuentes utilizadas.

- **R5 — Indexación de entidades iniciales**: El sistema DEBE (MUST) indexar y permitir la recuperación semántica de información de al menos las entidades Producto, Cliente, Proveedor, Venta, Compra y Gasto.

- **R6 — Respuesta ante falta de contexto**: Cuando no se encuentren documentos relevantes para una pregunta, el sistema DEBE (MUST) responder indicando al usuario que no dispone de datos suficientes para responder, sin inventar información.

- **R7 — Error cuando el generador no está disponible**: Si el servicio de generación de respuestas no está disponible o devuelve un error, el sistema DEBE (MUST) devolver un mensaje de error claro al usuario, sin exponer detalles técnicos internos.

- **R8 — Manejo de límite de cuota**: Si se excede la cuota disponible del servicio de generación, el sistema DEBE (MUST) informar al usuario de forma amigable y sugerir reintentar más tarde.

- **R9 — Reconstrucción del índice solo para administradores**: El endpoint de reconstrucción del índice de embeddings DEBE (MUST) estar restringido a usuarios con rol de administrador; otros usuarios DEBERÁN (SHALL) recibir un error 403.

- **R10 — Extensibilidad del índice**: El sistema DEBE (MUST) permitir agregar nuevos tipos de entidad al índice sin afectar los documentos de las entidades ya indexadas.

- **R11 — Guías de navegación del sistema**: El sistema DEBE (MUST) responder preguntas sobre cómo usar el sistema (rutas y pasos para realizar una acción), basándose en la tabla `guias_sistema` indexada como `entity_type = 'GUIA'`.

- **R12 — Sembrado de guías del sistema**: El DataSeeder DEBE (MUST) sembrar guías de navegación para los módulos principales del sistema, de modo que el chatbot pueda orientar a los usuarios desde el inicio.

- **R13 — API REST agnóstica del cliente**: El sistema DEBE (MUST) exponer el chatbot como una API REST pura consumible por cualquier cliente (Angular actual, Flutter futuro). El request y response DEBEN (MUST) usar JSON estable sin acoplarse a tecnologías de presentación. El backend DEBE (MUST) permitir múltiples orígenes (CORS) para el cliente web en desarrollo y la futura aplicación móvil.

- **R14 — Lógica RAG en backend (no en cliente)**: El sistema DEBE (MUST) mantener toda la lógica de recuperación aumentada por generación (embeddings, búsqueda vectorial, generación de respuestas) en el backend Spring Boot. Los clientes (web y móvil) únicamente DEBEN (MUST) enviar el mensaje del usuario y mostrar la respuesta devuelta.

## Escenarios

### Escenario 1: Usuario autenticado realiza una pregunta y obtiene respuesta fundamentada
- Dado: un usuario autenticado con un token válido
- Y: existen documentos indexados relacionados con la pregunta
- Cuando: envía una pregunta en español al endpoint de chat
- Entonces: recibe una respuesta en español generada a partir del contexto recuperado
- Y: la respuesta incluye las fuentes que fundamentan la información

### Escenario 2: Consulta sobre productos recupera datos de la entidad Producto
- Dado: un usuario autenticado
- Y: existen productos indexados con descripción, categoría, precio y stock
- Cuando: pregunta, por ejemplo, "¿qué productos de electricidad tenemos en stock?"
- Entonces: la respuesta menciona productos coincidentes con sus datos relevantes
- Y: las fuentes citadas corresponden a registros de productos

### Escenario 3: No se encuentran documentos similares
- Dado: un usuario autenticado
- Y: no hay documentos indexados cercanos semánticamente a la pregunta
- Cuando: envía una pregunta sobre un tema que no tiene datos en el índice
- Entonces: recibe una respuesta indicando que no tiene datos suficientes para responder
- Y: no inventa información ni responde con datos no recuperados

### Escenario 4: Usuario no autenticado intenta consultar
- Dado: un usuario sin sesión o con un token inválido
- Cuando: intenta enviar una pregunta al endpoint de chat
- Entonces: recibe una respuesta HTTP 401

### Escenario 5: Servicio de generación de respuestas no disponible
- Dado: un usuario autenticado
- Y: el servicio de generación de respuestas no responde o devuelve un error de conexión
- Cuando: envía una pregunta válida
- Entonces: recibe un mensaje de error claro y amigable
- Y: no se exponen trazas, URLs internas ni detalles técnicos del proveedor

### Escenario 6: Se excede el límite de cuota del servicio
- Dado: un usuario autenticado
- Y: se ha alcanzado el límite de peticiones de la cuota gratuita del servicio
- Cuando: envía una pregunta
- Entonces: recibe un mensaje indicando que se excedió la cuota y debe reintentar más tarde

### Escenario 7: Administrador reconstruye el índice
- Dado: un usuario autenticado con rol ADMIN
- Cuando: solicita la reconstrucción del índice de embeddings
- Entonces: el sistema regenera los embeddings de las seis entidades soportadas
- Y: no se generan documentos duplicados para la misma entidad

### Escenario 8: Se agrega un nuevo tipo de entidad al índice
- Dado: que existen documentos indexados de las seis entidades iniciales
- Cuando: se registra e indexa un nuevo tipo de entidad
- Entonces: los documentos de las entidades previas permanecen disponibles
- Y: el nuevo tipo de entidad se indexa correctamente

### Escenario 9: Pregunta formulada en español
- Dado: un usuario autenticado
- Cuando: envía la pregunta "¿cuál es el proveedor principal de tornillos?"
- Entonces: la respuesta está redactada en español
- Y: el tono es natural y comprensible

### Escenario 10: Pregunta vacía o en blanco
- Dado: un usuario autenticado
- Cuando: envía una pregunta vacía o compuesta solo por espacios
- Entonces: recibe una respuesta HTTP 400 con un mensaje de validación

### Escenario 11: Actualización de una entidad reflejada en el índice
- Dado: un usuario autenticado
- Y: existe un documento indexado para una entidad
- Cuando: se modifica la entidad y se sincroniza su índice
- Entonces: el embedding se actualiza para reflejar los datos actuales
- Y: el documento obsoleto no se devuelve en búsquedas posteriores

### Escenario 12: Usuario no administrador intenta reconstruir el índice
- Dado: un usuario autenticado sin rol ADMIN
- Cuando: intenta solicitar la reconstrucción del índice
- Entonces: recibe una respuesta HTTP 403

### Escenario 13: Usuario pregunta dónde registrar un producto
- Dado: un usuario autenticado
- Y: existe una guía sembrada para el módulo PRODUCTO con ruta `/productos` y pasos de registro
- Cuando: envía la pregunta "¿dónde registro un producto?"
- Entonces: recibe una respuesta en español que indica la ruta `/productos`
- Y: incluye los pasos para registrar un producto

### Escenario 14: Usuario pregunta cómo hacer una venta
- Dado: un usuario autenticado
- Y: existe una guía sembrada para el módulo VENTA con ruta `/ventas` y pasos para realizar una venta
- Cuando: envía la pregunta "¿cómo hago una venta?"
- Entonces: recibe una respuesta en español que indica la ruta `/ventas`
- Y: incluye los pasos para hacer una venta

### Escenario 15: Pregunta sobre navegación sin guía sembrada
- Dado: un usuario autenticado
- Y: no existe una guía sembrada relacionada con la acción consultada
- Cuando: envía una pregunta sobre cómo realizar una acción del sistema
- Entonces: recibe una respuesta indicando que no dispone de datos suficientes para orientarlo
- Y: no inventa una ruta ni pasos

### Escenario 16: Cliente móvil Flutter consume el mismo contrato de chat
- Dado: una aplicación móvil Flutter registrada como origen permitido en CORS
- Cuando: envía `{"message": "¿Cuáles son los requisitos?"}` a `POST /api/chat`
- Entonces: recibe un response JSON `{"answer": "...", "sources": [...]}`
- Y: el formato y contenido son idénticos a los devueltos al cliente Angular

### Escenario 17: Cliente solo envía el mensaje y recibe respuesta renderizable
- Dado: un usuario autenticado desde el cliente Angular o Flutter
- Cuando: envía únicamente el mensaje de texto al endpoint de chat
- Entonces: el cliente no ejecuta embeddings ni búsqueda vectorial
- Y: el backend devuelve la respuesta lista para mostrar en la interfaz del cliente
