import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TalentoService } from '../../../services/talento.service';
import { PublicacionPayload } from '../../../models/publicacion';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-publicacion-form', templateUrl: './publicacion-form.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PublicacionFormComponent implements OnInit {
  readonly id = this.route.snapshot.paramMap.get('id'); loading = false; saving = false; error = '';
  readonly form = this.fb.group({ slug: ['', [Validators.required, Validators.pattern(/^[a-z0-9-]+$/)]], titulo: ['', [Validators.required, Validators.maxLength(160)]], resumen: ['', [Validators.required, Validators.maxLength(300)]], descripcion: ['', Validators.required], categoria: [''], videoUrl: [''], fechaPublicacion: [''], fechaVencimiento: [''], seoTitle: ['', Validators.required], seoDescription: ['', Validators.required], canonical: [''] });
  constructor(private readonly fb: FormBuilder, private readonly route: ActivatedRoute, private readonly router: Router, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { if (this.id) this.service.obtenerPublicacion(this.id).subscribe({ next: p => this.form.patchValue({ ...p, seoTitle: p.metadataSEO?.title ?? '', seoDescription: p.metadataSEO?.description ?? '', canonical: p.metadataSEO?.canonical ?? '' }), error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
  save(): void { if (this.form.invalid) { this.form.markAllAsTouched(); return; } this.saving = true; const v = this.form.getRawValue(); const payload: PublicacionPayload = { slug: v.slug!, titulo: v.titulo!, resumen: v.resumen!, descripcion: v.descripcion!, categoria: v.categoria || undefined, videoUrl: v.videoUrl || null, estado: 'DRAFT', fechaPublicacion: v.fechaPublicacion || null, fechaVencimiento: v.fechaVencimiento || null, metadataSEO: { title: v.seoTitle!, description: v.seoDescription!, canonical: v.canonical || undefined } }; const request = this.id ? this.service.actualizarPublicacion(this.id, payload) : this.service.crearPublicacion(payload); request.subscribe({ next: () => this.router.navigate(['/talento/publicaciones']), error: err => { this.error = mensajeTalento(err); this.saving = false; this.cdr.markForCheck(); } }); }
}
