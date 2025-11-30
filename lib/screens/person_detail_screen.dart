// lib/screens/person_detail_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../widgets/observation_card.dart';
import 'activity_log_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final String name;
  final String? profileImage;
  final int streakDays;
  final String? instagramUrl;
  final String? githubUrl;
  final String? linkUrl;

  const PersonDetailScreen({
    super.key,
    required this.name,
    this.profileImage,
    required this.streakDays,
    this.instagramUrl,
    this.githubUrl,
    this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'tokyo_diary_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // 프로필 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // 프로필 이미지
                  Container(
                    width: 80,
                    height: 80,
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
                      size: 40,
                      color: AppColors.textSecondary,
                    )
                        : null,
                  ),

                  const SizedBox(width: 20),

                  // 이름
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: AppFonts.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 소셜 미디어 아이콘
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  if (instagramUrl != null)
                    _SocialIcon(
                      iconPath: 'icons/instagram_icon.png',
                      onTap: () {
                        print('Instagram: $instagramUrl');
                      },
                    ),
                  if (instagramUrl != null) const SizedBox(width: 12),

                  if (githubUrl != null)
                    _SocialIcon(
                      iconPath: 'icons/github_icon.png',
                      onTap: () {
                        print('GitHub: $githubUrl');
                      },
                    ),
                  if (githubUrl != null) const SizedBox(width: 12),

                  if (linkUrl != null)
                    _SocialIcon(
                      iconPath: 'icons/link_icon.png',
                      onTap: () {
                        print('Link: $linkUrl');
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 나의 관찰 기록
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 관찰 기록',
                    style: TextStyle(
                      fontSize: AppFonts.bodyLarge,
                      fontWeight: AppFonts.semiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 스트릭 바
                  _StreakBar(days: streakDays),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 나의 관찰일지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '나의 관찰일지',
                style: TextStyle(
                  fontSize: AppFonts.bodyLarge,
                  fontWeight: AppFonts.semiBold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 구분선
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 2,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            // 관찰일지 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: const [
                  ObservationCard(
                    title: '사랑하는 사람',
                    content: '토끼가 나무를 바라보고있다.토끼가 나무를 바라보고있...',
                  ),
                  SizedBox(height: 8),
                  ObservationCard(
                    title: '사랑하는 사람',
                    content: '토끼가 나무를 바라보고있다.토끼가 나무를 바라보고있...',
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // 활동일지 추가 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: _AddActivityLogButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityLogScreen(personName: name),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          iconPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _StreakBar extends StatelessWidget {
  final int days;

  const _StreakBar({required this.days});

  @override
  Widget build(BuildContext context) {
    final double percentage = (days / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.buttonBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        Text(
          '$days일',
          style: TextStyle(
            fontSize: 48,
            fontWeight: AppFonts.bold,
            color: AppColors.primary,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _AddActivityLogButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddActivityLogButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '활동일지 추가',
              style: TextStyle(
                fontSize: AppFonts.bodyMedium,
                fontWeight: AppFonts.semiBold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.add,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}