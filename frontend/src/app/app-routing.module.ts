import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/auth.guard';
import { permisosDeRuta } from './core/rutas-por-permiso';

const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  {
    path: 'auth',
    loadChildren: () => import('./auth/auth.module').then(m => m.AuthModule)
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/dashboard') }
  },
  {
    path: 'productos',
    loadChildren: () => import('./productos/productos.module').then(m => m.ProductosModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/productos') }
  },
  {
    path: 'categorias',
    loadChildren: () => import('./categorias/categorias.module').then(m => m.CategoriasModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/categorias') }
  },
  {
    path: 'proveedores',
    loadChildren: () => import('./proveedores/proveedores.module').then(m => m.ProveedoresModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/proveedores') }
  },
  {
    path: 'clientes',
    loadChildren: () => import('./clientes/clientes.module').then(m => m.ClientesModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/clientes') }
  },
  {
    path: 'ventas',
    loadChildren: () => import('./ventas/ventas.module').then(m => m.VentasModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/ventas') }
  },
  {
    path: 'compras',
    loadChildren: () => import('./compras/compras.module').then(m => m.ComprasModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/compras') }
  },
  {
    path: 'gestion-precios',
    loadChildren: () => import('./gestion-precios/gestion-precios.module').then(m => m.GestionPreciosModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/gestion-precios') }
  },
  {
    path: 'movimientos',
    loadChildren: () => import('./movimientos/movimientos.module').then(m => m.MovimientosModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/movimientos') }
  },
  {
    path: 'gastos',
    loadChildren: () => import('./gastos/gastos.module').then(m => m.GastosModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/gastos') }
  },
  {
    path: 'usuarios',
    loadChildren: () => import('./usuarios/usuarios.module').then(m => m.UsuariosModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/usuarios') }
  },
  {
    path: 'roles',
    loadChildren: () => import('./roles/roles.module').then(m => m.RolesModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/roles') }
  },
  {
    path: 'reportes',
    loadChildren: () => import('./reportes/reportes.module').then(m => m.ReportesModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/reportes') }
  },
  {
    path: 'logs',
    loadChildren: () => import('./logs/logs.module').then(m => m.LogsModule),
    canActivate: [AuthGuard],
    data: { permissions: permisosDeRuta('/logs') }
  },
  { path: '**', redirectTo: '/dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
