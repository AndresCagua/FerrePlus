import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/catalog_models.dart';
import '../../core/errors/failure_message.dart';
import '../../core/providers/auth_providers.dart';
import '../shared/widgets/confirm_dialog.dart';
import '../shared/widgets/app_empty_state.dart';
import '../shared/widgets/app_error_view.dart';
import '../shared/widgets/app_loading_indicator.dart';
import '../shared/widgets/page_scaffold.dart';
import '../shared/widgets/permission_visibility.dart';
import '../theme/app_spacing.dart';
import 'catalog_providers.dart';

enum CatalogKind { categorias, proveedores, clientes }

extension CatalogKindX on CatalogKind {
  String get title => name[0].toUpperCase() + name.substring(1);
  String get path => '/$name';
  String get createPermission => '${name.toUpperCase()}_CREAR';
  String get editPermission => '${name.toUpperCase()}_EDITAR';
  String get deletePermission => '${name.toUpperCase()}_ELIMINAR';
  int id(Object item) => item is Categoria
      ? item.id
      : item is Proveedor
      ? item.id
      : (item as Cliente).id;
  String label(Object item) => item is Categoria
      ? item.nombre
      : item is Proveedor
      ? item.nombre
      : (item as Cliente).nombre;
  String subtitle(Object item) => item is Categoria
      ? (item.descripcion ?? '')
      : item is Proveedor
      ? (item.email ?? item.telefono ?? '')
      : 'Saldo: ${(item as Cliente).saldoPendiente}';
  Future<void> remove(WidgetRef ref, int id) => this == CatalogKind.categorias
      ? ref.read(categoriasProvider.notifier).remove(id)
      : this == CatalogKind.proveedores
      ? ref.read(proveedoresProvider.notifier).remove(id)
      : ref.read(clientesProvider.notifier).remove(id);
  Future<void> reload(WidgetRef ref) => this == CatalogKind.categorias
      ? ref.read(categoriasProvider.notifier).reload()
      : this == CatalogKind.proveedores
      ? ref.read(proveedoresProvider.notifier).reload()
      : ref.read(clientesProvider.notifier).reload();
}

