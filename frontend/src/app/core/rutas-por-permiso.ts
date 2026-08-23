/**
 * Fuente única de verdad del mapa ruta → permiso (R7).
 *
 * Lista las rutas top-level de la aplicación con el permiso `MODULO_VER`
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
  /** Identifica un nodo virtual de agrupacion del menu administrativo. */
  module?: boolean;
  /** Rutas secundarias que se muestran como submenu del item. */
  children?: RutaPorPermiso[];
}

export const RUTAS_POR_PERMISO: RutaPorPermiso[] = [
  { label: 'Dashboard', icon: 'dashboard', route: '/dashboard', permissions: ['DASHBOARD_VER'] },
  {
    label: 'Talento',
    icon: 'work',
    route: '/talento',
    permissions: [],
    module: true,
    children: [
      { label: 'Publicaciones', icon: 'article', route: '/talento/publicaciones', permissions: ['TALENTO_PUBLICACIONES_VER'] },
      { label: 'Convocatorias laborales', icon: 'work_outline', route: '/talento/convocatorias', permissions: ['TALENTO_CONVOCATORIAS_VER'] },
      { label: 'Postulaciones', icon: 'assignment_ind', route: '/talento/postulaciones', permissions: ['TALENTO_POSTULACIONES_VER'] },
      { label: 'Destinatarios', icon: 'mark_email_read', route: '/talento/destinatarios', permissions: ['TALENTO_DESTINATARIOS_VER'] }
    ]
  },
  {
    label: 'Bodega',
    icon: 'warehouse',
    route: '/bodega',
    permissions: [],
    module: true,
    children: [
      { label: 'Productos', icon: 'inventory_2', route: '/productos', permissions: ['PRODUCTOS_VER'] },
      { label: 'Categorías', icon: 'category', route: '/categorias', permissions: ['CATEGORIAS_VER'] },
      { label: 'Proveedores', icon: 'local_shipping', route: '/proveedores', permissions: ['PROVEEDORES_VER'] },
      { label: 'Movimientos', icon: 'swap_vert', route: '/movimientos', permissions: ['MOVIMIENTOS_VER'] }
    ]
  },
  {
    label: 'Contabilidad',
    icon: 'account_balance',
    route: '/contabilidad',
    permissions: [],
    module: true,
    children: [
      { label: 'Contactos', icon: 'contact_mail', route: '/talento/contactos', permissions: ['CONTABILIDAD_CONTACTOS_VER'] },
      { label: 'Gastos', icon: 'money_off', route: '/gastos', permissions: ['GASTOS_VER'] },
      { label: 'Ventas', icon: 'point_of_sale', route: '/ventas', permissions: ['VENTAS_VER'] },
      { label: 'Compras', icon: 'shopping_cart', route: '/compras', permissions: ['COMPRAS_VER'] },
      { label: 'Clientes', icon: 'people', route: '/clientes', permissions: ['CLIENTES_VER'] },
      { label: 'Precios', icon: 'attach_money', route: '/gestion-precios', permissions: ['PRECIOS_VER'] },
      { label: 'Reportes', icon: 'bar_chart', route: '/reportes', permissions: ['REPORTES_VER'] }
    ]
  },
  {
    label: 'Mantenimiento',
    icon: 'build',
    route: '/mantenimiento',
    permissions: [],
    module: true,
    children: [
      { label: 'Usuarios', icon: 'manage_accounts', route: '/usuarios', permissions: ['USUARIOS_VER'] },
      { label: 'Roles', icon: 'admin_panel_settings', route: '/roles', permissions: ['ROLES_VER'] },
      { label: 'Logs', icon: 'receipt_long', route: '/logs', permissions: ['LOGS_VER'] }
    ]
  }
];

/** Filtra una jerarquia de menu sin exponer rutas que el usuario no puede ver. */
export function filtrarRutasPorPermiso(
  rutas: RutaPorPermiso[],
  hasAnyPermission: (permissions: string[]) => boolean
): RutaPorPermiso[] {
  return rutas.reduce<RutaPorPermiso[]>((visibleRoutes, ruta) => {
    const children = ruta.children
      ? filtrarRutasPorPermiso(ruta.children, hasAnyPermission)
      : undefined;
    const hasRoutePermission = !ruta.permissions?.length || hasAnyPermission(ruta.permissions);

    const hasVisibleChildren = (children?.length ?? 0) > 0;
    if ((ruta.module && hasVisibleChildren) || (!ruta.module && (hasRoutePermission || hasVisibleChildren))) {
      visibleRoutes.push({ ...ruta, children });
    }

    return visibleRoutes;
  }, []);
}

/** Retorna los permisos requeridos para una ruta top-level (o [] si no está mapeada). */
export function permisosDeRuta(route: string): string[] {
  const ruta = buscarRuta(RUTAS_POR_PERMISO, route);
  if (!ruta) {
    return [];
  }
  if (ruta.permissions?.length) {
    return ruta.permissions;
  }
  return permisosDeDescendientes(ruta);
}

/** Indica si una URL pertenece a una ruta declarada, incluyendo rutas anidadas. */
export function existeRutaParaUrl(url: string): boolean {
  return !!buscarRutaPorUrl(RUTAS_POR_PERMISO, url);
}

function buscarRuta(rutas: RutaPorPermiso[], route: string): RutaPorPermiso | undefined {
  for (const ruta of rutas) {
    if (ruta.route === route) {
      return ruta;
    }
    const encontrada = ruta.children ? buscarRuta(ruta.children, route) : undefined;
    if (encontrada) {
      return encontrada;
    }
  }
  return undefined;
}

function buscarRutaPorUrl(rutas: RutaPorPermiso[], url: string): RutaPorPermiso | undefined {
  for (const ruta of rutas) {
    if (url === ruta.route || url.startsWith(`${ruta.route}/`)) {
      const childMatch = ruta.children ? buscarRutaPorUrl(ruta.children, url) : undefined;
      return childMatch ?? ruta;
    }
    const childMatch = ruta.children ? buscarRutaPorUrl(ruta.children, url) : undefined;
    if (childMatch) {
      return childMatch;
    }
  }
  return undefined;
}

function permisosDeDescendientes(ruta: RutaPorPermiso): string[] {
  return (ruta.children ?? []).flatMap(child =>
    child.children?.length ? permisosDeDescendientes(child) : child.permissions ?? []
  );
}
