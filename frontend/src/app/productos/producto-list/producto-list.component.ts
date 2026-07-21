import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { ProductoService } from '../producto.service';
import { Producto } from '../../core/models';

@Component({
  selector: 'app-producto-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './producto-list.component.html',
  styleUrls: ['./producto-list.component.scss']
})
export class ProductoListComponent implements OnInit {
  displayedColumns: string[] = ['codigoBarras', 'nombre', 'categoria', 'precioVenta', 'stockActual', 'stockMinimo', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Producto>([]);
  loading = true;
  searchTerm = '';

  get totalItems(): number {
    return this.dataSource.filteredData.length;
  }

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private productoService: ProductoService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadProductos();
  }

  loadProductos(): void {
    this.loading = true;
    this.productoService.list().subscribe({
      next: (productos) => {
        this.dataSource.data = productos;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los productos', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/productos/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/productos', id, 'editar']);
  }

  deleteProducto(producto: Producto): void {
    Swal.fire({
      title: '¿Eliminar producto?',
      text: `Se eliminará "${producto.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.productoService.delete(producto.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Producto eliminado correctamente', 'success');
            this.loadProductos();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar el producto', 'error');
          }
        });
      }
    });
  }

  getStockClass(stock: number, minimo: number): string {
    return stock <= minimo ? 'badge-stock-low' : 'badge-stock-ok';
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
