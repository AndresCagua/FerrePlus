import { describe, it, expect } from 'vitest';
import { formatearDetalle, parsearDetalle } from './detalle.util';

describe('detalle.util (formateo de detalle en presentación)', () => {
  describe('parsearDetalle', () => {
    it('devuelve entradas tipo diff para valores con antes/despues', () => {
      const entradas = parsearDetalle('{"precioVenta":{"antes":100,"despues":130}}');
      expect(entradas).toEqual([
        { campo: 'precioVenta', tipo: 'diff', antes: 100, despues: 130 }
      ]);
    });

    it('devuelve entradas tipo valor para snapshots (CREAR/ELIMINAR/ANULAR/LOGIN)', () => {
      const entradas = parsearDetalle('{"nombre":"Martillo","activo":false,"total":100}');
      expect(entradas).toEqual([
        { campo: 'nombre', tipo: 'valor', valor: 'Martillo' },
        { campo: 'activo', tipo: 'valor', valor: false },
        { campo: 'total', tipo: 'valor', valor: 100 }
      ]);
    });

    it('devuelve null para detalle null/undefined/vacío', () => {
      expect(parsearDetalle(null)).toBeNull();
      expect(parsearDetalle(undefined)).toBeNull();
      expect(parsearDetalle('')).toBeNull();
    });

    it('devuelve null para JSON inválido (fallback a string crudo)', () => {
      expect(parsearDetalle('texto no json')).toBeNull();
      expect(parsearDetalle('{not json}')).toBeNull();
    });

    it('devuelve null para JSON válido que no es un objeto plano (string/número/array)', () => {
      expect(parsearDetalle('"texto"')).toBeNull();
      expect(parsearDetalle('123')).toBeNull();
      expect(parsearDetalle('[1,2]')).toBeNull();
    });
  });

  describe('formatearDetalle', () => {
    it('formatea un diff como "campo: antes -> despues"', () => {
      expect(formatearDetalle('{"precioVenta":{"antes":100,"despues":130}}')).toBe(
        'precioVenta: 100 -> 130'
      );
    });

    it('formatea un snapshot como "campo: valor" en líneas separadas', () => {
      expect(formatearDetalle('{"nombre":"Martillo","activo":false}')).toBe(
        'nombre: Martillo\nactivo: false'
      );
    });

    it('mezcla diffs y valores en el mismo detalle', () => {
      const texto = formatearDetalle(
        '{"precioVenta":{"antes":100,"despues":130},"margen":30}'
      );
      expect(texto).toBe('precioVenta: 100 -> 130\nmargen: 30');
    });

    it('serializa valores objeto/array como JSON compacto en un snapshot', () => {
      expect(formatearDetalle('{"cliente":{"id":1,"nombre":"X"}}')).toBe(
        'cliente: {"id":1,"nombre":"X"}'
      );
    });

    it('muestra "—" cuando detalle es null/undefined/vacío', () => {
      expect(formatearDetalle(null)).toBe('—');
      expect(formatearDetalle(undefined)).toBe('—');
      expect(formatearDetalle('')).toBe('—');
    });

    it('muestra el string crudo cuando JSON es inválido', () => {
      expect(formatearDetalle('detalle de auditoría en texto plano')).toBe(
        'detalle de auditoría en texto plano'
      );
      expect(formatearDetalle('{mal}')).toBe('{mal}');
    });

    it('muestra el string crudo cuando JSON válido no es un objeto plano', () => {
      expect(formatearDetalle('"solo texto"')).toBe('"solo texto"');
      expect(formatearDetalle('[1,2]')).toBe('[1,2]');
    });
  });
});
