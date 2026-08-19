import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Text input shared by presentation forms.
class AppFormField extends StatelessWidget {
  const AppFormField({
    this.controller,
    this.initialValue,
    required this.label,
    this.keyboardType,
    this.enabled,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.decoration,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue cannot be used together',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final TextInputType? keyboardType;
  final bool? enabled;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final InputDecoration fieldDecoration =
        (decoration ?? const InputDecoration()).copyWith(
          labelText: decoration?.labelText ?? label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
        );
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      decoration: fieldDecoration,
      minLines: 1,
    );
  }
}
