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
}
