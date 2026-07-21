import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import * as XLSX from 'xlsx';
import Swal from 'sweetalert2';
import { VentaService } from '../venta.service';
import { ClienteService } from '../../clientes/cliente.service';
import { Venta, Cliente } from '../../core/models';

@Component({
  selector: 'app-venta-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './venta-list.component.html',
  styleUrls: ['./venta-list.component.scss']
})
export class VentaListComponent implements OnInit {
  displayedColumns: string[] = ['numeroFactura', 'fecha', 'cliente', 'detalles', 'total', 'metodoPago', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Venta>([]);
  loading = true;

  // Lista completa de ventas (para filtros sin depender de dataSource.filter)
  ventasOriginal: Venta[] = [];

  // Filtros
  filtroTexto = '';
  filtroDesde: Date | null = null;
  filtroHasta: Date | null = null;
  filtroCliente: Cliente | null = null;
  filtroMetodoPago = '';

  // Lista de clientes para el select
  clientes: Cliente[] = [];

  // Opciones de método de pago
  metodosPago = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CREDITO'];

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private ventaService: VentaService,
    private clienteService: ClienteService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
    this.cargarVentas();
  }

  cargarClientes(): void {
    this.clienteService.list().subscribe({
      next: (clientes) => {
        this.clientes = clientes;
      }
    });
  }

  cargarVentas(): void {
    this.loading = true;
    this.ventaService.list().subscribe({
      next: (ventas) => {
        this.ventasOriginal = ventas;
        this.aplicarFiltros();
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar las ventas', 'error');
      }
    });
  }

  // ─── Filtros ────────────────────────────────────────────────

  onFilterChange(): void {
    this.aplicarFiltros();
  }

  private aplicarFiltros(): void {
    let filtradas = [...this.ventasOriginal];

    // Filtro por texto (número de factura)
    if (this.filtroTexto) {
      const t = this.filtroTexto.toLowerCase().trim();
      filtradas = filtradas.filter(v =>
        v.numeroFactura.toLowerCase().includes(t)
      );
    }

    // Filtro por rango de fechas
    if (this.filtroDesde) {
      const desde = new Date(this.filtroDesde);
      desde.setHours(0, 0, 0, 0);
      filtradas = filtradas.filter(v => {
        if (!v.fechaCreacion) return false;
        const fecha = new Date(v.fechaCreacion);
        return fecha >= desde;
      });
    }
    if (this.filtroHasta) {
      const hasta = new Date(this.filtroHasta);
      hasta.setHours(23, 59, 59, 999);
      filtradas = filtradas.filter(v => {
        if (!v.fechaCreacion) return false;
        const fecha = new Date(v.fechaCreacion);
        return fecha <= hasta;
      });
    }

    // Filtro por cliente
    if (this.filtroCliente) {
      filtradas = filtradas.filter(v =>
        v.cliente?.id === this.filtroCliente!.id
      );
    }

    // Filtro por método de pago
    if (this.filtroMetodoPago) {
      filtradas = filtradas.filter(v =>
        v.metodoPago === this.filtroMetodoPago
      );
    }

    this.dataSource.data = filtradas;
  }

  limpiarFiltros(): void {
    this.filtroTexto = '';
    this.filtroDesde = null;
    this.filtroHasta = null;
    this.filtroCliente = null;
    this.filtroMetodoPago = '';
    this.aplicarFiltros();
  }

  get ventasFiltradas(): Venta[] {
    return this.dataSource.data;
  }

  // ─── Exportar Excel ─────────────────────────────────────────

  exportToExcel(): void {
    const datos = this.ventasFiltradas.map(v => ({
      'Factura #': v.numeroFactura,
      'Fecha': v.fechaCreacion ? new Date(v.fechaCreacion).toLocaleDateString('es-PY') : '',
      'Cliente': v.cliente?.nombre || 'Consumidor Final',
      'Items': v.detalles?.length || 0,
      'Subtotal': v.subtotal,
      'Descuento': v.descuento,
      'IVA': v.iva,
      'Total': v.total,
      'Método Pago': v.metodoPago,
      'Estado': v.estado
    }));

    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.json_to_sheet(datos);

    // Ancho de columnas
    ws['!cols'] = [
      { wch: 20 }, // Factura
      { wch: 14 }, // Fecha
      { wch: 25 }, // Cliente
      { wch: 8 },  // Items
      { wch: 12 }, // Subtotal
      { wch: 12 }, // Descuento
      { wch: 10 }, // IVA
      { wch: 12 }, // Total
      { wch: 16 }, // Método Pago
      { wch: 12 }, // Estado
    ];

    XLSX.utils.book_append_sheet(wb, ws, 'Ventas');
    const nombre = this.filtroDesde || this.filtroHasta
      ? `ventas_${this.filtroDesde?.toISOString().slice(0, 10) || 'inicio'}_${this.filtroHasta?.toISOString().slice(0, 10) || 'fin'}`
      : 'ventas_completo';
    XLSX.writeFile(wb, `${nombre}.xlsx`);
  }

