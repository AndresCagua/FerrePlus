import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { RolListComponent } from './rol-list/rol-list.component';
import { RolFormComponent } from './rol-form/rol-form.component';

const routes: Routes = [
  { path: '', component: RolListComponent },
  { path: 'nuevo', component: RolFormComponent },
  { path: ':id/editar', component: RolFormComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class RolesRoutingModule { }