class SimpleCatalogPage extends ConsumerWidget {
  const SimpleCatalogPage({required this.kind, super.key});
  final CatalogKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Object>> value = switch (kind) {
      CatalogKind.categorias =>
        ref
            .watch(categoriasProvider)
            .whenData((List<Categoria> data) => data.cast<Object>()),
      CatalogKind.proveedores =>
        ref
            .watch(proveedoresProvider)
            .whenData((List<Proveedor> data) => data.cast<Object>()),
      CatalogKind.clientes =>
        ref
            .watch(clientesProvider)
            .whenData((List<Cliente> data) => data.cast<Object>()),
    };
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final bool mutationInFlight = switch (kind) {
      CatalogKind.categorias => ref.watch(categoriasProvider).isLoading,
      CatalogKind.proveedores => ref.watch(proveedoresProvider).isLoading,
      CatalogKind.clientes => ref.watch(clientesProvider).isLoading,
    };
    return PageScaffold(
      title: kind.title,
      floatingActionButton: PermissionVisibility(
        allowed: permissions.contains(kind.createPermission),
        child: FloatingActionButton(
          onPressed: () => context.push('${kind.path}/nuevo'),
          child: const Icon(Icons.add),
        ),
      ),
      child: value.when(
         loading: () => const AppLoadingIndicator(),
        error: (Object error, StackTrace stack) => _ErrorRetry(
          message: error.toString(),
          retry: () => kind.reload(ref),
        ),
        data: (List<Object> items) => items.isEmpty
            ? const AppEmptyState(
                title: 'Sin registros',
                subtitle: 'No hay registros disponibles.',
              )
            : RefreshIndicator(
                onRefresh: () => kind.reload(ref),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _CatalogTile(
                        item: items[index],
                        kind: kind,
                        permissions: permissions,
                        mutationInFlight: mutationInFlight,
                        ref: ref,
                      ),
                ),
              ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.item,
    required this.kind,
    required this.permissions,
    required this.ref,
    required this.mutationInFlight,
  });
  final Object item;
  final CatalogKind kind;
  final Set<String> permissions;
  final WidgetRef ref;
  final bool mutationInFlight;
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey<int>(kind.id(item)),
    title: Text(kind.label(item)),
    subtitle: Text(kind.subtitle(item)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PermissionVisibility(
          allowed: permissions.contains(kind.editPermission),
          child: IconButton(
            onPressed: () => context.push(
              '${kind.path}/${kind.id(item)}/editar',
              extra: item,
            ),
            icon: const Icon(Icons.edit),
          ),
        ),
        PermissionVisibility(
          allowed: permissions.contains(kind.deletePermission),
          child: IconButton(
            onPressed: mutationInFlight
                ? null
                : () async {
                    if (await confirmDelete(context, kind.label(item))) {
                      try {
                        await kind.remove(ref, kind.id(item));
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(userFailureMessage(error))),
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
  );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => AppErrorView(
        message: message,
        onRetry: retry,
        retryLabel: 'Reintentar',
      );
}

class CategoriasPage extends StatelessWidget {
  const CategoriasPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const SimpleCatalogPage(kind: CatalogKind.categorias);
}

class ProveedoresPage extends StatelessWidget {
  const ProveedoresPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const SimpleCatalogPage(kind: CatalogKind.proveedores);
}

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const SimpleCatalogPage(kind: CatalogKind.clientes);
}

class CatalogFormPage extends ConsumerStatefulWidget {
  const CatalogFormPage({required this.kind, this.id, this.item, super.key});
  final CatalogKind kind;
  final int? id;
  final Object? item;
  @override
  ConsumerState<CatalogFormPage> createState() => _CatalogFormPageState();
}

class _CatalogFormPageState extends ConsumerState<CatalogFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> fields =
      <String, TextEditingController>{};
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  @override
  void initState() {
    super.initState();
    for (final String name in <String>[
      'nombre',
      'descripcion',
      'ruc',
      'contacto',
      'telefono',
      'email',
      'direccion',
    ]) {
      fields[name] = TextEditingController();
    }
    _populate(widget.item);
    if (widget.id != null && widget.item == null) {
      Future<void>.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    if (mounted) setState(() => loadingExisting = true);
    try {
      final Object item = switch (widget.kind) {
        CatalogKind.categorias =>
          await ref.read(categoriaRepositoryProvider).getById(widget.id!),
        CatalogKind.proveedores =>
          await ref.read(proveedorRepositoryProvider).getById(widget.id!),
        CatalogKind.clientes =>
          await ref.read(clienteRepositoryProvider).getById(widget.id!),
      };
      if (!mounted) return;
      _populate(item);
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

  void _populate(Object? item) {
    if (item == null) return;
    final String name = item is Categoria
        ? item.nombre
        : item is Proveedor
        ? item.nombre
        : (item as Cliente).nombre;
    fields['nombre']!.text = name;
    if (item is Categoria) fields['descripcion']!.text = item.descripcion ?? '';
    if (item is Proveedor) {
      fields['ruc']!.text = item.ruc ?? '';
      fields['contacto']!.text = item.contacto ?? '';
      fields['telefono']!.text = item.telefono ?? '';
      fields['email']!.text = item.email ?? '';
      fields['direccion']!.text = item.direccion ?? '';
    }
    if (item is Cliente) {
      fields['ruc']!.text = item.ruc ?? '';
      fields['telefono']!.text = item.telefono ?? '';
      fields['email']!.text = item.email ?? '';
      fields['direccion']!.text = item.direccion ?? '';
    }
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
        ? widget.kind.createPermission
        : widget.kind.editPermission;
    if (!ref.read(authNotifierProvider).permisos.contains(permission) ||
        saving) {
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => saving = true);
    try {
      final String nombre = fields['nombre']!.text.trim();
      if (widget.kind == CatalogKind.categorias) {
        await ref
            .read(categoriasProvider.notifier)
            .save(
              Categoria(
                id: widget.id ?? 0,
                nombre: nombre,
                descripcion: fields['descripcion']!.text.trim(),
              ),
            );
      }
      if (widget.kind == CatalogKind.proveedores) {
        await ref
            .read(proveedoresProvider.notifier)
            .save(
              Proveedor(
                id: widget.id ?? 0,
                nombre: nombre,
                ruc: fields['ruc']!.text.trim(),
                contacto: fields['contacto']!.text.trim(),
                telefono: fields['telefono']!.text.trim(),
                email: fields['email']!.text.trim(),
                direccion: fields['direccion']!.text.trim(),
              ),
            );
      }
      if (widget.kind == CatalogKind.clientes) {
        await ref
            .read(clientesProvider.notifier)
            .save(
              Cliente(
                id: widget.id ?? 0,
                nombre: nombre,
                ruc: fields['ruc']!.text.trim(),
                telefono: fields['telefono']!.text.trim(),
                email: fields['email']!.text.trim(),
                direccion: fields['direccion']!.text.trim(),
              ),
            );
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFailureMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: '${widget.id == null ? 'Nuevo' : 'Editar'} ${widget.kind.title}',
    contentPadding: false,
    child: loadingExisting
        ? const AppLoadingIndicator()
        : loadError != null
        ? _ErrorRetry(
            message: userFailureMessage(loadError!),
            retry: _loadExisting,
          )
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space16),
              children: <Widget>[
                field('nombre', 'Nombre', true),
                field('descripcion', 'Descripcion', false),
                if (widget.kind != CatalogKind.categorias) ...<Widget>[
                  field('ruc', 'RUC', false),
                  field('contacto', 'Contacto', false),
                  field('telefono', 'Telefono', false),
                  field('email', 'Correo', false),
                  field('direccion', 'Direccion', false),
                ],
                FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const AppLoadingIndicator()
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
  );
  Widget field(String name, String label, bool required) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space12),
    child: TextFormField(
      controller: fields[name],
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (String? value) =>
                value == null || value.trim().isEmpty ? 'Campo requerido' : null
          : null,
    ),
  );
}
