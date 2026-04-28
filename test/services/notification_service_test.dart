import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  test(
    'nextDailyOccurrence keeps the reminder on the same day when still ahead',
    () {
      final service = NotificationService(
        adapter: FakeNotificationPluginAdapter(),
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
        nowProvider: () => tz.TZDateTime(tz.local, 2026, 4, 23, 9, 30),
      );

      final nextOccurrence = service.nextDailyOccurrence(18, 0);

      expect(nextOccurrence, tz.TZDateTime(tz.local, 2026, 4, 23, 18, 0));
    },
  );

  test(
    'nextDailyOccurrence rolls to the next day when the time already passed',
    () {
      final service = NotificationService(
        adapter: FakeNotificationPluginAdapter(),
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
        nowProvider: () => tz.TZDateTime(tz.local, 2026, 4, 23, 21, 15),
      );

      final nextOccurrence = service.nextDailyOccurrence(18, 0);

      expect(nextOccurrence, tz.TZDateTime(tz.local, 2026, 4, 24, 18, 0));
    },
  );

  test(
    'scheduleDailyReminder uses defaults and schedules when permission is granted',
    () async {
      final adapter = FakeNotificationPluginAdapter()
        ..androidPermissionGranted = true;
      final service = NotificationService(
        adapter: adapter,
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
        nowProvider: () => tz.TZDateTime(tz.local, 2026, 4, 23, 9, 0),
      );

      final scheduled = await service.scheduleDailyReminder(
        title: '',
        body: '',
        hour: 18,
        minute: 45,
      );

      expect(scheduled, isTrue);
      expect(adapter.initializeCallCount, 1);
      expect(adapter.cancelledIds, [0]);
      expect(adapter.lastScheduleRequest, isNotNull);
      expect(adapter.lastScheduleRequest!.id, 0);
      expect(adapter.lastScheduleRequest!.title, 'Test your Peakflow');
      expect(
        adapter.lastScheduleRequest!.body,
        'Take your peakflow record now!',
      );
      expect(
        adapter.lastScheduleRequest!.scheduledDate,
        tz.TZDateTime(tz.local, 2026, 4, 23, 18, 45),
      );
      expect(
        adapter.lastScheduleRequest!.androidScheduleMode,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
      expect(
        adapter.lastScheduleRequest!.matchDateTimeComponents,
        DateTimeComponents.time,
      );
    },
  );

  test(
    'scheduleDailyReminder stops before scheduling when permission is denied',
    () async {
      final adapter = FakeNotificationPluginAdapter()
        ..androidPermissionGranted = false;
      final service = NotificationService(
        adapter: adapter,
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
      );

      final scheduled = await service.scheduleDailyReminder(
        title: 'Reminder',
        body: 'Body',
        hour: 8,
        minute: 0,
      );

      expect(scheduled, isFalse);
      expect(adapter.lastScheduleRequest, isNull);
      expect(adapter.cancelledIds, isEmpty);
    },
  );

  test(
    'android null permission result is treated as granted for older versions',
    () async {
      final adapter = FakeNotificationPluginAdapter();
      final service = NotificationService(
        adapter: adapter,
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
        nowProvider: () => tz.TZDateTime(tz.local, 2026, 4, 23, 9, 0),
      );

      final scheduled = await service.scheduleDailyReminder(
        title: 'Reminder',
        body: 'Body',
        hour: 10,
        minute: 30,
      );

      expect(scheduled, isTrue);
      expect(adapter.lastScheduleRequest, isNotNull);
    },
  );

  test(
    'hasScheduledReminder requires allowed notifications and a matching pending id',
    () async {
      final adapter = FakeNotificationPluginAdapter()
        ..androidNotificationsEnabled = true
        ..pendingRequests = const [
          PendingNotificationRequest(3, 'Other', 'Body', null),
          PendingNotificationRequest(0, 'Peak Flow', 'Daily', null),
        ];
      final service = NotificationService(
        adapter: adapter,
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
      );

      final hasReminder = await service.hasScheduledReminder();

      expect(hasReminder, isTrue);
    },
  );

  test(
    'hasScheduledReminder returns false when notifications are disabled',
    () async {
      final adapter = FakeNotificationPluginAdapter()
        ..androidNotificationsEnabled = false
        ..pendingRequests = const [
          PendingNotificationRequest(0, 'Peak Flow', 'Daily', null),
        ];
      final service = NotificationService(
        adapter: adapter,
        platform: NotificationPlatform.android,
        configureLocalTimeZone: () async {},
      );

      final hasReminder = await service.hasScheduledReminder();

      expect(hasReminder, isFalse);
    },
  );
}

class FakeNotificationPluginAdapter implements NotificationPluginAdapter {
  int initializeCallCount = 0;
  bool? androidPermissionGranted;
  bool? androidNotificationsEnabled;
  bool? iosPermissionGranted;
  bool? macOsPermissionGranted;
  NotificationsEnabledOptions? iosPermissions;
  NotificationsEnabledOptions? macOsPermissions;
  List<PendingNotificationRequest> pendingRequests = const [];
  final List<int> cancelledIds = <int>[];
  FakeScheduleRequest? lastScheduleRequest;

  @override
  Future<void> initialize(InitializationSettings settings) async {
    initializeCallCount += 1;
  }

  @override
  Future<bool?> requestAndroidNotificationsPermission() async {
    return androidPermissionGranted;
  }

  @override
  Future<bool?> areAndroidNotificationsEnabled() async {
    return androidNotificationsEnabled;
  }

  @override
  Future<bool?> requestIosPermissions() async {
    return iosPermissionGranted;
  }

  @override
  Future<bool?> requestMacOsPermissions() async {
    return macOsPermissionGranted;
  }

  @override
  Future<NotificationsEnabledOptions?> checkIosPermissions() async {
    return iosPermissions;
  }

  @override
  Future<NotificationsEnabledOptions?> checkMacOsPermissions() async {
    return macOsPermissions;
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pendingRequests;
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
  }) async {
    lastScheduleRequest = FakeScheduleRequest(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: matchDateTimeComponents,
      notificationDetails: notificationDetails,
    );
  }
}

class FakeScheduleRequest {
  const FakeScheduleRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.androidScheduleMode,
    required this.matchDateTimeComponents,
    required this.notificationDetails,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final AndroidScheduleMode androidScheduleMode;
  final DateTimeComponents? matchDateTimeComponents;
  final NotificationDetails notificationDetails;
}
