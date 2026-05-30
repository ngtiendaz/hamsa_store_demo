import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final int? maxLines;
  final int? minLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.initialValue,
    this.controller,
    this.maxLines,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelMd,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: keyboardType == TextInputType.multiline ? maxLines : 1,
          minLines: keyboardType == TextInputType.multiline ? minLines : 1,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
