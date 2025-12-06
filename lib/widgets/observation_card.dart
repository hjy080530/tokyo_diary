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
    final dateLabel = date != null
        ? '${date!.year}.${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          if (dateLabel != null) ...[
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: AppFonts.bodySmall,
                fontWeight: AppFonts.medium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.bodyLarge,
              fontWeight: AppFonts.semiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
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
