import 'dart:io';

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
      await _configureTimezoneSafely();

      // Use launcher foreground drawable so we don't maintain a separate
      // notification icon asset file.
      const android = AndroidInitializationSettings('ic_launcher_foreground');
      const ios = DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _notifications.initialize(settings);
      await _createAndroidChannelIfNeeded();
      _initialized = true;
    } on MissingPluginException {
      _supported = false;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      _supported = false;
    }
  }

  Future<void> _configureTimezoneSafely() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      // Some Android devices can return timezone IDs not present
      // in timezone package database. Fallback to UTC to keep
      // notifications available instead of disabling the feature.
      debugPrint('Timezone fallback to UTC: $e');
      tz.setLocalLocation(tz.UTC);
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

    try {
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
            icon: 'ic_launcher_foreground',
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
    } catch (e) {
      debugPrint('Failed to enable daily reminder: $e');
      return false;
    }
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
    if (Platform.isAndroid) {
      final android =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final alreadyGranted = await android?.areNotificationsEnabled();
      if (alreadyGranted == true) return true;

      final androidGranted = await android?.requestNotificationsPermission();
      if (androidGranted == true) return true;
      if (androidGranted == null) {
        // On some devices/plugin paths this can be null, so we still verify
        // the effective system state before reporting success.
        final grantedAfterNull = await android?.areNotificationsEnabled();
        return grantedAfterNull == true;
      }
      // After request, read the current state again.
      final grantedAfterRequest = await android?.areNotificationsEnabled();
      return grantedAfterRequest == true;
    }

    final ios =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final macos =
        _notifications.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

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
        (iosGranted == false) || (macosGranted == false);
    return !deniedOnAnyPlatform;
  }

  Future<void> _createAndroidChannelIfNeeded() async {
    final android =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.defaultImportance,
    );
    await android.createNotificationChannel(channel);
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
