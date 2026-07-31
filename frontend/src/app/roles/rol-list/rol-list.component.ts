import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { RolService } from '../rol.service';
import { Rol } from '../../core/models';

@Component({
  selector: 'app-rol-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './rol-list.component.html',
  styleUrls: ['./rol-list.component.scss']
})
export class RolListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'descripcion', 'permisos', 'acciones'];
  dataSource = new MatTableDataSource<Rol>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private rolService: RolService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadRoles();
  }

  loadRoles(): void {
    this.loading = true;
    this.rolService.list().subscribe({
      next: (roles) => {
        this.dataSource.data = roles;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los roles', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/roles/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/roles', id, 'editar']);
  }

  deleteRol(rol: Rol): void {
    Swal.fire({
      title: '¿Eliminar rol?',
      text: `Se eliminará el rol "${rol.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.rolService.delete(rol.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Rol eliminado correctamente', 'success');
            this.loadRoles();
          },
          error: (err) => {
            const message = err.status === 409
              ? 'No se puede eliminar: el rol está asignado a usuarios activos.'
              : (err.error?.error || 'No se pudo eliminar el rol');
            Swal.fire('Error', message, 'error');
          }
        });
      }
    });
  }
}
