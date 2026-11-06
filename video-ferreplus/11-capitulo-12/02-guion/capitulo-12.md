# Capítulo 12 — Contacto: persistencia y notificación interna

## Objetivo

Mostrar el flujo completo de Contactanos sin cambiar el diseño del portal: formulario público, validación, persistencia en MongoDB, evento de dominio y una notificación interna capturada por Mailpit.

## Historia

Lucia Demo envía una consulta ficticia desde `/contactanos/`. La API responde `HTTP 201`, guarda el contacto como `UNREAD` y publica `ContactoReceivedEvent`. `MailEventListener` genera exactamente un correo interno con el asunto `Nuevo contacto: Consulta de demostracion`.

## Evidencia

- Endpoint: `POST /api/public/contactos`.
- Header requerido: `Idempotency-Key`.
- Validaciones: campos obligatorios, email, límites de tamaño, honeypot y CAPTCHA.
- Persistencia: colección `contactos`.
- Notificación: plantilla `mail/contacto-recibido.html`.
- Captura local: Mailpit en `127.0.0.1:8025`.
- `confirmacion-contacto.html` existe, pero no es invocada por `MailEventListener`; la demostración muestra solo el correo interno real.

## Seguridad de captura

Usar únicamente datos ficticios. Activar `SPRING_PROFILES_ACTIVE=dev`, `CAPTCHA_ENABLED=false` y SMTP local apuntando a `mailpit:1025`. No mostrar secretos, tokens, cuerpos completos de correo, logs privados ni URLs públicas.

## Limpieza

Eliminar el registro ficticio de MongoDB, la notificación asociada y todos los mensajes de Mailpit. Confirmar que OBS se detuvo y que no quedaron archivos temporales.
