// ===== AUTH =====
export interface AuthResponse {
  token: string;
  email: string;
  nombre: string;
  rol: string;
  usuarioId: number;
  /** Códigos de permiso efectivos del usuario (rol ∪ concedidos ∖ denegados). */
  permisos: string[];
}

// ===== CATÁLOGO DE PERMISOS / ROLES =====
export interface Permiso {
  id: number;
  codigo: string;
  nombre: string;
  accion: string;
  moduloId?: number;
  moduloCodigo?: string;
  moduloNombre?: string;
}

export interface Modulo {
  id: number;
  nombre: string;
  codigo: string;
  orden: number;
  permisos: Permiso[];
}

export interface Rol {
  id: number;
  nombre: string;
  descripcion: string;
  /** Códigos de permiso de la matriz del rol. */
  permisos: string[];
}

export interface RolRequest {
  nombre: string;
  descripcion: string;
  permisos: string[];
}

export interface UsuarioPermisoOverride {
  permisoCodigo: string;
  concedido: boolean;
}

export interface UsuarioRequestPayload {
  nombre: string;
  email: string;
  telefono: string;
  activo: boolean;
  rolId: number;
  password?: string;
  overrides: UsuarioPermisoOverride[];
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
  /** Códigos de permiso efectivos (rol ∪ concedidos ∖ denegados). Opcional porque `Usuario` también se usa anidado en ventas/compras/etc. */
  permisos?: string[];
  overrides?: UsuarioPermisoOverride[];
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

// ===== GESTIÓN DE PRECIOS =====
export interface PrecioProducto {
  id: number;
  nombre: string;
  codigoBarras: string;
  precioCompra: number;
  precioVenta: number;
  ganancia: number | null;
  margenPorcentaje: number | null;
  fechaActualizacion: string;
}

export interface HistoricoPrecioProducto {
  id: number;
  productoId: number;
  precioCompra: number;
  precioVenta: number;
  tipoCambio: string;
  referencia: string | null;
  fechaCambio: string;
  usuarioNombre: string | null;
}

export interface ActualizarPrecioVentaRequest {
  nuevoPrecio?: number;
  margenPorcentaje?: number;
  referencia?: string;
}

// ===== LOGS / AUDITORÍA =====
/** Envelope de paginación server-side (formato Spring `Page<T>`, R2/R7). */
export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first?: boolean;
  last?: boolean;
}

/** Fila de auditoría expuesta por `GET /api/logs` (R2). */
export interface AuditoriaLog {
  id: number;
  entidad: string;
  entidadId: number | null;
  accion: string;
  usuarioId?: number | null;
  usuarioNombre?: string | null;
  fecha: string;
  detalle?: string | null;
}

/** Respuesta de `DELETE /api/logs?desde=&hasta=` (R3): conteo de filas eliminadas. */
export interface EliminarLogsResponse {
  eliminados: number;
}

// ===== CHAT =====
export interface ChatRequest {
  question: string;
}

export interface ChatSource {
  entityType: string;
  entityId: number;
  excerpt?: string;
  metadata?: Record<string, unknown>;
}

export interface ChatResponse {
  answer: string;
  sources: ChatSource[];
}
