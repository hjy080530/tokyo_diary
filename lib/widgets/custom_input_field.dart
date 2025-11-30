// lib/widgets/custom_input_field.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomInputField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: AppFonts.bodyMedium,
            fontWeight: AppFonts.medium,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        // 입력 필드
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontSize: AppFonts.bodyMedium,
              fontWeight: AppFonts.regular,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                fontSize: AppFonts.bodyMedium,
                fontWeight: AppFonts.regular,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              counterText: '', // maxLength 카운터 숨기기
            ),
          ),
        ),
      ],
    );
  }
}