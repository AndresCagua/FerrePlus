import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { ProveedorService } from '../proveedor.service';
import { Proveedor } from '../../core/models';

@Component({
  selector: 'app-proveedor-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './proveedor-list.component.html',
  styleUrls: ['./proveedor-list.component.scss']
})
export class ProveedorListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'contacto', 'telefono', 'email', 'ruc', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Proveedor>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private proveedorService: ProveedorService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadProveedores();
  }

  loadProveedores(): void {
    this.loading = true;
    this.proveedorService.list().subscribe({
      next: (proveedores) => {
        this.dataSource.data = proveedores;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los proveedores', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/proveedores/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/proveedores', id, 'editar']);
  }

  deleteProveedor(proveedor: Proveedor): void {
    Swal.fire({
      title: '¿Eliminar proveedor?',
      text: `Se eliminará "${proveedor.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.proveedorService.delete(proveedor.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Proveedor eliminado correctamente', 'success');
            this.loadProveedores();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar el proveedor', 'error');
          }
        });
      }
    });
  }
}
