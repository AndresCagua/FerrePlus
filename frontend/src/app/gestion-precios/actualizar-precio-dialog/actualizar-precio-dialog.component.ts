import { ChangeDetectionStrategy, Component, Inject } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { PrecioService } from '../precio.service';
import { ActualizarPrecioVentaRequest } from '../../core/models';

export interface ActualizarPrecioDialogData {
  productoId: number;
  precioCompraActual: number;
}

@Component({
  selector: 'app-actualizar-precio-dialog',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './actualizar-precio-dialog.component.html',
  styleUrls: ['./actualizar-precio-dialog.component.scss']
})
export class ActualizarPrecioDialog {
  form: FormGroup;
  saving = false;
  precioCompraCero = this.data.precioCompraActual === 0;

  constructor(
    private fb: FormBuilder,
    private precioService: PrecioService,
    private dialogRef: MatDialogRef<ActualizarPrecioDialog>,
    @Inject(MAT_DIALOG_DATA) private data: ActualizarPrecioDialogData
  ) {
    this.form = this.fb.group({
      tipoOpcion: ['precio'],
      nuevoPrecio: [null, [Validators.min(0.01)]],
      margenPorcentaje: [{ value: null, disabled: true }, [Validators.min(0.01)]],
      referencia: ['']
    });

    // Cuando cambia la opción seleccionada, habilitar/deshabilitar campos
    this.form.get('tipoOpcion')?.valueChanges.subscribe(tipo => {
      if (tipo === 'precio') {
        this.form.get('nuevoPrecio')?.enable({ emitEvent: false });
        this.form.get('margenPorcentaje')?.disable({ emitEvent: false });
        this.form.get('margenPorcentaje')?.reset(null, { emitEvent: false });
      } else {
        this.form.get('margenPorcentaje')?.enable({ emitEvent: false });
        this.form.get('nuevoPrecio')?.disable({ emitEvent: false });
        this.form.get('nuevoPrecio')?.reset(null, { emitEvent: false });
      }
    });
  }

  onGuardar(): void {
    if (this.form.invalid) return;

    const dto: ActualizarPrecioVentaRequest = {};
    const tipo = this.form.get('tipoOpcion')?.value;
    const referencia = this.form.get('referencia')?.value;

    if (tipo === 'precio') {
      const val = this.form.get('nuevoPrecio')?.value;
      if (!val || val <= 0) return;
      dto.nuevoPrecio = Number(val);
    } else {
      const val = this.form.get('margenPorcentaje')?.value;
      if (!val || val <= 0) return;
      dto.margenPorcentaje = Number(val);
    }

    if (referencia) {
      dto.referencia = referencia;
    }

    this.saving = true;
    this.precioService.actualizarPrecioVenta(this.data.productoId, dto).subscribe({
      next: () => {
        this.saving = false;
        this.dialogRef.close(true);
      },
      error: () => {
        this.saving = false;
      }
    });
  }

  onCancelar(): void {
    this.dialogRef.close(false);
  }
}
