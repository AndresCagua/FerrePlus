import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  OnChanges,
  Output,
  SimpleChanges
} from '@angular/core';
import { Modulo, UsuarioPermisoOverride } from '../../core/models';

/**
 * Calcula la lista de overrides (usuario) a partir de los códigos efectivos
 * chequeados y la matriz del rol base. Semántica relativa al rol base (R7):
 *  - chequeado y en el rol      → sin override
 *  - chequeado y fuera del rol  → override { concedido: true }  (agregar)
 *  - desmarcado y en el rol     → override { concedido: false } (quitar)
 *  - desmarcado y fuera del rol → sin override
 */
export function buildOverrides(checked: string[], rolPermisos: string[]): UsuarioPermisoOverride[] {
  const base = new Set(rolPermisos);
  const overrides: UsuarioPermisoOverride[] = [];

  for (const code of checked) {
    if (!base.has(code)) {
      overrides.push({ permisoCodigo: code, concedido: true });
    }
  }

  for (const code of rolPermisos) {
    if (!checked.includes(code)) {
      overrides.push({ permisoCodigo: code, concedido: false });
    }
  }

  return overrides;
}

/**
 * Aplica la lista de overrides sobre la matriz del rol base para reconstruir
 * los códigos efectivos (rol ∪ concedidos ∖ denegados). Usado al cargar un
 * usuario en edición.
 */
export function aplicarOverrides(base: string[], overrides: UsuarioPermisoOverride[]): string[] {
  const result = new Set(base);
  for (const override of overrides) {
    if (override.concedido) {
      result.add(override.permisoCodigo);
    } else {
      result.delete(override.permisoCodigo);
    }
  }
  return [...result];
}

/**
 * Matriz de permisos módulo → acciones (mat-expansion-panel + mat-checkbox),
 * reutilizable para la matriz de un rol y para los overrides de un usuario.
 *
 * - `modo: 'rol'`: los checkboxes representan directamente la matriz del rol.
 * - `modo: 'usuario'`: los checkboxes representan los permisos EFECTIVOS; se
 *   marcan visualmente los overrides de agregar/quitar respecto del rol base
 *   (`rolPermisos`).
 *
 * Emite `change` con el array de códigos chequeados (permisos efectivos).
 */
@Component({
  selector: 'app-permisos-matriz',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './permisos-matriz.component.html',
  styleUrls: ['./permisos-matriz.component.scss']
})
export class PermisosMatrizComponent implements OnChanges {
  @Input() modulos: Modulo[] = [];
  @Input() checked: string[] = [];
  /** En modo 'usuario': códigos de la matriz del rol base (para el indicador de overrides). */
  @Input() rolPermisos: string[] = [];
  @Input() modo: 'rol' | 'usuario' = 'rol';
  @Output() change = new EventEmitter<string[]>();

  private checkedCodes: string[] = [];

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['checked']) {
      this.checkedCodes = [...(this.checked ?? [])];
    }
  }

  isChecked(code: string): boolean {
    return this.checkedCodes.includes(code);
  }

  isInRolBase(code: string): boolean {
    return this.rolPermisos.includes(code);
  }

  /** Modo usuario: permiso agregado respecto del rol base (checked, no está en el rol). */
  isOverrideAdd(code: string): boolean {
    return this.modo === 'usuario' && this.isChecked(code) && !this.isInRolBase(code);
  }

  /** Modo usuario: permiso quitado respecto del rol base (en el rol, desmarcado). */
  isOverrideRemove(code: string): boolean {
    return this.modo === 'usuario' && !this.isChecked(code) && this.isInRolBase(code);
  }

  isModuleChecked(modulo: Modulo): boolean {
    return modulo.permisos.length > 0 && modulo.permisos.every(p => this.isChecked(p.codigo));
  }

  isModuleIndeterminate(modulo: Modulo): boolean {
    const someChecked = modulo.permisos.some(p => this.isChecked(p.codigo));
    return someChecked && !this.isModuleChecked(modulo);
  }

  toggle(code: string, newState: boolean): void {
    if (newState) {
      if (!this.checkedCodes.includes(code)) {
        this.checkedCodes.push(code);
      }
    } else {
      this.checkedCodes = this.checkedCodes.filter(c => c !== code);
    }
    this.change.emit([...this.checkedCodes]);
  }

  toggleAll(modulo: Modulo, selectAll: boolean): void {
    for (const permiso of modulo.permisos) {
      if (selectAll) {
        if (!this.checkedCodes.includes(permiso.codigo)) {
          this.checkedCodes.push(permiso.codigo);
        }
      } else {
        this.checkedCodes = this.checkedCodes.filter(c => c !== permiso.codigo);
      }
    }
    this.change.emit([...this.checkedCodes]);
  }
}
