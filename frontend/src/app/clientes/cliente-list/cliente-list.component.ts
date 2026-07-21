import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import Swal from 'sweetalert2';
import { ClienteService } from '../cliente.service';
import { Cliente } from '../../core/models';

@Component({
  selector: 'app-cliente-list',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './cliente-list.component.html',
  styleUrls: ['./cliente-list.component.scss']
})
export class ClienteListComponent implements OnInit {
  displayedColumns: string[] = ['nombre', 'ruc', 'telefono', 'email', 'estado', 'acciones'];
  dataSource = new MatTableDataSource<Cliente>([]);
  loading = true;

  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private clienteService: ClienteService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadClientes();
  }

  loadClientes(): void {
    this.loading = true;
    this.clienteService.list().subscribe({
      next: (clientes) => {
        this.dataSource.data = clientes;
        this.loading = false;
        this.cdr.detectChanges();
        setTimeout(() => {
          this.dataSource.sort = this.sort;
        });
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los clientes', 'error');
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  navigateToNew(): void {
    this.router.navigate(['/clientes/nuevo']);
  }

  navigateToEdit(id: number): void {
    this.router.navigate(['/clientes', id, 'editar']);
  }

  deleteCliente(cliente: Cliente): void {
    Swal.fire({
      title: '¿Eliminar cliente?',
      text: `Se eliminará "${cliente.nombre}"`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.clienteService.delete(cliente.id).subscribe({
          next: () => {
            Swal.fire('Eliminado', 'Cliente eliminado correctamente', 'success');
            this.loadClientes();
          },
          error: () => {
            Swal.fire('Error', 'No se pudo eliminar el cliente', 'error');
          }
        });
      }
    });
  }
}
