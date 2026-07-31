import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import Swal from 'sweetalert2';
import { UsuarioService } from '../usuario.service';
import { RolService } from '../../roles/rol.service';
import { CatalogoService } from '../../core/catalogo.service';
import { Modulo, Rol, Usuario, UsuarioPermisoOverride, UsuarioRequestPayload } from '../../core/models';
import { aplicarOverrides, buildOverrides } from '../../shared/permisos-matriz/permisos-matriz.component';

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

  /** Roles cargados desde GET /api/roles (sin valores hardcodeados — R7). */
  rolesDisponibles: Rol[] = [];
  modulos: Modulo[] = [];
  /** Códigos de la matriz del rol base seleccionado. */
  rolBasePermisos: string[] = [];
  /** Códigos efectivos chequeados en la matriz de overrides. */
  checkedPermisos: string[] = [];

  constructor(
    private fb: FormBuilder,
    private usuarioService: UsuarioService,
    private rolService: RolService,
    private catalogoService: CatalogoService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(100)]],
      email: ['', [Validators.required, Validators.email]],
      telefono: [''],
      rolId: [null, Validators.required],
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

      this.initForm(this.usuarioId);
    } else {
      this.form.get('password')?.setValidators([Validators.required, Validators.minLength(4)]);
      this.form.get('password')?.updateValueAndValidity();
      this.initForm(null);
    }
  }

  private initForm(usuarioId: number | null): void {
    const catalogo$ = this.catalogoService.getModulos();
    const roles$ = this.rolService.list();
    const usuario$ = usuarioId ? this.usuarioService.getById(usuarioId) : of(null);

    forkJoin({ modulos: catalogo$, roles: roles$, usuario: usuario$ }).subscribe({
      next: ({ modulos, roles, usuario }) => {
        this.modulos = modulos;
        this.rolesDisponibles = roles;

        if (usuario) {
          this.patchUsuario(usuario);
        } else {
          this.loadingData = false;
          this.detectChanges();
        }
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los datos del formulario', 'error');
        this.router.navigate(['/usuarios']);
      }
    });
  }

  private patchUsuario(usuario: Usuario): void {
    this.form.patchValue({
      nombre: usuario.nombre,
      email: usuario.email,
      telefono: usuario.telefono,
      rolId: usuario.rolId,
      activo: usuario.activo
    });

    const rolBase = this.rolesDisponibles.find(r => r.id === usuario.rolId);
    this.rolBasePermisos = rolBase ? [...rolBase.permisos] : [];

    // Estado inicial: matriz del rol base después de aplicar los overrides del usuario.
    this.checkedPermisos = rolBase
      ? aplicarOverrides(this.rolBasePermisos, usuario.overrides ?? [])
      : [...(usuario.permisos ?? this.rolBasePermisos)];

    this.loadingData = false;
    this.detectChanges();
  }

  onRolChange(event: any): void {
    const rolId = Number(event?.value);
    const rol = this.rolesDisponibles.find(r => r.id === rolId);
    this.rolBasePermisos = rol ? [...rol.permisos] : [];
    // Al cambiar el rol base se recalcula el estado inicial de la matriz (R7).
    this.checkedPermisos = [...this.rolBasePermisos];
  }

  onMatrizChange(codigos: string[]): void {
    this.checkedPermisos = codigos;
  }

  private buildOverrides(): UsuarioPermisoOverride[] {
    return buildOverrides(this.checkedPermisos, this.rolBasePermisos);
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
    const data: UsuarioRequestPayload = {
      nombre: formValue.nombre,
      email: formValue.email,
      telefono: formValue.telefono,
      rolId: Number(formValue.rolId),
      activo: formValue.activo,
      overrides: this.buildOverrides()
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
        Swal.fire('Error', err.error?.error || 'No se pudo guardar el usuario', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/usuarios']);
  }
}
