import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TalentoService } from '../../../services/talento.service';
import { MediaImage, PublicacionPayload } from '../../../models/publicacion';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

export function normalizarSlug(titulo: string): string {
  const normalized = (titulo ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  if (!normalized) return 'publicacion';
  return normalized.split('-').reduce((result, token) => {
    const candidate = result ? `${result}-${token}` : token;
    return candidate.length <= 100 ? candidate : result;
  }, '');
}

@Component({ selector: 'app-publicacion-form', templateUrl: './publicacion-form.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PublicacionFormComponent implements OnInit {
  readonly id = this.route.snapshot.paramMap.get('id'); loading = false; saving = false; error = '';
  readonly form = this.fb.group({ slug: [''], titulo: ['', [Validators.required, Validators.maxLength(160)]], resumen: ['', [Validators.required, Validators.maxLength(300)]], descripcion: ['', Validators.required], categoria: [''], videoUrl: ['', Validators.pattern(/^https:\/\/(www\.)?(youtube\.com|youtu\.be)\//i)], enlacesX: [''], fechaPublicacion: [''], fechaVencimiento: [''], seoTitle: ['', Validators.required], seoDescription: ['', Validators.required], canonical: [''] });
  portada?: File;
  existingPortada?: MediaImage | null;
  portadaPreviewUrl = '';
  selectedPortadaName = '';
  galeria: File[] = [];
  readonly maxImageBytes = 5 * 1024 * 1024;
  readonly acceptedImageTypes = 'image/jpeg,image/png,image/webp';
  constructor(private readonly fb: FormBuilder, private readonly route: ActivatedRoute, private readonly router: Router, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.form.controls.titulo.valueChanges.subscribe(titulo => this.form.controls.slug.setValue(normalizarSlug(titulo ?? ''), { emitEvent: false })); if (this.id) this.service.obtenerPublicacion(this.id).subscribe({ next: p => { this.existingPortada = p.portada; this.form.patchValue({ slug: normalizarSlug(p.titulo), titulo: p.titulo, resumen: p.resumen, descripcion: p.descripcion, categoria: p.categoria ?? '', videoUrl: p.videoUrl ?? '', enlacesX: p.enlacesX?.join('\n') ?? '', fechaPublicacion: p.fechaPublicacion ?? '', fechaVencimiento: p.fechaVencimiento ?? '', seoTitle: p.metadataSEO?.title ?? '', seoDescription: p.metadataSEO?.description ?? '', canonical: p.metadataSEO?.canonical ?? '' }); this.cdr.markForCheck(); }, error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
  onPortada(event: Event): void { const file = (event.target as HTMLInputElement).files?.[0]; this.portada = this.validImage(file); this.selectedPortadaName = this.portada?.name ?? ''; this.portadaPreviewUrl = this.portada ? URL.createObjectURL(this.portada) : ''; }
  onGaleria(event: Event): void { this.galeria = Array.from((event.target as HTMLInputElement).files ?? []).map(file => this.validImage(file)).filter((file): file is File => !!file); }
  private validImage(file?: File): File | undefined { if (!file) return undefined; if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > this.maxImageBytes) { this.error = 'Usa imagenes JPG, PNG o WebP de hasta 5 MB.'; return undefined; } this.error = ''; return file; }
  existingPortadaUrl(): string | null { const key = this.existingPortada?.objectKey; return key && /^[0-9a-fA-F-]{36}\.(jpg|png|webp)$/.test(key) ? `/media/${encodeURIComponent(key)}` : null; }
  save(): void { if (this.form.invalid) { this.form.markAllAsTouched(); return; } this.saving = true; const v = this.form.getRawValue(); const payload: PublicacionPayload = { slug: v.slug!, titulo: v.titulo!, resumen: v.resumen!, descripcion: v.descripcion!, categoria: v.categoria || undefined, videoUrl: v.videoUrl || null, enlacesX: (v.enlacesX ?? '').split(/\r?\n|,/).map(url => url.trim()).filter(Boolean), estado: 'DRAFT', fechaPublicacion: v.fechaPublicacion || null, fechaVencimiento: v.fechaVencimiento || null, metadataSEO: { title: v.seoTitle!, description: v.seoDescription!, canonical: v.canonical || undefined } }; const request = this.id ? this.service.actualizarPublicacion(this.id, payload, this.portada, this.galeria) : this.service.crearPublicacion(payload, this.portada, this.galeria); request.subscribe({ next: () => this.router.navigate(['/talento/publicaciones']), error: err => { this.error = mensajeTalento(err); this.saving = false; this.cdr.markForCheck(); } }); }
}
