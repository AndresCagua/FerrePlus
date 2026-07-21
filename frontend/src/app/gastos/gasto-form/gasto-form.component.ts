import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { GastoService } from '../gasto.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-gasto-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './gasto-form.component.html',
  styleUrls: ['./gasto-form.component.scss']
})
export class GastoFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  gastoId: number | null = null;
  loading = false;
  loadingData = true;

  categorias = [
    'SERVICIOS', 'ALQUILER', 'SUMINISTROS', 'MANTENIMIENTO',
    'TRANSPORTE', 'IMPUESTOS', 'SALARIOS', 'MARKETING', 'OTROS'
  ];

  constructor(
    private fb: FormBuilder,
    private gastoService: GastoService,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      descripcion: ['', [Validators.required, Validators.maxLength(255)]],
      monto: [0, [Validators.required, Validators.min(0.01)]],
      categoria: ['OTROS', Validators.required],
      metodoPago: ['EFECTIVO', Validators.required],
      numeroComprobante: [''],
      observaciones: ['']
    });
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditing = true;
      this.gastoId = Number(id);
      this.loadGasto(this.gastoId);
    } else {
      this.loadingData = false;
      this.detectChanges();
    }
  }

  loadGasto(id: number): void {
    this.gastoService.getById(id).subscribe({
      next: (gasto) => {
        this.form.patchValue({
          descripcion: gasto.descripcion,
          monto: gasto.monto,
          categoria: gasto.categoria,
          metodoPago: gasto.metodoPago,
          numeroComprobante: gasto.numeroComprobante,
          observaciones: gasto.observaciones
        });
        this.loadingData = false;
        this.detectChanges();
      },
      error: () => {
        this.loadingData = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar el gasto', 'error');
        this.router.navigate(['/gastos']);
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
    const currentUser = this.authService.getCurrentUser();
    const data = {
      ...this.form.value,
      usuarioId: currentUser?.usuarioId
    };

    const request = this.isEditing
      ? this.gastoService.update(this.gastoId!, data)
      : this.gastoService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Gasto actualizado' : 'Gasto registrado',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/gastos']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo guardar el gasto', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/gastos']);
  }
}
