# Capítulo 11 — Ciclo completo de reclutamiento

**Objetivo:** Mostrar el flujo completo desde publicar una oferta laboral hasta registrar una postulación, notificar a los destinatarios y revisar la candidatura.

## Flujo de negocio

1. Talento crea una convocatoria en estado `DRAFT`.
2. Talento publica la convocatoria.
3. El portal público muestra la oportunidad.
4. Una persona candidata envía datos y un CV ficticio.
5. La API valida y persiste la postulación.
6. Mailpit recibe la notificación interna y la confirmación al candidato.
7. Talento consulta la postulación.
8. Se eliminan todos los datos de prueba.

## Evidencia técnica

- `frontend/src/app/talento/pages/convocatorias/convocatoria-form/convocatoria-form.component.ts`
- `frontend/src/app/talento/pages/postulaciones/postulacion-list/postulacion-list.component.html`
- `portal/src/pages/convocatorias/index.astro`
- `portal/src/components/ApplicationForm.astro`
- `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`
- `public-api/src/main/java/com/ferreplus/publico/mail/MailEventListener.java`

## Safe capture

- Candidate: `Carlos Demo <carlos.demo@example.test>`.
- CV: generated PDF with fictitious content.
- Mailpit local only; no external SMTP delivery.
- Do not print JWTs, full message bodies, private logs or real contact data.
- Verify each MKV with `ffmpeg -v error -xerror`.
