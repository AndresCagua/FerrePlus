import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatDialogModule } from '@angular/material/dialog';

import { LogsRoutingModule } from './logs-routing.module';
import { SharedModule } from '../shared/shared.module';
import { LogListComponent } from './log-list/log-list.component';
import { BorrarLogsDialog } from './log-list/borrar-logs-dialog.component';

/**
 * Módulo de Logs (R7/R8): consulta paginada server-side + borrado por rango.
 * NgModule NO standalone (patrón del proyecto, `config.yaml`). La ruta `/logs`
 * se carga lazy desde `app-routing.module.ts` con `LOGS_VER` en `data.permissions`.
 */
@NgModule({
  declarations: [
    LogListComponent,
    BorrarLogsDialog
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    LogsRoutingModule,
    SharedModule,
    MatTableModule,
    MatPaginatorModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatSelectModule,
    MatProgressSpinnerModule,
    MatTooltipModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatDialogModule
  ]
})
export class LogsModule { }
