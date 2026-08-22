import { convertToParamMap } from '@angular/router';
import { Subject, of } from 'rxjs';
import { describe, expect, it, vi } from 'vitest';
import { PostulacionListComponent } from './postulacion-list.component';

describe('PostulacionListComponent', () => {
  it('carga la convocatoria cuando cambia el query param', () => {
    const queryParamMap = new Subject<ReturnType<typeof convertToParamMap>>();
    const service = { listarPostulaciones: vi.fn().mockReturnValue(of([])) };
    const component = new PostulacionListComponent(
      { queryParamMap } as never,
      service as never,
      { markForCheck: vi.fn() } as never,
    );

    component.ngOnInit();
    queryParamMap.next(convertToParamMap({ convocatoriaId: 'conv-1' }));

    expect(service.listarPostulaciones).toHaveBeenCalledWith('conv-1', undefined);
    expect(component.convocatoriaId).toBe('conv-1');
  });
});
