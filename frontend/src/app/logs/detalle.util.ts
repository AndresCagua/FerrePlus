/**
 * Presentación legible del campo `detalle` de un log de auditoría (CHANGE 3).
 *
 * El backend envía `detalle` como string JSON crudo en una de dos formas:
 *  - ACTUALIZAR (diff): `{"campo": {"antes": X, "despues": Y}, ...}` — solo campos cambiados.
 *  - CREAR/ELIMINAR/ANULAR/LOGIN (snapshot): `{"campo": valor, ...}`.
 *
 * El JSON crudo se conserva en la API; este módulo SOLO formatea para presentación.
 * Es un helper puro (sin DOM) para poder testearlo de forma unitaria.
 */

/** Entrada formateada de un log: o bien un diff (antes/despues) o un valor simple. */
export interface DetalleEntrada {
  campo: string;
  tipo: 'diff' | 'valor';
  antes?: unknown;
  despues?: unknown;
  valor?: unknown;
}

/**
 * Parseo seguro de `detalle`. Devuelve `null` cuando NO se puede presentar como
 * objeto (detalle ausente, JSON inválido, o JSON válido que no es un objeto plano),
 * en cuyo caso la presentación muestra el string crudo.
 */
export function parsearDetalle(detalle: string | null | undefined): DetalleEntrada[] | null {
  if (detalle === null || detalle === undefined || detalle === '') {
    return null;
  }

  let parseado: unknown;
  try {
    parseado = JSON.parse(detalle);
  } catch {
    return null; // JSON inválido → mostrar raw string.
  }

  if (typeof parseado !== 'object' || parseado === null || Array.isArray(parseado)) {
    return null; // No es un objeto plano → mostrar raw string.
  }

  return Object.entries(parseado).map(([campo, valor]) => {
    const esDiff = esDiffAntesDespues(valor);
    if (esDiff) {
      const diff = valor as Record<string, unknown>;
      return { campo, tipo: 'diff', antes: diff['antes'], despues: diff['despues'] };
    }
    return { campo, tipo: 'valor', valor };
  });
}

/**
 * Formatea `detalle` para presentación:
 *  - `null`/vacío → `—`.
 *  - JSON inválido o no-objeto → string crudo.
 *  - Objeto → una línea por campo: `campo: antes -> despues` (diff) o `campo: valor`.
 */
export function formatearDetalle(detalle: string | null | undefined): string {
  const entradas = parsearDetalle(detalle);
  if (entradas === null) {
    if (detalle === null || detalle === undefined || detalle === '') {
      return '—';
    }
    return detalle; // raw string.
  }
  if (entradas.length === 0) {
    return '—'; // Objeto vacío `{}`.
  }
  return entradas.map(formatearEntrada).join('\n');
}

/** Detecta un diff: valor es un objeto con AMBAS claves `antes` y `despues`. */
function esDiffAntesDespues(valor: unknown): boolean {
  return (
    typeof valor === 'object' &&
    valor !== null &&
    !Array.isArray(valor) &&
    'antes' in (valor as Record<string, unknown>) &&
    'despues' in (valor as Record<string, unknown>)
  );
}

function formatearEntrada(entrada: DetalleEntrada): string {
  if (entrada.tipo === 'diff') {
    return `${entrada.campo}: ${formatearValor(entrada.antes)} -> ${formatearValor(entrada.despues)}`;
  }
  return `${entrada.campo}: ${formatearValor(entrada.valor)}`;
}

function formatearValor(valor: unknown): string {
  if (valor === null || valor === undefined) {
    return 'null';
  }
  if (typeof valor === 'object') {
    return JSON.stringify(valor); // objeto anidado en snapshot → JSON compacto.
  }
  return String(valor);
}
