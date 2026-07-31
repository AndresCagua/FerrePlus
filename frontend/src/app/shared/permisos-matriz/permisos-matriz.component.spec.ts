import { SimpleChange } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatIconModule } from '@angular/material/icon';
import { describe, it, expect, beforeEach } from 'vitest';
import {
  PermisosMatrizComponent,
  buildOverrides,
  aplicarOverrides
} from './permisos-matriz.component';
import { Modulo } from '../../core/models';

const modulos: Modulo[] = [
  {
    id: 6,
    nombre: 'Ventas',
    codigo: 'VENTAS',
    orden: 6,
    permisos: [
      { id: 1, codigo: 'VENTAS_VER', nombre: 'Ver ventas', accion: 'VER' },
      { id: 2, codigo: 'VENTAS_CREAR', nombre: 'Crear ventas', accion: 'CREAR' }
    ]
  },
  {
    id: 8,
    nombre: 'Precios',
    codigo: 'PRECIOS',
    orden: 8,
    permisos: [{ id: 3, codigo: 'PRECIOS_VER', nombre: 'Ver precios', accion: 'VER' }]
  }
];

/**
 * El fixture raíz de `TestBed.createComponent` no tiene binding de template para
 * los inputs (en la app real los bindings los ponen rol-form/usuario-form), por
 * lo que `ngOnChanges` no se dispara con asignación directa en este entorno de
 * tests. Se sincroniza el ciclo de vida manualmente con un `SimpleChange`, que es
 * el mismo contrato que Angular usa con un template binding.
 */
function setChecked(component: PermisosMatrizComponent, checked: string[]): void {
  component.checked = checked;
  component.ngOnChanges({ checked: new SimpleChange(undefined, checked, true) });
}

describe('PermisosMatrizComponent', () => {
  let fixture: ComponentFixture<PermisosMatrizComponent>;
  let component: PermisosMatrizComponent;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [NoopAnimationsModule, MatCheckboxModule, MatExpansionModule, MatIconModule],
      declarations: [PermisosMatrizComponent]
    });
    fixture = TestBed.createComponent(PermisosMatrizComponent);
    component = fixture.componentInstance;
  });

  it('emite los códigos chequeados al marcar y desmarcar', () => {
    component.modulos = modulos;
    setChecked(component, ['VENTAS_VER']);
    fixture.detectChanges();

    const emitted: string[][] = [];
    component.change.subscribe(c => emitted.push(c));

    component.toggle('VENTAS_CREAR', true);
    expect(emitted[0]).toEqual(['VENTAS_VER', 'VENTAS_CREAR']);

    component.toggle('VENTAS_VER', false);
    expect(emitted[1]).toEqual(['VENTAS_CREAR']);
  });

  it('toggleAll marca y desmarca todas las acciones de un módulo', () => {
    component.modulos = modulos;
    setChecked(component, []);
    fixture.detectChanges();

    const emitted: string[][] = [];
    component.change.subscribe(c => emitted.push(c));

    component.toggleAll(modulos[0], true);
    expect(emitted[0]).toEqual(['VENTAS_VER', 'VENTAS_CREAR']);

    component.toggleAll(modulos[0], false);
    expect(emitted[1]).toEqual([]);
  });

  it('calcula el estado indeterminado cuando solo hay algunos marcados', () => {
    component.modulos = modulos;
    setChecked(component, ['VENTAS_VER']);
    fixture.detectChanges();

    // Ventas: uno de dos marcados → no chequeado, indeterminado
    expect(component.isModuleChecked(modulos[0])).toBe(false);
    expect(component.isModuleIndeterminate(modulos[0])).toBe(true);
    // Precios: ninguno marcado → ni chequeado ni indeterminado
    expect(component.isModuleChecked(modulos[1])).toBe(false);
    expect(component.isModuleIndeterminate(modulos[1])).toBe(false);
  });

  it('en modo usuario marca overrides de agregar/quitar respecto del rol base', () => {
    component.modulos = modulos;
    setChecked(component, ['VENTAS_VER', 'PRECIOS_VER']);
    component.rolPermisos = ['VENTAS_VER', 'VENTAS_CREAR'];
    component.modo = 'usuario';
    fixture.detectChanges();

    // PRECIOS_VER chequeado pero fuera del rol → agregado
    expect(component.isOverrideAdd('PRECIOS_VER')).toBe(true);
    expect(component.isOverrideRemove('PRECIOS_VER')).toBe(false);
    // VENTAS_CREAR en el rol pero desmarcado → quitado
    expect(component.isOverrideRemove('VENTAS_CREAR')).toBe(true);
    expect(component.isOverrideAdd('VENTAS_CREAR')).toBe(false);
    // VENTAS_VER chequeado y en el rol → sin override
    expect(component.isOverrideAdd('VENTAS_VER')).toBe(false);
    expect(component.isOverrideRemove('VENTAS_VER')).toBe(false);
  });

  it('en modo rol no calcula overrides', () => {
    component.modulos = modulos;
    setChecked(component, ['VENTAS_VER', 'PRECIOS_VER']);
    component.rolPermisos = ['VENTAS_VER', 'VENTAS_CREAR'];
    component.modo = 'rol';
    fixture.detectChanges();

    expect(component.isOverrideAdd('PRECIOS_VER')).toBe(false);
    expect(component.isOverrideRemove('VENTAS_CREAR')).toBe(false);
  });

  it('renderiza un checkbox por permiso', () => {
    component.modulos = modulos;
    setChecked(component, ['VENTAS_VER']);
    fixture.detectChanges();

    const checkboxes: NodeListOf<Element> = fixture.nativeElement.querySelectorAll(
      '.permiso-checkbox'
    );
    expect(checkboxes.length).toBe(3);
  });

  it('no muestra la sección "No hay módulos" cuando hay módulos', () => {
    component.modulos = modulos;
    setChecked(component, []);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.empty-state')).toBeNull();
  });
});

