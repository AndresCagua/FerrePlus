import { convertToParamMap } from '@angular/router';
import { Subject, of } from 'rxjs';
import { describe, expect, it, vi } from 'vitest';
import { PostulacionListComponent } from './postulacion-list.component';

describe('PostulacionListComponent', () => {
  it('carga la convocatoria cuando cambia el query param', () => {
    const queryParamMap = new Subject<ReturnType<typeof convertToParamMap>>();
    const service = { listarConvocatorias: vi.fn().mockReturnValue(of([])), listarPostulaciones: vi.fn().mockReturnValue(of([])) };
    const component = new PostulacionListComponent(
      { queryParamMap } as never,
      { navigate: vi.fn() } as never,
      service as never,
      { markForCheck: vi.fn() } as never,
    );

    component.ngOnInit();
    queryParamMap.next(convertToParamMap({ convocatoriaId: 'conv-1' }));

    expect(service.listarConvocatorias).toHaveBeenCalled();
    expect(service.listarPostulaciones).toHaveBeenCalledWith('conv-1', undefined);
    expect(component.convocatoriaId).toBe('conv-1');
  });

  it('cambia la convocatoria conservando los parametros existentes', () => {
    const router = { navigate: vi.fn() };
    const service = { listarConvocatorias: vi.fn().mockReturnValue(of([])), listarPostulaciones: vi.fn().mockReturnValue(of([])) };
    const component = new PostulacionListComponent({} as never, router as never, service as never, { markForCheck: vi.fn() } as never);

    component.selectConvocatoria('conv-2');

    expect(router.navigate).toHaveBeenCalledWith([], expect.objectContaining({ queryParams: { convocatoriaId: 'conv-2' }, queryParamsHandling: 'merge' }));
  });
});
