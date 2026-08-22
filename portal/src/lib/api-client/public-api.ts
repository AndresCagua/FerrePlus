import type { ApplicationData, ContactData, Convocatoria, Publicacion } from './types';
import { PublicApiError } from './types';

const buildTimeBaseUrl = (import.meta.env.PUBLIC_API_URL ?? '').replace(/\/$/, '');
const timeoutMs = 8000;

function apiBaseUrl(): string {
  return typeof window === 'undefined' ? buildTimeBaseUrl : '';
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${apiBaseUrl()}${path}`, {
      cache: 'no-store',
      ...init,
      signal: controller.signal,
    });
    const body = await response.json().catch(() => null);
    if (!response.ok) {
      throw new PublicApiError(response.status, body?.detail ?? 'No fue posible completar la solicitud.', body?.errors);
    }
    return body as T;
  } catch (error) {
    if (error instanceof PublicApiError) throw error;
    throw new PublicApiError(0, 'El servicio publico no esta disponible en este momento.');
  } finally {
    clearTimeout(timeout);
  }
}

export const publicApi = {
  publicaciones: () => request<Publicacion[]>('/api/public/publicaciones'),
  publicacion: (slug: string) => request<Publicacion>(`/api/public/publicaciones/${encodeURIComponent(slug)}`),
  convocatorias: () => request<Convocatoria[]>('/api/public/convocatorias'),
  convocatoria: (id: string) => request<Convocatoria>(`/api/public/convocatorias/${encodeURIComponent(id)}`),
  postular: (id: string, data: ApplicationData, cv: File, idempotencyKey: string) => {
    const form = new FormData();
    form.append('data', new Blob([JSON.stringify(data)], { type: 'application/json' }));
    form.append('cv', cv);
    return request('/api/public/convocatorias/' + encodeURIComponent(id) + '/postulaciones', {
      method: 'POST', headers: { 'Idempotency-Key': idempotencyKey }, body: form,
    });
  },
  contactar: (data: ContactData, idempotencyKey: string) => request('/api/public/contactos', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'Idempotency-Key': idempotencyKey }, body: JSON.stringify(data),
  }),
};
