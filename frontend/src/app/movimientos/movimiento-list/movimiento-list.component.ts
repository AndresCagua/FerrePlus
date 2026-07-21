import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { MovimientoService } from '../movimiento.service';
import { Movimiento } from '../../core/models';

@Component({
  selector: 'app-movimiento-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './movimiento-list.component.html',
  styleUrls: ['./movimiento-list.component.scss']
})
export class MovimientoListComponent implements OnInit {
  displayedColumns: string[] = ['fecha', 'producto', 'tipo', 'cantidad', 'stockAnterior', 'stockPosterior', 'motivo', 'usuario'];
  dataSource = new MatTableDataSource<Movimiento>([]);
  loading = true;
  filterTipo = '';
  tipos = ['ENTRADA', 'SALIDA', 'AJUSTE'];

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private movimientoService: MovimientoService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadMovimientos();
  }

  loadMovimientos(): void {
    this.loading = true;
    this.movimientoService.list().subscribe({
      next: (movimientos) => {
        this.dataSource.data = movimientos;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los movimientos', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  filterByTipo(tipo: string): void {
    this.filterTipo = tipo;
    this.dataSource.filterPredicate = (data: Movimiento, filter: string) => {
      if (!filter) return true;
      return data.tipo === filter;
    };
    this.dataSource.filter = tipo;
  }

  navigateToNew(): void {
    this.router.navigate(['/movimientos/nuevo']);
  }

  getTipoClass(tipo: string): string {
    switch (tipo) {
      case 'ENTRADA': return 'badge-stock-ok';
      case 'SALIDA': return 'badge-stock-low';
      case 'AJUSTE': return 'badge bg-warning text-dark';
      default: return 'badge bg-secondary';
    }
  }
}
