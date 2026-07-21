import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatPaginator } from '@angular/material/paginator';
import { MatTableDataSource } from '@angular/material/table';
import { PrecioService } from '../precio.service';
import { PrecioProducto } from '../../core/models';

@Component({
  selector: 'app-precios-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './precios-list.component.html',
  styleUrls: ['./precios-list.component.scss']
})
export class PreciosListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'codigoBarras', 'precioCompra', 'precioVenta', 'ganancia', 'margenPorcentaje', 'fechaActualizacion'];
  dataSource = new MatTableDataSource<PrecioProducto>([]);
  loading = true;

  get totalItems(): number {
    return this.dataSource.filteredData.length;
  }

  constructor(
    private precioService: PrecioService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  @ViewChild(MatSort) sort!: MatSort;
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.loadPrecios();
  }

  loadPrecios(): void {
    this.loading = true;
    this.precioService.list().subscribe({
      next: (precios) => {
        this.dataSource.data = precios;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
          this.dataSource.paginator = this.paginator;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  irADetalle(row: PrecioProducto): void {
    this.router.navigate(['/gestion-precios', row.id]);
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
