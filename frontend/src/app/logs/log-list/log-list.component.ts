import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { MatTableDataSource } from '@angular/material/table';
import { PageEvent } from '@angular/material/paginator';
import Swal from 'sweetalert2';
import { LogService, LogFiltros, UsuarioOpcion } from '../log.service';
import { AuditoriaLog } from '../../core/models';
import { formatearDetalle as formatearDetalleUtil } from '../detalle.util';
import { BorrarLogsDialog, BorrarLogsRango } from './borrar-logs-dialog.component';

/**
 * Entidades singulares registradas en `auditoria` (Decisión D5): el backend
 * filtra por el valor SINGULAR de la columna `entidad` (VENTA, PRODUCTO...),
 * no por el código plural del catálogo (VENTAS, PRODUCTOS...).
 */
export const ENTIDADES_LOG: ReadonlyArray<{ label: string; valor: string }> = [
  { label: 'Usuarios', valor: 'USUARIO' },
  { label: 'Roles', valor: 'ROL' },
  { label: 'Productos', valor: 'PRODUCTO' },
  { label: 'Categorías', valor: 'CATEGORIA' },
  { label: 'Proveedores', valor: 'PROVEEDOR' },
  { label: 'Clientes', valor: 'CLIENTE' },
  { label: 'Ventas', valor: 'VENTA' },
  { label: 'Compras', valor: 'COMPRA' },
  { label: 'Precios', valor: 'PRECIO' },
  { label: 'Movimientos', valor: 'MOVIMIENTO' },
  { label: 'Gastos', valor: 'GASTO' },
  { label: 'Autenticación', valor: 'AUTH' }
];

/** Acciones posibles registradas por la instrumentación (R4/R5). */
export const ACCIONES_LOG: string[] = ['CREAR', 'ACTUALIZAR', 'ELIMINAR', 'ANULAR', 'LOGIN'];

/**
 * Consulta paginada **server-side** de logs de auditoría (R7) + borrado por
 * rango con confirmación (R8). A diferencia de los demás listados del proyecto,
 * la tabla NO filtra client-side: cada cambio de página/tamaño/filtro re-consulta
 * `GET /api/logs` (volumen alto). El botón "Borrar por rango" es visible solo
 * con `LOGS_ELIMINAR` y no existe borrado por fila individual (R8).
 */
@Component({
  selector: 'app-log-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './log-list.component.html',
  styleUrls: ['./log-list.component.scss']
})
export class LogListComponent implements OnInit {
  displayedColumns: string[] = ['entidad', 'entidadId', 'accion', 'usuarioId', 'usuarioNombre', 'fecha', 'detalle'];
  dataSource = new MatTableDataSource<AuditoriaLog>([]);
  filtrosForm: FormGroup;

  totalElements = 0;
  currentPage = 0;
  pageSize = 20;
  pageSizeOptions = [10, 20, 50];

  loading = true;
  deleting = false;

  readonly entidades = ENTIDADES_LOG;
  readonly acciones = ACCIONES_LOG;
  usuarios: UsuarioOpcion[] = [];

  constructor(
    private fb: FormBuilder,
    private logService: LogService,
    private dialog: MatDialog,
    private cdr: ChangeDetectorRef
  ) {
    this.filtrosForm = this.fb.group({
      fechaDesde: [null],
      fechaHasta: [null],
      usuarioId: [null],
      entidad: [''],
      accion: ['']
    });
  }

  ngOnInit(): void {
    this.loadUsuarios();
    this.loadLogs();
  }

  /** Carga usuarios con actividad para el dropdown del filtro (R7). */
  private loadUsuarios(): void {
    this.logService.listarUsuarios().subscribe({
      next: (usuarios) => {
        this.usuarios = usuarios;
        this.cdr.detectChanges();
      },
      error: () => { /* dropdown vacío si falla — no bloquea la tabla */ }
    });
  }

  /** Etiqueta legible de módulo para el valor singular de `entidad`. */
  entidadLabel(entidad: string): string {
    return ENTIDADES_LOG.find(e => e.valor === entidad)?.label ?? entidad;
  }

  /**
   * Presentación del `detalle` crudo del backend (CHANGE 3): parsea el JSON y
   * lo formatea como líneas `campo: valor` o `campo: antes -> despues` (diff).
   * Si no es parseable o no es un objeto, muestra el string crudo.
   */
  formatearDetalle(detalle: string | null | undefined): string {
    return formatearDetalleUtil(detalle);
  }

  onPageChange(event: PageEvent): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadLogs();
  }

  aplicarFiltros(): void {
    // Cualquier cambio de filtro vuelve a la primera página (R7 escenario 3).
    this.currentPage = 0;
    this.loadLogs();
  }

  limpiarFiltros(): void {
    this.filtrosForm.reset();
    this.currentPage = 0;
    this.loadLogs();
  }

  openBorrarRango(): void {
    const dialogRef = this.dialog.open(BorrarLogsDialog, {
      width: '480px'
    });

    dialogRef.afterClosed().subscribe((rango: BorrarLogsRango | null) => {
      if (!rango) {
        // Cancelado → NO se ejecuta ninguna operación (R8 escenario 2).
        return;
      }
      this.eliminarPorRango(rango);
    });
  }

  private eliminarPorRango(rango: BorrarLogsRango): void {
    this.deleting = true;
    this.cdr.detectChanges();
    this.logService.deleteByRange(rango.desde, rango.hasta).subscribe({
      next: (resp) => {
        this.deleting = false;
        this.cdr.detectChanges();
        Swal.fire({
          icon: 'success',
          title: 'Logs eliminados',
          text: `Se eliminaron ${resp.eliminados} registro(s) del ${rango.desde} al ${rango.hasta}`,
          timer: 2000,
          showConfirmButton: false
        });
        this.loadLogs();
      },
      error: (err) => {
        this.deleting = false;
        this.cdr.detectChanges();
        Swal.fire('Error', err.error?.error || 'No se pudieron eliminar los logs', 'error');
      }
    });
  }

  loadLogs(): void {
    this.loading = true;
    const filtros = this.buildFiltros();
    this.logService.list({
      page: this.currentPage,
      size: this.pageSize,
      ...filtros
    }).subscribe({
      next: (page) => {
        this.dataSource.data = page.content;
        this.totalElements = page.totalElements;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los logs', 'error');
      }
    });
  }

  private buildFiltros(): LogFiltros {
    const raw = this.filtrosForm.value;
    const filtros: LogFiltros = {};

    const desde = raw.fechaDesde as Date | null;
    const hasta = raw.fechaHasta as Date | null;
    if (desde) {
      filtros.fechaDesde = this.toDateString(desde);
    }
    if (hasta) {
      filtros.fechaHasta = this.toDateString(hasta);
    }
    if (raw.usuarioId != null && raw.usuarioId !== '') {
      filtros.usuarioId = Number(raw.usuarioId);
    }
    if (raw.entidad) {
      filtros.entidad = raw.entidad;
    }
    if (raw.accion) {
      filtros.accion = raw.accion;
    }

    return filtros;
  }

  private toDateString(fecha: Date): string {
    const year = fecha.getFullYear();
    const month = String(fecha.getMonth() + 1).padStart(2, '0');
    const day = String(fecha.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
