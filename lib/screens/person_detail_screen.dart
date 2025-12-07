// lib/screens/person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/gemini_service.dart';
import '../services/mongo_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';
import '../widgets/observation_card.dart';
import 'activity_log_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _launchExternalLink(url);
  }

  Future<void> _launchExternalLink(String? rawUrl) async {
    if (rawUrl == null) return;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.startsWith('http') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
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

  Future<void> _openFeedbackPicker() async {
    List<Map<String, dynamic>> logs;
    try {
      logs = await _logsFuture;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관찰일지를 불러오지 못했습니다.')),
      );
      return;
    }
    if (!mounted) return;
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 관찰일지를 작성해 주세요.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (ctx) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '피드백 받을 기록 선택',
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        fontWeight: AppFonts.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final activity = log['activity']?.toString() ?? '내용 없음';
                    final dateValue = log['date'];
                    String dateLabel = '날짜 정보 없음';
                    if (dateValue is DateTime) {
                      dateLabel =
                          '${dateValue.month}/${dateValue.day}';
                    } else if (dateValue is String) {
                      final parsed = DateTime.tryParse(dateValue);
                      if (parsed != null) {
                        dateLabel = '${parsed.month}/${parsed.day}';
                      }
                    }
                    return ListTile(
                      title: Text(
                        activity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(dateLabel),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openLogDetail(log);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _openLogDetail(Map<String, dynamic> log) async {
    final activity = log['activity']?.toString() ?? '';
    final thoughts = log['thoughts']?.toString() ?? '';
    final DateTime? date = () {
      final value = log['date'];
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetContext) {
        String? feedback;
        String? error;
        bool loading = false;

        Future<void> requestFeedback(StateSetter setModalState) async {
          if (activity.isEmpty && thoughts.isEmpty) {
            setModalState(() {
              error = '활동과 감상이 모두 비어 있어요.';
              feedback = null;
            });
            return;
          }
          setModalState(() {
            loading = true;
            error = null;
          });
          try {
            final result = await geminiService.generateFeedback(
              personName: _person['name']?.toString() ?? '이름 없음',
              personActivity: activity,
              userReflection: thoughts.isEmpty ? '미입력' : thoughts,
            );
            setModalState(() {
              feedback = result;
            });
          } catch (e) {
            setModalState(() {
              error =
                  e is GeminiException ? e.message : '피드백 요청에 실패했습니다.';
              feedback = null;
            });
          } finally {
            setModalState(() {
              loading = false;
            });
          }
        }

        final dateLabel = date != null
            ? '${date!.year}.${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')}'
            : null;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '관찰일지 상세',
                          style: TextStyle(
                            fontSize: AppFonts.bodyLarge,
                            fontWeight: AppFonts.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (dateLabel != null) ...[
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: AppFonts.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      '오늘의 활동',
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        fontWeight: AppFonts.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.isEmpty ? '내용이 없습니다.' : activity,
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '나의 감상',
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        fontWeight: AppFonts.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      thoughts.isEmpty ? '감상이 작성되지 않았어요.' : thoughts,
                      style: TextStyle(
                        fontSize: AppFonts.bodyMedium,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            loading ? null : () => requestFeedback(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Image.asset(
                                'assets/gemini_white_logo.png',
                                width: 18,
                                height: 18,
                              ),
                        label: Text(
                          loading ? '피드백 생성 중...' : '제미나이 피드백 받기',
                          style: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            fontWeight: AppFonts.semiBold,
                          ),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (feedback != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'AI 피드백',
                        style: TextStyle(
                          fontSize: AppFonts.bodyMedium,
                          fontWeight: AppFonts.semiBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: feedback!,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          strong: const TextStyle(
                            fontWeight: AppFonts.semiBold,
                            color: AppColors.textPrimary,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: AppColors.buttonBackground,
                            border: Border(
                              left: BorderSide(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                          ),
                          blockquotePadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          h1: TextStyle(
                            fontSize: AppFonts.bodyLarge,
                            fontWeight: AppFonts.bold,
                            color: AppColors.textPrimary,
                          ),
                          h2: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            fontWeight: AppFonts.semiBold,
                            color: AppColors.textPrimary,
                          ),
                          h3: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            fontWeight: AppFonts.semiBold,
                            color: AppColors.textPrimary,
                          ),
                          listBullet: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
                    '나의 관찰 스트릭',
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '나의 관찰일지',
                      style: TextStyle(
                        fontSize: AppFonts.bodyLarge,
                        fontWeight: AppFonts.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openFeedbackPicker,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/gemini_logo.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text('제미나이 피드백'),
                      ],
                    ),
                  ),
                ],
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
                        child: GestureDetector(
                          onTap: () => _openLogDetail(log),
                          behavior: HitTestBehavior.opaque,
                          child: ObservationCard(
                            title: log['activity']?.toString() ?? '',
                            content: log['thoughts']?.toString() ?? '',
                            date: date,
                          ),
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
            color: AppColors.buttonBorder.withValues(alpha: 0.3),
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
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
