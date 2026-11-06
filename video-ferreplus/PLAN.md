# Plan de video técnico de FerrePlus

> Espacio de trabajo local para producir videos que expliquen el funcionamiento de FerrePlus.
> Todo este directorio está excluido de Git. No guardar secretos, tokens, contraseñas ni datos reales.

## 1. Objetivo

Crear una serie de videos técnicos, claros y verificables sobre la arquitectura, el funcionamiento y la operación de FerrePlus. La IA se usará como apoyo para investigar el código, preparar guiones, generar diagramas, producir narración opcional y crear subtítulos; las pantallas, comandos y flujos deben corresponder al software real.

## 2. Principios de producción

- Usar herramientas y modelos con licencias open source o libres compatibles con el uso previsto.
- Priorizar grabaciones reales del proyecto sobre videos generados artificialmente.
- Validar cada afirmación contra el código, la documentación o una ejecución controlada.
- No mostrar secretos, archivos `.env`, tokens, claves privadas, credenciales ni datos personales.
- Usar datos ficticios o una base de datos descartable para las demostraciones.
- Separar material fuente, archivos de trabajo y exportaciones finales.
- Mantener los videos cortos: preferiblemente capítulos de 5 a 10 minutos.

## 3. Serie propuesta

### Capítulo 1 — Qué es FerrePlus

- Problema que resuelve.
- Usuarios y módulos principales.
- Vista general del flujo desde el navegador hasta las APIs y los datos.

### Capítulo 2 — Arquitectura general

- `frontend/`, `portal/`, `admin-api/` y `public-api/`.
- Docker Compose y redes.
- Traefik como entrypoint.
- Separación entre operación administrativa y funcionalidades públicas.

### Capítulo 3 — Levantar el entorno local

- Requisitos.
- `.env.example` y secretos locales.
- `docker compose up -d --build`.
- Healthchecks y diagnóstico de servicios.
- URLs locales.

### Capítulo 4 — Interfaces web

- Portal público Astro.
- Panel administrativo Angular.
- Navegación y consumo de APIs.
- Estados de carga, errores y autenticación.

### Capítulo 5 — APIs y límites de responsabilidad

- Responsabilidad de `admin-api`.
- Responsabilidad de `public-api`.
- DTOs, validación y respuestas de error.
- Flujo de una petición completa.

### Capítulo 6 — Persistencia y almacenamiento

- PostgreSQL para la operación administrativa.
- MongoDB para contenido público.
- Redis para límites y estado auxiliar.
- MinIO para medios y archivos.
- Ownership de datos y redes internas.

### Capítulo 7 — Chat IA, embeddings y RAG

- Widget de chat del panel administrativo.
- Diferencia entre consultas analíticas y consultas basadas en RAG.
- Clasificación de intención con TypeSafe Jev.
- Generación de embeddings con Gemini.
- Búsqueda semántica en PostgreSQL mediante `pgvector`.
- Construcción del contexto y generación de la respuesta.
- Fuentes devueltas junto con la respuesta.
- Seguridad: whitelist de intenciones, consultas analíticas de solo lectura y fallback seguro.
- Demostración real del flujo `POST /api/chat` sin mostrar tokens ni datos personales.

### Capítulo 8 — Seguridad

- JWT y autorización backend.
- Secretos fuera de Git.
- CORS, validación y rate limiting.
- Cloudflare Turnstile.
- Qué no debe exponerse en una demostración.

### Capítulo 9 — Cloudflare Tunnel

- Diferencia entre Quick Tunnel y named tunnel.
- Perfil opcional `tunnel`.
- Token montado como secreto.
- Flujo Cloudflare → `cloudflared` → Traefik.
- Actualización segura de `cloudflared`.

### Capítulo 10 — Flujo completo de negocio

Elegir un flujo y seguirlo de extremo a extremo. Opciones:

- Publicar contenido desde Talento y verlo en el portal público.
- Enviar un formulario de contacto.
- Postularse a una convocatoria y subir un CV.
- Crear una operación desde el panel administrativo.

### Capítulo 11 — Pruebas y mantenimiento

- Pruebas unitarias e integración.
- Builds.
- Healthchecks.
- Logs y troubleshooting.
- Actualización de dependencias y rollback.

## 4. Herramientas open source

