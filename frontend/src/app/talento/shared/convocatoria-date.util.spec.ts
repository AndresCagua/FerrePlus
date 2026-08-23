import { describe, expect, it } from 'vitest';
import { datetimeLocalToInstant, instantToDatetimeLocal } from './convocatoria-date.util';

describe('fechas de convocatoria', () => {
  it('convierte una fecha local del navegador a un instante ISO', () => {
    const instant = datetimeLocalToInstant('2026-08-20T10:00');
    expect(new Date(instant).getTime()).toBe(new Date(2026, 7, 20, 10, 0).getTime());
  });

  it('convierte un instante recibido al formato editable local', () => {
    expect(instantToDatetimeLocal(new Date(2026, 7, 20, 10, 0).toISOString())).toBe('2026-08-20T10:00');
  });

  it('rechaza fechas locales invalidas', () => {
    expect(() => datetimeLocalToInstant('2026-02-30T10:00')).toThrow();
  });
});
