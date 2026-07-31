import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatBadgeModule } from '@angular/material/badge';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatExpansionModule } from '@angular/material/expansion';

import { SidebarComponent } from './sidebar/sidebar.component';
import { HeaderComponent } from './header/header.component';
import { PermisosMatrizComponent } from './permisos-matriz/permisos-matriz.component';
import { HasPermissionDirective } from '../core/has-permission.directive';

@NgModule({
  declarations: [
    SidebarComponent,
    HeaderComponent,
    PermisosMatrizComponent,
    HasPermissionDirective
  ],
  imports: [
    CommonModule,
    RouterModule,
    MatIconModule,
    MatTooltipModule,
    MatBadgeModule,
    MatButtonModule,
    MatMenuModule,
    MatDividerModule,
    MatCheckboxModule,
    MatExpansionModule
  ],
  exports: [
    SidebarComponent,
    HeaderComponent,
    PermisosMatrizComponent,
    HasPermissionDirective
  ]
})
export class SharedModule { }
