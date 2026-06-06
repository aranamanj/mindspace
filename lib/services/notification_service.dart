import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const int moodNotificationId    = 1;
  static const int journalNotificationId = 2;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();
    _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  // ── Timezone detection ────────────────────────────────────────────────────

  void _configureLocalTimezone() {
    try {
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(name));
      return;
    } catch (_) {}

    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final etcName = offsetHours == 0
          ? 'UTC'
          : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
      tz.setLocalLocation(tz.getLocation(etcName));
      return;
    } catch (_) {}

    tz.setLocalLocation(tz.UTC);
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  Future<void> scheduleMoodReminder(TimeOfDay time) =>
      _scheduleDailyReminder(
        id: moodNotificationId,
        title: 'How are you feeling? 🌿',
        body: 'Take a moment to log your mood today.',
        channelId: 'mood_channel',
        channelName: 'Mood Reminders',
        time: time,
      );

  Future<void> scheduleJournalReminder(TimeOfDay time) =>
      _scheduleDailyReminder(
        id: journalNotificationId,
        title: 'Time to journal ✍️',
        body: 'Write down your thoughts for today.',
        channelId: 'journal_channel',
        channelName: 'Journal Reminders',
        time: time,
      );

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required TimeOfDay time,
  }) async {
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelMoodReminder()    => _plugin.cancel(moodNotificationId);
  Future<void> cancelJournalReminder() => _plugin.cancel(journalNotificationId);
  Future<void> cancelAll()             => _plugin.cancelAll();

  // ── Helper ────────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var dt = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
    return dt;
  }
}