# Capítulo 13 — Pruebas y mantenimiento de FerrePlus

## Objetivo

Mostrar una rutina reproducible para verificar el backend y frontend, comprobar healthchecks, diagnosticar con logs y mantener el entorno local con una ruta de rollback.

## Escenas

1. **Introducción:** las pruebas y el mantenimiento convierten un entorno que funciona en uno verificable.
2. **Backend:** Maven ejecuta la suite dentro de un contenedor, sin requerir Maven instalado en la máquina host.
3. **Frontend:** Angular ejecuta sus pruebas en modo CI, sin watch interactivo.
4. **Healthchecks:** Compose coordina dependencias saludables antes de iniciar los servicios.
5. **Logs:** el diagnóstico parte del estado actual y de líneas recientes, evitando imprimir secretos o payloads.
6. **Troubleshooting:** los endpoints de salud permiten ubicar rápidamente la capa que falla.
7. **Actualización y rollback:** se revisan cambios, se reconstruyen imágenes, se verifican servicios y se conserva una vuelta atrás.
8. **Cierre:** probar, observar, actualizar y revertir cuando sea necesario.

## Seguridad de la captura

- No mostrar `.env`, credenciales, tokens, claves, JWT, URLs públicas ni datos personales.
- Usar únicamente estados, conteos, códigos HTTP y procedimientos.
- No modificar el repositorio ni publicar cambios durante la demostración.
