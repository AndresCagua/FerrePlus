import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ProveedorService } from '../proveedor.service';

@Component({
  selector: 'app-proveedor-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './proveedor-form.component.html',
  styleUrls: ['./proveedor-form.component.scss']
})
export class ProveedorFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  proveedorId: number | null = null;
  loading = false;
  loadingData = true;

  constructor(
    private fb: FormBuilder,
    private proveedorService: ProveedorService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(200)]],
      contacto: ['', Validators.required],
      telefono: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      direccion: [''],
      ruc: ['', Validators.required],
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
      this.proveedorId = Number(id);
      this.loadProveedor(this.proveedorId);
    } else {
      this.loadingData = false;
      this.detectChanges();
    }
  }

  loadProveedor(id: number): void {
    this.proveedorService.getById(id).subscribe({
      next: (proveedor) => {
        this.form.patchValue({
          nombre: proveedor.nombre,
          contacto: proveedor.contacto,
          telefono: proveedor.telefono,
          email: proveedor.email,
          direccion: proveedor.direccion,
          ruc: proveedor.ruc,
          activo: proveedor.activo
        });
        this.loadingData = false;
        this.detectChanges();
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar el proveedor', 'error');
        this.router.navigate(['/proveedores']);
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
      ? this.proveedorService.update(this.proveedorId!, data)
      : this.proveedorService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Proveedor actualizado' : 'Proveedor creado',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/proveedores']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo guardar el proveedor', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/proveedores']);
  }
}
