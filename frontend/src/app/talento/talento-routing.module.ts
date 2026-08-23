import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { PublicacionListComponent } from './pages/publicaciones/publicacion-list/publicacion-list.component';
import { PublicacionFormComponent } from './pages/publicaciones/publicacion-form/publicacion-form.component';
import { ConvocatoriaListComponent } from './pages/convocatorias/convocatoria-list/convocatoria-list.component';
import { ConvocatoriaFormComponent } from './pages/convocatorias/convocatoria-form/convocatoria-form.component';
import { PostulacionListComponent } from './pages/postulaciones/postulacion-list/postulacion-list.component';
import { PostulacionDetailComponent } from './pages/postulaciones/postulacion-detail/postulacion-detail.component';
import { ContactosComponent } from './pages/contactos/contactos.component';
import { DestinatariosComponent } from './pages/destinatarios/destinatarios.component';
import { AuthGuard } from '../core/auth.guard';

const routes: Routes = [
  { path: '', redirectTo: 'publicaciones', pathMatch: 'full' },
  { path: 'publicaciones', component: PublicacionListComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_PUBLICACIONES_VER'] } },
  { path: 'publicaciones/nuevo', component: PublicacionFormComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_PUBLICACIONES_CREAR'] } },
  { path: 'publicaciones/:id/editar', component: PublicacionFormComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_PUBLICACIONES_EDITAR'] } },
  { path: 'convocatorias', component: ConvocatoriaListComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_CONVOCATORIAS_VER'] } },
  { path: 'convocatorias/nuevo', component: ConvocatoriaFormComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_CONVOCATORIAS_CREAR'] } },
  { path: 'convocatorias/:id/editar', component: ConvocatoriaFormComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_CONVOCATORIAS_EDITAR'] } },
  { path: 'postulaciones', component: PostulacionListComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_POSTULACIONES_VER'] } },
  { path: 'postulaciones/:id', component: PostulacionDetailComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_POSTULACIONES_VER'] } },
  { path: 'contactos', component: ContactosComponent, canActivate: [AuthGuard], data: { permissions: ['CONTABILIDAD_CONTACTOS_VER'] } },
  { path: 'destinatarios', component: DestinatariosComponent, canActivate: [AuthGuard], data: { permissions: ['TALENTO_DESTINATARIOS_VER'] } }
];

@NgModule({ imports: [RouterModule.forChild(routes)], exports: [RouterModule] })
export class TalentoRoutingModule {}
