class ApiPaths {
  const ApiPaths._();

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String currentUser = '/api/usuarios/me';
  static const String productos = '/api/productos';
  static const String productosStockBajo = '/api/productos/stock-bajo';
  static const String categorias = '/api/categorias';
  static const String proveedores = '/api/proveedores';
  static const String clientes = '/api/clientes';
  static const String ventas = '/api/ventas';
  static const String compras = '/api/compras';
  static const String movimientosStock = '/api/movimientos-stock';
  static const String gastos = '/api/gastos';
  static const String reportesVentas = '/api/reportes/ventas';
  static const String ventasReporte = '/api/ventas/reportes/por-fecha';
  static const String comprasReporte = '/api/compras/reportes/por-fecha';
  static const String precios = '/api/precios';
  static const String usuarios = '/api/usuarios';
  static const String roles = '/api/roles';
  static const String modulos = '/api/modulos';
  static const String permisos = '/api/permisos';
  static const String reportesDashboard = '/api/reportes/dashboard';
  static const String reportesInventario = '/api/reportes/inventario';
  static const String reportesMovimientos = '/api/reportes/movimientos';
  static const String logs = '/api/logs';
  static const String chat = '/api/chat';
  static const String chatIndexRebuild = '/api/chat/index/rebuild';
}
