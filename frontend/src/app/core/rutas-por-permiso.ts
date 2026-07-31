/**
 * Fuente única de verdad del mapa ruta → permiso (R7).
 *
 * Lista las 13 rutas top-level de la aplicación con el permiso `MODULO_VER`
 * que cada una requiere. Este mapa lo consumen:
 *  - `SidebarComponent` (items del menú filtrados por permiso),
 *  - `AuthService.getHomeRoute()` (navegación post-login),
 *  - `AuthGuard` (redirect a la primera ruta permitida),
 *  - `AppRoutingModule` (`data.permissions` de cada ruta).
 *
 * El orden del arreglo define la prioridad de `getHomeRoute()`: DASHBOARD
 * primero y luego el resto en orden de menú.
 */
export interface RutaPorPermiso {
  label: string;
  icon: string;
  /** Path top-level (con `/` inicial). */
  route: string;
  /** Permisos `MODULO_VER` requeridos para acceder (se evalúa con hasAnyPermission). */
  permissions?: string[];
}

export const RUTAS_POR_PERMISO: RutaPorPermiso[] = [
  { label: 'Dashboard', icon: 'dashboard', route: '/dashboard', permissions: ['DASHBOARD_VER'] },
  { label: 'Productos', icon: 'inventory_2', route: '/productos', permissions: ['PRODUCTOS_VER'] },
  { label: 'Categorías', icon: 'category', route: '/categorias', permissions: ['CATEGORIAS_VER'] },
  { label: 'Proveedores', icon: 'local_shipping', route: '/proveedores', permissions: ['PROVEEDORES_VER'] },
  { label: 'Clientes', icon: 'people', route: '/clientes', permissions: ['CLIENTES_VER'] },
  { label: 'Ventas', icon: 'point_of_sale', route: '/ventas', permissions: ['VENTAS_VER'] },
  { label: 'Compras', icon: 'shopping_cart', route: '/compras', permissions: ['COMPRAS_VER'] },
  { label: 'Precios', icon: 'attach_money', route: '/gestion-precios', permissions: ['PRECIOS_VER'] },
  { label: 'Movimientos', icon: 'swap_vert', route: '/movimientos', permissions: ['MOVIMIENTOS_VER'] },
  { label: 'Gastos', icon: 'money_off', route: '/gastos', permissions: ['GASTOS_VER'] },
  { label: 'Usuarios', icon: 'manage_accounts', route: '/usuarios', permissions: ['USUARIOS_VER'] },
  { label: 'Roles', icon: 'admin_panel_settings', route: '/roles', permissions: ['ROLES_VER'] },
  { label: 'Reportes', icon: 'bar_chart', route: '/reportes', permissions: ['REPORTES_VER'] }
];

/** Retorna los permisos requeridos para una ruta top-level (o [] si no está mapeada). */
export function permisosDeRuta(route: string): string[] {
  return RUTAS_POR_PERMISO.find(item => item.route === route)?.permissions ?? [];
}
