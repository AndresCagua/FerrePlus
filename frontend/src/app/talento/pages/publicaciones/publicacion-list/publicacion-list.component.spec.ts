import { describe, expect, it } from 'vitest';
import { PublicacionListComponent } from './publicacion-list.component';

describe('PublicacionListComponent', () => {
  it('mantiene el listado sin helpers exclusivos de portada', () => {
    const compiledTemplate = (PublicacionListComponent as typeof PublicacionListComponent & {
      ɵcmp: { template?: () => unknown };
    }).ɵcmp.template?.toString() ?? '';

    expect(compiledTemplate).not.toContain('portada');
    expect(PublicacionListComponent.prototype).not.toHaveProperty('portadaUrl');
    expect(PublicacionListComponent.prototype).not.toHaveProperty('portadaFailed');
    expect(PublicacionListComponent.prototype).not.toHaveProperty('failedPortadas');
  });
});
