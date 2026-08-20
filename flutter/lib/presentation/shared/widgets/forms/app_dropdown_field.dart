import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Dropdown form field with the same visual contract as [AppFormField].
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.enabled,
    this.validator,
    this.decoration,
    super.key,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  /// Flutter 3.38 makes [initialValue] the non-deprecated API for this field.
  final T? initialValue;
  final bool? enabled;
  final FormFieldValidator<T>? validator;
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
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: enabled == false ? null : onChanged,
      validator: validator,
      decoration: fieldDecoration,
    );
  }
}
