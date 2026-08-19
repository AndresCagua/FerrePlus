// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use,
// ignore_for_file: prefer_const_constructors, use_null_aware_elements
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/permission_codes.dart';
import '../../core/errors/failure_message.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/use_cases/build_purchase.dart';
import '../../domain/use_cases/build_sale.dart';
import 'catalog_providers.dart';
import 'commercial_providers.dart';
import '../shared/widgets/app_error_view.dart';
import '../shared/widgets/app_empty_state.dart';
import '../shared/widgets/app_loading_indicator.dart';
import '../shared/widgets/page_scaffold.dart';
import '../shared/widgets/forms/app_dropdown_field.dart';
import '../shared/widgets/forms/app_form_field.dart';
import '../shared/widgets/forms/app_form_section.dart';
import '../shared/widgets/confirm_dialog.dart';
import '../theme/app_spacing.dart';

Widget _error(Object error, VoidCallback retry) => AppErrorView(
  message: 'No se pudo cargar la informacion: $error',
  onRetry: retry,
);

Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) =>
    showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );

Future<bool> _confirm(BuildContext context, String title) => confirmAction(
  context,
  title: title,
  message: 'Esta accion no se puede deshacer.',
  confirmLabel: 'Confirmar',
);

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
      appBar: AppBarBuilder(
        title: 'Ventas',
        actions: <Widget>[
          IconButton(
            tooltip: 'Ver reportes de ventas',
            onPressed: () => context.push('/ventas/reportes'),
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      floatingActionButton: permissions.contains(PermissionCodes.ventasCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/ventas/nuevo'),
              tooltip: 'Nueva venta',
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
              loading: () => const AppLoadingIndicator(),
              error: (Object e, StackTrace s) =>
                  _error(e, () => ref.read(ventasProvider.notifier).reload()),
              data: (List<Venta> items) => items.isEmpty
                  ? const AppEmptyState(
                      title: 'Sin ventas',
                      subtitle: 'No hay ventas registradas.',
                    )
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
  bool saving = false;
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
    if (saving ||
        !ref
            .read(authNotifierProvider.notifier)
            .hasPermission(PermissionCodes.ventasCrear))
      return;
    setState(() => saving = true);
    try {
      final VentaRequest request = BuildSale().call(
        detalles: details,
        clienteId: clientId,
        descuento: num.tryParse(discount.text) ?? 0,
        metodoPago: method,
        observaciones: observations.text.trim(),
        usuarioId: ref.read(authNotifierProvider).user?.id,
      );
      await ref.read(ventasProvider.notifier).create(request);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      if (mounted) setState(() => saving = false);
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
      appBar: AppBarBuilder(title: 'Nueva venta POS'),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppFormSection(
                title: 'DATOS DE LA VENTA',
                children: <Widget>[],
              ),
              AppDropdownField<int>(
                label: 'Cliente',
                initialValue: clientId,
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
              AppDropdownField<String>(
                label: 'Metodo de pago',
                initialValue: method,
                items:
                    const <String>[
                          'EFECTIVO',
                          'TARJETA',
                          'TRANSFERENCIA',
                          'CREDITO',
                        ]
                        .map(
                          (String x) => DropdownMenuItem<String>(
                            value: x,
                            child: Text(x),
                          ),
                        )
                        .toList(),
                onChanged: (String? v) => setState(() => method = v ?? method),
              ),
              const AppFormSection(title: 'PRODUCTOS', children: <Widget>[]),
              AppDropdownField<int>(
                label: 'Producto',
                initialValue: productId,
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
              AppFormField(
                label: 'Cantidad',
                controller: quantity,
                keyboardType: TextInputType.number,
              ),
              AppFormField(
                label: 'Precio unitario',
                controller: price,
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
                        tooltip: 'Eliminar linea',
                        onPressed: () =>
                            setState(() => details.removeAt(entry.key)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const AppFormSection(title: 'RESUMEN', children: <Widget>[]),
              AppFormField(
                label: 'Descuento',
                controller: discount,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              AppFormField(label: 'Observaciones', controller: observations),
              Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
              Text('IVA (15%): ${iva.toStringAsFixed(2)}'),
              Text(
                'Total: ${(subtotal - discountValue + iva).toStringAsFixed(2)}',
              ),
              FilledButton(
                onPressed:
                    ref
                            .watch(authNotifierProvider)
                            .permisos
                            .contains(PermissionCodes.ventasCrear) &&
                        !saving
                    ? _save
                    : null,
                child: saving
                    ? const AppLoadingIndicator()
                    : const Text('Guardar venta'),
              ),
            ],
          ),
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
    final AsyncValue<Venta> value = ref.watch(ventaDetailProvider(id));
    final bool canCancel = ref
        .watch(authNotifierProvider)
        .permisos
        .contains(PermissionCodes.ventasEliminar);
    final bool mutationInFlight = ref.watch(ventasProvider).isLoading;
    return Scaffold(
      appBar: AppBarBuilder(title: 'Detalle de venta'),
      body: value.when(
        loading: () => const AppLoadingIndicator(),
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
                onPressed: mutationInFlight
                    ? null
                    : () async {
                        if (await _confirm(context, 'Anular venta')) {
                          try {
                            await ref.read(ventasProvider.notifier).anular(id);
                            if (context.mounted) context.pop();
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(userFailureMessage(error)),
                                ),
                              );
                            }
                          }
                        }
                      },
                child: mutationInFlight
                    ? const AppLoadingIndicator()
                    : const Text('Anular venta'),
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
    final bool mutationInFlight = ref.watch(comprasProvider).isLoading;
    return Scaffold(
      appBar: AppBarBuilder(
        title: 'Compras',
        actions: <Widget>[
          IconButton(
            tooltip: 'Ver reportes de compras',
            onPressed: () => context.push('/compras/reportes'),
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      floatingActionButton: permissions.contains(PermissionCodes.comprasCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/compras/nuevo'),
              tooltip: 'Nueva compra',
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
              loading: () => const AppLoadingIndicator(),
              error: (Object e, StackTrace s) =>
                  _error(e, () => ref.read(comprasProvider.notifier).reload()),
              data: (List<Compra> items) => items.isEmpty
                  ? const AppEmptyState(
                      title: 'Sin compras',
                      subtitle: 'No hay compras registradas.',
                    )
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
                                  tooltip: 'Anular compra',
                                  onPressed: mutationInFlight
                                      ? null
                                      : () async {
                                          if (await _confirm(
                                            context,
                                            'Anular compra',
                                          ))
                                            try {
                                              await ref
                                                  .read(
                                                    comprasProvider.notifier,
                                                  )
                                                  .anular(x.id);
                                            } catch (error) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      userFailureMessage(error),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                        },
                                  icon: mutationInFlight
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: AppLoadingIndicator(),
                                        )
                                      : const Icon(Icons.cancel_outlined),
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
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) Future<void>.microtask(_loadExisting);
  }

  Future<void> _loadExisting() async {
    if (mounted) {
      setState(() {
        loadingExisting = true;
        loadError = null;
      });
    }
    try {
      final Compra purchase = await ref
          .read(compraRepositoryProvider)
          .getById(widget.id!);
      if (!mounted) return;
      invoice.text = purchase.numeroFactura;
      supplierId = purchase.proveedorId;
      invoiceDate = purchase.fechaFactura;
      status = purchase.estado ?? status;
      discount.text = purchase.descuento.toString();
      observations.text = purchase.observaciones ?? '';
      details
        ..clear()
        ..addAll(purchase.detalles);
      setState(() => loadingExisting = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          loadingExisting = false;
          loadError = error;
        });
      }
    }
  }

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
    final String permission = widget.id == null
        ? PermissionCodes.comprasCrear
        : PermissionCodes.comprasEditar;
    if (saving ||
        !ref.read(authNotifierProvider.notifier).hasPermission(permission))
      return;
    setState(() => saving = true);
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
              usuarioId: ref.read(authNotifierProvider).user?.id,
            ),
          );
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      if (mounted) setState(() => saving = false);
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
      appBar: AppBarBuilder(
        title: widget.id == null ? 'Nueva compra' : 'Editar compra',
      ),
      body: loadingExisting
          ? const AppLoadingIndicator()
          : loadError != null
          ? _error(loadError!, _loadExisting)
          : Form(
              key: keyForm,
              child: ListView(
                shrinkWrap: true,
                cacheExtent: 10000,
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: <Widget>[
                  const AppFormSection(
                    title: 'DATOS DE LA COMPRA',
                    children: <Widget>[],
                  ),
                  AppFormField(
                    label: 'Numero de factura',
                    controller: invoice,
                    validator: (String? v) => v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  AppDropdownField<int>(
                    label: 'Proveedor',
                    initialValue: supplierId,
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
                  AppDropdownField<String>(
                    label: 'Estado',
                    initialValue: status,
                    items: const <String>['PENDIENTE', 'COMPLETADA', 'ANULADA']
                        .map(
                          (String x) => DropdownMenuItem<String>(
                            value: x,
                            child: Text(x),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) =>
                        setState(() => status = v ?? status),
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? value = await _pickDate(
                        context,
                        invoiceDate,
                      );
                      if (mounted) setState(() => invoiceDate = value);
                    },
                    child: Text(
                      invoiceDate == null
                          ? 'Fecha factura'
                          : DateFormatter.forDisplay(invoiceDate!),
                    ),
                  ),
                  AppDropdownField<int>(
                    label: 'Producto',
                    initialValue: productId,
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
                  AppFormField(
                    label: 'Cantidad',
                    controller: quantity,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormField(
                    label: 'Precio unitario',
                    controller: price,
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
                  AppFormField(
                    label: 'Descuento',
                    controller: discount,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppFormField(
                    label: 'Observaciones',
                    controller: observations,
                  ),
                  Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
                  Text('IVA (15%): ${iva.toStringAsFixed(2)}'),
                  Text('Total: ${(subtotal - d + iva).toStringAsFixed(2)}'),
                  FilledButton(
                    onPressed:
                        !saving &&
                            ref
                                .watch(authNotifierProvider)
                                .permisos
                                .contains(
                                  widget.id == null
                                      ? PermissionCodes.comprasCrear
                                      : PermissionCodes.comprasEditar,
                                )
                        ? () {
                            if (keyForm.currentState!.validate() &&
                                details.isNotEmpty)
                              _save();
                          }
                        : null,
                    child: saving
                        ? const AppLoadingIndicator()
                        : const Text('Guardar compra'),
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
      appBar: AppBarBuilder(title: 'Movimientos de stock'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/movimientos/nuevo'),
              tooltip: 'Nuevo movimiento',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          const _MovementFilter(),
          Expanded(
            child: value.when(
              loading: () => const AppLoadingIndicator(),
              error: (Object e, StackTrace s) => _error(
                e,
                () => ref.read(movimientosProvider.notifier).reload(),
              ),
              data: (List<MovimientoStock> items) => items.isEmpty
                  ? const AppEmptyState(
                      title: 'Sin movimientos',
                      subtitle: 'No hay movimientos registrados.',
                    )
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
  bool saving = false;
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
      appBar: AppBarBuilder(title: 'Nuevo movimiento'),
      body: ListView(
        shrinkWrap: true,
        cacheExtent: 10000,
        padding: const EdgeInsets.all(AppSpacing.space16),
        children: <Widget>[
          const AppFormSection(
            title: 'DETALLE DEL MOVIMIENTO',
            children: <Widget>[],
          ),
          AppDropdownField<int>(
            label: 'Producto',
            initialValue: productId,
            items: products
                .map(
                  (Producto x) =>
                      DropdownMenuItem<int>(value: x.id, child: Text(x.nombre)),
                )
                .toList(),
            onChanged: (int? v) => setState(() => productId = v),
          ),
          AppFormField(
            label: 'Cantidad',
            controller: quantity,
            keyboardType: TextInputType.number,
          ),
          AppDropdownField<String>(
            label: 'Tipo',
            initialValue: type,
            items: const <String>['ENTRADA', 'SALIDA', 'AJUSTE']
                .map(
                  (String x) =>
                      DropdownMenuItem<String>(value: x, child: Text(x)),
                )
                .toList(),
            onChanged: (String? v) => setState(() => type = v ?? type),
          ),
          AppFormField(label: 'Referencia', controller: reference),
          AppFormField(label: 'Motivo', controller: reason),
          AppFormField(label: 'Precio unitario', controller: price),
          FilledButton(
            onPressed:
                !saving &&
                    ref
                        .watch(authNotifierProvider)
                        .permisos
                        .contains(PermissionCodes.movimientosCrear)
                ? () async {
                    final int? q = int.tryParse(quantity.text);
                    if (saving || productId == null || q == null || q <= 0)
                      return;
                    setState(() => saving = true);
                    try {
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
                              usuarioId: ref
                                  .read(authNotifierProvider)
                                  .user
                                  ?.id,
                            ),
                          );
                      if (context.mounted) context.pop();
                    } catch (error) {
                      if (context.mounted) {
                        setState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userFailureMessage(error))),
                        );
                      }
                    }
                  }
                : null,
            child: saving
                ? const AppLoadingIndicator()
                : const Text('Registrar movimiento'),
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
    final bool mutationInFlight = ref.watch(gastosProvider).isLoading;
    return Scaffold(
      appBar: AppBarBuilder(title: 'Gastos'),
      floatingActionButton: permissions.contains(PermissionCodes.gastosCrear)
          ? FloatingActionButton(
              onPressed: () => context.push('/gastos/nuevo'),
              tooltip: 'Nuevo gasto',
              child: const Icon(Icons.add),
            )
          : null,
      body: value.when(
        loading: () => const AppLoadingIndicator(),
        error: (Object e, StackTrace s) =>
            _error(e, () => ref.read(gastosProvider.notifier).reload()),
        data: (List<Gasto> items) => items.isEmpty
            ? const AppEmptyState(
                title: 'Sin gastos',
                subtitle: 'No hay gastos registrados.',
              )
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
                            tooltip: 'Editar gasto',
                            onPressed: () =>
                                context.push('/gastos/${x.id}/editar'),
                            icon: const Icon(Icons.edit),
                          ),
                        if (permissions.contains(
                          PermissionCodes.gastosEliminar,
                        ))
                          IconButton(
                            tooltip: 'Eliminar gasto',
                            onPressed: mutationInFlight
                                ? null
                                : () async {
                                    if (await _confirm(
                                      context,
                                      'Eliminar gasto',
                                    ))
                                      try {
                                        await ref
                                            .read(gastosProvider.notifier)
                                            .remove(x.id);
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                userFailureMessage(error),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                  },
                            icon: mutationInFlight
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: AppLoadingIndicator(),
                                  )
                                : const Icon(Icons.delete_outline),
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
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) Future<void>.microtask(_loadExisting);
  }

  Future<void> _loadExisting() async {
    if (mounted) {
      setState(() {
        loadingExisting = true;
        loadError = null;
      });
    }
    try {
      final Gasto expense = await ref
          .read(gastoRepositoryProvider)
          .getById(widget.id!);
      if (!mounted) return;
      description.text = expense.descripcion;
      amount.text = expense.monto.toString();
      category.text = expense.categoria ?? '';
      method.text = expense.metodoPago ?? '';
      receipt.text = expense.numeroComprobante ?? '';
      observations.text = expense.observaciones ?? '';
      date = expense.fechaGasto;
      setState(() => loadingExisting = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          loadingExisting = false;
          loadError = error;
        });
      }
    }
  }

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
    appBar: AppBarBuilder(
      title: widget.id == null ? 'Nuevo gasto' : 'Editar gasto',
    ),
    body: loadingExisting
        ? const AppLoadingIndicator()
        : loadError != null
        ? _error(loadError!, _loadExisting)
        : Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              cacheExtent: 10000,
              padding: const EdgeInsets.all(AppSpacing.space16),
              children: <Widget>[
                const AppFormSection(
                  title: 'DATOS DEL GASTO',
                  children: <Widget>[],
                ),
                AppFormField(
                  label: 'Descripcion',
                  controller: description,
                  validator: (String? v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
                AppFormField(
                  label: 'Monto',
                  controller: amount,
                  keyboardType: TextInputType.number,
                  validator: (String? v) =>
                      num.tryParse(v ?? '') == null ? 'Monto invalido' : null,
                ),
                AppFormField(label: 'Categoria', controller: category),
                AppFormField(label: 'Metodo de pago', controller: method),
                AppFormField(
                  label: 'Numero de comprobante',
                  controller: receipt,
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
                AppFormField(label: 'Observaciones', controller: observations),
                FilledButton(
                  onPressed:
                      ref
                              .watch(authNotifierProvider)
                              .permisos
                              .contains(
                                widget.id == null
                                    ? PermissionCodes.gastosCrear
                                    : PermissionCodes.gastosEditar,
                              ) &&
                          !saving
                      ? () async {
                          if (!(formKey.currentState?.validate() ?? false))
                            return;
                          setState(() => saving = true);
                          try {
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
                                    usuarioId: ref
                                        .read(authNotifierProvider)
                                        .user
                                        ?.id,
                                  ),
                                );
                            if (context.mounted) context.pop();
                          } catch (error) {
                            if (context.mounted) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(userFailureMessage(error)),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoadingIndicator(),
                        )
                      : const Text('Guardar gasto'),
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
    appBar: AppBarBuilder(
      title: widget.sales ? 'Reporte de ventas' : 'Reporte de compras',
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
        if (loading) const AppLoadingIndicator(),
        Expanded(
          child: results.isEmpty
              ? const AppEmptyState(
                  title: 'Sin datos',
                  subtitle: 'Sin datos en el rango seleccionado.',
                )
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
