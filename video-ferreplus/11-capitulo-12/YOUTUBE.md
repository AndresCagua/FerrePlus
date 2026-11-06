# Video 11 — Contacto: persistencia y notificación interna

## Título sugerido

FerrePlus capítulo 12: formulario de Contactanos, MongoDB y correo interno con Mailpit

## Descripción

En este capítulo de la serie técnica de FerrePlus seguimos una consulta ficticia desde el formulario público de Contactanos hasta su persistencia en MongoDB y la notificación interna por correo.

El flujo real que se verifica localmente es:

- Validación del formulario y clave de idempotencia.
- `POST /api/public/contactos` con respuesta `HTTP 201`.
- Registro inicial `UNREAD` en MongoDB.
- Publicación de `ContactoReceivedEvent`.
- Un correo interno capturado por Mailpit.
- Limpieza completa de los datos de demostración.

No se utilizan cuentas SMTP externas ni datos personales reales. La captura evita mostrar secretos, tokens, cuerpos completos de correo y logs privados.

## Capítulos

00:00 Introducción
00:28 Formulario público
01:00 Envío y respuesta HTTP
01:34 Persistencia e idempotencia
02:02 Notificación interna
02:34 Evidencia de Mailpit
03:04 Limpieza y cierre

## Tecnologías

Astro · Spring Boot · MongoDB · eventos de aplicación · JavaMail · Mailpit · Docker Compose

## Código

Repositorio: https://github.com/andres-ferreplus/ferreplus

#FerrePlus #SpringBoot #MongoDB #Astro #Mailpit #SoftwareArchitecture
