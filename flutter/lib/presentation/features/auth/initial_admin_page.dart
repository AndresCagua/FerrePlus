import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../theme/app_spacing.dart';

class InitialAdminPage extends ConsumerStatefulWidget {
  const InitialAdminPage({required this.repository, super.key});

  final AuthRepository repository;

  @override
  ConsumerState<InitialAdminPage> createState() => _InitialAdminPageState();
}

class _InitialAdminPageState extends ConsumerState<InitialAdminPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.repository.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Administrador registrado correctamente.'),
        ),
      );
      context.go('/auth');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Registro inicial',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Registrar administrador'),
                  const SizedBox(height: AppSpacing.space20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                        ? 'Ingresa el nombre'
                        : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (String? value) =>
                        value == null || !value.contains('@')
                        ? 'Ingresa un correo valido'
                        : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contrasena'),
                    validator: (String? value) =>
                        value == null || value.length < 6
                        ? 'La contrasena debe tener al menos 6 caracteres'
                        : null,
                  ),
                  TextFormField(
                    controller: _confirmationController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contrasena',
                    ),
                    validator: (String? value) =>
                        value != _passwordController.text
                        ? 'Las contrasenas no coinciden'
                        : null,
                  ),
                  if (_error != null)
                    AppErrorView(message: _error!, onRetry: _submit),
                  const SizedBox(height: AppSpacing.space20),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const AppLoadingIndicator()
                        : const Text('Registrar'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Volver al login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
