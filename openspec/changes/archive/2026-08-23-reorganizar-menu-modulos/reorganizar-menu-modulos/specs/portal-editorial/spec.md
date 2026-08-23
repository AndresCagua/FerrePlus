# Portal editorial publico — Delta

## MODIFIED Requirements

### Requirement: R3 — Publicaciones y cartelera

La publicacion publicada DEBE conservar su portada, galeria, video, enlaces X y metadata SEO, pero su URL publica DEBE resolverse por el slug backend normalizado y unico definido en la especificacion de slug. Un borrador NO DEBE ser resoluble ni indexable por slug.

#### Scenario: Slug publico resuelve una publicacion publicada

- GIVEN una publicacion `PUBLISHED` con slug unico
- WHEN un visitante solicita la ruta publica del slug
- THEN recibe el contenido editorial y metadata SEO efectiva
- AND la portada sigue renderizandose cuando existe

#### Scenario: Slug de borrador no expone contenido

- GIVEN una publicacion `DRAFT`
- WHEN un visitante solicita su slug
- THEN recibe 404 o estado publico equivalente
- AND el borrador no aparece en sitemap ni metadata indexable

### Requirement: R15 — Portal Astro publico

El portal DEBE presentar el articulo en una columna central de `720px +/- 24px` en viewport de escritorio. El contenido y los embeds DEBEN usar `max-width: 100%`; las imagenes DEBEN ser responsive y conservar `alt` util. YouTube DEBE mantener relacion 16:9 con espacio reservado para evitar CLS. Cada embed X DEBE estar centrado, permitir wrap de URLs largas y no producir overflow horizontal.

El espaciado vertical entre bloques editoriales DEBE permanecer entre 20px y 32px, salvo la separacion mayor intencional del encabezado. En viewport movil de 320px a 767px, `document.documentElement.scrollWidth` DEBE ser menor o igual al viewport width. Debe respetarse `prefers-reduced-motion`.

#### Scenario: Columna y espaciado editorial medibles

- GIVEN una pagina publicada en viewport de 1440px
- WHEN se inspecciona el articulo
- THEN su columna mide entre 696px y 744px
- AND los bloques sucesivos usan separaciones de 20px a 32px

#### Scenario: YouTube conserva 16:9

- GIVEN una publicacion con enlace YouTube valido
- WHEN se renderiza el bloque multimedia
- THEN el contenedor mantiene relacion 16:9
- AND su ancho nunca supera la columna ni el viewport
- AND se reserva su espacio antes de cargar contenido externo

#### Scenario: X centrado sin overflow

- GIVEN una publicacion con una o mas URLs de X, incluyendo una URL larga
- WHEN se renderiza en escritorio y movil
- THEN cada bloque queda centrado dentro de la columna
- AND el texto puede envolver sus segmentos largos
- AND no aparece scroll horizontal

#### Scenario: Imagen responsive y accesible

- GIVEN una portada o imagen de galeria
- WHEN se renderiza en un viewport de 320px
- THEN su ancho computado no excede el contenedor
- AND tiene texto alternativo derivado de `alt` o titulo
- AND no desplaza horizontalmente la pagina

#### Scenario: Falla de embed no rompe el articulo

- GIVEN X o YouTube no carga o rechaza el embed
- WHEN se procesa el contenido
- THEN se conserva un enlace/fallback accesible
- AND el texto editorial continua visible

## ADDED Requirements

### Requirement: Aislamiento visual del portal

Los cambios visuales DEBEN limitarse a la pagina y componentes editoriales de publicaciones; no DEBEN alterar identidad global, navegacion, formularios publicos no relacionados ni contratos de candidatos.

#### Scenario: Otras paginas no cambian su ancho

- GIVEN una pagina publica de convocatorias o contacto
- WHEN se aplican los estilos editoriales
- THEN no hereda accidentalmente la columna de publicaciones
- AND sus controles existentes mantienen comportamiento y responsive vigente

## Fuera de alcance

- Rediseño integral, nuevo sistema de diseño, analitica, CMS, nuevas paginas o proveedor de embeds.
