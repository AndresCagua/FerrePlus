import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TalentoService } from '../../../services/talento.service';
import { fechaFinPosteriorAInicio } from '../../../shared/form-validators';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-convocatoria-form', templateUrl: './convocatoria-form.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class ConvocatoriaFormComponent {
  readonly id = this.route.snapshot.paramMap.get('id'); error = ''; saving = false;
  readonly form = this.fb.group({ titulo: ['', Validators.required], descripcion: ['', Validators.required], requisitos: ['', Validators.required], ubicacion: ['', Validators.required], modalidad: ['', Validators.required], fechaApertura: ['', Validators.required], fechaCierre: ['', Validators.required] }, { validators: fechaFinPosteriorAInicio });
  constructor(private readonly fb: FormBuilder, private readonly route: ActivatedRoute, private readonly router: Router, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) { if (this.id) this.service.obtenerConvocatoria(this.id).subscribe({ next: c => this.form.patchValue({ ...c, requisitos: c.requisitos.join('\n') }), error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
  save(): void { if (this.form.invalid) { this.form.markAllAsTouched(); return; } const v = this.form.getRawValue(); const payload = { titulo: v.titulo!, descripcion: v.descripcion!, requisitos: v.requisitos!.split('\n').map(x => x.trim()).filter(Boolean), ubicacion: v.ubicacion!, modalidad: v.modalidad!, fechaApertura: v.fechaApertura!, fechaCierre: v.fechaCierre!, estado: 'DRAFT' as const }; this.saving = true; const request = this.id ? this.service.actualizarConvocatoria(this.id, payload) : this.service.crearConvocatoria(payload); request.subscribe({ next: () => this.router.navigate(['/talento/convocatorias']), error: e => { this.error = mensajeTalento(e); this.saving = false; this.cdr.markForCheck(); } }); }
}
