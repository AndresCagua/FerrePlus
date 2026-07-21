import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CompraListComponent } from './compra-list/compra-list.component';
import { CompraFormComponent } from './compra-form/compra-form.component';

const routes: Routes = [
  { path: '', component: CompraListComponent },
  { path: 'nueva', component: CompraFormComponent },
  { path: 'editar/:id', component: CompraFormComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ComprasRoutingModule { }