describe('buildOverrides (overrides relativos al rol base)', () => {
  it('checked fuera del rol → concedido true; desmarcado dentro del rol → concedido false; resto sin override', () => {
    const overrides = buildOverrides(['VENTAS_VER', 'PRECIOS_VER'], ['VENTAS_VER', 'VENTAS_CREAR']);
    expect(overrides).toEqual([
      { permisoCodigo: 'PRECIOS_VER', concedido: true },
      { permisoCodigo: 'VENTAS_CREAR', concedido: false }
    ]);
  });

  it('sin diferencias entre checked y rol base → sin overrides', () => {
    expect(buildOverrides(['A', 'B'], ['A', 'B'])).toEqual([]);
    expect(buildOverrides([], [])).toEqual([]);
  });
});

describe('aplicarOverrides (efectivos = rol ∪ concedidos ∖ denegados)', () => {
  it('reconstruye los efectivos sumando concedidos y quitando denegados', () => {
    const efectivos = aplicarOverrides(['VENTAS_VER', 'VENTAS_CREAR'], [
      { permisoCodigo: 'PRECIOS_VER', concedido: true },
      { permisoCodigo: 'VENTAS_CREAR', concedido: false }
    ]);
    expect(efectivos.sort()).toEqual(['PRECIOS_VER', 'VENTAS_VER']);
  });

  it('un override denegado gana aunque otro concedido lo agregue (∖ después de ∪)', () => {
    const efectivos = aplicarOverrides(['X', 'Y'], [
      { permisoCodigo: 'X', concedido: true },
      { permisoCodigo: 'X', concedido: false }
    ]);
    expect(efectivos).toEqual(['Y']);
  });

  it('sin overrides devuelve el rol base', () => {
    expect(aplicarOverrides(['A', 'B'], [])).toEqual(['A', 'B']);
  });
});
