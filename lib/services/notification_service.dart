import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationPlatform { android, ios, macos, unsupported }

NotificationPlatform currentNotificationPlatform() {
  if (kIsWeb) {
    return NotificationPlatform.unsupported;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => NotificationPlatform.android,
    TargetPlatform.iOS => NotificationPlatform.ios,
    TargetPlatform.macOS => NotificationPlatform.macos,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => NotificationPlatform.unsupported,
  };
}

abstract class NotificationPluginAdapter {
  Future<void> initialize(InitializationSettings settings);

  Future<bool?> requestAndroidNotificationsPermission();

  Future<bool?> areAndroidNotificationsEnabled();

  Future<bool?> requestIosPermissions();

  Future<bool?> requestMacOsPermissions();

  Future<NotificationsEnabledOptions?> checkIosPermissions();

  Future<NotificationsEnabledOptions?> checkMacOsPermissions();

  Future<void> cancel(int id);

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required DateTimeComponents? matchDateTimeComponents,
  });
}

class FlutterLocalNotificationsAdapter implements NotificationPluginAdapter {
  FlutterLocalNotificationsAdapter([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize(InitializationSettings settings) async {
    await _plugin.initialize(settings);
  }

  @override
  Future<bool?> requestAndroidNotificationsPermission() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<bool?> areAndroidNotificationsEnabled() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  @override
  Future<bool?> requestIosPermissions() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<bool?> requestMacOsPermissions() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<NotificationsEnabledOptions?> checkIosPermissions() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
  }

  @override
  Future<NotificationsEnabledOptions?> checkMacOsPermissions() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required DateTimeComponents? matchDateTimeComponents,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}

Future<void> configureNotificationLocalTimeZone() async {
  tz.initializeTimeZones();
  final timeZone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZone.identifier));
}

class NotificationService {
  NotificationService({
    NotificationPluginAdapter? adapter,
    NotificationPlatform? platform,
    Future<void> Function()? configureLocalTimeZone,
    tz.TZDateTime Function()? nowProvider,
    this.notificationId = 0,
    this.defaultTitle = 'Test your Peakflow',
    this.defaultBody = 'Take your peakflow record now!',
  }) : _adapter = adapter ?? FlutterLocalNotificationsAdapter(),
       _platform = platform ?? currentNotificationPlatform(),
       _configureLocalTimeZone =
           configureLocalTimeZone ?? configureNotificationLocalTimeZone,
       _nowProvider = nowProvider ?? (() => tz.TZDateTime.now(tz.local));

  final NotificationPluginAdapter _adapter;
  final NotificationPlatform _platform;
  final Future<void> Function() _configureLocalTimeZone;
  final tz.TZDateTime Function() _nowProvider;
  final int notificationId;
  final String defaultTitle;
  final String defaultBody;

  bool _initialized = false;

  bool get supportsScheduledNotifications =>
      _platform == NotificationPlatform.android ||
      _platform == NotificationPlatform.ios ||
      _platform == NotificationPlatform.macos;

  Future<void> initialize() async {
    if (!supportsScheduledNotifications || _initialized) {
      return;
    }

    await _configureLocalTimeZone();
    await _adapter.initialize(_initializationSettings);
    _initialized = true;
  }

  tz.TZDateTime nextDailyOccurrence(int hour, int minute) {
    final now = _nowProvider();
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

  Future<bool> requestPermissions() async {
    await initialize();

    switch (_platform) {
      case NotificationPlatform.android:
        return await _adapter.requestAndroidNotificationsPermission() ?? true;
      case NotificationPlatform.ios:
        return await _adapter.requestIosPermissions() ?? false;
      case NotificationPlatform.macos:
        return await _adapter.requestMacOsPermissions() ?? false;
      case NotificationPlatform.unsupported:
        return false;
    }
  }

  Future<bool> areNotificationsAllowed() async {
    await initialize();

    switch (_platform) {
      case NotificationPlatform.android:
        return await _adapter.areAndroidNotificationsEnabled() ?? false;
      case NotificationPlatform.ios:
        return (await _adapter.checkIosPermissions())?.isEnabled ?? false;
      case NotificationPlatform.macos:
        return (await _adapter.checkMacOsPermissions())?.isEnabled ?? false;
      case NotificationPlatform.unsupported:
        return false;
    }
  }

  Future<bool> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!supportsScheduledNotifications) {
      return false;
    }

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return false;
    }

    await _adapter.cancel(notificationId);
    await _adapter.zonedSchedule(
      id: notificationId,
      title: title.isEmpty ? defaultTitle : title,
      body: body.isEmpty ? defaultBody : body,
      scheduledDate: nextDailyOccurrence(hour, minute),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    return true;
  }

  Future<bool> hasScheduledReminder() async {
    if (!supportsScheduledNotifications) {
      return false;
    }

    final notificationsAllowed = await areNotificationsAllowed();
    if (!notificationsAllowed) {
      return false;
    }

    final pendingRequests = await _adapter.pendingNotificationRequests();
    return pendingRequests.any((request) => request.id == notificationId);
  }

  Future<void> cancelReminder() async {
    if (!supportsScheduledNotifications) {
      return;
    }

    await initialize();
    await _adapter.cancel(notificationId);
  }

  InitializationSettings get _initializationSettings =>
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'peakflow_daily',
      'Peakflow daily reminder',
      channelDescription: 'Peakflow daily reminder to take record',
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );
}
