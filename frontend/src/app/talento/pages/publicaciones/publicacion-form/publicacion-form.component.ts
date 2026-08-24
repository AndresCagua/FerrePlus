import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, ValidationErrors, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
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

export const MENSAJE_ENLACE_X_INVALIDO = 'El enlace de X no es valido. Usa una URL de x.com o twitter.com.';

export function validarEnlacesX(control: AbstractControl): ValidationErrors | null {
  const enlaces = String(control.value ?? '').split(/\r?\n|,/).map(url => url.trim()).filter(Boolean);
  const invalid = enlaces.some(enlace => {
    try {
      const url = new URL(enlace);
      return url.protocol !== 'https:' || !['x.com', 'twitter.com'].includes(url.hostname.toLowerCase());
    } catch {
      return true;
    }
  });
  return invalid ? { enlacesX: MENSAJE_ENLACE_X_INVALIDO } : null;
}

@Component({ selector: 'app-publicacion-form', templateUrl: './publicacion-form.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PublicacionFormComponent implements OnInit, OnDestroy {
  readonly id = this.route.snapshot.paramMap.get('id'); loading = false; saving = false; error = '';
  seoLoading = false; seoError = '';
  readonly form = this.fb.group({ slug: [''], titulo: ['', [Validators.required, Validators.maxLength(160)]], resumen: ['', [Validators.required, Validators.maxLength(300)]], descripcion: ['', Validators.required], categoria: [''], videoUrl: ['', Validators.pattern(/^https:\/\/(www\.)?(youtube\.com|youtu\.be)\//i)], enlacesX: ['', validarEnlacesX], fechaPublicacion: [''], fechaVencimiento: [''], seoTitle: ['', Validators.maxLength(200)], seoDescription: ['', Validators.maxLength(500)], canonical: [''] });
  portada?: File;
  existingPortada?: MediaImage | null;
  portadaPreviewUrl = '';
  selectedPortadaName = '';
  galeria: File[] = [];
  private seoDebounceHandle?: ReturnType<typeof setTimeout>;
  private lastAutomaticSeoSource = '';
  private seoTitleManuallyEdited = false;
  private seoDescriptionManuallyEdited = false;
  private seoPatchInProgress = false;
  private readonly destroy$ = new Subject<void>();
  readonly maxImageBytes = 5 * 1024 * 1024;
  readonly acceptedImageTypes = 'image/jpeg,image/png,image/webp';
  constructor(private readonly fb: FormBuilder, private readonly route: ActivatedRoute, private readonly router: Router, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void {
    this.form.controls.titulo.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(titulo => {
      this.form.controls.slug.setValue(normalizarSlug(titulo ?? ''), { emitEvent: false });
      this.scheduleAutomaticSeo();
    });
    this.form.controls.resumen.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => this.scheduleAutomaticSeo());
    this.form.controls.descripcion.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => this.scheduleAutomaticSeo());
    this.form.controls.seoTitle.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => {
      if (!this.seoPatchInProgress) this.seoTitleManuallyEdited = true;
    });
    this.form.controls.seoDescription.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => {
      if (!this.seoPatchInProgress) this.seoDescriptionManuallyEdited = true;
    });
    if (this.id) this.service.obtenerPublicacion(this.id).subscribe({ next: p => { this.existingPortada = p.portada; this.form.patchValue({ slug: normalizarSlug(p.titulo), titulo: p.titulo, resumen: p.resumen, descripcion: p.descripcion, categoria: p.categoria ?? '', videoUrl: p.videoUrl ?? '', enlacesX: p.enlacesX?.join('\n') ?? '', fechaPublicacion: p.fechaPublicacion ?? '', fechaVencimiento: p.fechaVencimiento ?? '', seoTitle: p.metadataSEO?.title ?? '', seoDescription: p.metadataSEO?.description ?? '', canonical: p.metadataSEO?.canonical ?? '' }); this.cdr.markForCheck(); }, error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } });
  }
  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); if (this.seoDebounceHandle) clearTimeout(this.seoDebounceHandle); }
  onPortada(event: Event): void { const file = (event.target as HTMLInputElement).files?.[0]; this.portada = this.validImage(file); this.selectedPortadaName = this.portada?.name ?? ''; this.portadaPreviewUrl = this.portada ? URL.createObjectURL(this.portada) : ''; }
  onGaleria(event: Event): void { this.galeria = Array.from((event.target as HTMLInputElement).files ?? []).map(file => this.validImage(file)).filter((file): file is File => !!file); }
  private validImage(file?: File): File | undefined { if (!file) return undefined; if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > this.maxImageBytes) { this.error = 'Usa imagenes JPG, PNG o WebP de hasta 5 MB.'; return undefined; } this.error = ''; return file; }
  existingPortadaUrl(): string | null { const key = this.existingPortada?.objectKey; return key && /^[0-9a-fA-F-]{36}\.(jpg|png|webp)$/.test(key) ? `/media/${encodeURIComponent(key)}` : null; }
  private sourceContent(): { titulo: string; resumen: string; descripcion: string; key: string } | null {
    const value = this.form.getRawValue();
    const titulo = value.titulo?.trim() ?? '';
    const resumen = value.resumen?.trim() ?? '';
    const descripcion = value.descripcion?.trim() ?? '';
    if (!titulo || !resumen || !descripcion) return null;
    return { titulo, resumen, descripcion, key: `${titulo}\u0000${resumen}\u0000${descripcion}` };
  }
  private scheduleAutomaticSeo(): void {
    if (this.id) return;
    const source = this.sourceContent();
    if (!source || source.key === this.lastAutomaticSeoSource) {
      if (this.seoDebounceHandle) clearTimeout(this.seoDebounceHandle);
      return;
    }
    if (this.seoDebounceHandle) clearTimeout(this.seoDebounceHandle);
    this.seoDebounceHandle = setTimeout(() => {
      this.seoDebounceHandle = undefined;
      const current = this.sourceContent();
      if (!current || current.key === this.lastAutomaticSeoSource || this.seoLoading) return;
      this.lastAutomaticSeoSource = current.key;
      this.generateSeo(false, current);
    }, 300);
  }
  generateSeo(manual = true, requestedSource?: { titulo: string; resumen: string; descripcion: string; key: string }): void {
    if (this.seoLoading) return;
    const source = requestedSource ?? this.sourceContent();
    if (!source) {
      this.seoError = 'Completa titulo, resumen y descripcion antes de generar SEO.';
      this.cdr.markForCheck();
      return;
    }
    this.seoLoading = true;
    this.seoError = '';
    this.service.sugerirSeo({ titulo: source.titulo, resumen: source.resumen, descripcion: source.descripcion }).subscribe({
      next: suggestion => {
        if (!suggestion?.title?.trim() || !suggestion?.description?.trim()) {
          this.seoError = 'La IA devolvio una sugerencia incompleta. Puedes reintentar o editar los campos manualmente.';
        } else {
          const current = this.sourceContent();
          if (manual || current?.key === source.key) {
            this.seoPatchInProgress = true;
            const seoPatch: { seoTitle?: string; seoDescription?: string } = {};
            if (manual || !this.seoTitleManuallyEdited) seoPatch.seoTitle = suggestion.title.trim();
            if (manual || !this.seoDescriptionManuallyEdited) seoPatch.seoDescription = suggestion.description.trim();
            this.form.patchValue(seoPatch, { emitEvent: false });
            this.seoPatchInProgress = false;
          }
         }
         this.seoLoading = false;
         this.cdr.markForCheck();
       },
       error: () => {
         this.seoError = 'No se pudo generar SEO. Verifica el contenido o reintenta.';
         this.seoLoading = false;
         this.cdr.markForCheck();
       },
    });
  }
  save(): void { if (this.form.invalid) { this.form.markAllAsTouched(); return; } this.saving = true; const v = this.form.getRawValue(); const metadataSEO = v.seoTitle || v.seoDescription || v.canonical ? { title: v.seoTitle || '', description: v.seoDescription || '', canonical: v.canonical || undefined } : undefined; const payload: PublicacionPayload = { slug: v.slug!, titulo: v.titulo!, resumen: v.resumen!, descripcion: v.descripcion!, categoria: v.categoria || undefined, videoUrl: v.videoUrl || null, enlacesX: (v.enlacesX ?? '').split(/\r?\n|,/).map(url => url.trim()).filter(Boolean), estado: 'DRAFT', fechaPublicacion: v.fechaPublicacion || null, fechaVencimiento: v.fechaVencimiento || null, metadataSEO }; const request = this.id ? this.service.actualizarPublicacion(this.id, payload, this.portada, this.galeria) : this.service.crearPublicacion(payload, this.portada, this.galeria); request.subscribe({ next: () => this.router.navigate(['/talento/publicaciones']), error: err => { this.error = mensajeTalento(err); this.saving = false; this.cdr.markForCheck(); } }); }
}
