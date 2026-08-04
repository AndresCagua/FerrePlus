import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';

/** Rango confirmado por el usuario en el diálogo (formato `yyyy-MM-dd`). */
export interface BorrarLogsRango {
  desde: string;
  hasta: string;
}

/**
 * Diálogo destructivo de borrado por rango (R8): selecciona desde/hasta con
 * datepickers, muestra el rango y exige confirmación explícita. El borrado es
 * IRREVERSIBLE y no se conoce el conteo antes de ejecutar; Cancelar no ejecuta
 * nada (no llama al endpoint).
 */
@Component({
  selector: 'app-borrar-logs-dialog',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './borrar-logs-dialog.component.html',
  styleUrls: ['./borrar-logs-dialog.component.scss']
})
export class BorrarLogsDialog {
  form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<BorrarLogsDialog>
  ) {
    this.form = this.fb.group({
      desde: [null, Validators.required],
      hasta: [null, Validators.required]
    });
  }

  /** Rango revertido (`hasta` anterior a `desde`) → no se puede confirmar. */
  get rangoInvalido(): boolean {
    const desde = this.form.get('desde')?.value as Date | null;
    const hasta = this.form.get('hasta')?.value as Date | null;
    return !!(desde && hasta && hasta.getTime() < desde.getTime());
  }

  onConfirmar(): void {
    if (this.form.invalid || this.rangoInvalido) {
      return;
    }
    this.dialogRef.close({
      desde: this.toDateString(this.form.get('desde')?.value as Date),
      hasta: this.toDateString(this.form.get('hasta')?.value as Date)
    });
  }

  onCancelar(): void {
    this.dialogRef.close(null);
  }

  private toDateString(fecha: Date): string {
    const year = fecha.getFullYear();
    const month = String(fecha.getMonth() + 1).padStart(2, '0');
    const day = String(fecha.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
