// lib/widgets/observation_card.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';

class ObservationCard extends StatelessWidget {
  final String title;
  final String content;
  final DateTime? date;

  const ObservationCard({
    super.key,
    required this.title,
    required this.content,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.buttonBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.bodyLarge,
              fontWeight: AppFonts.semiBold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // 내용
          Text(
            content,
            style: TextStyle(
              fontSize: AppFonts.bodyMedium,
              fontWeight: AppFonts.regular,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}