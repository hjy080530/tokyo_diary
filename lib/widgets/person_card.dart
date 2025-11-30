// lib/widgets/person_card.dart 업데이트 (클릭 이벤트 추가)
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../screens/person_detail_screen.dart';

class PersonCard extends StatelessWidget {
  final String name;
  final String? profileImage;
  final int streakDays;
  final bool hasInstagram;
  final bool hasGithub;
  final bool hasLink;
  final String? instagramUrl;
  final String? githubUrl;
  final String? linkUrl;

  const PersonCard({
    super.key,
    required this.name,
    this.profileImage,
    this.streakDays = 0,
    this.hasInstagram = false,
    this.hasGithub = false,
    this.hasLink = false,
    this.instagramUrl,
    this.githubUrl,
    this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonDetailScreen(
              name: name,
              profileImage: profileImage,
              streakDays: streakDays,
              instagramUrl: instagramUrl,
              githubUrl: githubUrl,
              linkUrl: linkUrl,
            ),
          ),
        );
      },
      child: Container(
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
                if (hasInstagram)
                  _SocialIconPlaceholder(
                    iconPath: 'assets/icons/instagram_logo.png',
                  ),
                if (hasInstagram) const SizedBox(width: 12),

                if (hasGithub)
                  _SocialIconPlaceholder(
                    iconPath: 'assets/icons/github_icon.png',
                  ),
                if (hasGithub) const SizedBox(width: 12),

                if (hasLink)
                  _SocialIconPlaceholder(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        iconPath,
        fit: BoxFit.contain,
      ),
    );
  }
}