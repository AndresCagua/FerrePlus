import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { PreciosListComponent } from './precios-list/precios-list.component';
import { PrecioDetailComponent } from './precio-detail/precio-detail.component';

const routes: Routes = [
  { path: '', component: PreciosListComponent },
  { path: ':id', component: PrecioDetailComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class GestionPreciosRoutingModule { }
