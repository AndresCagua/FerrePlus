# Publicaciones administrativas — Especificacion

## Proposito

Definir los cambios editoriales del modulo Talento sin eliminar `portada` del dominio ni del portal publico.

## Requisitos

### R1: Listado sin columna portada

El listado administrativo DEBE eliminar la columna, thumbnail, fallback y helpers exclusivos de `portada`. El modelo, formulario, contrato API, almacenamiento y portal DEBEN conservar el campo `portada` sin cambios funcionales.

#### Scenario: Portada no aparece en la tabla

- GIVEN una publicacion con portada y otra sin portada
- WHEN un usuario autorizado abre el listado
- THEN ninguna columna ni control de fila representa portada
- AND titulo, estado y demas columnas existentes siguen disponibles

#### Scenario: Portada se conserva fuera del listado

- GIVEN una publicacion con portada
- WHEN se abre el formulario o el portal publico
- THEN la portada continua disponible para previsualizacion/renderizado
- AND eliminar la columna no elimina ni modifica el valor persistido

### R2: Contrato editorial estable

El listado DEBE seguir usando el contrato vigente de publicaciones y NO DEBE introducir campos de CMS, analitica o multi-tenant. Cambiar slug o SEO no DEBE convertir el listado en propietario de la media.

#### Scenario: No regresion de media

- GIVEN una respuesta API que contiene `portada`, galeria y video
- WHEN se carga el listado
- THEN se omite visualmente solo `portada`
- AND galeria, video y metadata no se borran ni se reescriben

## Fuera de alcance

- Eliminar portada del modelo, formulario, API, MongoDB o portal.
- Rediseñar el listado completo o cambiar estados de publicacion.
