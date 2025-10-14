import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _dailyChannel = const AndroidNotificationChannel(
    'daily_progress_channel',
    'Daily Baby Progress Reminders',
    description: 'Daily motivation to log your baby\'s milestones and wins.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initializationSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_dailyChannel);

    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    required String preference,
    String? babyName,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    await cancelDailyReminder();

    final time = _mapPreferenceToTime(preference);
    final message = _selectMessage(babyName: babyName);
    final scheduledDate = _nextInstanceOfTime(time);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannel.id,
        _dailyChannel.name,
        channelDescription: _dailyChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const DefaultStyleInformation(true, true),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      message.title,
      message.body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);
  }

  TimeOfDay _mapPreferenceToTime(String preference) {
    switch (preference) {
      case 'midday':
        return const TimeOfDay(hour: 13, minute: 0);
      case 'evening':
        return const TimeOfDay(hour: 19, minute: 30);
      case 'morning':
      default:
        return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  _NotificationMessage _selectMessage({String? babyName}) {
    final friendlyName = babyName != null && babyName.trim().isNotEmpty
        ? babyName.trim()
        : 'your little one';

    final messages = <_NotificationMessage>[
      _NotificationMessage(
        'Celebrate today\'s wins',
        'Take 2 minutes to log $friendlyName\'s progress—every check-in keeps momentum strong.',
      ),
      _NotificationMessage(
        'Daily progress boost',
        'Capture a quick update for $friendlyName and unlock smarter activity ideas tomorrow.',
      ),
      _NotificationMessage(
        'Your habit is paying off',
        'Share one milestone moment for $friendlyName tonight—future you will be grateful.',
      ),
      _NotificationMessage(
        'Critical window reminder',
        'Consistency compounds. Record $friendlyName\'s development now while the window is wide open.',
      ),
    ];

    final index = DateTime.now().weekday % messages.length;
    return messages[index];
  }
}

class _NotificationMessage {
  const _NotificationMessage(this.title, this.body);

  final String title;
  final String body;
}
