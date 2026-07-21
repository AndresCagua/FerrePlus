import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule } from '@angular/material/dialog';
import { MatRadioModule } from '@angular/material/radio';
import { MatTooltipModule } from '@angular/material/tooltip';
import { BaseChartDirective } from 'ng2-charts';

import { GestionPreciosRoutingModule } from './gestion-precios-routing.module';
import { PreciosListComponent } from './precios-list/precios-list.component';
import { PrecioDetailComponent } from './precio-detail/precio-detail.component';
import { ActualizarPrecioDialog } from './actualizar-precio-dialog/actualizar-precio-dialog.component';

@NgModule({
  declarations: [
    PreciosListComponent,
    PrecioDetailComponent,
    ActualizarPrecioDialog
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    GestionPreciosRoutingModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatProgressSpinnerModule,
    MatDialogModule,
    MatRadioModule,
    MatTooltipModule,
    BaseChartDirective
  ]
})
export class GestionPreciosModule { }
