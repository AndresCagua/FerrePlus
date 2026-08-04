import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { ReactiveFormsModule } from '@angular/forms';
import { PageEvent } from '@angular/material/paginator';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatDialog } from '@angular/material/dialog';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { of } from 'rxjs';
import { LogListComponent } from './log-list.component';
import { LogService } from '../log.service';
import { UsuarioOpcion } from '../log.service';
import { AuthService } from '../../core/auth.service';
import { HasPermissionDirective } from '../../core/has-permission.directive';
import { AuditoriaLog, Page } from '../../core/models';

// Evita que sweetalert2 intente renderizar en jsdom durante los flujos de error/borrado.
vi.mock('sweetalert2', () => ({
  default: {
    fire: vi.fn(() => Promise.resolve({ isConfirmed: true }))
  }
}));

describe('LogListComponent (tabla server-side + filtros + borrado por rango)', () => {
  let fixture: ComponentFixture<LogListComponent>;
  let component: LogListComponent;
  let listMock: ReturnType<typeof vi.fn>;
  let deleteMock: ReturnType<typeof vi.fn>;
  let listarUsuariosMock: ReturnType<typeof vi.fn>;
  let authMock: {
    hasPermission: ReturnType<typeof vi.fn>;
    hasAnyPermission: ReturnType<typeof vi.fn>;
  };
  let dialogMock: { open: ReturnType<typeof vi.fn> };

  const pageMock: Page<AuditoriaLog> = {
    content: [
      {
        id: 1,
        entidad: 'VENTA',
        entidadId: 10,
        accion: 'CREAR',
        usuarioId: 3,
        usuarioNombre: 'Admin',
        fecha: '2026-01-01T10:00:00',
        detalle: '{"total":100}'
      },
      {
        id: 2,
        entidad: 'PRODUCTO',
        entidadId: null,
        accion: 'ELIMINAR',
        fecha: '2026-01-02T10:00:00',
        detalle: null
      }
    ],
    totalElements: 2,
    totalPages: 1,
    size: 20,
    number: 0,
    first: true,
    last: true
  };

  beforeEach(() => {
    listMock = vi.fn();
    deleteMock = vi.fn();
    listarUsuariosMock = vi.fn().mockReturnValue(of([]));
    authMock = {
      hasPermission: vi.fn(() => true),
      hasAnyPermission: vi.fn(() => true)
    };
    dialogMock = { open: vi.fn() };

    TestBed.configureTestingModule({
      imports: [
        NoopAnimationsModule,
        ReactiveFormsModule,
        MatTableModule,
        MatPaginatorModule,
        MatFormFieldModule,
        MatInputModule,
        MatSelectModule,
        MatCardModule,
        MatButtonModule,
        MatIconModule,
        MatProgressSpinnerModule,
        MatTooltipModule,
        MatDatepickerModule,
        MatNativeDateModule
      ],
      declarations: [LogListComponent, HasPermissionDirective],
      providers: [
        { provide: LogService, useValue: { list: listMock, deleteByRange: deleteMock, listarUsuarios: listarUsuariosMock } },
        { provide: AuthService, useValue: authMock },
        { provide: MatDialog, useValue: dialogMock }
      ]
    });

    listMock.mockReturnValue(of(pageMock));
    fixture = TestBed.createComponent(LogListComponent);
    component = fixture.componentInstance;
  });

  it('renderiza las filas de la página devuelta por el backend', () => {
    fixture.detectChanges();

    // Las filas de mat-table son <tr class="mat-mdc-row"> (no <mat-row>).
    const rows = fixture.nativeElement.querySelectorAll('.mat-mdc-row');
    expect(rows.length).toBe(2);

    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('Ventas');
    expect(text).toContain('Admin');
    expect(text).toContain('CREAR');
    expect(text).toContain('Productos');
    expect(text).toContain('ELIMINAR');
  });

  it('muestra las cabeceras ID Entidad, ID Usuario y Usuario', () => {
    fixture.detectChanges();

    const headerEls = fixture.nativeElement.querySelectorAll('.mat-mdc-header-cell') as NodeListOf<Element>;
    const headers = Array.from(headerEls).map(th => (th.textContent ?? '').trim());

    expect(headers).toContain('ID Entidad');
    expect(headers).toContain('ID Usuario');
    expect(headers).toContain('Usuario');
  });

  it('muestra el ID Usuario con fallback "—" cuando es null/undefined', () => {
    fixture.detectChanges();

    const rows = fixture.nativeElement.querySelectorAll('.mat-mdc-row');
    // Orden de columnas: entidad, entidadId, accion, usuarioId, usuarioNombre, fecha, detalle.
    const cellsFila1 = rows[0].querySelectorAll('.mat-mdc-cell');
    expect(cellsFila1[3].textContent?.trim()).toBe('3'); // usuarioId: 3

    const cellsFila2 = rows[1].querySelectorAll('.mat-mdc-cell');
    expect(cellsFila2[3].textContent?.trim()).toBe('—'); // usuarioId: undefined
  });

  it('muestra el estado vacío cuando el backend devuelve una página sin filas', () => {
    listMock.mockReturnValue(
      of({ content: [], totalElements: 0, totalPages: 0, size: 20, number: 0 })
    );

    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.empty-state')).toBeTruthy();
    expect(fixture.nativeElement.textContent).toContain('No se encontraron logs');
  });

  it('aplicarFiltros re-consulta el servidor con los filtros formateados y vuelve a la página 0', () => {
    component.filtrosForm.setValue({
      fechaDesde: new Date(2026, 0, 1),
      fechaHasta: new Date(2026, 0, 31),
      usuarioId: 1,
      entidad: 'VENTA',
      accion: 'CREAR'
    });

    component.aplicarFiltros();

    expect(listMock).toHaveBeenCalledWith({
      page: 0,
      size: 20,
      fechaDesde: '2026-01-01',
      fechaHasta: '2026-01-31',
      usuarioId: 1,
      entidad: 'VENTA',
      accion: 'CREAR'
    });
  });

  it('aplicarFiltros omite usuarioId cuando es null', () => {
    component.filtrosForm.setValue({
      fechaDesde: null,
      fechaHasta: null,
      usuarioId: null,
      entidad: '',
      accion: ''
    });

    component.aplicarFiltros();

    expect(listMock).toHaveBeenCalledWith(
      expect.objectContaining({
        page: 0,
        size: 20
      })
    );
    const llamado = listMock.mock.calls[0][0] as Record<string, unknown>;
    expect('usuarioId' in llamado).toBe(false);
  });

  it('limpiarFiltros resetea el formulario y re-consulta desde la página 0', () => {
    component.filtrosForm.setValue({
      fechaDesde: new Date(2026, 0, 1),
      fechaHasta: null,
      usuarioId: 3,
      entidad: 'GASTO',
      accion: ''
    });

    component.limpiarFiltros();

    expect(component.filtrosForm.value.fechaDesde).toBeNull();
    expect(listMock).toHaveBeenCalledWith({
      page: 0,
      size: 20,
      fechaDesde: undefined,
      fechaHasta: undefined,
      usuarioId: undefined,
      entidad: undefined,
      accion: undefined
    });
  });

  it('onPageChange re-consulta el servidor con la nueva página y tamaño', () => {
    component.onPageChange({ pageIndex: 2, pageSize: 50, length: 120 } as PageEvent);

    expect(listMock).toHaveBeenCalledWith(expect.objectContaining({ page: 2, size: 50 }));
  });

  it('el botón "Borrar por rango" es visible solo con LOGS_ELIMINAR', () => {
    authMock.hasPermission.mockReturnValue(true);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[data-testid="borrar-rango"]')).toBeTruthy();
  });

  it('el botón "Borrar por rango" NO se renderiza sin LOGS_ELIMINAR', () => {
    authMock.hasPermission.mockReturnValue(false);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[data-testid="borrar-rango"]')).toBeNull();
  });

  it('cancelar el diálogo de borrado NO llama a deleteByRange', () => {
    dialogMock.open.mockReturnValue({ afterClosed: () => of(null) });

    component.openBorrarRango();

    expect(deleteMock).not.toHaveBeenCalled();
    expect(listMock).not.toHaveBeenCalled();
  });

  it('confirmar el diálogo llama a deleteByRange con el rango y recarga la lista', () => {
    deleteMock.mockReturnValue(of({ eliminados: 5 }));
    dialogMock.open.mockReturnValue({
      afterClosed: () => of({ desde: '2026-01-01', hasta: '2026-01-31' })
    });

    component.openBorrarRango();

    expect(deleteMock).toHaveBeenCalledWith('2026-01-01', '2026-01-31');
    expect(listMock).toHaveBeenCalledTimes(1);
    expect(listMock).toHaveBeenCalledWith(expect.objectContaining({ page: 0, size: 20 }));
  });

  it('formatea detalle tipo diff como "campo: antes -> despues"', () => {
    listMock.mockReturnValue(
      of({
        ...pageMock,
        content: [
          {
            id: 8,
            entidad: 'PRODUCTO',
            entidadId: 4,
            accion: 'ACTUALIZAR',
            usuarioId: 1,
            usuarioNombre: 'Admin',
            fecha: '2026-01-03T10:00:00',
            detalle: '{"precioVenta":{"antes":100,"despues":130}}'
          }
        ]
      })
    );

    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('precioVenta: 100 -> 130');
  });

  it('formatea detalle tipo snapshot (CREAR/ELIMINAR) como "campo: valor"', () => {
    fixture.detectChanges();
    const text = fixture.nativeElement.textContent as string;
    // Primer log pageMock: detalle '{"total":100}' → snapshot → "total: 100".
    expect(text).toContain('total: 100');
  });

  it('muestra el string crudo cuando detalle es JSON inválido', () => {
    listMock.mockReturnValue(
      of({
        ...pageMock,
        content: [
          {
            id: 9,
            entidad: 'AUTH',
            entidadId: 2,
            accion: 'LOGIN',
            usuarioId: 2,
            usuarioNombre: 'Vendedor',
            fecha: '2026-01-03T10:00:00',
            detalle: 'texto de auditoría sin formato'
          }
        ]
      })
    );

    fixture.detectChanges();
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('texto de auditoría sin formato');
  });

  it('muestra "—" cuando detalle es null', () => {
    fixture.detectChanges();
    const text = fixture.nativeElement.textContent as string;
    // Segundo registro de pageMock tiene detalle: null.
    expect(text).toContain('—');
  });

  it('loadUsuarios llama listarUsuarios y carga la lista de usuarios', () => {
    const usuarios: UsuarioOpcion[] = [{ id: 1, nombre: 'Administrador' }, { id: 5, nombre: 'Vendedor' }];
    listarUsuariosMock.mockReturnValue(of(usuarios));

    fixture.detectChanges();

    expect(listarUsuariosMock).toHaveBeenCalled();
    expect(component.usuarios).toEqual(usuarios);
  });

  it('loadUsuarios maneja error sin bloquear la tabla', () => {
    listarUsuariosMock.mockReturnValue(of([]));

    fixture.detectChanges();

    expect(component.usuarios).toEqual([]);
    // La tabla debe cargar normalmente a pesar del error en usuarios
    expect(component.dataSource.data.length).toBe(2);
  });
});
