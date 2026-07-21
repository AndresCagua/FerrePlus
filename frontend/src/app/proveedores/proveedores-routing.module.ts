import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ProveedorListComponent } from './proveedor-list/proveedor-list.component';
import { ProveedorFormComponent } from './proveedor-form/proveedor-form.component';

const routes: Routes = [
  { path: '', component: ProveedorListComponent },
  { path: 'nuevo', component: ProveedorFormComponent },
  { path: ':id/editar', component: ProveedorFormComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ProveedoresRoutingModule { }
