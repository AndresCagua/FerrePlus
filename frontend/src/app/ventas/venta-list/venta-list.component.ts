import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { VentaService } from '../venta.service';
import { Venta } from '../../core/models';

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
  filterEstado = '';

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private ventaService: VentaService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadVentas();
  }

  loadVentas(): void {
    this.loading = true;
    this.ventaService.list().subscribe({
      next: (ventas) => {
        this.dataSource.data = ventas;
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

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

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
            this.loadVentas();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo anular la venta', 'error');
          }
        });
      }
    });
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
