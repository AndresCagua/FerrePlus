import { FormBuilder } from '@angular/forms';
import { of } from 'rxjs';
import { describe, expect, it, vi } from 'vitest';
import { normalizarSlug, PublicacionFormComponent } from './publicacion-form.component';

describe('PublicacionFormComponent', () => {
  it('preview slug follows the backend normalization rules', () => {
    expect(normalizarSlug('Talento: Niño Técnico / Bogotá')).toBe('talento-nino-tecnico-bogota');
    expect(normalizarSlug('***')).toBe('publicacion');
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
});
