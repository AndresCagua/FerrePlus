import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/errors/failure_message.dart';
import '../../../domain/models/catalog_models.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/permission_visibility.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../catalog_providers.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});
  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  final TextEditingController search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Producto>> value = ref.watch(productosProvider);
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    return PageScaffold(
      title: 'Productos',
      floatingActionButton: PermissionVisibility(
        allowed: permissions.contains(PermissionCodes.productosCrear),
        child: FloatingActionButton(
          onPressed: () => context.push('/productos/nuevo'),
          child: const Icon(Icons.add),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: TextField(
              controller: search,
              onChanged: (String text) =>
                  ref.read(productosProvider.notifier).search(value: text),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre o codigo',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: value.when(
              loading: () => const AppLoadingIndicator(),
              error: (Object error, StackTrace stack) => AppErrorView(
                message: 'No se pudieron cargar los productos.',
                onRetry: () => ref.read(productosProvider.notifier).reload(),
                retryLabel: 'Reintentar',
              ),
              data: (List<Producto> products) => products.isEmpty
                  ? const AppEmptyState(
                      title: 'Sin productos',
                      subtitle: 'No hay productos disponibles.',
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(productosProvider.notifier).reload(),
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (BuildContext context, int index) =>
                            _tile(context, products[index], permissions),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    Producto product,
    Set<String> permissions,
  ) {
    final bool mutationInFlight = ref.watch(productosProvider).isLoading;
    final bool low =
        product.stockMinimo != null &&
        product.stockActual <= product.stockMinimo!;
    return ListTile(
      key: ValueKey<int>(product.id),
      title: Text(product.nombre),
      subtitle: Text(
        'Stock: ${product.stockActual}  Precio: ${product.precioVenta}',
      ),
      leading: low
          ? Icon(
              Icons.warning_amber,
              color: (Theme.of(context).extension<AppSemanticColors>() ??
                      AppSemanticColors.light)
                  .warning,
            )
          : null,
      trailing: PermissionVisibility(
        allowed:
            permissions.contains(PermissionCodes.productosEditar) ||
            permissions.contains(PermissionCodes.productosEliminar),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PermissionVisibility(
              allowed: permissions.contains(PermissionCodes.productosEditar),
              child: IconButton(
                tooltip: 'Editar producto',
                onPressed: () => context.push(
                  '/productos/${product.id}/editar',
                  extra: product,
                ),
                icon: const Icon(Icons.edit),
              ),
            ),
            PermissionVisibility(
              allowed: permissions.contains(PermissionCodes.productosEliminar),
              child: IconButton(
                tooltip: 'Eliminar producto',
                onPressed: mutationInFlight
                    ? null
                    : () async {
                        if (await confirmDelete(context, product.nombre)) {
                          try {
                            await ref
                                .read(productosProvider.notifier)
                                .remove(product.id);
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
                icon: mutationInFlight
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingIndicator(),
                      )
                    : const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductosListPage extends StatelessWidget {
  const ProductosListPage({super.key});
  @override
  Widget build(BuildContext context) => const ProductosPage();
}

class ProductoFormPage extends ConsumerStatefulWidget {
  const ProductoFormPage({this.id, this.product, super.key});
  final int? id;
  final Producto? product;
  @override
  ConsumerState<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends ConsumerState<ProductoFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> fields =
      <String, TextEditingController>{};
  int? selectedCategoriaId;
  int? selectedProveedorId;
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  @override
  void initState() {
    super.initState();
    for (final String name in <String>[
      'nombre',
      'descripcion',
      'codigoBarras',
      'ubicacion',
      'stockActual',
      'stockMinimo',
      'stockMaximo',
      'precioCompra',
      'precioVenta',
      'unidadMedida',
    ]) {
      fields[name] = TextEditingController();
    }
    _populate(widget.product);
    if (widget.id != null && widget.product == null) {
      Future<void>.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    if (mounted) setState(() => loadingExisting = true);
    try {
      final Producto product = await ref
          .read(productoRepositoryProvider)
          .getById(widget.id!);
      if (!mounted) return;
      _populate(product);
      setState(() {
        loadingExisting = false;
        loadError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          loadingExisting = false;
          loadError = error;
        });
      }
    }
  }

  void _populate(Producto? product) {
    if (product == null) return;
    final Map<String, String> values = <String, String>{
      'nombre': product.nombre,
      'descripcion': product.descripcion ?? '',
      'codigoBarras': product.codigoBarras ?? '',
      'ubicacion': product.ubicacion ?? '',
      'stockActual': product.stockActual.toString(),
      'stockMinimo': product.stockMinimo?.toString() ?? '',
      'stockMaximo': product.stockMaximo?.toString() ?? '',
      'precioCompra': product.precioCompra.toString(),
      'precioVenta': product.precioVenta.toString(),
      'unidadMedida': product.unidadMedida ?? '',
    };
    for (final MapEntry<String, String> entry in values.entries) {
      fields[entry.key]!.text = entry.value;
    }
    selectedCategoriaId = product.categoria?.id;
    selectedProveedorId = product.proveedor?.id;
  }

  @override
  void dispose() {
    for (final TextEditingController field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final String permission = widget.id == null
        ? PermissionCodes.productosCrear
        : PermissionCodes.productosEditar;
    if (!ref.read(authNotifierProvider).permisos.contains(permission) ||
        saving) {
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Producto product = Producto(
      id: widget.id ?? 0,
      nombre: fields['nombre']!.text.trim(),
      descripcion: fields['descripcion']!.text.trim(),
      codigoBarras: fields['codigoBarras']!.text.trim(),
      ubicacion: fields['ubicacion']!.text.trim(),
      stockActual: int.tryParse(fields['stockActual']!.text) ?? 0,
      stockMinimo: int.tryParse(fields['stockMinimo']!.text),
      stockMaximo: int.tryParse(fields['stockMaximo']!.text),
      precioCompra: double.tryParse(fields['precioCompra']!.text) ?? 0,
      precioVenta: double.tryParse(fields['precioVenta']!.text) ?? 0,
      unidadMedida: fields['unidadMedida']!.text.trim(),
      categoria: _selectedCategoria(ref),
      proveedor: _selectedProveedor(ref),
    );
    setState(() => saving = true);
    try {
      await ref.read(productosProvider.notifier).save(product);
      if (mounted) {
        final GoRouter? router = GoRouter.maybeOf(context);
        if (router != null) {
          router.pop();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFailureMessage(error))));
      }
    }
  }

  Categoria? _selectedCategoria(WidgetRef ref) {
    final List<Categoria>? items = ref.read(categoriasProvider).value;
    return items
        ?.where((Categoria item) => item.id == selectedCategoriaId)
        .firstOrNull;
  }

  Proveedor? _selectedProveedor(WidgetRef ref) {
    final List<Proveedor>? items = ref.read(proveedoresProvider).value;
    return items
        ?.where((Proveedor item) => item.id == selectedProveedorId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final List<Categoria> categorias =
        ref.watch(categoriasProvider).value ?? <Categoria>[];
    final List<Proveedor> proveedores =
        ref.watch(proveedoresProvider).value ?? <Proveedor>[];
    final bool allowed = permissions.contains(
      widget.id == null
          ? PermissionCodes.productosCrear
          : PermissionCodes.productosEditar,
    );
    return PageScaffold(
      title: widget.id == null ? 'Nuevo producto' : 'Editar producto',
      contentPadding: false,
      child: loadingExisting
          ? const AppLoadingIndicator()
          : loadError != null
           ? AppErrorView(
               message: 'No se pudo cargar el producto.',
               onRetry: _loadExisting,
               retryLabel: 'Reintentar',
             )
          : !allowed
          ? const Center(child: Text('No tienes permiso para esta accion.'))
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: <Widget>[
                  field('nombre', 'Nombre', true),
                  field('descripcion', 'Descripcion', false),
                  field('codigoBarras', 'Codigo de barras', false),
                  field('ubicacion', 'Ubicacion', false),
                  field('stockActual', 'Stock actual', true),
                  field('stockMinimo', 'Stock minimo', false),
                  field('stockMaximo', 'Stock maximo', false),
                  field('precioCompra', 'Precio compra', true),
                  field('precioVenta', 'Precio venta', true),
                  field('unidadMedida', 'Unidad de medida', false),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoriaId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categorias
                        .map(
                          (Categoria item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (int? value) =>
                        setState(() => selectedCategoriaId = value),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedProveedorId,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items: proveedores
                        .map(
                          (Proveedor item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (int? value) =>
                        setState(() => selectedProveedorId = value),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AppLoadingIndicator(),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget field(String name, String label, bool required) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
    child: TextFormField(
      controller: fields[name],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (String? value) =>
                value == null || value.trim().isEmpty ? 'Campo requerido' : null
          : null,
    ),
  );
}
