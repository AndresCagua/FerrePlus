import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { VentaService } from '../venta.service';
import { ProductoService } from '../../productos/producto.service';
import { ClienteService } from '../../clientes/cliente.service';
import { AuthService } from '../../core/auth.service';
import { Producto, Cliente } from '../../core/models';

@Component({
  selector: 'app-venta-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './venta-form.component.html',
  styleUrls: ['./venta-form.component.scss']
})
export class VentaFormComponent implements OnInit {
  form: FormGroup;
  loading = false;
  productos: Producto[] = [];
  clientes: Cliente[] = [];
  productoSearchTerm = '';
  filteredProductos: Producto[] = [];
  selectedProducto: Producto | null = null;

  constructor(
    private fb: FormBuilder,
    private ventaService: VentaService,
    private productoService: ProductoService,
    private clienteService: ClienteService,
    private authService: AuthService,
    private router: Router
  ) {
    this.form = this.fb.group({
      clienteId: [null],
      metodoPago: ['EFECTIVO', Validators.required],
      items: this.fb.array([])
    });
  }

  ngOnInit(): void {
    this.loadProductos();
    this.loadClientes();
  }

  get items(): FormArray {
    return this.form.get('items') as FormArray;
  }

  loadProductos(): void {
    this.productoService.list().subscribe({
      next: (productos) => {
        this.productos = productos.filter(p => p.activo && p.stockActual > 0);
        this.filteredProductos = [...this.productos];
      }
    });
  }

  loadClientes(): void {
    this.clienteService.list().subscribe({
      next: (clientes) => {
        this.clientes = clientes.filter(c => c.activo);
      }
    });
  }

  filterProductos(event: Event): void {
    const term = (event.target as HTMLInputElement).value.toLowerCase();
    this.filteredProductos = this.productos.filter(p =>
      p.nombre.toLowerCase().includes(term) ||
      (p.codigoBarras && p.codigoBarras.toLowerCase().includes(term))
    );
  }

  addProductoToCart(producto: Producto): void {
    const existingIndex = this.items.controls.findIndex(
      item => item.get('productoId')?.value === producto.id
    );

    if (existingIndex >= 0) {
      const control = this.items.at(existingIndex);
      const currentQty = control.get('cantidad')?.value || 0;
      if (currentQty < producto.stockActual) {
        control.patchValue({ cantidad: currentQty + 1 });
      } else {
        Swal.fire('Stock insuficiente', `Stock disponible: ${producto.stockActual}`, 'warning');
      }
    } else {
      const itemGroup = this.fb.group({
        productoId: [producto.id],
        productoNombre: [producto.nombre],
        cantidad: [1, [Validators.required, Validators.min(1)]],
        precioUnitario: [{ value: producto.precioVenta, disabled: true }],
        subtotal: [producto.precioVenta]
      });

      itemGroup.get('cantidad')?.valueChanges.subscribe(qty => {
        const unitPrice = itemGroup.get('precioUnitario')?.value || 0;
        itemGroup.patchValue({ subtotal: (qty ?? 0) * unitPrice }, { emitEvent: false });
        this.updateTotals();
      });

      this.items.push(itemGroup);
    }

    this.productoSearchTerm = '';
    this.filteredProductos = [...this.productos];
    this.selectedProducto = null;
    this.updateTotals();
  }

  removeItem(index: number): void {
    this.items.removeAt(index);
    this.updateTotals();
  }

  updateQuantity(index: number, qty: number): void {
    const control = this.items.at(index);
    const producto = this.productos.find(p => p.id === control.get('productoId')?.value);
    if (producto && qty > producto.stockActual) {
      Swal.fire('Stock insuficiente', `Stock disponible: ${producto.stockActual}`, 'warning');
      control.patchValue({ cantidad: producto.stockActual });
      return;
    }
    control.patchValue({ cantidad: qty < 1 ? 1 : qty });
  }

  updateTotals(): void {
    // Totals are computed reactively
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

  get itemCount(): number {
    return this.items.controls.reduce((sum, item) => sum + (item.get('cantidad')?.value || 0), 0);
  }

  hasItems(): boolean {
    return this.items.controls.some(c => c.get('productoId')?.value);
  }

  itemAt(index: number): AbstractControl | null {
    return this.items.controls[index] ?? null;
  }

  clearCart(): void {
    while (this.items.length > 0) {
      this.items.removeAt(0);
    }
  }

  onSubmit(): void {
    if (this.items.length === 0 || this.items.controls.every(c => !c.get('productoId')?.value)) {
      Swal.fire('Carrito vacío', 'Agrega al menos un producto', 'warning');
      return;
    }

    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    const ventaData: any = {
      clienteId: this.form.get('clienteId')?.value || null,
      metodoPago: this.form.get('metodoPago')?.value,
      usuarioId: currentUser?.usuarioId,
      detalles: this.items.controls
        .filter(c => c.get('productoId')?.value)
        .map(c => ({
          productoId: c.get('productoId')?.value,
          cantidad: c.get('cantidad')?.value,
          precioUnitario: c.get('precioUnitario')?.value
        }))
    };

    this.ventaService.create(ventaData).subscribe({
      next: (venta) => {
        this.loading = false;
        Swal.fire({
          icon: 'success',
          title: 'Venta registrada',
          text: `Factura #${venta.numeroFactura} - Total: $${venta.total.toFixed(2)}`,
          confirmButtonText: 'Ver detalle'
        }).then(() => {
          this.router.navigate(['/ventas', venta.id]);
        });
      },
      error: (err) => {
        this.loading = false;
        Swal.fire('Error', err.error?.message || 'No se pudo registrar la venta', 'error');
      }
    });
  }

  cancel(): void {
    if (this.items.length > 0 && this.items.controls.some(c => c.get('productoId')?.value)) {
      Swal.fire({
        title: '¿Cancelar venta?',
        text: 'Los datos ingresados se perderán',
        icon: 'question',
        showCancelButton: true,
        confirmButtonColor: '#c62828',
        cancelButtonColor: '#78909c',
        confirmButtonText: 'Sí, cancelar',
        cancelButtonText: 'Continuar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.router.navigate(['/ventas']);
        }
      });
    } else {
      this.router.navigate(['/ventas']);
    }
  }
}
