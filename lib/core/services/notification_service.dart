import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_content_service.dart';

/// Manages local notifications for BodyPress.
///
/// Two hardcoded daily pushes:
/// - **Morning** at 08:30 — start-of-day motivation.
/// - **Evening** at 20:00 — end-of-day reflection.
///
/// Plus a **Smart Insights** channel for data-driven notifications
/// triggered from background captures.
class NotificationService {
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Hardcoded schedule ──────────────────────────────────────────────────

  /// Morning push: 08:30
  static const morningHour = 8;
  static const morningMinute = 30;

  /// Evening push: 20:00
  static const eveningHour = 20;
  static const eveningMinute = 0;

  /// Monochrome notification small icon (white silhouette on transparent).
  /// Android tints this; a full-colour launcher icon would render as a white
  /// square, so a dedicated drawable is required.
  static const _androidIcon = '@drawable/ic_notification';

  // ── Channel IDs ─────────────────────────────────────────────────────────

  static const _dailyChannelId = 'bodypress_daily_reminder';
  static const _dailyChannelName = 'Daily Body Blog';
  static const _dailyChannelDescription =
      'A daily reminder to check your body blog';

  static const _smartChannelId = 'bodypress_smart_insights';
  static const _smartChannelName = 'Smart Body Insights';
  static const _smartChannelDescription =
      'Data-driven notifications with your real biometrics';

  static const persistentChannelId = 'bodypress_persistent';
  static const _persistentChannelName = 'Body Monitoring';
  static const _persistentChannelDescription =
      'Keeps BodyPress connected to your body in the background';

  static const _morningNotifId = 9001;
  static const _eveningNotifId = 9002;
  static const _smartNotifId = 9003;
  static const persistentNotifId = 9004;

  // ── Morning messages (08:30 — motivational, forward-looking) ────────────

  static const morningMessages = <({String title, String body})>[
    (
      title: '☀️ Good morning — your body has news',
      body:
          'Sleep score, recovery, overnight heart rate — it\'s all in your body blog →',
    ),
    (
      title: '🌅 Rise & read your body',
      body: 'Your body tracked your night. See what happened while you slept →',
    ),
    (
      title: '🧬 Your body wrote you an overnight report',
      body:
          'Sleep, heart rate, recovery — all there. Start your day informed →',
    ),
    (
      title: '⚡ How charged is your body battery?',
      body:
          'Sleep quality + overnight vitals = your energy forecast. Check it →',
    ),
    (
      title: '🫀 Your body has a morning briefing',
      body:
          'Heart, sleep, readiness — one tap to see how you\'re starting the day →',
    ),
    (
      title: '📖 New day, new body chapter',
      body:
          'Yesterday\'s story is written. Today\'s is just starting — check in →',
    ),
    (
      title: '🎯 Body check-in: start of day',
      body: 'Your body tracked everything overnight. See the summary →',
    ),
    (
      title: '🔬 Your morning body report is in',
      body: 'Real data from your real night. Open your body blog →',
    ),
    (
      title: '💡 Your body knows how you slept',
      body: 'And it has opinions. See the overnight data →',
    ),
    (
      title: '🌟 Morning insight from your body',
      body:
          'Sleep, recovery, resting heart rate — today\'s baseline is ready →',
    ),
    (
      title: '🏃 Ready for today?',
      body: 'Your body measured your readiness overnight. See how you scored →',
    ),
    (
      title: '🧘 A moment of body awareness',
      body: 'Before the day takes over — check how your body is doing →',
    ),
  ];

  // ── Evening messages (20:00 — reflective, summary-focused) ─────────────

  static const eveningMessages = <({String title, String body})>[
    (
      title: '🌙 Your body\'s daily wrap-up',
      body:
          'Steps, heart, movement, environment — today\'s full story is ready →',
    ),
    (
      title: '📊 End-of-day body report',
      body: 'Your body collected data all day. See the complete picture →',
    ),
    (
      title: '🔥 What did your body do today?',
      body:
          'Steps walked, calories burned, heart patterns — all compiled for you →',
    ),
    (
      title: '📝 Your body published today\'s post',
      body: 'A first-person account of your entire day. Written by your data →',
    ),
    (
      title: '🧠 Your body noticed things today',
      body: 'Patterns, anomalies, streaks — check what it observed →',
    ),
    (
      title: '💬 Your body left you a note',
      body: 'With real data. And real insights. Open it →',
    ),
    (
      title: '🫀 Pulse. Steps. Story.',
      body:
          'Your body turned today\'s numbers into narrative. Read the evening edition →',
    ),
    (
      title: '🪞 Day in review: the inside edition',
      body: 'Forget appearances — your body blog shows what really happened →',
    ),
    (
      title: '🌊 Today\'s body wave',
      body: 'Energy, recovery, movement — the full picture before you rest →',
    ),
    (
      title: '🎤 Your body has the mic tonight',
      body: 'Steps, rhythm, environment — all in today\'s evening narrative →',
    ),
    (
      title: '🚀 Your body has end-of-day news',
      body:
          'Not just numbers — a story. Steps, rest, stress. All real. All you →',
    ),
    (
      title: '🎯 One tap. Your whole day.',
      body:
          'Your body blog summarised everything. Don\'t miss tonight\'s edition →',
    ),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Initialise the notification plugin and create Android channels.
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialised) return;

