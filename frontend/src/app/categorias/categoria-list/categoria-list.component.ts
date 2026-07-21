import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { CategoriaService } from '../categoria.service';
import { Categoria } from '../../core/models';

@Component({
  selector: 'app-categoria-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './categoria-list.component.html',
  styleUrls: ['./categoria-list.component.scss']
})
export class CategoriaListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'descripcion', 'activo', 'acciones'];
  dataSource = new MatTableDataSource<Categoria>([]);
  loading = true;
  searchTerm = '';

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private categoriaService: CategoriaService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadCategorias();
  }

  loadCategorias(): void {
    this.loading = true;
    this.categoriaService.list().subscribe({
      next: (categorias) => {
        this.dataSource.data = categorias;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar las categorías', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/categorias/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/categorias', id, 'editar']);
  }

  deleteCategoria(categoria: Categoria): void {
    Swal.fire({
      title: '¿Eliminar categoría?',
      text: `Se eliminará "${categoria.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.categoriaService.delete(categoria.id).subscribe({
          next: () => {
            Swal.fire('Eliminada', 'Categoría eliminada correctamente', 'success');
            this.loadCategorias();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar la categoría. Verifica que no tenga productos asociados.', 'error');
          }
        });
      }
    });
  }
}
