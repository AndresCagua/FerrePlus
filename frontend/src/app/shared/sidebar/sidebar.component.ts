import { ChangeDetectionStrategy, Component, DestroyRef, EventEmitter, Input, Output, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs/operators';
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
  private static readonly STORAGE_KEY = 'ferreplus_menu_v1';
  @Input() collapsed = false;
  @Output() toggleSidebar = new EventEmitter<void>();

  /**
   * Items del menú desde la fuente única de verdad (`RUTAS_POR_PERMISO`):
   * el sidebar, la navegación post-login y el guard comparten el mismo mapa
   * ruta → permiso (R7).
   */
  menuItems: RutaPorPermiso[] = RUTAS_POR_PERMISO;
  visibleMenuItems: RutaPorPermiso[] = [];
  expandedGroups: Record<string, boolean> = {};

  private readonly destroyRef = inject(DestroyRef);
  private readonly router = inject(Router, { optional: true });
  private activeUrl = this.router?.url ?? '';

  constructor(public authService: AuthService) {
    this.authService.currentUser$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        this.refreshMenu();
      });
    this.router?.events
      .pipe(filter(event => event instanceof NavigationEnd), takeUntilDestroyed(this.destroyRef))
      .subscribe(event => {
        this.activeUrl = (event as NavigationEnd).urlAfterRedirects;
        this.openActiveGroup();
      });
  }

  private refreshMenu(): void {
    this.visibleMenuItems = filtrarRutasPorPermiso(
      this.menuItems,
      permissions => this.authService.hasAnyPermission(permissions)
    );
    const stored = this.readExpandedGroups();
    this.expandedGroups = {};
    this.visibleMenuItems.filter(item => item.module).forEach(item => {
      this.expandedGroups[item.route] = stored[item.route] ?? false;
    });
    this.openActiveGroup();
  }

  private openActiveGroup(): void {
    const activeGroup = this.visibleMenuItems.find(item => item.module && this.isModuleActive(item));
    if (activeGroup) {
      this.expandedGroups[activeGroup.route] = true;
    }
  }

  private readExpandedGroups(): Record<string, boolean> {
    try {
      const stored = localStorage.getItem(SidebarComponent.STORAGE_KEY);
      if (!stored) return {};
      const parsed: unknown = JSON.parse(stored);
      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};
      return Object.fromEntries(
        Object.entries(parsed).filter(([, value]) => typeof value === 'boolean')
      );
    } catch {
      return {};
    }
  }

  private persistExpandedGroups(): void {
    try {
      localStorage.setItem(SidebarComponent.STORAGE_KEY, JSON.stringify(this.expandedGroups));
    } catch {
      // El menu sigue funcionando en memoria si el navegador bloquea storage.
    }
  }

  /** El grupo navega a una pagina accesible, incluso si esta colapsado. */
  navigationRoute(item: RutaPorPermiso): string {
    return item.children?.[0]?.route ?? item.route;
  }

  isExpanded(item: RutaPorPermiso): boolean {
    return !!this.expandedGroups[item.route];
  }

  isModuleActive(item: RutaPorPermiso): boolean {
    return !!item.children?.some(child =>
      this.activeUrl === child.route || this.activeUrl.startsWith(`${child.route}/`)
    );
  }

  groupContentId(item: RutaPorPermiso): string {
    return `menu-group-${item.label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
  }

  toggleModule(item: RutaPorPermiso): void {
    this.expandedGroups[item.route] = !this.isExpanded(item);
    this.persistExpandedGroups();
  }

  onModuleKeydown(event: KeyboardEvent, item: RutaPorPermiso): void {
    if (event.key === 'Enter' || event.key === ' ' || event.key === 'Spacebar') {
      event.preventDefault();
      this.toggleModule(item);
    }
  }

  trackByRoute(_index: number, item: RutaPorPermiso): string {
    return item.route;
  }

  onToggle(): void {
    this.toggleSidebar.emit();
  }
}
