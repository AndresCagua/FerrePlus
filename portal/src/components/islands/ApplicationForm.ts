import { publicApi } from '../../lib/api-client/public-api';
import { PublicApiError } from '../../lib/api-client/types';

export function setupApplicationForm(form: HTMLFormElement): void {
  const status = form.querySelector<HTMLElement>('[data-status]');
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const button = form.querySelector<HTMLButtonElement>('button[type="submit"]');
    const data = new FormData(form);
    const cv = data.get('cv');
    if (!(cv instanceof File) || cv.size === 0) { if (status) status.textContent = 'Adjunta tu hoja de vida.'; return; }
    if (cv.size > 5 * 1024 * 1024) { if (status) status.textContent = 'El archivo no puede superar 5 MB.'; return; }
    const payload = { nombres:String(data.get('nombres') ?? ''), apellidos:String(data.get('apellidos') ?? ''), email:String(data.get('email') ?? ''), telefono:String(data.get('telefono') ?? ''), ciudad:String(data.get('ciudad') ?? ''), honeypot:String(data.get('honeypot') ?? '') };
    if (button) button.disabled = true; if (status) { status.hidden = false; status.className = 'status'; status.textContent = 'Enviando postulacion…'; }
    try { await publicApi.postular(form.dataset.convocatoriaId ?? '', payload, cv, crypto.randomUUID()); form.reset(); if (status) status.textContent = 'Recibimos tu postulacion. Gracias por confiar en nosotros.'; }
    catch (error) { if (status) { status.className = 'status error'; status.textContent = error instanceof PublicApiError && error.status === 429 ? 'Alcanzaste el limite de envios. Intenta mas tarde.' : error instanceof PublicApiError && error.status === 409 ? 'Esta postulacion ya fue recibida.' : 'No pudimos enviar tu postulacion. Revisa los datos e intenta nuevamente.'; } }
    finally { if (button) button.disabled = false; }
  });
}
