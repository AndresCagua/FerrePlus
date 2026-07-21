import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ProductoService } from '../producto.service';
import { CategoriaService } from '../../categorias/categoria.service';
import { Categoria } from '../../core/models';

@Component({
  selector: 'app-producto-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './producto-form.component.html',
  styleUrls: ['./producto-form.component.scss']
})
export class ProductoFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  productoId: number | null = null;
  loading = false;
  loadingData = true;
  categorias: Categoria[] = [];

  constructor(
    private fb: FormBuilder,
    private productoService: ProductoService,
    private categoriaService: CategoriaService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.form = this.fb.group({
      codigoBarras: [''],
      nombre: ['', [Validators.required, Validators.maxLength(200)]],
      descripcion: [''],
      ubicacion: [''],
      categoriaId: ['', Validators.required],
      precioVenta: [0, [Validators.required, Validators.min(0.01)]],
      precioCompra: [0, [Validators.required, Validators.min(0.01)]],
      stockActual: [0, [Validators.required, Validators.min(0)]],
      stockMinimo: [0, [Validators.required, Validators.min(0)]],
      stockMaximo: [0],
      unidadMedida: ['UNIDAD', Validators.required],
      activo: [true]
    });
  }

  ngOnInit(): void {
    this.loadCategorias();
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditing = true;
      this.productoId = Number(id);
      this.loadProducto(this.productoId);
    } else {
      this.loadingData = false;
    }
  }

  loadCategorias(): void {
    this.categoriaService.list().subscribe({
      next: (categorias) => {
        this.categorias = categorias;
      }
    });
  }

  loadProducto(id: number): void {
    this.productoService.getById(id).subscribe({
      next: (producto) => {
        this.form.patchValue({
          codigoBarras: producto.codigoBarras,
          nombre: producto.nombre,
          descripcion: producto.descripcion,
          ubicacion: producto.ubicacion,
          categoriaId: producto.categoria?.id,
          precioVenta: producto.precioVenta,
          precioCompra: producto.precioCompra,
          stockActual: producto.stockActual,
          stockMinimo: producto.stockMinimo,
          stockMaximo: producto.stockMaximo,
          unidadMedida: producto.unidadMedida,
          activo: producto.activo
        });
        this.loadingData = false;
      },
      error: () => {
        this.loadingData = false;
        Swal.fire('Error', 'No se pudo cargar el producto', 'error');
        this.router.navigate(['/productos']);
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
    const formValue = this.form.value;

    const data: any = {
      nombre: formValue.nombre,
      descripcion: formValue.descripcion || null,
      codigoBarras: formValue.codigoBarras || null,
      ubicacion: formValue.ubicacion || null,
      stockActual: formValue.stockActual,
      stockMinimo: formValue.stockMinimo,
      stockMaximo: formValue.stockMaximo,
      precioCompra: formValue.precioCompra,
      precioVenta: formValue.precioVenta,
      unidadMedida: formValue.unidadMedida,
      activo: formValue.activo
    };

    if (formValue.categoriaId) {
      data.categoria = { id: formValue.categoriaId };
    }

    const request = this.isEditing
      ? this.productoService.update(this.productoId!, data)
      : this.productoService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Producto actualizado' : 'Producto creado',
          text: this.isEditing ? 'Los cambios se guardaron correctamente' : 'El producto se registró correctamente',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/productos']);
      },
      error: (err) => {
        this.loading = false;
        Swal.fire('Error', err.error?.message || 'No se pudo guardar el producto', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/productos']);
  }
}
