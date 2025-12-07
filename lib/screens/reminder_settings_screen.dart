import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';

class ReminderSettingsScreen extends StatefulWidget {
  final ObjectId personId;
  final String personName;

  const ReminderSettingsScreen({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _enabled = true;
  TimeOfDay _time = ReminderPreferences.defaultTime;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final id = widget.personId.toHexString();
    final settings = await ReminderPreferences.instance.load(id);
    if (!mounted) return;
    setState(() {
      _enabled = settings.enabled;
      _time = settings.time;
      _loading = false;
    });

    if (settings.isDefault && settings.enabled) {
      await _persistAndSchedule(settings);
    }
  }

  Future<void> _persistAndSchedule(ReminderSetting setting) async {
    final id = widget.personId.toHexString();
    await ReminderPreferences.instance.save(id, setting);
    await notificationService.scheduleDailyReminder(
      personId: id,
      personName: widget.personName,
      time: setting.time,
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    setState(() => _saving = true);
    final id = widget.personId.toHexString();
    final setting = ReminderSetting(enabled: _enabled, time: _time);

    if (_enabled) {
      await ReminderPreferences.instance.save(id, setting);
      await notificationService.scheduleDailyReminder(
        personId: id,
        personName: widget.personName,
        time: _time,
      );
    } else {
      await ReminderPreferences.instance.save(id, setting);
      await notificationService.cancelReminder(id);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, _enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          '${widget.personName} 알람 설정',
                          style: TextStyle(
                            fontSize: AppFonts.bodyLarge,
                            fontWeight: AppFonts.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '알람 활성화',
                                    style: TextStyle(
                                      fontSize: AppFonts.bodyMedium,
                                      fontWeight: AppFonts.semiBold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '알람을 끄면 오늘 이후 알림이 발송되지 않아요.',
                                    style: TextStyle(
                                      fontSize: AppFonts.bodySmall,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _enabled,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() => _enabled = value);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '알람 시간',
                            style: TextStyle(
                              fontSize: AppFonts.bodyMedium,
                              fontWeight: AppFonts.medium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _enabled ? _selectTime : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: _enabled
                                    ? AppColors.background
                                    : Colors.grey.shade200,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    MaterialLocalizations.of(context)
                                        .formatTimeOfDay(_time),
                                    style: TextStyle(
                                      fontSize: AppFonts.bodyLarge,
                                      fontWeight: AppFonts.semiBold,
                                      color: _enabled
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: _enabled
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                '저장하기',
                                style: TextStyle(
                                  fontSize: AppFonts.bodyLarge,
                                  fontWeight: AppFonts.semiBold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
