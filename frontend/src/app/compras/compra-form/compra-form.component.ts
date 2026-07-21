import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { CompraService } from '../compra.service';
import { ProveedorService } from '../../proveedores/proveedor.service';
import { ProductoService } from '../../productos/producto.service';
import { AuthService } from '../../core/auth.service';
import { Proveedor, Producto } from '../../core/models';

@Component({
  selector: 'app-compra-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './compra-form.component.html',
  styleUrls: ['./compra-form.component.scss']
})
export class CompraFormComponent implements OnInit {
  form: FormGroup;
  loading = false;
  proveedores: Proveedor[] = [];
  productos: Producto[] = [];
  filteredProductos: Producto[] = [];

  constructor(
    private fb: FormBuilder,
    private compraService: CompraService,
    private proveedorService: ProveedorService,
    private productoService: ProductoService,
    private authService: AuthService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      proveedorId: ['', Validators.required],
      items: this.fb.array([])
    });
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    this.loadProveedores();
    this.loadProductos();
  }

  get items(): FormArray {
    return this.form.get('items') as FormArray;
  }

  loadProveedores(): void {
    this.proveedorService.list().subscribe({
      next: (proveedores) => {
        this.proveedores = proveedores.filter(p => p.activo);
        this.detectChanges();
      }
    });
  }

  loadProductos(): void {
    this.productoService.list().subscribe({
      next: (productos) => {
        this.productos = productos;
        this.filteredProductos = [...productos];
        this.detectChanges();
      }
    });
  }

  addItem(): void {
    const itemGroup = this.fb.group({
      productoId: ['', Validators.required],
      cantidad: [1, [Validators.required, Validators.min(1)]],
      precioUnitario: [0, [Validators.required, Validators.min(0.01)]]
    });
    this.items.push(itemGroup);
  }

  removeItem(index: number): void {
    this.items.removeAt(index);
  }

  get subtotal(): number {
    return this.items.controls.reduce((sum, item) => {
      return sum + (item.get('cantidad')?.value || 0) * (item.get('precioUnitario')?.value || 0);
    }, 0);
  }

  get iva(): number {
    return this.subtotal * 0.12;
  }

  get total(): number {
    return this.subtotal + this.iva;
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      Swal.fire('Formulario incompleto', 'Completa todos los campos requeridos', 'warning');
      return;
    }

    if (this.items.length === 0) {
      Swal.fire('Sin items', 'Agrega al menos un producto', 'warning');
      return;
    }

    this.loading = true;
    this.detectChanges();
    const currentUser = this.authService.getCurrentUser();
    const data = {
      proveedorId: this.form.get('proveedorId')?.value,
      usuarioId: currentUser?.usuarioId,
      detalles: this.items.controls.map(c => ({
        productoId: c.get('productoId')?.value,
        cantidad: c.get('cantidad')?.value,
        precioUnitario: c.get('precioUnitario')?.value
      }))
    };

    this.compraService.create(data).subscribe({
      next: (compra) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: 'Compra registrada',
          text: `Factura #${compra.numeroFactura} - Total: $${compra.total.toFixed(2)}`,
          confirmButtonText: 'OK'
        });
        this.router.navigate(['/compras']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo registrar la compra', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/compras']);
  }
}
