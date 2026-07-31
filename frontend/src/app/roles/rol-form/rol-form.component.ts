import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import Swal from 'sweetalert2';
import { CatalogoService } from '../../core/catalogo.service';
import { AuthService } from '../../core/auth.service';
import { Modulo, Rol, RolRequest } from '../../core/models';
import { RolService } from '../rol.service';

@Component({
  selector: 'app-rol-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './rol-form.component.html',
  styleUrls: ['./rol-form.component.scss']
})
export class RolFormComponent implements OnInit {
  form: FormGroup;
  modulos: Modulo[] = [];
  checkedPermisos: string[] = [];
  isEditing = false;
  rolId: number | null = null;
  rolActual: Rol | null = null;
  /** Indica si el rol que se está editando es el rol del usuario logueado (riesgo de auto-bloqueo). */
  esMiRol = false;
  loading = false;
  loadingData = true;

  constructor(
    private fb: FormBuilder,
    private rolService: RolService,
    private catalogoService: CatalogoService,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(50)]],
      descripcion: ['', [Validators.maxLength(200)]]
    });
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    this.isEditing = !!id;
    this.rolId = id ? Number(id) : null;

    const modulos$ = this.catalogoService.getModulos();
    const rol$ = this.isEditing ? this.rolService.getById(this.rolId!) : of(null);

    forkJoin({ modulos: modulos$, rol: rol$ }).subscribe({
      next: ({ modulos, rol }) => {
        this.modulos = modulos;

        if (rol) {
          this.rolActual = rol;
          this.form.patchValue({
            nombre: rol.nombre,
            descripcion: rol.descripcion
          });
          this.checkedPermisos = [...rol.permisos];
          this.esMiRol = this.authService.getCurrentUser()?.rol === rol.nombre;
        }

        this.loadingData = false;
        this.detectChanges();
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudieron cargar los datos del formulario', 'error');
        this.router.navigate(['/roles']);
      }
    });
  }

  onMatrizChange(codigos: string[]): void {
    const quitados = this.checkedPermisos.filter(code => !codigos.includes(code));
    this.checkedPermisos = codigos;

    // Riesgo mitigado: si se está editando el rol propio y se desmarcan permisos,
    // advertir que guardar podría bloquear el acceso a módulos.
    if (this.esMiRol && quitados.length > 0) {
      Swal.fire({
        icon: 'warning',
        title: 'Cuidado: estás editando tu propio rol',
        text: 'Quitaste permisos de tu propio rol. Si guardas, podrías perder acceso a algunos módulos.',
        confirmButtonText: 'Entendido'
      });
    }
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
    const dto: RolRequest = {
      nombre: formValue.nombre,
      descripcion: formValue.descripcion,
      permisos: this.checkedPermisos
    };

    const request = this.isEditing
      ? this.rolService.update(this.rolId!, dto)
      : this.rolService.create(dto);

    request.subscribe({
      next: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Rol actualizado' : 'Rol creado',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/roles']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.error || 'No se pudo guardar el rol', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/roles']);
  }
}
