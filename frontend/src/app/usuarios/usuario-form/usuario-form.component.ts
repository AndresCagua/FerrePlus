import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { UsuarioService } from '../usuario.service';

@Component({
  selector: 'app-usuario-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './usuario-form.component.html',
  styleUrls: ['./usuario-form.component.scss']
})
export class UsuarioFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  usuarioId: number | null = null;
  loading = false;
  loadingData = true;

  roles = ['ADMIN', 'CAJERO', 'BODEGUERO', 'SUPERVISOR'];

  constructor(
    private fb: FormBuilder,
    private usuarioService: UsuarioService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(100)]],
      email: ['', [Validators.required, Validators.email]],
      telefono: [''],
      rolNombre: ['CAJERO', Validators.required],
      password: [''],
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
      this.usuarioId = Number(id);

      this.form.get('password')?.clearValidators();
      this.form.get('password')?.updateValueAndValidity();

      this.loadUsuario(this.usuarioId);
    } else {
      this.form.get('password')?.setValidators([Validators.required, Validators.minLength(4)]);
      this.form.get('password')?.updateValueAndValidity();
      this.loadingData = false;
      this.detectChanges();
    }
  }

  loadUsuario(id: number): void {
    this.usuarioService.getById(id).subscribe({
      next: (usuario) => {
        this.form.patchValue({
          nombre: usuario.nombre,
          email: usuario.email,
          telefono: usuario.telefono,
          rolNombre: usuario.rolNombre,
          activo: usuario.activo
        });
        this.loadingData = false;
        this.detectChanges();
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar el usuario', 'error');
        this.router.navigate(['/usuarios']);
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
    const formValue = this.form.value;
    const data: any = {
      nombre: formValue.nombre,
      email: formValue.email,
      telefono: formValue.telefono,
      rolNombre: formValue.rolNombre,
      activo: formValue.activo
    };

    if (formValue.password) {
      data.password = formValue.password;
    }

    const request = this.isEditing
      ? this.usuarioService.update(this.usuarioId!, data)
      : this.usuarioService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Usuario actualizado' : 'Usuario creado',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/usuarios']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo guardar el usuario', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/usuarios']);
  }
}
