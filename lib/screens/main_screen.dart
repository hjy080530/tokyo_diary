// lib/screens/main_screen.dart 업데이트 (동경인물 추가 버튼 연결)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/person_card.dart';
import 'add_person_screen.dart';
import 'person_detail_screen.dart';
import 'reminder_overview_screen.dart';

final adoredPersonsProvider = FutureProvider.family<List<Map<String, dynamic>>, ObjectId>((ref, userId) {
  return mongoService.fetchAdoredPersonsByUserId(userId);
});

class MainScreen extends ConsumerWidget {
  final Map<String, dynamic> user;

  const MainScreen({super.key, required this.user});

  Map<String, String> _socialLinkMap(List<dynamic>? links) {
    if (links == null) return {};
    final result = <String, String>{};
    for (final link in links) {
      if (link is Map<String, dynamic>) {
        final type = link['type'];
        final url = link['url'];
        if (type is String && url is String) {
          result[type] = url;
        }
      }
    }
    return result;
  }

  int _currentStreakFrom(dynamic stats) {
    if (stats is Map<String, dynamic>) {
      final value = stats['currentStreak'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) {
        return int.tryParse(value.toString()) ?? 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdRaw = user['_id'];
    final userId = userIdRaw is ObjectId ? userIdRaw : null;
    final name = user['name']?.toString();
    final email = user['email']?.toString();
    final userLabel =
        (name != null && name.isNotEmpty) ? name : (email ?? '사용자');
    final adoredAsync = userId == null
        ? const AsyncValue.data(<Map<String, dynamic>>[])
        : ref.watch(adoredPersonsProvider(userId));

    String? highlightName;
    adoredAsync.whenData((list) {
      if (list.isNotEmpty) {
        final first = list.first['name']?.toString();
        if (first != null && first.isNotEmpty) {
          highlightName = first;
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 - 타이틀 + 알람 아이콘
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/tokyo_diary_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
          IconButton(
            onPressed: userId == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReminderOverviewScreen(
                          userId: userId,
                        ),
                      ),
                    );
                  },
            icon: Icon(
              Icons.alarm,
              color: userId == null
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
          ),
                ],
              ),
            ),

            // 인사말 배너
            _GreetingBanner(
              userLabel: userLabel,
              highlightName: highlightName,
            ),

            const SizedBox(height: 32),

            // 나의 동경대상 섹션
            Expanded(
              child: adoredAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    '동경대상을 불러오지 못했습니다.',
                    style: TextStyle(
                      fontSize: AppFonts.bodyMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                data: (persons) => ListView(
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
                    if (persons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          '아직 등록된 동경대상이 없습니다. 추가해 보세요!',
                          style: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    for (final person in persons) ...[
                      PersonCard(
                        name: person['name']?.toString() ?? '이름 없음',
                        profileImage: person['profileImage'] as String?,
                        streakDays: _currentStreakFrom(person['stats']),
                        socialLinks:
                            _socialLinkMap(person['socialLinks'] as List?),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonDetailScreen(
                                adoredPerson: person,
                                user: user,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 40),
                    Center(
                    child: _AddPersonButton(
                        onPressed: userId == null
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddPersonScreen(userId: userId),
                                  ),
                                );
                                if (result == true) {
                                  ref.invalidate(adoredPersonsProvider(userId));
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingBanner extends StatefulWidget {
  final String userLabel;
  final String? highlightName;

  const _GreetingBanner({
    required this.userLabel,
    this.highlightName,
  });

  @override
  State<_GreetingBanner> createState() => _GreetingBannerState();
}

class _GreetingBannerState extends State<_GreetingBanner> {
  final PageController _pageController = PageController();
  final List<String> _backgrounds =
      List.generate(5, (index) => 'assets/backgrounds/${index + 1}.png');
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
              color: Colors.black.withValues(alpha: 0.1),
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
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
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
                      '안녕하세요, ${widget.userLabel}님!',
                      style: TextStyle(
                        fontSize: AppFonts.bodyLarge,
                        fontWeight: AppFonts.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '오늘의 ${widget.highlightName ?? '동경대상'}님의 활동이 궁금하지 않으세요?',
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        fontWeight: AppFonts.medium,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
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
  final VoidCallback? onPressed;

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
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
