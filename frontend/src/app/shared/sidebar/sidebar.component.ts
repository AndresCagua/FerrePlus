import { ChangeDetectionStrategy, Component, DestroyRef, EventEmitter, Input, Output, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../core/auth.service';
import {
  filtrarRutasPorPermiso,
  RUTAS_POR_PERMISO,
  RutaPorPermiso
} from '../../core/rutas-por-permiso';

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
  visibleMenuItems: RutaPorPermiso[] = [];

  private readonly destroyRef = inject(DestroyRef);

  constructor(public authService: AuthService) {
    this.authService.currentUser$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        this.visibleMenuItems = filtrarRutasPorPermiso(
          this.menuItems,
          permissions => this.authService.hasAnyPermission(permissions)
        );
      });
  }

  /** El grupo navega a una pagina accesible, incluso si esta colapsado. */
  navigationRoute(item: RutaPorPermiso): string {
    return item.children?.[0]?.route ?? item.route;
  }

  trackByRoute(_index: number, item: RutaPorPermiso): string {
    return item.route;
  }

  onToggle(): void {
    this.toggleSidebar.emit();
  }
}
