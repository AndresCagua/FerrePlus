import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/permission_codes.dart';
import '../../core/errors/failure_message.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/models/commercial_models.dart';
import 'admin_providers.dart';

String money(num value) => NumberFormat.currency(symbol: '\$').format(value);
String dateText(DateTime? value) => value == null
    ? '--'
    : DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
String dateOnly(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
bool can(WidgetRef ref, String permission) =>
    ref.watch(authNotifierProvider).permisos.contains(permission);

Widget errorView(Object error, VoidCallback retry) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Icon(Icons.cloud_off, size: 40),
      const Text('No se pudo cargar la informacion'),
      Text('$error', maxLines: 2, overflow: TextOverflow.ellipsis),
      FilledButton(onPressed: retry, child: const Text('Reintentar')),
    ],
  ),
);

class PreciosPage extends ConsumerWidget {
  const PreciosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PrecioProducto>> state = ref.watch(preciosProvider);
    final bool mutationInFlight = state.isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Precios')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            errorView(e, () => ref.invalidate(preciosProvider)),
        data: (List<PrecioProducto> prices) => prices.isEmpty
            ? const Center(child: Text('No hay precios disponibles.'))
            : RefreshIndicator(
                onRefresh: () => ref.read(preciosProvider.notifier).reload(),
                child: ListView.builder(
                  itemCount: prices.length,
                  itemBuilder: (BuildContext context, int index) {
                    final PrecioProducto price = prices[index];
                    return ListTile(
                      key: ValueKey<int>(price.id),
                      title: Text(price.nombre),
                      subtitle: Text(
                        'Compra ${money(price.precioCompra)}  ·  '
                        'Venta ${money(price.precioVenta)}\n'
                        'Ganancia ${money(price.ganancia)}  ·  '
                        'Margen ${price.margenPorcentaje.toStringAsFixed(1)}%',
                      ),
                      isThreeLine: true,
                      trailing: can(ref, PermissionCodes.preciosEditar)
                          ? IconButton(
                              tooltip: 'Actualizar precio',
                              icon: const Icon(Icons.edit),
                              onPressed: mutationInFlight
                                  ? null
                                  : () => _showPriceDialog(context, ref, price),
                            )
                          : null,
                      onTap: () => context.push(
                        '/gestion-precios/${price.id}/historial',
                        extra: price,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

Future<void> _showPriceDialog(
  BuildContext context,
  WidgetRef ref,
  PrecioProducto price,
) async {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController value = TextEditingController();
  final TextEditingController reference = TextEditingController();
  String mode = 'precio';
  bool saving = false;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) set) =>
          AlertDialog(
            title: const Text('Actualizar precio de venta'),
            content: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: mode,
                    decoration: const InputDecoration(labelText: 'Calculo'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'precio',
                        child: Text('Nuevo precio'),
                      ),
                      DropdownMenuItem(
                        value: 'margen',
                        child: Text('Margen %'),
                      ),
                    ],
                    onChanged: (String? next) => set(() => mode = next ?? mode),
                  ),
                  TextFormField(
                    controller: value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: mode == 'precio'
                          ? 'Nuevo precio'
                          : 'Margen porcentaje',
                    ),
                    validator: (String? text) =>
                        double.tryParse(text ?? '') == null
                        ? 'Ingrese un numero valido'
                        : null,
                  ),
                  TextFormField(
                    controller: reference,
                    decoration: const InputDecoration(labelText: 'Referencia'),
                    validator: (String? text) =>
                        text == null || text.trim().isEmpty
                        ? 'La referencia es requerida'
                        : null,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(key.currentState?.validate() ?? false)) return;
                        set(() => saving = true);
                        final double parsed = double.parse(value.text);
                        final ActualizarPrecioVentaRequest request =
                            mode == 'precio'
                            ? ActualizarPrecioVentaRequest(
                                nuevoPrecio: parsed,
                                referencia: reference.text.trim(),
                              )
                            : ActualizarPrecioVentaRequest(
                                margenPorcentaje: parsed,
                                referencia: reference.text.trim(),
                              );
                        try {
                          await ref
                              .read(preciosProvider.notifier)
                              .updatePrice(price.id, request);
                          if (dialogContext.mounted) dialogContext.pop();
                        } catch (error) {
                          if (dialogContext.mounted) {
                            set(() => saving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(userFailureMessage(error)),
                              ),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Actualizar'),
              ),
            ],
          ),
    ),
  );
  value.dispose();
  reference.dispose();
}

