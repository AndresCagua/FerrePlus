import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { CategoriaService } from '../categoria.service';
import { Categoria } from '../../core/models';

@Component({
  selector: 'app-categoria-form',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './categoria-form.component.html',
  styleUrls: ['./categoria-form.component.scss']
})
export class CategoriaFormComponent implements OnInit {
  form: FormGroup;
  isEditing = false;
  categoriaId: number | null = null;
  loading = false;
  loadingData = true;

  constructor(
    private fb: FormBuilder,
    private categoriaService: CategoriaService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.form = this.fb.group({
      nombre: ['', [Validators.required, Validators.maxLength(100)]],
      descripcion: ['', Validators.maxLength(255)]
    });
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditing = true;
      this.categoriaId = Number(id);
      this.loadCategoria(this.categoriaId);
    } else {
      this.loadingData = false;
    }
  }

  loadCategoria(id: number): void {
    this.categoriaService.getById(id).subscribe({
      next: (categoria) => {
        this.form.patchValue({
          nombre: categoria.nombre,
          descripcion: categoria.descripcion
        });
        this.loadingData = false;
      },
      error: () => {
        this.loadingData = false;
        Swal.fire('Error', 'No se pudo cargar la categoría', 'error');
        this.router.navigate(['/categorias']);
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
    const data = this.form.value;

    const request = this.isEditing
      ? this.categoriaService.update(this.categoriaId!, data)
      : this.categoriaService.create(data);

    request.subscribe({
      next: () => {
        this.loading = false;
        Swal.fire({
          icon: 'success',
          title: this.isEditing ? 'Categoría actualizada' : 'Categoría creada',
          timer: 1500,
          showConfirmButton: false
        });
        this.router.navigate(['/categorias']);
      },
      error: (err) => {
        this.loading = false;
        Swal.fire('Error', err.error?.message || 'No se pudo guardar la categoría', 'error');
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/categorias']);
  }
}
