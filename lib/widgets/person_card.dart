// lib/widgets/person_card.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';

class PersonCard extends StatelessWidget {
  final String name;
  final String? profileImage;
  final bool hasInstagram;
  final bool hasGithub;
  final bool hasLink;

  const PersonCard({
    super.key,
    required this.name,
    this.profileImage,
    this.hasInstagram = false,
    this.hasGithub = false,
    this.hasLink = false,
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
          // 프로필 이미지 + 이름
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.buttonBorder,
                  image: profileImage != null
                      ? DecorationImage(
                    image: AssetImage(profileImage!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: profileImage == null
                    ? Icon(
                  Icons.person,
                  size: 30,
                  color: AppColors.textSecondary,
                )
                    : null,
              ),

              const SizedBox(width: 16),

              // 이름
              Text(
                name,
                style: TextStyle(
                  fontSize: AppFonts.bodyLarge,
                  fontWeight: AppFonts.medium,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 소셜 미디어 아이콘들
          Row(
            children: [
              if (hasInstagram) _SocialIconPlaceholder(color: Colors.pink),
              if (hasInstagram) const SizedBox(width: 12),

              if (hasGithub) _SocialIconPlaceholder(color: Colors.black),
              if (hasGithub) const SizedBox(width: 12),

              if (hasLink) _SocialIconPlaceholder(color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialIconPlaceholder extends StatelessWidget {
  final Color color;

  const _SocialIconPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(
        Icons.link,
        size: 20,
        color: color,
      ),
    );
  }
}