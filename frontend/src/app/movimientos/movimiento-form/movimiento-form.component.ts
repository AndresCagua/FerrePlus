import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { MovimientoService } from '../movimiento.service';
import { ProductoService } from '../../productos/producto.service';
import { AuthService } from '../../core/auth.service';
import { Producto } from '../../core/models';

@Component({
  selector: 'app-movimiento-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './movimiento-form.component.html',
  styleUrls: ['./movimiento-form.component.scss']
})
export class MovimientoFormComponent implements OnInit {
  form: FormGroup;
  loading = false;
  productos: Producto[] = [];
  productoSelected: Producto | null = null;

  constructor(
    private fb: FormBuilder,
    private movimientoService: MovimientoService,
    private productoService: ProductoService,
    private authService: AuthService,
    private router: Router
  ) {
    this.form = this.fb.group({
      productoId: ['', Validators.required],
      tipo: ['ENTRADA', Validators.required],
      cantidad: [1, [Validators.required, Validators.min(1)]],
      motivo: ['', Validators.required],
      referencia: ['']
    });

    this.form.get('productoId')?.valueChanges.subscribe(id => {
      if (id) {
        this.productoSelected = this.productos.find(p => p.id === id) || null;
      } else {
        this.productoSelected = null;
      }
    });
  }

  ngOnInit(): void {
    this.loadProductos();
  }

  loadProductos(): void {
    this.productoService.list().subscribe({
      next: (productos) => {
        this.productos = productos;
      }
    });
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    if (this.productoSelected && this.form.get('tipo')?.value === 'SALIDA') {
      const qty = this.form.get('cantidad')?.value;
      if (qty > this.productoSelected.stockActual) {
        Swal.fire('Stock insuficiente',
          `Stock actual: ${this.productoSelected.stockActual}. No puedes registrar una salida de ${qty}.`,
          'warning');
        return;
      }
    }

    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    const data = {
      ...this.form.value,
      usuarioId: currentUser?.usuarioId
    };

    this.movimientoService.create(data).subscribe({
      next: () => {
        this.loading = false;
        Swal.fire({
          icon: 'success',
          title: 'Movimiento registrado',
          text: 'El movimiento de inventario se registró correctamente',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/movimientos']);
      },
      error: (err) => {
        this.loading = false;
        Swal.fire('Error', err.error?.message || 'No se pudo registrar el movimiento', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/movimientos']);
  }
}
