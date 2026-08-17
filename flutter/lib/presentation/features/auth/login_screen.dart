import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../domain/models/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(_email.text.trim(), _password.text);
    if (mounted && ref.read(authNotifierProvider).status == AuthStatus.authenticated) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authNotifierProvider);
    final bool loading = auth.status == AuthStatus.unknown;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text('FerrePlus', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo'), validator: (value) => value != null && value.contains('@') ? null : 'Ingresa un correo valido'),
                const SizedBox(height: 12),
                TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contrasena'), validator: (value) => value != null && value.length >= 6 ? null : 'La contrasena debe tener al menos 6 caracteres'),
                if (auth.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(auth.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 20),
                FilledButton(onPressed: loading ? null : _submit, child: loading ? const CircularProgressIndicator() : const Text('Ingresar')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
