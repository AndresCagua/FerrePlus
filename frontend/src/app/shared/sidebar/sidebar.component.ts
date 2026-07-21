import { ChangeDetectionStrategy, Component, Input, Output, EventEmitter } from '@angular/core';
import { AuthService } from '../../core/auth.service';

interface MenuItem {
  label: string;
  icon: string;
  route: string;
  roles?: string[];
}

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

  menuItems: MenuItem[] = [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard' },
    { label: 'Productos', icon: 'inventory_2', route: '/productos' },
    { label: 'Categorías', icon: 'category', route: '/categorias' },
    { label: 'Proveedores', icon: 'local_shipping', route: '/proveedores' },
    { label: 'Clientes', icon: 'people', route: '/clientes' },
    { label: 'Ventas', icon: 'point_of_sale', route: '/ventas' },
    { label: 'Compras', icon: 'shopping_cart', route: '/compras' },
    { label: 'Precios', icon: 'attach_money', route: '/gestion-precios' },
    { label: 'Movimientos', icon: 'swap_vert', route: '/movimientos' },
    { label: 'Gastos', icon: 'money_off', route: '/gastos' },
    { label: 'Usuarios', icon: 'manage_accounts', route: '/usuarios', roles: ['ADMIN'] },
    { label: 'Reportes', icon: 'bar_chart', route: '/reportes', roles: ['ADMIN', 'SUPERVISOR'] }
  ];

  constructor(public authService: AuthService) {}

  get visibleMenuItems(): MenuItem[] {
    return this.menuItems.filter(item => {
      if (!item.roles || item.roles.length === 0) {
        return true;
      }
      return this.authService.hasAnyRole(item.roles);
    });
  }

  onToggle(): void {
    this.toggleSidebar.emit();
  }
}
