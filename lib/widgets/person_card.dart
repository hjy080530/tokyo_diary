// lib/widgets/person_card.dart 업데이트 (클릭 이벤트 추가)
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';



class PersonCard extends StatelessWidget {
  final String name;
  final String? profileImage;
  final int streakDays;
  final Map<String, String> socialLinks;
  final VoidCallback? onTap;

  const PersonCard({
    super.key,
    required this.name,
    this.profileImage,
    this.streakDays = 0,
    this.socialLinks = const {},
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                if (socialLinks.containsKey('instagram'))
                  const _SocialIconPlaceholder(
                    iconPath: 'assets/icons/instagram_icon.png',
                  ),
                if (socialLinks.containsKey('instagram'))
                  const SizedBox(width: 12),
                if (socialLinks.containsKey('github'))
                  const _SocialIconPlaceholder(
                    iconPath: 'assets/icons/github_icon.png',
                  ),
                if (socialLinks.containsKey('github'))
                  const SizedBox(width: 12),
                if (socialLinks.containsKey('link'))
                  const _SocialIconPlaceholder(
                    iconPath: 'assets/icons/link_icon.png',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIconPlaceholder extends StatelessWidget {
  final String iconPath;

  const _SocialIconPlaceholder({
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        iconPath,
        fit: BoxFit.contain,
      ),
    );
  }
}
