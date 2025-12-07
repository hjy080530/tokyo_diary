import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../services/reminder_preferences.dart';
import 'reminder_settings_screen.dart';

class ReminderOverviewScreen extends StatefulWidget {
  final ObjectId userId;

  const ReminderOverviewScreen({super.key, required this.userId});

  @override
  State<ReminderOverviewScreen> createState() => _ReminderOverviewScreenState();
}

class _ReminderOverviewScreenState extends State<ReminderOverviewScreen> {
  late Future<List<Map<String, dynamic>>> _adoredFuture;

  @override
  void initState() {
    super.initState();
    _adoredFuture =
        mongoService.fetchAdoredPersonsByUserId(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _adoredFuture =
          mongoService.fetchAdoredPersonsByUserId(widget.userId);
    });
  }

  Future<void> _openReminder(Map<String, dynamic> person) async {
    final id = person['_id'];
    if (id is! ObjectId) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderSettingsScreen(
          personId: id,
          personName: person['name']?.toString() ?? '이름 없음',
        ),
      ),
    );
    if (result != null) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '알람 설정',
                    style: TextStyle(
                      fontSize: AppFonts.bodyLarge,
                      fontWeight: AppFonts.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _adoredFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '알람 정보를 불러오지 못했습니다.',
                        style: TextStyle(
                          fontSize: AppFonts.bodyMedium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  final persons = snapshot.data ?? [];
                  if (persons.isEmpty) {
                    return Center(
                      child: Text(
                        '먼저 동경 대상을 추가해 주세요.',
                        style: TextStyle(
                          fontSize: AppFonts.bodyMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemBuilder: (context, index) {
                        final person = persons[index];
                        return _ReminderPersonTile(
                          person: person,
                          onTap: () => _openReminder(person),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: persons.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderPersonTile extends StatelessWidget {
  final Map<String, dynamic> person;
  final VoidCallback onTap;

  const _ReminderPersonTile({
    required this.person,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final id = person['_id'];
    final name = person['name']?.toString() ?? '이름 없음';
    final description = person['description']?.toString();
    if (id is! ObjectId) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<ReminderSetting>(
      future:
          ReminderPreferences.instance.load(id.toHexString()),
      builder: (context, snapshot) {
        final setting = snapshot.data ??
            const ReminderSetting(
              enabled: true,
              time: ReminderPreferences.defaultTime,
              isDefault: true,
            );
        final subtitle = setting.enabled
            ? '매일 ${MaterialLocalizations.of(context).formatTimeOfDay(setting.time)} 알림'
            : '알림 꺼짐';
        final subtitleColor =
            setting.enabled ? AppColors.textPrimary : AppColors.textSecondary;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: AppFonts.bodyLarge,
                          fontWeight: AppFonts.semiBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppFonts.bodySmall,
                          color: subtitleColor,
                        ),
                      ),
                      if (description != null && description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: AppFonts.bodySmall,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
