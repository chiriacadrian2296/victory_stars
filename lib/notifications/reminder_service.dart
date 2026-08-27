import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules (or cancels) the single daily "log a win" reminder notification.
/// One fixed notification id — there is only ever at most one reminder, so
/// re-scheduling simply overwrites it.
class ReminderService {
  ReminderService._(this._plugin);

  static const _notificationId = 1001;
  static bool _timezoneReady = false;

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<ReminderService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(settings: const InitializationSettings(android: androidSettings));

    if (!_timezoneReady) {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      _timezoneReady = true;
    }

    return ReminderService._(plugin);
  }

  /// Android 13+ requires runtime permission for notifications. Returns
  /// whether the reminder can actually be shown; other platforms in this
  /// app (none yet) default to true since no prompt is needed.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationId,
      scheduledDate: scheduled,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // Inexact scheduling avoids needing Android's separate "exact alarm"
      // permission flow — a reminder landing within a few minutes of the
      // chosen time is more than good enough for this use case.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() => _plugin.cancel(id: _notificationId);
}
