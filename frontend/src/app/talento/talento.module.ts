import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { SharedModule } from '../shared/shared.module';
import { TalentoRoutingModule } from './talento-routing.module';
import { IndisponibilidadTalentoComponent } from './components/indisponibilidad/indisponibilidad.component';
import { CvDownloadComponent } from './components/cv-download/cv-download.component';
import { PublicacionListComponent } from './pages/publicaciones/publicacion-list/publicacion-list.component';
import { PublicacionFormComponent } from './pages/publicaciones/publicacion-form/publicacion-form.component';
import { ConvocatoriaListComponent } from './pages/convocatorias/convocatoria-list/convocatoria-list.component';
import { ConvocatoriaFormComponent } from './pages/convocatorias/convocatoria-form/convocatoria-form.component';
import { PostulacionListComponent } from './pages/postulaciones/postulacion-list/postulacion-list.component';
import { PostulacionDetailComponent } from './pages/postulaciones/postulacion-detail/postulacion-detail.component';
import { ContactosComponent } from './pages/contactos/contactos.component';
import { DestinatariosComponent } from './pages/destinatarios/destinatarios.component';

@NgModule({ declarations: [IndisponibilidadTalentoComponent, CvDownloadComponent, PublicacionListComponent, PublicacionFormComponent, ConvocatoriaListComponent, ConvocatoriaFormComponent, PostulacionListComponent, PostulacionDetailComponent, ContactosComponent, DestinatariosComponent], imports: [CommonModule, ReactiveFormsModule, RouterModule, SharedModule, TalentoRoutingModule, MatTableModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatProgressSpinnerModule, MatSelectModule] })
export class TalentoModule {}
