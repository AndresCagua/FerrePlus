import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { UsuarioService } from '../usuario.service';
import { Usuario } from '../../core/models';

@Component({
  selector: 'app-usuario-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './usuario-list.component.html',
  styleUrls: ['./usuario-list.component.scss']
})
export class UsuarioListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'email', 'rolNombre', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Usuario>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private usuarioService: UsuarioService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadUsuarios();
  }

  loadUsuarios(): void {
    this.loading = true;
    this.usuarioService.list().subscribe({
      next: (usuarios) => {
        this.dataSource.data = usuarios;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los usuarios', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/usuarios/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/usuarios', id, 'editar']);
  }

  deleteUsuario(usuario: Usuario): void {
    Swal.fire({
      title: '¿Eliminar usuario?',
      text: `Se eliminará a "${usuario.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.usuarioService.delete(usuario.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Usuario eliminado correctamente', 'success');
            this.loadUsuarios();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar el usuario', 'error');
          }
        });
      }
    });
  }

  getRolClass(rolNombre: string): string {
    switch (rolNombre) {
      case 'ADMIN': return 'badge bg-danger';
      case 'SUPERVISOR': return 'badge bg-warning text-dark';
      case 'CAJERO': return 'badge bg-info text-dark';
      case 'BODEGUERO': return 'badge bg-secondary';
      default: return 'badge bg-primary';
    }
  }
}
