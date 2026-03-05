import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  static const String _dailyReminderId = 'daily_reminder_id';
  static const String _reminderEnabledKey = 'notifications.reminder_enabled';
  static const String _firstLaunchPromptShownKey =
      'notifications.first_launch_prompt_shown';

  static const int _notificationId = 1001;
  static const String _notificationChannelId = 'daily_reminder_channel';
  static const String _notificationChannelName = 'Daily reminders';
  static const String _notificationChannelDescription =
      'Daily reminder for TalkTogether';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = true;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);

      await _notifications.initialize(settings);
      _initialized = true;
    } on MissingPluginException {
      _supported = false;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      _supported = false;
    }
  }

  Future<bool> shouldAskForInitialPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLaunchPromptShownKey) ?? false);
  }

  Future<void> markInitialPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchPromptShownKey, true);
  }

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  Future<bool> enableDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_supported) return false;

    final permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) return false;

    await _notifications.zonedSchedule(
      _notificationId,
      title,
      body,
      _nextInstanceOfTime(hour: hour, minute: minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _dailyReminderId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, true);
    return true;
  }

  Future<void> disableDailyReminder() async {
    await init();
    if (_supported) {
      await _notifications.cancel(_notificationId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, false);
  }

  Future<bool> _requestPermissions() async {
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final ios =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    final macos =
        _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macosGranted = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final deniedOnAnyPlatform =
        (androidGranted == false) ||
        (iosGranted == false) ||
        (macosGranted == false);
    return !deniedOnAnyPlatform;
  }

  tz.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
