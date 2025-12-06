// lib/screens/person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';
import '../widgets/observation_card.dart';
import 'activity_log_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> adoredPerson;
  final Map<String, dynamic> user;

  const PersonDetailScreen({
    super.key,
    required this.adoredPerson,
    required this.user,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late Map<String, dynamic> _person;
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _person = widget.adoredPerson;
    _logsFuture = _loadLogs();
    _ensureDefaultReminder();
  }

  Future<List<Map<String, dynamic>>> _loadLogs() {
    final id = _person['_id'];
    if (id is ObjectId) {
      return mongoService.fetchObservationLogsByPerson(id);
    }
    return Future.value(const []);
  }

  Map<String, String> _socialLinkMap() {
    final links = _person['socialLinks'];
    if (links is! List) return {};
    final map = <String, String>{};
    for (final link in links) {
      if (link is Map<String, dynamic>) {
        final type = link['type'];
        final url = link['url'];
        if (type is String && url is String) {
          map[type] = url;
        }
      }
    }
    return map;
  }

  int _currentStreak() {
    final stats = _person['stats'];
    if (stats is Map<String, dynamic>) {
      final value = stats['currentStreak'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) return int.tryParse(value.toString()) ?? 0;
    }
    return 0;
  }

  void _handleLinkTap(String platform, String url) {
    debugPrint('$platform: $url');
  }

  Future<void> _refreshPerson() async {
    final id = _person['_id'];
    if (id is! ObjectId) return;
    final updated = await mongoService.fetchAdoredPersonById(id);
    if (updated != null && mounted) {
      setState(() {
        _person = updated;
      });
      await _rescheduleSavedReminder();
    }
  }

  Future<void> _openActivityLog() async {
    final adoredPersonId = _person['_id'];
    final userId = widget.user['_id'];
    if (adoredPersonId is! ObjectId || userId is! ObjectId) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityLogScreen(
          personName: _person['name']?.toString() ?? '이름 없음',
          adoredPersonId: adoredPersonId,
          userId: userId,
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _logsFuture = _loadLogs();
        });
      }
      await _refreshPerson();
    }
  }

  Future<void> _ensureDefaultReminder() async {
    final id = _person['_id'];
    if (id is! ObjectId) return;
    final personId = id.toHexString();
    final settings = await ReminderPreferences.instance.load(personId);
    if (settings.isDefault && settings.enabled) {
      await ReminderPreferences.instance.save(
        personId,
        ReminderSetting(enabled: settings.enabled, time: settings.time),
      );
      await notificationService.scheduleDailyReminder(
        personId: personId,
        personName: _person['name']?.toString() ?? '이름 없음',
        time: settings.time,
      );
    } else if (settings.enabled) {
      await notificationService.scheduleDailyReminder(
        personId: personId,
        personName: _person['name']?.toString() ?? '이름 없음',
        time: settings.time,
      );
    }
  }

  Future<void> _rescheduleSavedReminder() async {
    final id = _person['_id'];
    if (id is! ObjectId) return;
    final personId = id.toHexString();
    final settings = await ReminderPreferences.instance.load(personId);
    if (settings.enabled) {
      await notificationService.scheduleDailyReminder(
        personId: personId,
        personName: _person['name']?.toString() ?? '이름 없음',
        time: settings.time,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialLinks = _socialLinkMap();
    final name = _person['name']?.toString() ?? '이름 없음';
    final description = _person['description']?.toString();
    final profileImage = _person['profileImage'] as String?;
    final streakDays = _currentStreak();

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
                      'assets/tokyo_diary_logo.png',
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

                  // 이름 및 설명
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: AppFonts.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: AppFonts.bodyMedium,
                              fontWeight: AppFonts.regular,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
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
                  if (socialLinks['instagram'] != null)
                    _SocialIcon(
                      iconPath: 'assets/icons/instagram_icon.png',
                      onTap: () => _handleLinkTap(
                        'Instagram',
                        socialLinks['instagram']!,
                      ),
                    ),
                  if (socialLinks['instagram'] != null)
                    const SizedBox(width: 12),

                  if (socialLinks['github'] != null)
                    _SocialIcon(
                      iconPath: 'assets/icons/github_icon.png',
                      onTap: () => _handleLinkTap(
                        'GitHub',
                        socialLinks['github']!,
                      ),
                    ),
                  if (socialLinks['github'] != null)
                    const SizedBox(width: 12),

                  if (socialLinks['link'] != null)
                    _SocialIcon(
                      iconPath: 'assets/icons/link_icon.png',
                      onTap: () => _handleLinkTap(
                        'Link',
                        socialLinks['link']!,
                      ),
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
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: 2,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            // 관찰일지 리스트
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '관찰일지를 불러오지 못했습니다.',
                        style: TextStyle(
                          fontSize: AppFonts.bodyMedium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        '아직 관찰일지가 없습니다.',
                        style: TextStyle(
                          fontSize: AppFonts.bodyMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final dateValue = log['date'];
                      DateTime? date;
                      if (dateValue is DateTime) {
                        date = dateValue;
                      } else if (dateValue is String) {
                        date = DateTime.tryParse(dateValue);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ObservationCard(
                          title: log['activity']?.toString() ?? '',
                          content: log['thoughts']?.toString() ?? '',
                          date: date,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 활동일지 추가 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: _AddActivityLogButton(
                  onPressed: _openActivityLog,
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
          shape: RoundedRectangleBorder(),
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