  // ─── Imprimir ───────────────────────────────────────────────

  printTable(): void {
    // Guardar estado actual
    const printContents = document.getElementById('venta-table')?.innerHTML;
    if (!printContents) return;

    const originalTitle = document.title;
    document.title = 'Ventas - FerrePlus';

    const ventana = window.open('', '_blank', 'width=1200,height=800');
    if (!ventana) {
      Swal.fire('Error', 'No se pudo abrir la ventana de impresión. Permití ventanas emergentes.', 'error');
      return;
    }

    ventana.document.write(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Ventas - FerrePlus</title>
        <style>
          body { font-family: 'Inter', Arial, sans-serif; margin: 20px; color: #333; }
          h1 { font-size: 20px; margin-bottom: 4px; }
          .subtitle { color: #666; font-size: 13px; margin-bottom: 20px; }
          table { width: 100%; border-collapse: collapse; font-size: 12px; }
          th { background: #1565C0; color: white; padding: 8px 10px; text-align: left; }
          td { padding: 6px 10px; border-bottom: 1px solid #ddd; }
          tr:nth-child(even) { background: #f9f9f9; }
          .text-end { text-align: right; }
          .fw-bold { font-weight: 700; }
          .acciones-col { display: none; }
          @media print {
            body { margin: 10px; }
            th { background: #333 !important; color: white !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
            tr:nth-child(even) { background: #f5f5f5 !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          }
        </style>
      </head>
      <body>
        <h1>FerrePlus — Reporte de Ventas</h1>
        <div class="subtitle">
          Generado: ${new Date().toLocaleString('es-PY')}
          ${this.filtroDesde ? ` | Desde: ${this.filtroDesde.toLocaleDateString('es-PY')}` : ''}
          ${this.filtroHasta ? ` | Hasta: ${this.filtroHasta.toLocaleDateString('es-PY')}` : ''}
          ${this.filtroCliente ? ` | Cliente: ${this.filtroCliente.nombre}` : ''}
          ${this.filtroMetodoPago ? ` | Pago: ${this.filtroMetodoPago}` : ''}
          | Total registros: ${this.ventasFiltradas.length}
        </div>
        <table>
          <thead>
            <tr>
              <th>Factura #</th>
              <th>Fecha</th>
              <th>Cliente</th>
              <th>Items</th>
              <th class="text-end">Total</th>
              <th>Pago</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            ${this.ventasFiltradas.map(v => `
              <tr>
                <td>${v.numeroFactura}</td>
                <td>${v.fechaCreacion ? new Date(v.fechaCreacion).toLocaleDateString('es-PY') : ''}</td>
                <td>${v.cliente?.nombre || 'Consumidor Final'}</td>
                <td>${v.detalles?.length || 0}</td>
                <td class="text-end fw-bold">$${Number(v.total).toFixed(2)}</td>
                <td>${v.metodoPago}</td>
                <td>${v.estado}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
        <script>
          window.onload = function() { window.print(); };
        <\/script>
      </body>
      </html>
    `);
    ventana.document.close();
  }

  // ─── Navegación ─────────────────────────────────────────────

  navigateToNew(): void {
    this.router.navigate(['/ventas/nueva']);
  }

  viewDetail(id: number): void {
    this.router.navigate(['/ventas', id]);
  }

  anularVenta(venta: Venta): void {
    Swal.fire({
      title: '¿Anular venta?',
      text: `Se anulará la factura ${venta.numeroFactura}`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, anular',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.ventaService.anular(venta.id).subscribe({
          next: () => {
            Swal.fire('Anulada', 'Venta anulada correctamente', 'success');
            this.cargarVentas();
          },
          error: () => {
            this.loading = false;
            this.cdr.detectChanges();
            Swal.fire('Error', 'No se pudo anular la venta', 'error');
          }
        });
      }
    });
  }

  // ─── Utilitarios ────────────────────────────────────────────

  compararClientes(a: Cliente | null, b: Cliente | null): boolean {
    return a?.id === b?.id;
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }

  getEstadoClass(estado: string): string {
    switch (estado) {
      case 'COMPLETADA': return 'badge-stock-ok';
      case 'ANULADA': return 'badge-stock-low';
      case 'PENDIENTE': return 'badge bg-warning text-dark';
      default: return 'badge bg-secondary';
    }
  }
}
