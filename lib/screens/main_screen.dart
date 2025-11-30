// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../widgets/person_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 - 타이틀
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                '懂慌日誌',
                style: AppFonts.titleStyle.copyWith(
                  fontSize: AppFonts.titleMedium,
                ),
              ),
            ),

            // 인사말 배너
            _GreetingBanner(),

            const SizedBox(height: 32),

            // 나의 동경대상 섹션
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  Text(
                    '나의 동경대상',
                    style: TextStyle(
                      fontSize: AppFonts.bodyLarge,
                      fontWeight: AppFonts.semiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 구분선
                  Container(
                    height: 2,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 16),

                  // 동경대상 리스트
                  const PersonCard(
                    name: '사랑하는 사람',
                    hasInstagram: true,
                    hasGithub: true,
                    hasLink: true,
                  ),

                  const SizedBox(height: 16),

                  const PersonCard(
                    name: '오주현',
                    hasInstagram: true,
                    hasGithub: true,
                    hasLink: true,
                  ),

                  const SizedBox(height: 40),

                  // 동경인물 추가 버튼
                  Center(
                    child: _AddPersonButton(
                      onPressed: () {
                        // TODO: 동경인물 추가 로직
                        print('동경인물 추가 버튼 클릭');
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/aquarium_bg.jpg'), // 추후 추가
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 어두운 오버레이
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // 텍스트 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '안녕하세요, 지영님!',
                  style: TextStyle(
                    fontSize: AppFonts.bodyLarge,
                    fontWeight: AppFonts.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '오늘의 ***님의 활동이 궁금하지 않으세요?',
                  style: TextStyle(
                    fontSize: AppFonts.bodyMedium,
                    fontWeight: AppFonts.medium,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 물고기 이모지들 (추후 실제 이미지로 교체 가능)
          Positioned(
            right: 30,
            top: 40,
            child: Text(
              '🐠',
              style: TextStyle(fontSize: 40),
            ),
          ),
          Positioned(
            right: 80,
            bottom: 50,
            child: Text(
              '🐟',
              style: TextStyle(fontSize: 35),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPersonButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddPersonButton({required this.onPressed});

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
              '동경인물 추가',
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