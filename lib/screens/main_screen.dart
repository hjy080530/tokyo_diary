// lib/screens/main_screen.dart 업데이트 (동경인물 추가 버튼 연결)
import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../widgets/person_card.dart';
import 'add_person_screen.dart';

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
              child:
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'tokyo_diary_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
            ),

            // 인사말 배너
            _GreetingBanner(),

            const SizedBox(height: 140),

            // 나의 동경대상 섹션
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      '나의 동경대상',
                      style: TextStyle(
                        fontSize: AppFonts.bodyLarge,
                        fontWeight: AppFonts.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const PersonCard(
                    name: '사랑하는 사람',
                    streakDays: 42,
                    hasInstagram: true,
                    hasGithub: true,
                    hasLink: true,
                    instagramUrl: 'https://instagram.com/example',
                    githubUrl: 'https://github.com/example',
                    linkUrl: 'https://example.com',
                  ),
                  const SizedBox(height: 16),
                  const PersonCard(
                    name: '오주현',
                    streakDays: 56,
                    hasInstagram: true,
                    hasGithub: true,
                    hasLink: true,
                    instagramUrl: 'https://instagram.com/example2',
                    githubUrl: 'https://github.com/example2',
                    linkUrl: 'https://example2.com',
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: _AddPersonButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPersonScreen(),
                          ),
                        );
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

class _GreetingBanner extends StatefulWidget {
  const _GreetingBanner();

  @override
  State<_GreetingBanner> createState() => _GreetingBannerState();
}

class _GreetingBannerState extends State<_GreetingBanner> {
  final PageController _pageController = PageController();
  final List<String> _backgrounds =
      List.generate(5, (index) => 'backgrounds/${index + 1}.png');
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % _backgrounds.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _backgrounds.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Image.asset(
                    _backgrounds[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 0, 0),
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
            ],
          ),
        ),
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