| Necesidad | Herramienta recomendada | Uso |
| --- | --- | --- |
| Asistencia para guiones | Ollama + modelo local | Resumir código y convertirlo en guion verificable |
| Diagramas | Mermaid, Graphviz, Inkscape | Arquitectura, secuencias y flujos |
| Grabación | OBS Studio | Capturar navegador, terminal y diagramas |
| Voz | Piper TTS o voz propia | Narración local; revisar licencia de cada voz |
| Transcripción | Whisper o faster-whisper | Crear subtítulos y revisar el guion |
| Edición | Kdenlive | Cortes, transiciones, títulos, audio y subtítulos |
| Audio | Audacity | Reducción de ruido y normalización |
| Terminal | asciinema | Capturas reproducibles de comandos |
| Animaciones | Blender | Animaciones complejas, si realmente aportan claridad |
| Conversión | FFmpeg | Formatos, compresión y extracción de audio |

La licencia del programa no cubre necesariamente la licencia del modelo, voz, fuente, música o asset utilizado. Revisar cada licencia antes de publicar.

## 5. Flujo de producción

### Paso 1 — Investigación

1. Leer la documentación y los archivos relevantes del capítulo.
2. Registrar rutas, comandos, servicios y ejemplos reales en `01-planificacion/`.
3. Identificar qué partes pueden ejecutarse con datos ficticios.
4. Marcar secretos o datos que deben ocultarse.

### Paso 2 — Guion

Preparar en `02-guiones/`:

- objetivo del capítulo;
- audiencia;
- narración;
- texto visible en pantalla;
- comandos que se mostrarán;
- tomas necesarias;
- advertencias técnicas;
- checklist de verificación.

La IA puede redactar una primera versión, pero una persona debe verificarla contra el repositorio.

### Paso 3 — Diagramas

Guardar en `03-diagramas/`:

- archivos Mermaid fuente;
- SVG o PNG renderizados;
- diagramas de arquitectura;
- diagramas de secuencia;
- mapas de flujo de datos.

Conservar siempre el archivo fuente editable junto al render.

### Paso 4 — Grabación

Guardar material bruto en `04-grabaciones/`:

- captura de pantalla;
- navegador;
- terminal;
- demostraciones del sistema;
- tomas alternativas.

Usar un entorno controlado y comprobar que no aparezcan tokens, `.env`, credenciales ni datos reales.

### Paso 5 — Audio y subtítulos

Guardar en `05-audio/`:

- voz original;
- voz generada;
- música libre, si aplica;
- audio limpio y normalizado.

Guardar en `06-subtitulos/`:

- transcripción original;
- `.srt` generado;
- versión corregida;
- glosario de términos técnicos.

### Paso 6 — Edición y exportación

Guardar proyectos de Kdenlive y archivos intermedios en `07-edicion/`. Guardar únicamente los videos finales en `08-exportados/`, usando nombres descriptivos, por ejemplo:

```text
01-introduccion-ferreplus-v1.mp4
02-arquitectura-general-ferreplus-v1.mp4
```

Los assets reutilizables, logos y tipografías deben ir en `09-assets/`. Scripts auxiliares de render, validación o conversión deben ir en `10-herramientas/`.

## 6. Video piloto: 8 minutos

Título sugerido: **Cómo funciona FerrePlus localmente: de Docker Compose a Cloudflare Tunnel**.

| Tiempo | Contenido |
| --- | --- |
| 0:00–0:40 | Objetivo y panorama del sistema |
| 0:40–2:00 | Arquitectura general |
| 2:00–3:30 | Docker Compose, servicios y redes |
| 3:30–5:00 | Traefik, portales y APIs |
| 5:00–5:50 | PostgreSQL, MongoDB, Redis y MinIO |
| 5:50–6:50 | Chat IA: clasificación, RAG y fuentes |
| 6:50–7:30 | Cloudflare Tunnel |
| 7:30–8:00 | Flujo completo y cierre |

## 7. Checklist antes de publicar

- [ ] El guion coincide con la implementación actual.
- [ ] Los comandos fueron ejecutados en un entorno controlado.
- [ ] No aparecen secretos, tokens, claves ni datos personales.
- [ ] Los diagramas reflejan los servicios actuales.
- [ ] Se corrigieron nombres técnicos en la narración y subtítulos.
- [ ] Las herramientas, modelos, voces, música y fuentes tienen licencias compatibles.
- [ ] El video tiene audio entendible y subtítulos revisados.
- [ ] Se exportó una copia final reproducible.
- [ ] Se verificó que los archivos siguen ignorados por Git.

## 8. Estructura del directorio

```text
video-ferreplus/
├── PLAN.md
├── 01-planificacion/
├── 02-guiones/
├── 03-diagramas/
├── 04-grabaciones/
├── 05-audio/
├── 06-subtitulos/
├── 07-edicion/
├── 08-exportados/
├── 09-assets/
└── 10-herramientas/
```
