// lib/widgets/observation_card.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';

class ObservationCard extends StatelessWidget {
  final String title;
  final String content;
  final DateTime? date;
  final List<String> tags;

  const ObservationCard({
    super.key,
    required this.title,
    required this.content,
    this.date,
    this.tags = const [],
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
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: AppFonts.bodySmall,
                      color: AppColors.background,
                      fontWeight: AppFonts.medium,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
