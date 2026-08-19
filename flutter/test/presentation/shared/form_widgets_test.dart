import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/presentation/shared/widgets/forms/app_dropdown_field.dart';
import 'package:ferreplus/presentation/shared/widgets/forms/app_form_field.dart';
import 'package:ferreplus/presentation/shared/widgets/forms/app_form_section.dart';

void main() {
  testWidgets('shared form fields expose labels and validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Form(
            child: Column(
              children: <Widget>[
                const AppFormField(label: 'Nombre', validator: _required),
                AppDropdownField<String>(
                  label: 'Estado',
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  ],
                  onChanged: (_) {},
                ),
                const AppFormSection(
                  title: 'DATOS',
                  children: <Widget>[Text('Contenido')],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('DATOS'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('AppFormField keeps validator behavior', (
    WidgetTester tester,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: const AppFormField(label: 'Nombre', validator: _required),
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Campo requerido'), findsOneWidget);
  });
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Campo requerido' : null;
