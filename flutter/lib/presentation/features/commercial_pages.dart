// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use,
// ignore_for_file: prefer_const_constructors, use_null_aware_elements
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/permission_codes.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/use_cases/build_purchase.dart';
import '../../domain/use_cases/build_sale.dart';
import 'catalog_providers.dart';
import 'commercial_providers.dart';

Widget _error(Object error, VoidCallback retry) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text('Error: $error'),
      FilledButton(onPressed: retry, child: const Text('Reintentar')),
    ],
  ),
);

Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) =>
    showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );

Future<bool> _confirm(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: const Text('Esta accion no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String? status;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(status ?? 'SIN_ESTADO'));
}

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});
  @override
  ConsumerState<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends ConsumerState<VentasPage> {
  DateTime? from;
  DateTime? to;
  String? status;
  int? client;
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Venta>> value = ref.watch(ventasProvider);
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final List<Cliente> clients =
        ref.watch(clientesProvider).value ?? <Cliente>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/ventas/reportes'),
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      floatingActionButton: permissions.contains(PermissionCodes.ventasCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/ventas/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          _CommercialFilters(
            from: from,
            to: to,
            status: status,
            options: <String>['COMPLETADA', 'ANULADA', 'PENDIENTE'],
            onStatus: (String? v) {
              status = v;
              _filter();
            },
            onFrom: (DateTime? v) {
              from = v;
              _filter();
            },
            onTo: (DateTime? v) {
              to = v;
              _filter();
            },
            extra: DropdownButton<int>(
              hint: const Text('Cliente'),
              value: client,
              items: clients
                  .map(
                    (Cliente x) => DropdownMenuItem<int>(
                      value: x.id,
                      child: Text(x.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) {
                client = v;
                _filter();
              },
            ),
          ),
          Expanded(
            child: value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  _error(e, () => ref.read(ventasProvider.notifier).reload()),
              data: (List<Venta> items) => items.isEmpty
                  ? const Center(child: Text('No hay ventas.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Venta item = items[index];
                        return ListTile(
                          key: ValueKey<int>(item.id),
                          title: Text(
                            item.numeroFactura ?? 'Venta #${item.id}',
                          ),
                          subtitle: _StatusBadge(item.estado),
                          trailing: Text(item.total.toStringAsFixed(2)),
                          onTap: () => context.push('/ventas/${item.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _filter() => ref
      .read(ventasProvider.notifier)
      .filter(from: from, to: to, status: status, client: client);
}

class _CommercialFilters extends StatelessWidget {
  const _CommercialFilters({
    required this.from,
    required this.to,
    required this.status,
    required this.options,
    required this.onStatus,
    required this.onFrom,
    required this.onTo,
    this.extra,
  });
  final DateTime? from, to;
  final String? status;
  final List<String> options;
  final ValueChanged<String?> onStatus;
  final ValueChanged<DateTime?> onFrom, onTo;
  final Widget? extra;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: <Widget>[
        TextButton(
          onPressed: () async => onFrom(await _pickDate(context, from)),
          child: Text(from == null ? 'Desde' : DateFormatter.forDisplay(from!)),
        ),
        TextButton(
          onPressed: () async => onTo(await _pickDate(context, to)),
          child: Text(to == null ? 'Hasta' : DateFormatter.forDisplay(to!)),
        ),
        DropdownButton<String>(
          hint: const Text('Estado'),
          value: status,
          items: options
              .map(
                (String x) =>
                    DropdownMenuItem<String>(value: x, child: Text(x)),
              )
              .toList(),
          onChanged: onStatus,
        ),
        if (extra != null) extra!,
      ],
    ),
  );
}

class VentaFormPage extends ConsumerStatefulWidget {
  const VentaFormPage({super.key});
  @override
  ConsumerState<VentaFormPage> createState() => _VentaFormState();
}

class _VentaFormState extends ConsumerState<VentaFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController quantity = TextEditingController(text: '1'),
      price = TextEditingController(),
      discount = TextEditingController(text: '0'),
      observations = TextEditingController();
  final List<DetalleVenta> details = <DetalleVenta>[];
  int? productId, clientId;
  String method = 'EFECTIVO';
  @override
  void dispose() {
    quantity.dispose();
    price.dispose();
    discount.dispose();
    observations.dispose();
    super.dispose();
  }

  num get subtotal => details.fold<num>(
    0,
    (num total, DetalleVenta x) => total + x.cantidad * x.precioUnitario,
  );
  Future<void> _save() async {
    try {
      final VentaRequest request = BuildSale().call(
        detalles: details,
        clienteId: clientId,
        descuento: num.tryParse(discount.text) ?? 0,
        metodoPago: method,
        observaciones: observations.text.trim(),
      );
      await ref.read(ventasProvider.notifier).create(request);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Producto> products =
        ref.watch(productosProvider).value ?? <Producto>[];
    final List<Cliente> clients =
        ref.watch(clientesProvider).value ?? <Cliente>[];
    final num discountValue = num.tryParse(discount.text) ?? 0;
    final num iva = (subtotal - discountValue) * .15;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta POS')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<int>(
              initialValue: clientId,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: clients
                  .map(
                    (Cliente x) => DropdownMenuItem<int>(
                      value: x.id,
                      child: Text(x.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() => clientId = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Metodo de pago'),
              items:
                  const <String>[
                        'EFECTIVO',
                        'TARJETA',
                        'TRANSFERENCIA',
                        'CREDITO',
                      ]
                      .map(
                        (String x) =>
                            DropdownMenuItem<String>(value: x, child: Text(x)),
                      )
                      .toList(),
              onChanged: (String? v) => setState(() => method = v ?? method),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Producto'),
              value: productId,
              items: products
                  .map(
                    (Producto x) => DropdownMenuItem<int>(
                      value: x.id,
                      child: Text('${x.nombre} (stock ${x.stockActual})'),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() {
                productId = v;
                final Producto? p = products
                    .where((Producto x) => x.id == v)
                    .firstOrNull;
                price.text = p?.precioVenta.toString() ?? '';
              }),
            ),
            TextFormField(
              controller: quantity,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: price,
              decoration: const InputDecoration(labelText: 'Precio unitario'),
              keyboardType: TextInputType.number,
            ),
            FilledButton(
              onPressed: () {
                final Producto? p = products
                    .where((Producto x) => x.id == productId)
                    .firstOrNull;
                final int? count = int.tryParse(quantity.text);
                final num? unit = num.tryParse(price.text);
                if (p == null ||
                    count == null ||
                    unit == null ||
                    count <= 0 ||
                    count > p.stockActual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Producto, cantidad valida y stock disponible son obligatorios.',
                      ),
                    ),
                  );
                  return;
                }
                setState(
                  () => details.add(
                    DetalleVenta(
                      productoId: p.id,
                      productoNombre: p.nombre,
                      cantidad: count,
                      precioUnitario: unit,
                      subtotal: count * unit,
                    ),
                  ),
                );
              },
              child: const Text('Agregar linea'),
            ),
            ...details.asMap().entries.map(
              (MapEntry<int, DetalleVenta> entry) => ListTile(
                key: ValueKey<int>(entry.key),
                title: Text(entry.value.productoNombre ?? 'Producto'),
                subtitle: Text(
                  '${entry.value.cantidad} x ${entry.value.precioUnitario}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(entry.value.subtotal!.toStringAsFixed(2)),
                    IconButton(
                      onPressed: () =>
                          setState(() => details.removeAt(entry.key)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
            TextFormField(
              controller: discount,
              decoration: const InputDecoration(labelText: 'Descuento'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            TextFormField(
              controller: observations,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
            Text('IVA (15%): ${iva.toStringAsFixed(2)}'),
            Text(
              'Total: ${(subtotal - discountValue + iva).toStringAsFixed(2)}',
            ),
            FilledButton(onPressed: _save, child: const Text('Guardar venta')),
          ],
        ),
      ),
    );
  }
}

class VentaDetailPage extends ConsumerWidget {
  const VentaDetailPage({required this.id, super.key});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Venta> value = ref.watch(
      FutureProvider<Venta>(
        (Ref ref) => ref.watch(ventaRepositoryProvider).getById(id),
      ),
    );
    final bool canCancel = ref
        .watch(authNotifierProvider)
        .permisos
        .contains(PermissionCodes.ventasEliminar);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de venta')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) => _error(e, () {}),
        data: (Venta sale) => ListView(
          children: <Widget>[
            ListTile(
              title: Text(sale.numeroFactura ?? 'Venta'),
              subtitle: Text('Total: ${sale.total}'),
            ),
            ...sale.detalles.map(
              (DetalleVenta x) => ListTile(
                title: Text(x.productoNombre ?? 'Producto'),
                subtitle: Text('${x.cantidad} x ${x.precioUnitario}'),
              ),
            ),
            if (canCancel && sale.estado != 'ANULADA')
              FilledButton.tonal(
                onPressed: () async {
                  if (await _confirm(context, 'Anular venta')) {
                    await ref.read(ventasProvider.notifier).anular(id);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text('Anular venta'),
              ),
          ],
        ),
      ),
    );
  }
}

class ComprasPage extends ConsumerStatefulWidget {
  const ComprasPage({super.key});
  @override
  ConsumerState<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends ConsumerState<ComprasPage> {
  DateTime? from, to;
  String? status;
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Compra>> value = ref.watch(comprasProvider);
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/compras/reportes'),
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      floatingActionButton: permissions.contains(PermissionCodes.comprasCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/compras/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          _CommercialFilters(
            from: from,
            to: to,
            status: status,
            options: const <String>['COMPLETADA', 'ANULADA', 'PENDIENTE'],
            onStatus: (String? v) {
              status = v;
              _filter();
            },
            onFrom: (DateTime? v) {
              from = v;
              _filter();
            },
            onTo: (DateTime? v) {
              to = v;
              _filter();
            },
          ),
          Expanded(
            child: value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  _error(e, () => ref.read(comprasProvider.notifier).reload()),
              data: (List<Compra> items) => items.isEmpty
                  ? const Center(child: Text('No hay compras.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Compra x = items[index];
                        return ListTile(
                          title: Text(x.numeroFactura),
                          subtitle: _StatusBadge(x.estado),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(x.total.toStringAsFixed(2)),
                              if (permissions.contains(
                                    PermissionCodes.comprasEliminar,
                                  ) &&
                                  x.estado != 'ANULADA')
                                IconButton(
                                  onPressed: () async {
                                    if (await _confirm(
                                      context,
                                      'Anular compra',
                                    ))
                                      await ref
                                          .read(comprasProvider.notifier)
                                          .anular(x.id);
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                ),
                            ],
                          ),
                          onTap: () => context.push('/compras/${x.id}/editar'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _filter() => ref
      .read(comprasProvider.notifier)
      .filter(from: from, to: to, status: status);
}

class CompraFormPage extends ConsumerStatefulWidget {
  const CompraFormPage({this.id, super.key});
  final int? id;
  @override
  ConsumerState<CompraFormPage> createState() => _CompraFormState();
}

class _CompraFormState extends ConsumerState<CompraFormPage> {
  final GlobalKey<FormState> keyForm = GlobalKey<FormState>();
  final TextEditingController invoice = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      price = TextEditingController(),
      discount = TextEditingController(text: '0'),
      observations = TextEditingController();
  final List<DetalleCompra> details = <DetalleCompra>[];
  int? supplierId, productId;
  DateTime? invoiceDate;
  String status = 'PENDIENTE';
  @override
  void dispose() {
    invoice.dispose();
    quantity.dispose();
    price.dispose();
    discount.dispose();
    observations.dispose();
    super.dispose();
  }

  num get subtotal => details.fold<num>(
    0,
    (num t, DetalleCompra x) => t + x.cantidad * x.precioUnitario,
  );
  Future<void> _save() async {
    try {
      await ref
          .read(comprasProvider.notifier)
          .save(
            widget.id,
            BuildPurchase().call(
              numeroFactura: invoice.text,
              detalles: details,
              proveedorId: supplierId,
              descuento: num.tryParse(discount.text) ?? 0,
              fechaFactura: invoiceDate,
              estado: status,
              observaciones: observations.text,
            ),
          );
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Producto> products =
        ref.watch(productosProvider).value ?? <Producto>[];
    final List<Proveedor> suppliers =
        ref.watch(proveedoresProvider).value ?? <Proveedor>[];
    final num d = num.tryParse(discount.text) ?? 0, iva = (subtotal - d) * .15;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Nueva compra' : 'Editar compra'),
      ),
      body: Form(
        key: keyForm,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: invoice,
              decoration: const InputDecoration(labelText: 'Numero de factura'),
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Proveedor'),
              value: supplierId,
              items: suppliers
                  .map(
                    (Proveedor x) => DropdownMenuItem<int>(
                      value: x.id,
                      child: Text(x.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() => supplierId = v),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado'),
              value: status,
              items: const <String>['PENDIENTE', 'COMPLETADA', 'ANULADA']
                  .map(
                    (String x) =>
                        DropdownMenuItem<String>(value: x, child: Text(x)),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => status = v ?? status),
            ),
            TextButton(
              onPressed: () async {
                final DateTime? value = await _pickDate(context, invoiceDate);
                if (mounted) setState(() => invoiceDate = value);
              },
              child: Text(
                invoiceDate == null
                    ? 'Fecha factura'
                    : DateFormatter.forDisplay(invoiceDate!),
              ),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Producto'),
              value: productId,
              items: products
                  .map(
                    (Producto x) => DropdownMenuItem<int>(
                      value: x.id,
                      child: Text(x.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() {
                productId = v;
                price.text =
                    products
                        .where((Producto x) => x.id == v)
                        .firstOrNull
                        ?.precioCompra
                        .toString() ??
                    '';
              }),
            ),
            TextField(
              controller: quantity,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: price,
              decoration: const InputDecoration(labelText: 'Precio unitario'),
              keyboardType: TextInputType.number,
            ),
            FilledButton(
              onPressed: () {
                final Producto? p = products
                    .where((Producto x) => x.id == productId)
                    .firstOrNull;
                final int? q = int.tryParse(quantity.text);
                final num? unit = num.tryParse(price.text);
                if (p == null ||
                    q == null ||
                    q <= 0 ||
                    unit == null ||
                    unit < 0)
                  return;
                setState(
                  () => details.add(
                    DetalleCompra(
                      productoId: p.id,
                      productoNombre: p.nombre,
                      cantidad: q,
                      precioUnitario: unit,
                      subtotal: q * unit,
                    ),
                  ),
                );
              },
              child: const Text('Agregar linea'),
            ),
            ...details.map(
              (DetalleCompra x) => ListTile(
                title: Text(x.productoNombre ?? 'Producto'),
                subtitle: Text('${x.cantidad} x ${x.precioUnitario}'),
                trailing: Text(x.subtotal!.toStringAsFixed(2)),
              ),
            ),
            TextField(
              controller: discount,
              decoration: const InputDecoration(labelText: 'Descuento'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: observations,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
            Text('IVA (15%): ${iva.toStringAsFixed(2)}'),
            Text('Total: ${(subtotal - d + iva).toStringAsFixed(2)}'),
            FilledButton(
              onPressed: () {
                if (keyForm.currentState!.validate() && details.isNotEmpty)
                  _save();
              },
              child: const Text('Guardar compra'),
            ),
          ],
        ),
      ),
    );
  }
}

class MovimientosPage extends ConsumerWidget {
  const MovimientosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MovimientoStock>> value = ref.watch(
      movimientosProvider,
    );
    final bool canCreate = ref
        .watch(authNotifierProvider)
        .permisos
        .contains(PermissionCodes.movimientosCrear);
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos de stock')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/movimientos/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          const _MovementFilter(),
          Expanded(
            child: value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => _error(
                e,
                () => ref.read(movimientosProvider.notifier).reload(),
              ),
              data: (List<MovimientoStock> items) => items.isEmpty
                  ? const Center(child: Text('No hay movimientos.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MovimientoStock x = items[index];
                        return ListTile(
                          title: Text(
                            '${x.tipo} · ${x.productoNombre ?? x.productoId}',
                          ),
                          subtitle: Text('${x.cantidad} · ${x.motivo ?? ''}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementFilter extends ConsumerWidget {
  const _MovementFilter();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: <Widget>[
      DropdownButton<String>(
        hint: const Text('Tipo'),
        items: const <String>['ENTRADA', 'SALIDA', 'AJUSTE']
            .map(
              (String x) => DropdownMenuItem<String>(value: x, child: Text(x)),
            )
            .toList(),
        onChanged: (String? x) =>
            ref.read(movimientosProvider.notifier).filter(movementType: x),
      ),
      TextButton(
        onPressed: () async {
          final DateTime? d = await _pickDate(context, null);
          if (d != null) ref.read(movimientosProvider.notifier).filter(from: d);
        },
        child: const Text('Desde'),
      ),
      TextButton(
        onPressed: () async {
          final DateTime? d = await _pickDate(context, null);
          if (d != null) ref.read(movimientosProvider.notifier).filter(to: d);
        },
        child: const Text('Hasta'),
      ),
    ],
  );
}

class MovimientoFormPage extends ConsumerStatefulWidget {
  const MovimientoFormPage({super.key});
  @override
  ConsumerState<MovimientoFormPage> createState() => _MovimientoFormState();
}

class _MovimientoFormState extends ConsumerState<MovimientoFormPage> {
  int? productId;
  String type = 'AJUSTE';
  final TextEditingController quantity = TextEditingController(),
      reference = TextEditingController(),
      reason = TextEditingController(),
      price = TextEditingController();
  @override
  void dispose() {
    quantity.dispose();
    reference.dispose();
    reason.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Producto> products =
        ref.watch(productosProvider).value ?? <Producto>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Producto'),
            value: productId,
            items: products
                .map(
                  (Producto x) =>
                      DropdownMenuItem<int>(value: x.id, child: Text(x.nombre)),
                )
                .toList(),
            onChanged: (int? v) => setState(() => productId = v),
          ),
          TextField(
            controller: quantity,
            decoration: const InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo'),
            value: type,
            items: const <String>['ENTRADA', 'SALIDA', 'AJUSTE']
                .map(
                  (String x) =>
                      DropdownMenuItem<String>(value: x, child: Text(x)),
                )
                .toList(),
            onChanged: (String? v) => setState(() => type = v ?? type),
          ),
          TextField(
            controller: reference,
            decoration: const InputDecoration(labelText: 'Referencia'),
          ),
          TextField(
            controller: reason,
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
          TextField(
            controller: price,
            decoration: const InputDecoration(labelText: 'Precio unitario'),
          ),
          FilledButton(
            onPressed: () async {
              final int? q = int.tryParse(quantity.text);
              if (productId == null || q == null || q <= 0) return;
              await ref
                  .read(movimientosProvider.notifier)
                  .create(
                    MovimientoStockRequest(
                      productoId: productId!,
                      cantidad: q,
                      tipo: type,
                      referencia: reference.text,
                      motivo: reason.text,
                      precioUnitario: num.tryParse(price.text),
                    ),
                  );
              if (context.mounted) context.pop();
            },
            child: const Text('Registrar movimiento'),
          ),
        ],
      ),
    );
  }
}

class GastosPage extends ConsumerWidget {
  const GastosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Gasto>> value = ref.watch(gastosProvider);
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: permissions.contains(PermissionCodes.gastosCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/gastos/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            _error(e, () => ref.read(gastosProvider.notifier).reload()),
        data: (List<Gasto> items) => items.isEmpty
            ? const Center(child: Text('No hay gastos.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final Gasto x = items[index];
                  return ListTile(
                    title: Text(x.descripcion),
                    subtitle: Text(x.categoria ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(x.monto.toStringAsFixed(2)),
                        if (permissions.contains(PermissionCodes.gastosEditar))
                          IconButton(
                            onPressed: () =>
                                context.push('/gastos/${x.id}/editar'),
                            icon: const Icon(Icons.edit),
                          ),
                        if (permissions.contains(
                          PermissionCodes.gastosEliminar,
                        ))
                          IconButton(
                            onPressed: () async {
                              if (await _confirm(context, 'Eliminar gasto'))
                                await ref
                                    .read(gastosProvider.notifier)
                                    .remove(x.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class GastoFormPage extends ConsumerStatefulWidget {
  const GastoFormPage({this.id, super.key});
  final int? id;
  @override
  ConsumerState<GastoFormPage> createState() => _GastoFormState();
}

class _GastoFormState extends ConsumerState<GastoFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController description = TextEditingController(),
      amount = TextEditingController(),
      category = TextEditingController(),
      method = TextEditingController(),
      receipt = TextEditingController(),
      observations = TextEditingController();
  DateTime? date;
  @override
  void dispose() {
    for (final TextEditingController x in <TextEditingController>[
      description,
      amount,
      category,
      method,
      receipt,
      observations,
    ])
      x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.id == null ? 'Nuevo gasto' : 'Editar gasto'),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextFormField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Descripcion'),
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'Campo requerido' : null,
          ),
          TextFormField(
            controller: amount,
            decoration: const InputDecoration(labelText: 'Monto'),
            keyboardType: TextInputType.number,
            validator: (String? v) =>
                num.tryParse(v ?? '') == null ? 'Monto invalido' : null,
          ),
          TextField(
            controller: category,
            decoration: const InputDecoration(labelText: 'Categoria'),
          ),
          TextField(
            controller: method,
            decoration: const InputDecoration(labelText: 'Metodo de pago'),
          ),
          TextField(
            controller: receipt,
            decoration: const InputDecoration(
              labelText: 'Numero de comprobante',
            ),
          ),
          TextButton(
            onPressed: () async {
              final DateTime? value = await _pickDate(context, date);
              if (mounted) setState(() => date = value);
            },
            child: Text(
              date == null
                  ? 'Fecha del gasto'
                  : DateFormatter.forDisplay(date!),
            ),
          ),
          TextField(
            controller: observations,
            decoration: const InputDecoration(labelText: 'Observaciones'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              await ref
                  .read(gastosProvider.notifier)
                  .save(
                    widget.id,
                    GastoRequest(
                      descripcion: description.text.trim(),
                      monto: num.parse(amount.text),
                      categoria: category.text.trim(),
                      metodoPago: method.text.trim(),
                      numeroComprobante: receipt.text.trim(),
                      fechaGasto: date,
                      observaciones: observations.text.trim(),
                    ),
                  );
              if (context.mounted) context.pop();
            },
            child: const Text('Guardar gasto'),
          ),
        ],
      ),
    ),
  );
}

class CommercialReportPage extends ConsumerStatefulWidget {
  const CommercialReportPage({required this.sales, super.key});
  final bool sales;
  @override
  ConsumerState<CommercialReportPage> createState() => _CommercialReportState();
}

class _CommercialReportState extends ConsumerState<CommercialReportPage> {
  DateTime? from, to;
  List<Object> results = <Object>[];
  bool loading = false;
  Future<void> load() async {
    if (from == null || to == null) return;
    setState(() => loading = true);
    final List<Object> loaded = widget.sales
        ? (await ref.read(ventasProvider.notifier).report(from!, to!))
              .cast<Object>()
        : (await ref.read(comprasProvider.notifier).report(from!, to!))
              .cast<Object>();
    if (mounted)
      setState(() {
        results = loaded;
        loading = false;
      });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.sales ? 'Reporte de ventas' : 'Reporte de compras'),
    ),
    body: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            TextButton(
              onPressed: () async {
                final DateTime? value = await _pickDate(context, from);
                if (mounted) setState(() => from = value);
              },
              child: Text(
                from == null ? 'Desde' : DateFormatter.forDisplay(from!),
              ),
            ),
            TextButton(
              onPressed: () async {
                final DateTime? value = await _pickDate(context, to);
                if (mounted) setState(() => to = value);
              },
              child: Text(to == null ? 'Hasta' : DateFormatter.forDisplay(to!)),
            ),
            FilledButton(onPressed: load, child: const Text('Consultar')),
          ],
        ),
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('Sin datos en el rango seleccionado.'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Object item = results[index];
                    final num total = item is Venta
                        ? item.total
                        : (item as Compra).total;
                    return ListTile(
                      title: Text(
                        item is Venta
                            ? (item.numeroFactura ?? 'Venta')
                            : (item as Compra).numeroFactura,
                      ),
                      trailing: Text(total.toStringAsFixed(2)),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
