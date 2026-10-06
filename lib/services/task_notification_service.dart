import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TaskNotificationService {
  TaskNotificationService._();

  static final TaskNotificationService instance = TaskNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _ongoingChannelId = 'task_deadline_ongoing';
  static const String _expiredChannelId = 'task_deadline_expired';
  static const int _flagOngoingEvent = 0x00000002;
  static const int _flagNoClear = 0x00000020;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(initializationSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _ongoingChannelId,
        'Task reminders',
        description: 'Persistent reminders for upcoming task deadlines',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _expiredChannelId,
        'Expired task reminders',
        description: 'Dismissible reminders for tasks that reached deadline',
        importance: Importance.high,
      ),
    );

    _isInitialized = true;
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    await initialize();

    final now = DateTime.now();

    if (deadline.isAfter(now)) {
      await _showOngoingTaskNotification(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
      );
      await _scheduleExpiredTaskNotification(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
      );
    } else {
      await _showExpiredTaskNotification(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
      );
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await initialize();
    await _notifications.cancel(taskId);
  }

  Future<void> _showOngoingTaskNotification({
    required int taskId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    final deadlineText = _formatDeadline(deadline);
    final details = AndroidNotificationDetails(
      _ongoingChannelId,
      'Task reminders',
      channelDescription: 'Persistent reminders for upcoming task deadlines',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      when: deadline.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      additionalFlags: Int32List.fromList([
        _flagOngoingEvent,
        _flagNoClear,
      ]),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '$description\nDeadline: $deadlineText',
        contentTitle: title,
        summaryText: deadlineText,
      ),
    );

    await _notifications.show(
      taskId,
      title,
      'Deadline: $deadlineText',
      NotificationDetails(android: details),
      payload: taskId.toString(),
    );
  }

  Future<void> _scheduleExpiredTaskNotification({
    required int taskId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    final scheduledDate = tz.TZDateTime.from(deadline, tz.local);

    await _notifications.zonedSchedule(
      taskId,
      title,
      'Deadline reached: ${_formatDeadline(deadline)}',
      scheduledDate,
      NotificationDetails(
        android: _expiredNotificationDetails(
          title: title,
          description: description,
          deadline: deadline,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: taskId.toString(),
    );
  }

  Future<void> _showExpiredTaskNotification({
    required int taskId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    await _notifications.show(
      taskId,
      title,
      'Deadline reached: ${_formatDeadline(deadline)}',
      NotificationDetails(
        android: _expiredNotificationDetails(
          title: title,
          description: description,
          deadline: deadline,
        ),
      ),
      payload: taskId.toString(),
    );
  }

  AndroidNotificationDetails _expiredNotificationDetails({
    required String title,
    required String description,
    required DateTime deadline,
  }) {
    final deadlineText = _formatDeadline(deadline);

    return AndroidNotificationDetails(
      _expiredChannelId,
      'Expired task reminders',
      channelDescription:
          'Dismissible reminders for tasks that reached deadline',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '$description\nDeadline: $deadlineText',
        contentTitle: title,
        summaryText: 'Deadline reached',
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final hour = deadline.hour.toString().padLeft(2, '0');
    final minute = deadline.minute.toString().padLeft(2, '0');

    return '${deadline.day}/${deadline.month}/${deadline.year} $hour:$minute';
  }
}
