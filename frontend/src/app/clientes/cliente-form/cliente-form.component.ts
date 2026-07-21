import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ClienteService } from '../cliente.service';

@Component({
  selector: 'app-cliente-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './cliente-form.component.html',
  styleUrls: ['./cliente-form.component.scss']
})
export class ClienteFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  clienteId: number | null = null;
  loading = false;
  loadingData = true;

  constructor(
    private fb: FormBuilder,
    private clienteService: ClienteService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(200)]],
      ruc: [''],
      telefono: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      direccion: [''],
      activo: [true]
    });
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditing = true;
      this.clienteId = Number(id);
      this.loadCliente(this.clienteId);
    } else {
      this.loadingData = false;
      this.detectChanges();
    }
  }

  loadCliente(id: number): void {
    this.clienteService.getById(id).subscribe({
      next: (cliente) => {
        this.form.patchValue({
          nombre: cliente.nombre,
          ruc: cliente.ruc,
          telefono: cliente.telefono,
          email: cliente.email,
          direccion: cliente.direccion,
          activo: cliente.activo
        });
        this.loadingData = false;
        this.detectChanges();
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar el cliente', 'error');
        this.router.navigate(['/clientes']);
      }
    });
  }

  onSubmit(): void {
    if (this.form.invalid) {
      Object.keys(this.form.controls).forEach(key => {
        this.form.get(key)?.markAsTouched();
      });
      return;
    }

    this.loading = true;
    this.detectChanges();
    const data = this.form.value;

    const request = this.isEditing
      ? this.clienteService.update(this.clienteId!, data)
      : this.clienteService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Cliente actualizado' : 'Cliente creado',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/clientes']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo guardar el cliente', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/clientes']);
  }
}
