import { publicApi } from '../../lib/api-client/public-api';
import { PublicApiError } from '../../lib/api-client/types';

export function setupContactForm(form: HTMLFormElement): void {
  const status = form.querySelector<HTMLElement>('[data-status]');
  form.addEventListener('submit', async (event) => {
    event.preventDefault(); if (!form.reportValidity()) return;
    const button = form.querySelector<HTMLButtonElement>('button[type="submit"]'); const data = new FormData(form);
    const payload = { nombre:String(data.get('nombre') ?? ''), email:String(data.get('email') ?? ''), telefono:String(data.get('telefono') ?? ''), asunto:String(data.get('asunto') ?? ''), mensaje:String(data.get('mensaje') ?? ''), honeypot:String(data.get('honeypot') ?? '') };
    if (button) button.disabled = true; if (status) { status.hidden = false; status.className = 'status'; status.textContent = 'Enviando mensaje…'; }
    try { await publicApi.contactar(payload, crypto.randomUUID()); form.reset(); if (status) status.textContent = 'Tu mensaje fue recibido. Te responderemos pronto.'; }
    catch (error) { if (status) { status.className = 'status error'; status.textContent = error instanceof PublicApiError && error.status === 429 ? 'Alcanzaste el limite de envios. Intenta mas tarde.' : 'No pudimos enviar tu mensaje. Intenta nuevamente.'; } }
    finally { if (button) button.disabled = false; }
  });
}
