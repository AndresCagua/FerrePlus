import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { MovimientoListComponent } from './movimiento-list/movimiento-list.component';
import { MovimientoFormComponent } from './movimiento-form/movimiento-form.component';

const routes: Routes = [
  { path: '', component: MovimientoListComponent },
  { path: 'nuevo', component: MovimientoFormComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class MovimientosRoutingModule { }
