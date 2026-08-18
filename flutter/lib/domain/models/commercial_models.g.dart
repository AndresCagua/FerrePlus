// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commercial_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DetalleVenta _$DetalleVentaFromJson(Map<String, dynamic> json) =>
    _DetalleVenta(
      id: (json['id'] as num?)?.toInt(),
      productoId: (json['productoId'] as num?)?.toInt(),
      productoNombre: json['productoNombre'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: json['precioUnitario'] as num,
      subtotal: json['subtotal'] as num?,
    );

Map<String, dynamic> _$DetalleVentaToJson(_DetalleVenta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productoId': instance.productoId,
      'productoNombre': instance.productoNombre,
      'cantidad': instance.cantidad,
      'precioUnitario': instance.precioUnitario,
      'subtotal': instance.subtotal,
    };

_Venta _$VentaFromJson(Map<String, dynamic> json) => _Venta(
  id: (json['id'] as num).toInt(),
  numeroFactura: json['numeroFactura'] as String?,
  clienteId: (json['clienteId'] as num?)?.toInt(),
  clienteNombre: json['clienteNombre'] as String?,
  subtotal: json['subtotal'] as num,
  descuento: json['descuento'] as num,
  iva: json['iva'] as num,
  total: json['total'] as num,
  metodoPago: json['metodoPago'] as String?,
  estado: json['estado'] as String?,
  observaciones: json['observaciones'] as String?,
  usuarioId: (json['usuarioId'] as num?)?.toInt(),
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
  fechaAnulacion: json['fechaAnulacion'] == null
      ? null
      : DateTime.parse(json['fechaAnulacion'] as String),
  detalles:
      (json['detalles'] as List<dynamic>?)
          ?.map((e) => DetalleVenta.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DetalleVenta>[],
);

Map<String, dynamic> _$VentaToJson(_Venta instance) => <String, dynamic>{
  'id': instance.id,
  'numeroFactura': instance.numeroFactura,
  'clienteId': instance.clienteId,
  'clienteNombre': instance.clienteNombre,
  'subtotal': instance.subtotal,
  'descuento': instance.descuento,
  'iva': instance.iva,
  'total': instance.total,
  'metodoPago': instance.metodoPago,
  'estado': instance.estado,
  'observaciones': instance.observaciones,
  'usuarioId': instance.usuarioId,
  'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
  'fechaAnulacion': instance.fechaAnulacion?.toIso8601String(),
  'detalles': instance.detalles,
};

_VentaRequest _$VentaRequestFromJson(Map<String, dynamic> json) =>
    _VentaRequest(
      numeroFactura: json['numeroFactura'] as String?,
      clienteId: (json['clienteId'] as num?)?.toInt(),
      subtotal: json['subtotal'] as num,
      descuento: json['descuento'] as num,
      iva: json['iva'] as num,
      total: json['total'] as num,
      metodoPago: json['metodoPago'] as String?,
      estado: json['estado'] as String?,
      observaciones: json['observaciones'] as String?,
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
      detalles: (json['detalles'] as List<dynamic>)
          .map((e) => DetalleVenta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VentaRequestToJson(_VentaRequest instance) =>
    <String, dynamic>{
      'numeroFactura': instance.numeroFactura,
      'clienteId': instance.clienteId,
      'subtotal': instance.subtotal,
      'descuento': instance.descuento,
      'iva': instance.iva,
      'total': instance.total,
      'metodoPago': instance.metodoPago,
      'estado': instance.estado,
      'observaciones': instance.observaciones,
      'usuarioId': instance.usuarioId,
      'detalles': instance.detalles,
    };

_DetalleCompra _$DetalleCompraFromJson(Map<String, dynamic> json) =>
    _DetalleCompra(
      id: (json['id'] as num?)?.toInt(),
      productoId: (json['productoId'] as num?)?.toInt(),
      productoNombre: json['productoNombre'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: json['precioUnitario'] as num,
      subtotal: json['subtotal'] as num?,
    );

Map<String, dynamic> _$DetalleCompraToJson(_DetalleCompra instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productoId': instance.productoId,
      'productoNombre': instance.productoNombre,
      'cantidad': instance.cantidad,
      'precioUnitario': instance.precioUnitario,
      'subtotal': instance.subtotal,
    };

_Compra _$CompraFromJson(Map<String, dynamic> json) => _Compra(
  id: (json['id'] as num).toInt(),
  numeroFactura: json['numeroFactura'] as String,
  proveedorId: (json['proveedorId'] as num?)?.toInt(),
  proveedorNombre: json['proveedorNombre'] as String?,
  subtotal: json['subtotal'] as num,
  descuento: json['descuento'] as num,
  iva: json['iva'] as num,
  total: json['total'] as num,
  estado: json['estado'] as String?,
  observaciones: json['observaciones'] as String?,
  fechaFactura: json['fechaFactura'] == null
      ? null
      : DateTime.parse(json['fechaFactura'] as String),
  usuarioId: (json['usuarioId'] as num?)?.toInt(),
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
  detalles:
      (json['detalles'] as List<dynamic>?)
          ?.map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DetalleCompra>[],
);

Map<String, dynamic> _$CompraToJson(_Compra instance) => <String, dynamic>{
  'id': instance.id,
  'numeroFactura': instance.numeroFactura,
  'proveedorId': instance.proveedorId,
  'proveedorNombre': instance.proveedorNombre,
  'subtotal': instance.subtotal,
  'descuento': instance.descuento,
  'iva': instance.iva,
  'total': instance.total,
  'estado': instance.estado,
  'observaciones': instance.observaciones,
  'fechaFactura': instance.fechaFactura?.toIso8601String(),
  'usuarioId': instance.usuarioId,
  'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
  'detalles': instance.detalles,
};

_CompraRequest _$CompraRequestFromJson(Map<String, dynamic> json) =>
    _CompraRequest(
      numeroFactura: json['numeroFactura'] as String,
      proveedorId: (json['proveedorId'] as num?)?.toInt(),
      subtotal: json['subtotal'] as num,
      descuento: json['descuento'] as num,
      iva: json['iva'] as num,
      total: json['total'] as num,
      estado: json['estado'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaFactura: json['fechaFactura'] == null
          ? null
          : DateTime.parse(json['fechaFactura'] as String),
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
      detalles: (json['detalles'] as List<dynamic>)
          .map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CompraRequestToJson(_CompraRequest instance) =>
    <String, dynamic>{
      'numeroFactura': instance.numeroFactura,
      'proveedorId': instance.proveedorId,
      'subtotal': instance.subtotal,
      'descuento': instance.descuento,
      'iva': instance.iva,
      'total': instance.total,
      'estado': instance.estado,
      'observaciones': instance.observaciones,
      'fechaFactura': instance.fechaFactura?.toIso8601String(),
      'usuarioId': instance.usuarioId,
      'detalles': instance.detalles,
    };

_MovimientoStock _$MovimientoStockFromJson(Map<String, dynamic> json) =>
    _MovimientoStock(
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num?)?.toInt(),
      productoNombre: json['productoNombre'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      tipo: json['tipo'] as String,
      referencia: json['referencia'] as String?,
      motivo: json['motivo'] as String?,
      precioUnitario: json['precioUnitario'] as num?,
      stockAnterior: (json['stockAnterior'] as num?)?.toInt(),
      stockPosterior: (json['stockPosterior'] as num?)?.toInt(),
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
      usuarioNombre: json['usuarioNombre'] as String?,
      fecha: json['fecha'] == null
          ? null
          : DateTime.parse(json['fecha'] as String),
    );

Map<String, dynamic> _$MovimientoStockToJson(_MovimientoStock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productoId': instance.productoId,
      'productoNombre': instance.productoNombre,
      'cantidad': instance.cantidad,
      'tipo': instance.tipo,
      'referencia': instance.referencia,
      'motivo': instance.motivo,
      'precioUnitario': instance.precioUnitario,
      'stockAnterior': instance.stockAnterior,
      'stockPosterior': instance.stockPosterior,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'fecha': instance.fecha?.toIso8601String(),
    };

_MovimientoStockRequest _$MovimientoStockRequestFromJson(
  Map<String, dynamic> json,
) => _MovimientoStockRequest(
  productoId: (json['productoId'] as num).toInt(),
  cantidad: (json['cantidad'] as num).toInt(),
  tipo: json['tipo'] as String,
  referencia: json['referencia'] as String?,
  motivo: json['motivo'] as String?,
  precioUnitario: json['precioUnitario'] as num?,
  usuarioId: (json['usuarioId'] as num?)?.toInt(),
);

Map<String, dynamic> _$MovimientoStockRequestToJson(
  _MovimientoStockRequest instance,
) => <String, dynamic>{
  'productoId': instance.productoId,
  'cantidad': instance.cantidad,
  'tipo': instance.tipo,
  'referencia': instance.referencia,
  'motivo': instance.motivo,
  'precioUnitario': instance.precioUnitario,
  'usuarioId': instance.usuarioId,
};

_Gasto _$GastoFromJson(Map<String, dynamic> json) => _Gasto(
  id: (json['id'] as num).toInt(),
  descripcion: json['descripcion'] as String,
  monto: json['monto'] as num,
  categoria: json['categoria'] as String?,
  metodoPago: json['metodoPago'] as String?,
  numeroComprobante: json['numeroComprobante'] as String?,
  fechaGasto: json['fechaGasto'] == null
      ? null
      : DateTime.parse(json['fechaGasto'] as String),
  observaciones: json['observaciones'] as String?,
  usuarioId: (json['usuarioId'] as num?)?.toInt(),
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$GastoToJson(_Gasto instance) => <String, dynamic>{
  'id': instance.id,
  'descripcion': instance.descripcion,
  'monto': instance.monto,
  'categoria': instance.categoria,
  'metodoPago': instance.metodoPago,
  'numeroComprobante': instance.numeroComprobante,
  'fechaGasto': instance.fechaGasto?.toIso8601String(),
  'observaciones': instance.observaciones,
  'usuarioId': instance.usuarioId,
  'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
};

_GastoRequest _$GastoRequestFromJson(Map<String, dynamic> json) =>
    _GastoRequest(
      descripcion: json['descripcion'] as String,
      monto: json['monto'] as num,
      categoria: json['categoria'] as String?,
      metodoPago: json['metodoPago'] as String?,
      numeroComprobante: json['numeroComprobante'] as String?,
      fechaGasto: json['fechaGasto'] == null
          ? null
          : DateTime.parse(json['fechaGasto'] as String),
      observaciones: json['observaciones'] as String?,
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GastoRequestToJson(_GastoRequest instance) =>
    <String, dynamic>{
      'descripcion': instance.descripcion,
      'monto': instance.monto,
      'categoria': instance.categoria,
      'metodoPago': instance.metodoPago,
      'numeroComprobante': instance.numeroComprobante,
      'fechaGasto': instance.fechaGasto?.toIso8601String(),
      'observaciones': instance.observaciones,
      'usuarioId': instance.usuarioId,
    };
