import { FormControl, FormGroup } from '@angular/forms';
import { describe, it, expect } from 'vitest';
import { fechaFinPosteriorAInicio } from './form-validators';

describe('validadores de talento', () => {
  it('rechaza una fecha de cierre anterior o igual a la apertura', () => { const form = new FormGroup({ fechaApertura: new FormControl('2026-08-20T10:00'), fechaCierre: new FormControl('2026-08-20T09:00') }); expect(fechaFinPosteriorAInicio(form)).toEqual({ rangoFechasInvalido: true }); });
  it('acepta un periodo valido', () => { const form = new FormGroup({ fechaApertura: new FormControl('2026-08-20T10:00'), fechaCierre: new FormControl('2026-08-20T11:00') }); expect(fechaFinPosteriorAInicio(form)).toBeNull(); });
});
