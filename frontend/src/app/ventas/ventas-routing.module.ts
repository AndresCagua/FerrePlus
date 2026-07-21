import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { VentaListComponent } from './venta-list/venta-list.component';
import { VentaFormComponent } from './venta-form/venta-form.component';
import { VentaDetailComponent } from './venta-detail/venta-detail.component';

const routes: Routes = [
  { path: '', component: VentaListComponent },
  { path: 'nueva', component: VentaFormComponent },
  { path: ':id', component: VentaDetailComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class VentasRoutingModule { }
