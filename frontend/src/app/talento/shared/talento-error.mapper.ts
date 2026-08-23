import { HttpErrorResponse } from '@angular/common/http';

export const INDISPONIBILIDAD_TALENTO = 'Servicio de postulaciones temporalmente no disponible';

export function esDependenciaNoDisponible(error: unknown): boolean {
  if (error instanceof HttpErrorResponse) {
    return error.status === 0 || error.status === 502 || error.status === 503 || error.status === 504;
  }
  return error instanceof Error && /timeout|network|unavailable/i.test(error.message);
}

export function mensajeTalento(error: unknown): string {
  return esDependenciaNoDisponible(error)
    ? INDISPONIBILIDAD_TALENTO
    : mensajeErrorApi(error) ?? 'No se pudo completar la operacion. Intenta nuevamente.';
}

function mensajeErrorApi(error: unknown): string | null {
  if (!(error instanceof HttpErrorResponse)) return null;
  const detail = error.error?.detail;
  const fieldErrors = error.error?.errors;
  if (fieldErrors && typeof fieldErrors === 'object') {
    const messages = Object.values(fieldErrors).filter((message): message is string => typeof message === 'string');
    if (messages.length) return messages.join(' ');
  }
  return typeof detail === 'string' ? detail : null;
}
