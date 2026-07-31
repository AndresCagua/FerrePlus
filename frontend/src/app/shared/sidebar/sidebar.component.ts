import { ChangeDetectionStrategy, Component, Input, Output, EventEmitter } from '@angular/core';
import { AuthService } from '../../core/auth.service';
import { RUTAS_POR_PERMISO, RutaPorPermiso } from '../../core/rutas-por-permiso';

@Component({
  selector: 'app-sidebar',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent {
  @Input() collapsed = false;
  @Output() toggleSidebar = new EventEmitter<void>();

  /**
   * Items del menú desde la fuente única de verdad (`RUTAS_POR_PERMISO`):
   * el sidebar, la navegación post-login y el guard comparten el mismo mapa
   * ruta → permiso (R7).
   */
  menuItems: RutaPorPermiso[] = RUTAS_POR_PERMISO;

  constructor(public authService: AuthService) {}

  get visibleMenuItems(): RutaPorPermiso[] {
    return this.menuItems.filter(item =>
      !item.permissions || item.permissions.length === 0 ||
      this.authService.hasAnyPermission(item.permissions)
    );
  }

  onToggle(): void {
    this.toggleSidebar.emit();
  }
}
