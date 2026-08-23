import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

export const fechaFinPosteriorAInicio: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const inicio = control.get('fechaApertura')?.value;
  const fin = control.get('fechaCierre')?.value;
  return inicio && fin && new Date(fin) <= new Date(inicio) ? { rangoFechasInvalido: true } : null;
};
