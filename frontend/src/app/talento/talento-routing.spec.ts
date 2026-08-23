import { describe, it, expect } from 'vitest';
import {
  filtrarRutasPorPermiso,
  RUTAS_POR_PERMISO,
  permisosDeRuta
} from '../core/rutas-por-permiso';
import { INDISPONIBILIDAD_TALENTO } from './shared/talento-error.mapper';

describe('RBAC y resiliencia de talento', () => {
  it('registra la ruta lazy con los permisos de lectura de Talento', () => { const permisos = permisosDeRuta('/talento'); expect(RUTAS_POR_PERMISO.some(r => r.route === '/talento')).toBe(true); expect(permisos).toContain('TALENTO_PUBLICACIONES_VER'); expect(permisos).not.toContain('CONTABILIDAD_CONTACTOS_VER'); });
  it('expone las secciones de talento como submenu', () => {
    const talento = RUTAS_POR_PERMISO.find(ruta => ruta.route === '/talento');

    expect(talento?.children?.map(child => child.label)).toEqual([
      'Publicaciones',
      'Convocatorias laborales',
      'Postulaciones',
      'Destinatarios'
    ]);
  });
  it('asigna Contactos a Contabilidad sin cambiar su URL', () => {
    const contabilidad = RUTAS_POR_PERMISO.find(ruta => ruta.label === 'Contabilidad');
    expect(contabilidad?.children?.find(child => child.route === '/talento/contactos')).toMatchObject({
      label: 'Contactos',
      permissions: ['CONTABILIDAD_CONTACTOS_VER']
    });
  });
  it('filtra los hijos de Contabilidad por permiso y conserva el grupo visible', () => {
    const visible = filtrarRutasPorPermiso(RUTAS_POR_PERMISO, permissions =>
      permissions.includes('CONTABILIDAD_CONTACTOS_VER')
    );
    const contabilidad = visible.find(ruta => ruta.label === 'Contabilidad');

    expect(contabilidad?.children?.map(child => child.route)).toEqual(['/talento/contactos']);
  });
  it('mantiene el literal de fallback contractual', () => { expect(INDISPONIBILIDAD_TALENTO).toBe('Servicio de postulaciones temporalmente no disponible'); });
});