    const androidInit = AndroidInitializationSettings(_androidIcon);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channels (no-op on iOS).
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyChannelId,
          _dailyChannelName,
          description: _dailyChannelDescription,
          importance: Importance.high,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _smartChannelId,
          _smartChannelName,
          description: _smartChannelDescription,
          importance: Importance.high,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          persistentChannelId,
          _persistentChannelName,
          description: _persistentChannelDescription,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
    }

    _initialised = true;
  }

  // ── Public helpers ────────────────────────────────────────────────────

  /// Request notification permission on Android 13+ / iOS.
  Future<bool> requestPermission() async {
    // Android 13+
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  // ── Daily reminder scheduling ─────────────────────────────────────────

  /// Schedule the two hardcoded daily pushes (morning 08:30 + evening 20:00).
  ///
  /// Replaces any previously scheduled reminders. Each picks a random
  /// message from the appropriate pool — re-scheduled on every app launch
  /// so the messages rotate.
  Future<void> scheduleDailyReminders() async {
    await _ensureInitialised();

    // Cancel any existing daily reminders first.
    await _plugin.cancel(_morningNotifId);
    await _plugin.cancel(_eveningNotifId);

    await _scheduleOne(
      id: _morningNotifId,
      hour: morningHour,
      minute: morningMinute,
      messages: morningMessages,
    );
    await _scheduleOne(
      id: _eveningNotifId,
      hour: eveningHour,
      minute: eveningMinute,
      messages: eveningMessages,
    );

    debugPrint(
      '[NotificationService] Scheduled morning ($morningHour:$morningMinute) '
      '+ evening ($eveningHour:$eveningMinute) reminders.',
    );
  }

  /// Cancel both daily reminders.
  Future<void> cancelDailyReminders() async {
    await _ensureInitialised();
    await _plugin.cancel(_morningNotifId);
    await _plugin.cancel(_eveningNotifId);
  }

  /// Legacy single-reminder cancel (for migration).
  Future<void> cancelDailyReminder() async {
    await _ensureInitialised();
    await _plugin.cancel(_morningNotifId);
  }

  Future<void> _scheduleOne({
    required int id,
    required int hour,
    required int minute,
    required List<({String title, String body})> messages,
  }) async {
    final msg = messages[Random().nextInt(messages.length)];

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Use exact alarms when the permission is granted; fall back to inexact
    // scheduling otherwise so that reminders are still registered even when
    // the user hasn't allowed exact alarms (Android 12+).
    final exactAllowed = await Permission.scheduleExactAlarm.status.then(
      (s) => s.isGranted,
    );
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint(
      '[NotificationService] Scheduling id=$id at $hour:$minute '
      '(mode: ${scheduleMode.name})',
    );

    await _plugin.zonedSchedule(
      id,
      msg.title,
      msg.body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: _androidIcon,
          styleInformation: BigTextStyleInformation(msg.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Smart data-driven notification ──────────────────────────────────────

  /// Show a data-driven notification with real biometric content.
  ///
  /// Called from the background capture executor (once per day) with a
  /// [NotifContent] produced by [NotificationContentService].
  Future<void> showSmartNotification(NotifContent content) async {
    await _ensureInitialised();

    await _plugin.show(
      _smartNotifId,
      content.title,
      content.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _smartChannelId,
          _smartChannelName,
          channelDescription: _smartChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: _androidIcon,
          styleInformation: BigTextStyleInformation(content.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a test daily notification immediately (for the debug panel).
  Future<void> showTestDailyReminder() async {
    await _ensureInitialised();

    final allMessages = [...morningMessages, ...eveningMessages];
    final msg = allMessages[Random().nextInt(allMessages.length)];

    await _plugin.show(
      _morningNotifId + 100, // unique test ID
      msg.title,
      msg.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: _androidIcon,
          styleInformation: BigTextStyleInformation(msg.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────

  Future<void> _ensureInitialised() async {
    if (!_initialised) await initialize();
  }
}
