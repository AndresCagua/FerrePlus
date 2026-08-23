import { describe, expect, it } from 'vitest';
import {
  filtrarRutasPorPermiso,
  RUTAS_POR_PERMISO,
  RutaPorPermiso,
} from './rutas-por-permiso';

describe('RUTAS_POR_PERMISO', () => {
  it('asigna cada ruta administrativa exactamente a un modulo y deja Dashboard directo', () => {
    const directItems = RUTAS_POR_PERMISO.filter(item => !item.module);
    const modules = RUTAS_POR_PERMISO.filter(item => item.module);
    const assignedRoutes = modules.flatMap(module => module.children ?? []).map(item => item.route);

    expect(directItems.map(item => item.route)).toEqual(['/dashboard']);
    expect(modules.map(item => item.label)).toEqual(['Talento', 'Bodega', 'Contabilidad', 'Mantenimiento']);
    expect(new Set(assignedRoutes).size).toBe(assignedRoutes.length);
    expect(assignedRoutes).toHaveLength(18);
    expect(assignedRoutes).not.toContain('/dashboard');
  });

  it('conserva el padre virtual solo por descendientes autorizados', () => {
    const visible = filtrarRutasPorPermiso(RUTAS_POR_PERMISO, permissions =>
      permissions.includes('PRODUCTOS_VER')
    );
    const bodega = visible.find(item => item.label === 'Bodega');

    expect(bodega?.children?.map(item => item.route)).toEqual(['/productos']);
    expect(visible.some(item => item.label === 'Mantenimiento')).toBe(false);
  });

  it('elimina un padre cuando no conserva hijos visibles, aunque el padre no tenga permisos', () => {
    const module: RutaPorPermiso = {
      label: 'Mantenimiento',
      icon: 'build',
      route: '/mantenimiento',
      module: true,
      permissions: [],
      children: [{
        label: 'Logs', icon: 'receipt_long', route: '/logs', permissions: ['LOGS_VER']
      }]
    };

    expect(filtrarRutasPorPermiso([module], () => false)).toEqual([]);
  });
});