class PrecioHistorialPage extends ConsumerWidget {
  const PrecioHistorialPage({required this.id, this.precio, super.key});
  final int id;
  final PrecioProducto? precio;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FutureProvider<List<HistoricoPrecio>> provider =
        FutureProvider.autoDispose<List<HistoricoPrecio>>(
          (ref) => ref.watch(precioRepositoryProvider).historial(id),
        );
    final AsyncValue<List<HistoricoPrecio>> state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(precio?.nombre ?? 'Historial de precios')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            errorView(e, () => ref.invalidate(provider)),
        data: (List<HistoricoPrecio> history) => history.isEmpty
            ? const Center(child: Text('No hay cambios registrados.'))
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (BuildContext context, int index) {
                  final HistoricoPrecio item = history[index];
                  return Card(
                    child: ListTile(
                      title: Text('Venta ${money(item.precioVenta)}'),
                      subtitle: Text(
                        'Compra ${money(item.precioCompra)}  ·  '
                        '${item.tipoCambio ?? 'Cambio'}\n'
                        '${dateText(item.fechaCambio)}  ·  '
                        '${item.usuarioNombre ?? 'Sistema'}\n'
                        'Ref: ${item.referencia ?? '--'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Usuario>> state = ref.watch(usuariosProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: <Widget>[
          if (can(ref, PermissionCodes.usuariosCrear))
            IconButton(
              tooltip: 'Nuevo usuario',
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/usuarios/nuevo'),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            errorView(e, () => ref.invalidate(usuariosProvider)),
        data: (List<Usuario> users) => users.isEmpty
            ? const Center(child: Text('No hay usuarios disponibles.'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (BuildContext context, int index) {
                  final Usuario user = users[index];
                  return ListTile(
                    key: ValueKey<int>(user.id),
                    title: Text(user.nombre),
                    subtitle: Text(
                      '${user.email}  ·  ${user.rolNombre ?? 'Sin rol'}',
                    ),
                    trailing: Chip(
                      label: Text(user.activo ? 'Activo' : 'Inactivo'),
                      backgroundColor: user.activo
                          ? Colors.green.withValues(alpha: .15)
                          : Colors.red.withValues(alpha: .15),
                    ),
                    onTap: can(ref, PermissionCodes.usuariosEditar)
                        ? () => context.push(
                            '/usuarios/${user.id}/editar',
                            extra: user,
                          )
                        : null,
                  );
                },
              ),
      ),
    );
  }
}

class UsuarioFormPage extends ConsumerStatefulWidget {
  const UsuarioFormPage({this.id, this.usuario, super.key});
  final int? id;
  final Usuario? usuario;
  @override
  ConsumerState<UsuarioFormPage> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends ConsumerState<UsuarioFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController name, email, phone, password;
  bool active = true;
  int? roleId;
  final List<UsuarioPermiso> overrides = <UsuarioPermiso>[];
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  Usuario? loadedUsuario;
  @override
  void initState() {
    super.initState();
    final Usuario? user = widget.usuario;
    name = TextEditingController(text: user?.nombre);
    email = TextEditingController(text: user?.email);
    phone = TextEditingController(text: user?.telefono);
    password = TextEditingController();
    active = user?.activo ?? true;
    roleId = user?.rolId;
    overrides.addAll(user?.overrides ?? const <UsuarioPermiso>[]);
    if (widget.id != null && user == null) {
      Future<void>.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    if (mounted) setState(() => loadingExisting = true);
    try {
      final Usuario user = await ref
          .read(usuarioRepositoryProvider)
          .getById(widget.id!);
      if (!mounted) return;
      loadedUsuario = user;
      name.text = user.nombre;
      email.text = user.email;
      phone.text = user.telefono ?? '';
      active = user.activo;
      roleId = user.rolId;
      overrides
        ..clear()
        ..addAll(user.overrides);
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

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final bool editing = widget.id != null;
    final String permission = !editing
        ? PermissionCodes.usuariosCrear
        : PermissionCodes.usuariosEditar;
    if (saving ||
        !ref.read(authNotifierProvider.notifier).hasPermission(permission)) {
      return;
    }
    if (!(formKey.currentState?.validate() ?? false) || roleId == null) return;
    final UsuarioRequest request = UsuarioRequest(
      nombre: name.text.trim(),
      email: email.text.trim(),
      telefono: phone.text.trim(),
      activo: active,
      rolId: roleId!,
      password: password.text.trim().isEmpty ? null : password.text.trim(),
      overrides: List<UsuarioPermiso>.of(overrides),
    );
    setState(() => saving = true);
    try {
      await ref
          .read(usuariosProvider.notifier)
          .save(editing ? widget.id : null, request);
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
  Widget build(BuildContext context) {
    final AsyncValue<List<Rol>> roles = ref.watch(rolesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Nuevo usuario' : 'Editar usuario'),
      ),
      body: loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? errorView(loadError!, _loadExisting)
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _field(name, 'Nombre', required: true),
                  _field(email, 'Email', required: true, email: true),
                  _field(phone, 'Telefono'),
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: active,
                    onChanged: (bool v) => setState(() => active = v),
                  ),
                  roles.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (Object e, StackTrace s) =>
                        Text('No se pudieron cargar roles: $e'),
                    data: (List<Rol> values) => DropdownButtonFormField<int>(
                      initialValue: roleId,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: values
                          .map(
                            (Rol r) => DropdownMenuItem<int>(
                              value: r.id,
                              child: Text(r.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (int? v) => setState(() => roleId = v),
                      validator: (int? v) =>
                          v == null ? 'Seleccione un rol' : null,
                    ),
                  ),
                  _field(
                    password,
                    widget.id == null
                        ? 'Contrasena (requerida)'
                        : 'Nueva contrasena (opcional)',
                    required: widget.id == null,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Overrides de permisos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...overrides.asMap().entries.map(
                    (MapEntry<int, UsuarioPermiso> entry) =>
                        _overrideRow(entry.key, entry.value),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(
                      () => overrides.add(
                        const UsuarioPermiso(
                          permisoCodigo: '',
                          concedido: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar override'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        !saving &&
                            can(
                              ref,
                              widget.id == null
                                  ? PermissionCodes.usuariosCrear
                                  : PermissionCodes.usuariosEditar,
                            )
                        ? save
                        : null,
                    child: saving
                        ? const CircularProgressIndicator()
                        : const Text('Guardar'),
                  ),
                  if (widget.id != null) ...<Widget>[
                    if (can(ref, PermissionCodes.usuariosEditar))
                      OutlinedButton(
                        onPressed: () =>
                            _changePassword(context, ref, widget.id!),
                        child: const Text('Cambiar contrasena'),
                      ),
                    if (can(ref, PermissionCodes.usuariosEliminar))
                      TextButton(
                        onPressed: () => _deleteUser(
                          context,
                          ref,
                          loadedUsuario ?? widget.usuario!,
                        ),
                        child: const Text('Eliminar usuario'),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _overrideRow(int index, UsuarioPermiso item) => Row(
    children: <Widget>[
      Expanded(
        child: TextFormField(
          initialValue: item.permisoCodigo,
          decoration: const InputDecoration(labelText: 'Codigo permiso'),
          onChanged: (String v) => overrides[index] = UsuarioPermiso(
            permisoCodigo: v,
            concedido: overrides[index].concedido,
          ),
        ),
      ),
      Checkbox(
        value: item.concedido,
        onChanged: (bool? v) => setState(
          () => overrides[index] = UsuarioPermiso(
            permisoCodigo: item.permisoCodigo,
            concedido: v ?? false,
          ),
        ),
      ),
      IconButton(
        onPressed: () => setState(() => overrides.removeAt(index)),
        icon: const Icon(Icons.delete_outline),
      ),
    ],
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool email = false,
  bool obscure = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: email ? TextInputType.emailAddress : null,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (String? value) =>
              value == null || value.trim().isEmpty ? 'Campo requerido' : null
        : null,
  ),
);

Future<void> _changePassword(
  BuildContext context,
  WidgetRef ref,
  int id,
) async {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController current = TextEditingController();
  final TextEditingController next = TextEditingController();
  bool saving = false;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) set) =>
          AlertDialog(
            title: const Text('Cambiar contrasena'),
            content: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _field(
                    current,
                    'Contrasena actual',
                    required: true,
                    obscure: true,
                  ),
                  _field(
                    next,
                    'Nueva contrasena',
                    required: true,
                    obscure: true,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => dialog.pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(key.currentState?.validate() ?? false)) return;
                        set(() => saving = true);
                        try {
                          await ref
                              .read(usuariosProvider.notifier)
                              .changePassword(
                                id,
                                CambioPasswordRequest(
                                  passwordActual: current.text,
                                  nuevoPassword: next.text,
                                ),
                              );
                          if (dialog.mounted) dialog.pop();
                        } catch (error) {
                          if (dialog.mounted) {
                            set(() => saving = false);
                            ScaffoldMessenger.of(dialog).showSnackBar(
                              SnackBar(
                                content: Text(userFailureMessage(error)),
                              ),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cambiar'),
              ),
            ],
          ),
    ),
  );
  current.dispose();
  next.dispose();
}

Future<void> _deleteUser(
  BuildContext context,
  WidgetRef ref,
  Usuario user,
) async {
  bool deleting = false;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialog) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) set) {
        return AlertDialog(
          title: const Text('Confirmar eliminacion'),
          content: Text('Eliminar a ${user.nombre}?'),
          actions: <Widget>[
            TextButton(
              onPressed: deleting ? null : () => dialog.pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: deleting
                  ? null
                  : () async {
                      set(() => deleting = true);
                      try {
                        await ref
                            .read(usuariosProvider.notifier)
                            .remove(user.id);
                        if (dialog.mounted) dialog.pop(true);
                      } catch (error) {
                        if (dialog.mounted) {
                          set(() => deleting = false);
                          ScaffoldMessenger.of(dialog).showSnackBar(
                            SnackBar(content: Text(userFailureMessage(error))),
                          );
                        }
                      }
                    },
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Eliminar'),
            ),
          ],
        );
      },
    ),
  );
  if (confirmed == true) {
    if (context.mounted) context.pop();
  }
}

class RolesPage extends ConsumerWidget {
  const RolesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Rol>> state = ref.watch(rolesProvider);
    final bool mutationInFlight = state.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
        actions: <Widget>[
          if (can(ref, PermissionCodes.rolesCrear))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/roles/nuevo'),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            errorView(e, () => ref.invalidate(rolesProvider)),
        data: (List<Rol> values) => ListView.builder(
          itemCount: values.length,
          itemBuilder: (BuildContext context, int index) {
            final Rol role = values[index];
            return ListTile(
              key: ValueKey<int>(role.id),
              title: Text(role.nombre),
              subtitle: Text('${role.permisos.length} permisos'),
              trailing: can(ref, PermissionCodes.rolesEliminar)
                  ? IconButton(
                      tooltip: 'Eliminar rol',
                      icon: mutationInFlight
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      onPressed: mutationInFlight
                          ? null
                          : () => _deleteRole(context, ref, role),
                    )
                  : null,
              onTap: can(ref, PermissionCodes.rolesEditar)
                  ? () => context.push('/roles/${role.id}/editar', extra: role)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

Future<void> _deleteRole(BuildContext context, WidgetRef ref, Rol role) async {
  bool deleting = false;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) set) {
        return AlertDialog(
          title: const Text('Confirmar eliminacion'),
          content: Text('Eliminar el rol ${role.nombre}?'),
          actions: <Widget>[
            TextButton(
              onPressed: deleting ? null : () => dialog.pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: deleting
                  ? null
                  : () async {
                      set(() => deleting = true);
                      try {
                        await ref.read(rolesProvider.notifier).remove(role.id);
                        if (dialog.mounted) dialog.pop();
                      } catch (error) {
                        if (dialog.mounted) {
                          set(() => deleting = false);
                          ScaffoldMessenger.of(dialog).showSnackBar(
                            SnackBar(content: Text(userFailureMessage(error))),
                          );
                        }
                      }
                    },
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Eliminar'),
            ),
          ],
        );
      },
    ),
  );
}

class RolFormPage extends ConsumerStatefulWidget {
  const RolFormPage({this.id, this.rol, super.key});
  final int? id;
  final Rol? rol;
  @override
  ConsumerState<RolFormPage> createState() => _RolFormState();
}

class _RolFormState extends ConsumerState<RolFormPage> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  late final TextEditingController name, description;
  final Set<String> selected = <String>{};
  bool saving = false;
  bool loadingExisting = false;
  Object? loadError;
  Rol? loadedRol;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.rol?.nombre);
    description = TextEditingController(text: widget.rol?.descripcion);
    selected.addAll(widget.rol?.permisos ?? const <String>[]);
    if (widget.id != null && widget.rol == null) {
      Future<void>.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    if (mounted) setState(() => loadingExisting = true);
    try {
      final Rol role = await ref
          .read(rolRepositoryProvider)
          .getById(widget.id!);
      if (!mounted) return;
      loadedRol = role;
      name.text = role.nombre;
      description.text = role.descripcion ?? '';
      selected
        ..clear()
        ..addAll(role.permisos);
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

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final bool editing = widget.id != null;
    final String permission = !editing
        ? PermissionCodes.rolesCrear
        : PermissionCodes.rolesEditar;
    if (saving ||
        !ref.read(authNotifierProvider.notifier).hasPermission(permission)) {
      return;
    }
    if (!(key.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await ref
          .read(rolesProvider.notifier)
          .save(
            editing ? widget.id : null,
            RolRequest(
              nombre: name.text.trim(),
              descripcion: description.text.trim(),
              permisos: selected.toList()..sort(),
            ),
          );
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
  Widget build(BuildContext context) {
    final AsyncValue<List<Modulo>> modules = ref.watch(modulosProvider);
    final AsyncValue<List<Permiso>> permissions = ref.watch(permisosProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Nuevo rol' : 'Editar rol'),
      ),
      body: loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? errorView(loadError!, _loadExisting)
          : Form(
              key: key,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _field(name, 'Nombre', required: true),
                  _field(description, 'Descripcion'),
                  const SizedBox(height: 12),
                  modules.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (Object e, StackTrace s) => Text('$e'),
                    data: (List<Modulo> values) => permissions.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (Object e, StackTrace s) => Text('$e'),
                      data: (List<Permiso> all) =>
                          _permissionMatrix(values, all),
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        !saving &&
                            can(
                              ref,
                              widget.id == null
                                  ? PermissionCodes.rolesCrear
                                  : PermissionCodes.rolesEditar,
                            )
                        ? save
                        : null,
                    child: saving
                        ? const CircularProgressIndicator()
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _permissionMatrix(List<Modulo> modules, List<Permiso> all) {
    final List<Modulo> resolved = modules.map((Modulo module) {
      final List<Permiso> own = all
          .where(
            (Permiso p) =>
                p.moduloId == module.id || p.moduloCodigo == module.codigo,
          )
          .toList();
      return Modulo(
        id: module.id,
        nombre: module.nombre,
        codigo: module.codigo,
        orden: module.orden,
        permisos: own.isEmpty ? module.permisos : own,
      );
    }).toList();
    return Column(
      children: resolved.map((Modulo module) {
        return Card(
          child: ExpansionTile(
            title: Text(module.nombre),
            children: module.permisos.map((Permiso permission) {
              return CheckboxListTile(
                value: selected.contains(permission.codigo),
                title: Text(permission.nombre),
                subtitle: Text(permission.codigo),
                onChanged: (bool? value) => setState(() {
                  if (value == true) {
                    selected.add(permission.codigo);
                  } else {
                    selected.remove(permission.codigo);
                  }
                }),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reportes')),
    body: ListView(
      children: <Widget>[
        ListTile(
          title: const Text('Ventas por fecha'),
          leading: const Icon(Icons.point_of_sale),
          onTap: () => context.push('/reportes/ventas'),
        ),
        ListTile(
          title: const Text('Inventario'),
          leading: const Icon(Icons.inventory),
          onTap: () => context.push('/reportes/inventario'),
        ),
        ListTile(
          title: const Text('Movimientos'),
          leading: const Icon(Icons.swap_vert),
          onTap: () => context.push('/reportes/movimientos'),
        ),
      ],
    ),
  );
}

class DashboardAdminPage extends ConsumerWidget {
  const DashboardAdminPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReporteDashboard> state = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            errorView(e, () => ref.invalidate(dashboardProvider)),
        data: (ReporteDashboard report) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _kpiGrid(report),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: _salesChart(report.ventasPorDia)),
          ],
        ),
      ),
    );
  }
}

Widget _kpiGrid(ReporteDashboard r) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    _metric('Ventas hoy', money(r.ventasHoy)),
    _metric('Ventas mes', money(r.ventasMes)),
    _metric('Compras mes', money(r.totalComprasMes)),
    _metric('Gastos mes', money(r.totalGastosMes)),
    _metric('Stock bajo', '${r.productosStockBajo}'),
  ],
);
Widget _metric(String label, String value) => SizedBox(
  width: 170,
  child: Card(
    child: ListTile(
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
  ),
);
Widget _salesChart(List<ChartPoint> points) {
  if (points.isEmpty) return const Center(child: Text('Sin ventas por dia'));
  return LineChart(
    LineChartData(
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: points
              .asMap()
              .entries
              .map(
                (MapEntry<int, ChartPoint> e) =>
                    FlSpot(e.key.toDouble(), e.value.total),
              )
              .toList(),
          isCurved: true,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
    ),
  );
}

class ReporteDetallePage extends ConsumerWidget {
  const ReporteDetallePage({required this.kind, super.key});
  final String kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool inventory = kind == 'inventario';
    final AsyncValue<ReporteDashboard> state = inventory
        ? ref.watch(inventoryReportProvider)
        : ref.watch(movementsReportProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Reporte de $kind')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) => errorView(
          e,
          () => inventory
              ? ref.invalidate(inventoryReportProvider)
              : ref.invalidate(movementsReportProvider),
        ),
        data: (ReporteDashboard r) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _metric('Productos', '${r.totalProductos}'),
            _metric('Stock bajo', '${r.productosStockBajo}'),
            ...r.productosStockBajoList.map(
              (Map<String, Object?> item) => ListTile(
                title: Text(
                  '${item['nombre'] ?? item['productoNombre'] ?? 'Producto'}',
                ),
                subtitle: Text('Stock: ${item['stockActual'] ?? '--'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReporteVentasPage extends ConsumerStatefulWidget {
  const ReporteVentasPage({super.key});
  @override
  ConsumerState<ReporteVentasPage> createState() => _ReporteVentasState();
}

class _ReporteVentasState extends ConsumerState<ReporteVentasPage> {
  DateTime desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime hasta = DateTime.now();
  Future<void> pick(bool from) async {
    final DateTime? value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: from ? desde : hasta,
    );
    if (value != null) {
      setState(() {
        if (from) {
          desde = value;
        } else {
          hasta = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Venta>> state = ref.watch(
      reportSalesProvider(DateRange(desde, hasta)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas por fecha')),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: () => pick(true),
                  child: Text('Desde ${dateOnly(desde)}'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => pick(false),
                  child: Text('Hasta ${dateOnly(hasta)}'),
                ),
              ),
            ],
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => errorView(
                e,
                () => ref.invalidate(
                  reportSalesProvider(DateRange(desde, hasta)),
                ),
              ),
              data: (List<Venta> values) => values.isEmpty
                  ? const Center(child: Text('No hay ventas en el rango.'))
                  : ListView.builder(
                      itemCount: values.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Venta sale = values[index];
                        return ListTile(
                          title: Text(
                            sale.numeroFactura ?? 'Venta #${sale.id}',
                          ),
                          subtitle: Text(dateText(sale.fechaCreacion)),
                          trailing: Text(money(sale.total)),
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

class LogsPageView extends ConsumerStatefulWidget {
  const LogsPageView({super.key});
  @override
  ConsumerState<LogsPageView> createState() => _LogsState();
}

class _LogsState extends ConsumerState<LogsPageView> {
  final TextEditingController entity = TextEditingController();
  final TextEditingController action = TextEditingController();
  DateTime? from, to;
  int? userId;
  Future<void> pick(bool start) async {
    final DateTime? value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: start ? from ?? DateTime.now() : to ?? DateTime.now(),
    );
    if (value != null) {
      setState(() {
        if (start) {
          from = value;
        } else {
          to = value;
        }
      });
    }
  }

  Future<void> apply() => ref
      .read(logsProvider.notifier)
      .setFilters(
        from: from,
        to: to,
        user: userId,
        entity: entity.text.trim(),
        action: action.text.trim(),
      );
  @override
  void dispose() {
    entity.dispose();
    action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LogsPage> state = ref.watch(logsProvider);
    final AsyncValue<List<UsuarioOpcion>> users = ref.watch(logUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: <Widget>[
          if (can(ref, PermissionCodes.logsEliminar))
            IconButton(
              tooltip: 'Borrar por rango',
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep),
              onPressed: ref.watch(logsProvider).isLoading
                  ? null
                  : _deleteRange,
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _filters(users),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  errorView(e, () => ref.invalidate(logsProvider)),
              data: _logList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(AsyncValue<List<UsuarioOpcion>> users) => Padding(
    padding: const EdgeInsets.all(8),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        TextButton(
          onPressed: () => pick(true),
          child: Text(from == null ? 'Fecha desde' : dateOnly(from!)),
        ),
        TextButton(
          onPressed: () => pick(false),
          child: Text(to == null ? 'Fecha hasta' : dateOnly(to!)),
        ),
        SizedBox(
          width: 140,
          child: users.when(
            data: (List<UsuarioOpcion> values) => DropdownButton<int>(
              isExpanded: true,
              value: userId,
              hint: const Text('Usuario'),
              items: values
                  .map(
                    (UsuarioOpcion u) => DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(u.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() => userId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace s) => const Text('Usuarios'),
          ),
        ),
        SizedBox(
          width: 130,
          child: TextField(
            controller: entity,
            decoration: const InputDecoration(labelText: 'Entidad'),
          ),
        ),
        SizedBox(
          width: 130,
          child: TextField(
            controller: action,
            decoration: const InputDecoration(labelText: 'Accion'),
          ),
        ),
        FilledButton(onPressed: apply, child: const Text('Filtrar')),
      ],
    ),
  );
  Widget _logList(LogsPage page) => Column(
    children: <Widget>[
      Expanded(
        child: page.content.isEmpty
            ? const Center(child: Text('No hay logs.'))
            : ListView.builder(
                itemCount: page.content.length,
                itemBuilder: (BuildContext context, int index) {
                  final Auditoria item = page.content[index];
                  return ListTile(
                    key: ValueKey<int>(item.id),
                    title: Text('${item.entidad} · ${item.accion}'),
                    subtitle: Text(
                      '${item.usuarioNombre ?? 'Sistema'} · ${dateText(item.fecha)}\n${item.detalle ?? ''}',
                    ),
                  );
                },
              ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            onPressed: page.number > 0
                ? () => ref.read(logsProvider.notifier).goTo(page.number - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${page.number + 1} / ${page.totalPages == 0 ? 1 : page.totalPages}',
          ),
          IconButton(
            onPressed: page.number + 1 < page.totalPages
                ? () => ref.read(logsProvider.notifier).goTo(page.number + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ],
  );
  Future<void> _deleteRange() async {
    if (from == null || to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione fecha desde y hasta')),
      );
      return;
    }
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: const Text('Se eliminaran los logs del rango seleccionado.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => dialog.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => dialog.pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (yes == true) {
      try {
        final LogsEliminados result = await ref
            .read(logsProvider.notifier)
            .deleteRange(from!, to!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.eliminados} logs eliminados')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(userFailureMessage(error))));
        }
      }
    }
  }
}
