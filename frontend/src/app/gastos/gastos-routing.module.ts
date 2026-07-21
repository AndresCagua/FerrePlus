import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { GastoListComponent } from './gasto-list/gasto-list.component';
import { GastoFormComponent } from './gasto-form/gasto-form.component';

const routes: Routes = [
  { path: '', component: GastoListComponent },
  { path: 'nuevo', component: GastoFormComponent },
  { path: ':id/editar', component: GastoFormComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class GastosRoutingModule { }
