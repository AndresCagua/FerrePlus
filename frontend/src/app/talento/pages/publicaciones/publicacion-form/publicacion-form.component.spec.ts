import { FormBuilder } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { of, Subject, throwError } from 'rxjs';
import { describe, expect, it, vi } from 'vitest';
import { MENSAJE_ENLACE_X_INVALIDO, normalizarSlug, PublicacionFormComponent, validarEnlacesX } from './publicacion-form.component';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

describe('PublicacionFormComponent', () => {
  it('preview slug follows the backend normalization rules', () => {
    expect(normalizarSlug('Talento: Niño Técnico / Bogotá')).toBe('talento-nino-tecnico-bogota');
    expect(normalizarSlug('***')).toBe('publicacion');
  });

  it('acepta unicamente URLs HTTPS de x.com o twitter.com', () => {
    expect(validarEnlacesX({ value: 'https://x.com/ferreplus\nhttps://TWITTER.com/ferreplus' } as never)).toBeNull();
    expect(validarEnlacesX({ value: 'https://facebook.com/ferreplus' } as never)).toEqual({ enlacesX: MENSAJE_ENLACE_X_INVALIDO });
    expect(validarEnlacesX({ value: 'https://x.com.evil.example/ferreplus' } as never)).toEqual({ enlacesX: MENSAJE_ENLACE_X_INVALIDO });
  });

  it('no envia la publicacion cuando un enlace X es invalido', () => {
    const service = { crearPublicacion: vi.fn() };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => null } } } as never,
      { navigate: vi.fn() } as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion', enlacesX: 'https://facebook.com/ferreplus' });

    component.save();

    expect(component.form.controls.enlacesX.invalid).toBe(true);
    expect(component.form.controls.enlacesX.errors?.['enlacesX']).toBe(MENSAJE_ENLACE_X_INVALIDO);
    expect(service.crearPublicacion).not.toHaveBeenCalled();
  });

  it('muestra el error de campo que devuelve el backend sin exponer detalles internos', () => {
    const error = new HttpErrorResponse({ status: 400, error: {
      detail: 'El enlace de X no es valido. Usa una URL de x.com o twitter.com.',
      errors: { enlacesX: 'El enlace de X no es valido. Usa una URL de x.com o twitter.com.' },
      stackTrace: 'secret',
    } });

    expect(mensajeTalento(error)).toBe(MENSAJE_ENLACE_X_INVALIDO);
    expect(mensajeTalento(error)).not.toContain('secret');
  });

  function createComponent() {
    const service = { obtenerPublicacion: vi.fn().mockReturnValue(of({ portada: { objectKey: '550e8400-e29b-41d4-a716-446655440000.webp' } })) };
    const component = new PublicacionFormComponent(
      new FormBuilder(),
      { snapshot: { paramMap: { get: () => 'pub-1' } } } as never,
      {} as never,
      service as never,
      { markForCheck: vi.fn() } as never,
    );
    return { component, service };
  }

  it('muestra la portada existente sin convertirla en un reemplazo', () => {
    const { component, service } = createComponent();

    component.ngOnInit();

    expect(service.obtenerPublicacion).toHaveBeenCalledWith('pub-1');
    expect(component.existingPortadaUrl()).toContain('/media/550e8400-e29b-41d4-a716-446655440000.webp');
    expect(component.portada).toBeUndefined();
  });

  it('rechaza tipos de imagen o tamanos que el backend no acepta', () => {
    const { component } = createComponent();
    const file = new File(['contenido'], 'portada.gif', { type: 'image/gif' });

    component.onPortada({ target: { files: [file] } } as unknown as Event);

    expect(component.portada).toBeUndefined();
    expect(component.error).toContain('JPG, PNG o WebP');
  });

  it('rellena SEO con IA y bloquea solicitudes duplicadas mientras carga', () => {
    const response = new Subject<{ title: string; description: string }>();
    const service = {
      obtenerPublicacion: vi.fn().mockReturnValue(of({ portada: null })),
      sugerirSeo: vi.fn().mockReturnValue(response.asObservable()),
    };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => 'pub-1' } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });

    component.generateSeo();
    component.generateSeo();
    response.next({ title: 'Titulo sugerido', description: 'Descripcion sugerida' });

    expect(service.sugerirSeo).toHaveBeenCalledTimes(1);
    expect(component.form.controls.seoTitle.value).toBe('Titulo sugerido');
    expect(component.form.controls.seoDescription.value).toBe('Descripcion sugerida');
  });

  it('mantiene el guardado manual disponible cuando la IA falla', () => {
    const service = {
      obtenerPublicacion: vi.fn().mockReturnValue(of({ portada: null })),
      sugerirSeo: vi.fn()
        .mockReturnValueOnce(throwError(() => new Error('network failure')))
        .mockReturnValueOnce(of({ title: 'Reintento SEO', description: 'Descripcion reintentada' })),
    };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => 'pub-1' } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });

    component.generateSeo();

    expect(component.seoLoading).toBe(false);
    expect(component.seoError).toContain('No se pudo generar SEO');
    expect(component.saving).toBe(false);

    component.generateSeo();

    expect(component.form.controls.seoTitle.value).toBe('Reintento SEO');
    expect(component.form.controls.seoDescription.value).toBe('Descripcion reintentada');
    expect(service.sugerirSeo).toHaveBeenCalledTimes(2);
  });

  it('marca como incompleta una respuesta sin ambos campos SEO', () => {
    const service = {
      obtenerPublicacion: vi.fn().mockReturnValue(of({ portada: null })),
      sugerirSeo: vi.fn().mockReturnValue(of({ title: 'Solo titulo', description: '' })),
    };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => 'pub-1' } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });

    component.generateSeo();

    expect(component.seoError).toContain('incompleta');
    expect(component.form.controls.seoTitle.value).toBe('');
  });

  it('genera SEO automaticamente en un formulario nuevo cuando el contenido esta completo', () => {
    vi.useFakeTimers();
    const service = {
      sugerirSeo: vi.fn().mockReturnValue(of({ title: 'SEO automatico', description: 'Descripcion SEO' })),
      crearPublicacion: vi.fn(),
    };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => null } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();

    component.form.controls.titulo.setValue('Titulo');
    component.form.controls.resumen.setValue('Resumen');
    expect(service.sugerirSeo).not.toHaveBeenCalled();
    component.form.controls.descripcion.setValue('Descripcion');
    vi.advanceTimersByTime(300);

    expect(service.sugerirSeo).toHaveBeenCalledTimes(1);
    expect(component.form.controls.seoTitle.value).toBe('SEO automatico');
    vi.useRealTimers();
  });

  it('no reintenta automaticamente despues de un fallo, pero permite reintento manual', () => {
    vi.useFakeTimers();
    const service = {
      sugerirSeo: vi.fn()
        .mockReturnValueOnce(throwError(() => new Error('network failure')))
        .mockReturnValueOnce(of({ title: 'SEO reintentado', description: 'Descripcion reintentada' })),
    };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => null } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });

    vi.advanceTimersByTime(300);

    expect(service.sugerirSeo).toHaveBeenCalledTimes(1);
    expect(component.seoError).toContain('No se pudo generar SEO');

    component.generateSeo();

    expect(service.sugerirSeo).toHaveBeenCalledTimes(2);
    expect(component.form.controls.seoTitle.value).toBe('SEO reintentado');
    expect(component.form.controls.seoDescription.value).toBe('Descripcion reintentada');
    vi.useRealTimers();
  });

  it('no duplica la generacion automatica para el mismo contenido y conserva ediciones SEO', () => {
    vi.useFakeTimers();
    const response = new Subject<{ title: string; description: string }>();
    const service = { sugerirSeo: vi.fn().mockReturnValue(response.asObservable()) };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => null } } } as never,
      {} as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });
    vi.advanceTimersByTime(300);
    component.form.controls.seoTitle.setValue('SEO editado');
    response.next({ title: 'SEO IA', description: 'Descripcion IA' });
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });
    vi.advanceTimersByTime(300);

    expect(service.sugerirSeo).toHaveBeenCalledTimes(1);
    expect(component.form.controls.seoTitle.value).toBe('SEO editado');
    expect(component.form.controls.seoDescription.value).toBe('Descripcion IA');
    vi.useRealTimers();
  });

  it('permite guardar aunque falle la generacion SEO automatica', () => {
    vi.useFakeTimers();
    const service = {
      sugerirSeo: vi.fn().mockReturnValue(throwError(() => new Error('network failure'))),
      crearPublicacion: vi.fn().mockReturnValue(of({})),
    };
    const router = { navigate: vi.fn() };
    const component = new PublicacionFormComponent(
      new FormBuilder(), { snapshot: { paramMap: { get: () => null } } } as never,
      router as never, service as never, { markForCheck: vi.fn() } as never,
    );
    component.ngOnInit();
    component.form.patchValue({ titulo: 'Titulo', resumen: 'Resumen', descripcion: 'Descripcion' });
    vi.advanceTimersByTime(300);
    component.save();

    expect(service.crearPublicacion).toHaveBeenCalledTimes(1);
    vi.useRealTimers();
  });
});
