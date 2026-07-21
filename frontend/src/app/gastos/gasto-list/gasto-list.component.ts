import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { GastoService } from '../gasto.service';
import { Gasto } from '../../core/models';

@Component({
  selector: 'app-gasto-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './gasto-list.component.html',
  styleUrls: ['./gasto-list.component.scss']
})
export class GastoListComponent implements OnInit {
  displayedColumns: string[] = ['fecha', 'descripcion', 'monto', 'categoria', 'metodoPago', 'usuario', 'acciones'];
  dataSource = new MatTableDataSource<Gasto>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private gastoService: GastoService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadGastos();
  }

  loadGastos(): void {
    this.loading = true;
    this.gastoService.list().subscribe({
      next: (gastos) => {
        this.dataSource.data = gastos;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los gastos', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/gastos/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/gastos', id, 'editar']);
  }

  deleteGasto(gasto: Gasto): void {
    Swal.fire({
      title: '¿Eliminar gasto?',
      text: `Se eliminará "${gasto.descripcion}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.gastoService.delete(gasto.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Gasto eliminado correctamente', 'success');
            this.loadGastos();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar el gasto', 'error');
          }
        });
      }
    });
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
