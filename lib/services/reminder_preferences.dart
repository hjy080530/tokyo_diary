import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSetting {
  final bool enabled;
  final TimeOfDay time;
  final bool isDefault;

  const ReminderSetting({
    required this.enabled,
    required this.time,
    this.isDefault = false,
  });

  ReminderSetting copyWith({
    bool? enabled,
    TimeOfDay? time,
    bool? isDefault,
  }) {
    return ReminderSetting(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class ReminderPreferences {
  ReminderPreferences._();

  static final ReminderPreferences instance = ReminderPreferences._();

  static const TimeOfDay defaultTime = TimeOfDay(hour: 11, minute: 0);

  Future<ReminderSetting> load(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_key(personId, 'enabled'));
    final hour = prefs.getInt(_key(personId, 'hour'));
    final minute = prefs.getInt(_key(personId, 'minute'));

    if (enabled == null || hour == null || minute == null) {
      return const ReminderSetting(
        enabled: true,
        time: defaultTime,
        isDefault: true,
      );
    }

    return ReminderSetting(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> save(String personId, ReminderSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(personId, 'enabled'), setting.enabled);
    await prefs.setInt(_key(personId, 'hour'), setting.time.hour);
    await prefs.setInt(_key(personId, 'minute'), setting.time.minute);
  }

  Future<void> clear(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(personId, 'enabled'));
    await prefs.remove(_key(personId, 'hour'));
    await prefs.remove(_key(personId, 'minute'));
  }

  String _key(String id, String field) => 'reminder_${id}_$field';
}
