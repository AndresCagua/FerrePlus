import { describe, it, expect } from 'vitest';
import { RUTAS_POR_PERMISO, permisosDeRuta } from '../core/rutas-por-permiso';
import { INDISPONIBILIDAD_TALENTO } from './shared/talento-error.mapper';

describe('RBAC y resiliencia de talento', () => {
  it('registra la ruta lazy con todos los permisos de lectura', () => { const permisos = permisosDeRuta('/talento'); expect(RUTAS_POR_PERMISO.some(r => r.route === '/talento')).toBe(true); expect(permisos).toContain('TALENTO_PUBLICACIONES_VER'); expect(permisos).toContain('CONTABILIDAD_CONTACTOS_VER'); });
  it('mantiene el literal de fallback contractual', () => { expect(INDISPONIBILIDAD_TALENTO).toBe('Servicio de postulaciones temporalmente no disponible'); });
});
