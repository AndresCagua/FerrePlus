import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { CompraService } from '../compra.service';
import { Compra } from '../../core/models';

@Component({
  selector: 'app-compra-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './compra-list.component.html',
  styleUrls: ['./compra-list.component.scss']
})
export class CompraListComponent implements OnInit {
  displayedColumns: string[] = ['numeroFactura', 'fecha', 'proveedor', 'detalles', 'total', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Compra>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private compraService: CompraService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadCompras();
  }

  loadCompras(): void {
    this.loading = true;
    this.compraService.list().subscribe({
      next: (compras) => {
        this.dataSource.data = compras;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar las compras', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  completarCompra(compra: Compra): void {
    Swal.fire({
      title: '¿Completar compra?',
      text: `Se marcará la factura ${compra.numeroFactura} como completada`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#2e7d32',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, completar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.compraService.update(compra.id, { estado: 'COMPLETADA' }).subscribe({
          next: () => {
            Swal.fire('Completada', 'Compra completada correctamente', 'success');
            this.loadCompras();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo completar la compra', 'error');
          }
        });
      }
    });
  }

  navigateToNew(): void {
    this.router.navigate(['/compras/nueva']);
  }

  editarCompra(id: number): void {
    this.router.navigate(['/compras/editar', id]);
  }

  anularCompra(compra: Compra): void {
    Swal.fire({
      title: '¿Anular compra?',
      text: `Se anulará la factura ${compra.numeroFactura}`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, anular',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.compraService.anular(compra.id).subscribe({
          next: () => {
            Swal.fire('Anulada', 'Compra anulada correctamente', 'success');
            this.loadCompras();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo anular la compra', 'error');
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
