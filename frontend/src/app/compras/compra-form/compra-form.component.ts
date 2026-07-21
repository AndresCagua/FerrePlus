import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { CompraService } from '../compra.service';
import { ProveedorService } from '../../proveedores/proveedor.service';
import { ProductoService } from '../../productos/producto.service';
import { AuthService } from '../../core/auth.service';
import { IVA_RATE } from '../../core/constants';
import { Proveedor, Producto, Compra, DetalleCompra } from '../../core/models';

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
  editando = false;
  compraId: number | null = null;
  proveedores: Proveedor[] = [];
  productos: Producto[] = [];
  filteredProductos: Producto[] = [];

  constructor(
    private fb: FormBuilder,
    private compraService: CompraService,
    private proveedorService: ProveedorService,
    private productoService: ProductoService,
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      numeroFactura: ['', Validators.required],
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

    // Verificar si es edición
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editando = true;
      this.compraId = Number(id);
      this.cargarCompra(this.compraId);
    }
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

  cargarCompra(id: number): void {
    this.loading = true;
    this.detectChanges();
    this.compraService.getById(id).subscribe({
      next: (compra) => {
        this.form.patchValue({
          proveedorId: compra.proveedor?.id,
          numeroFactura: compra.numeroFactura
        });
        compra.detalles?.forEach(d => this.agregarItemDesdeDetalle(d));
        this.loading = false;
        this.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar la compra', 'error');
        this.router.navigate(['/compras']);
      }
    });
  }

  private agregarItemDesdeDetalle(d: DetalleCompra): void {
    const prodId = d.productoId ?? d.producto?.id;
    const prodNombre = d.productoNombre ?? d.producto?.nombre;
    const itemGroup = this.fb.group({
      productoId: [prodId, Validators.required],
      nombre: [prodNombre],
      cantidad: [d.cantidad, [Validators.required, Validators.min(1)]],
      precioUnitario: [d.precioUnitario, [Validators.required, Validators.min(0.01)]]
    });
    this.items.push(itemGroup);
  }

  addItem(): void {
    const itemGroup = this.fb.group({
      productoId: ['', Validators.required],
      nombre: [''],
      cantidad: [1, [Validators.required, Validators.min(1)]],
      precioUnitario: [0, [Validators.required, Validators.min(0.01)]]
    });
    this.items.push(itemGroup);
  }

  removeItem(index: number): void {
    this.items.removeAt(index);
  }

  onProductoChange(index: number): void {
    const control = this.items.at(index);
    const productoId = control.get('productoId')?.value;
    const producto = this.productos.find(p => p.id === productoId);
    if (producto) {
      control.patchValue({
        nombre: producto.nombre,
        precioUnitario: producto.precioCompra || producto.precioVenta
      });
    }
  }

  get subtotal(): number {
    return this.items.controls.reduce((sum, item) => {
      return sum + (item.get('cantidad')?.value || 0) * (item.get('precioUnitario')?.value || 0);
    }, 0);
  }

  get iva(): number {
    return this.subtotal * IVA_RATE;
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
      numeroFactura: this.form.get('numeroFactura')?.value,
      proveedorId: this.form.get('proveedorId')?.value,
      usuarioId: currentUser?.usuarioId,
      subtotal: this.subtotal,
      descuento: 0,
      iva: this.iva,
      total: this.total,
      detalles: this.items.controls.map(c => ({
        productoId: c.get('productoId')?.value,
        cantidad: c.get('cantidad')?.value,
        precioUnitario: c.get('precioUnitario')?.value,
        subtotal: (c.get('cantidad')?.value || 0) * (c.get('precioUnitario')?.value || 0)
      }))
    };

    const request = this.editando && this.compraId
      ? this.compraService.update(this.compraId, data)
      : this.compraService.create(data);

    request.subscribe({
      next: (compra) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire({
          icon: 'success',
          title: this.editando ? 'Compra actualizada' : 'Compra registrada',
          text: `Factura #${compra.numeroFactura} - Total: $${compra.total.toFixed(2)}`,
          confirmButtonText: 'OK'
        });
        this.router.navigate(['/compras']);
      },
      error: (err) => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', err.error?.message || 'No se pudo guardar la compra', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/compras']);
  }
}
