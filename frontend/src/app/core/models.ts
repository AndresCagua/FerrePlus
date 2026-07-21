// ===== AUTH =====
export interface AuthResponse {
  token: string;
  email: string;
  nombre: string;
  rol: string;
  usuarioId: number;
}

// ===== USUARIO =====
export interface Usuario {
  id: number;
  nombre: string;
  email: string;
  telefono: string;
  activo: boolean;
  rolId: number;
  rolNombre: string;
  password?: string;
  fechaCreacion?: string;
  fechaActualizacion?: string;
}

// ===== CATEGORIA =====
export interface Categoria {
  id: number;
  nombre: string;
  descripcion: string;
  fechaCreacion?: string;
}

// ===== PRODUCTO =====
export interface Producto {
  id: number;
  nombre: string;
  descripcion?: string;
  codigoBarras: string;
  ubicacion?: string;
  stockActual: number;
  stockMinimo: number;
  stockMaximo: number;
  precioCompra: number;
  precioVenta: number;
  unidadMedida: string;
  imagen?: string;
  categoria?: Categoria;
  proveedor?: Proveedor;
  activo: boolean;
  fechaCreacion?: string;
  fechaActualizacion?: string;
}

// ===== PROVEEDOR =====
export interface Proveedor {
  id: number;
  nombre: string;
  ruc: string;
  contacto: string;
  telefono: string;
  email: string;
  direccion: string;
  activo: boolean;
  fechaCreacion?: string;
}

// ===== CLIENTE =====
export interface Cliente {
  id: number;
  nombre: string;
  ruc: string;
  telefono: string;
  email: string;
  direccion: string;
  saldoPendiente: number;
  activo: boolean;
  fechaCreacion?: string;
}

// ===== DETALLE VENTA =====
export interface DetalleVenta {
  id: number;
  productoId: number;
  productoNombre: string;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
  producto?: Producto; // cuando viene del backend como objeto anidado
}

// ===== VENTA =====
export interface Venta {
  id: number;
  numeroFactura: string;
  cliente?: Cliente;
  subtotal: number;
  descuento: number;
  iva: number;
  total: number;
  metodoPago: string;
  estado: string;
  observaciones?: string;
  usuario?: Usuario;
  fechaCreacion?: string;
  fechaAnulacion?: string;
  detalles?: DetalleVenta[];
}

// ===== DETALLE COMPRA =====
export interface DetalleCompra {
  id: number;
  productoId: number;
  productoNombre: string;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
  producto?: Producto; // cuando viene del backend como objeto anidado
}

// ===== COMPRA =====
export interface Compra {
  id: number;
  numeroFactura: string;
  proveedor?: Proveedor;
  subtotal: number;
  descuento: number;
  iva: number;
  total: number;
  estado: string;
  observaciones?: string;
  usuario?: Usuario;
  fechaCreacion?: string;
  fechaAnulacion?: string;
  detalles?: DetalleCompra[];
}

// ===== MOVIMIENTO STOCK =====
export interface Movimiento {
  id: number;
  producto?: Producto;
  cantidad: number;
  tipo: string;
  referencia?: string;
  motivo: string;
  precioUnitario?: number;
  usuario?: Usuario;
  stockAnterior: number;
  stockPosterior: number;
  fecha?: string;
}

// ===== GASTO =====
export interface Gasto {
  id: number;
  descripcion: string;
  monto: number;
  categoria: string;
  metodoPago: string;
  numeroComprobante?: string;
  fechaGasto?: string;
  observaciones?: string;
  usuario?: Usuario;
  fechaCreacion?: string;
}

// ===== REPORTE / DASHBOARD DATA =====
export interface VentaDiaria {
  fecha: string;
  total: number;
}

export interface DashboardData {
  totalProductos: number;
  productosStockBajo: number;
  ventasHoy: number;
  totalVentasHoy: number;
  ventasMes: number;
  totalVentasMes: number;
  comprasMes: number;
  totalComprasMes: number;
  gastosMes: number;
  totalGastosMes: number;
  totalClientes: number;
  totalProveedores: number;
  totalUsuarios: number;
  saldoPendienteClientes: number;
  productosStockBajoList?: Producto[];
  ventasPorDia?: VentaDiaria[];
}
