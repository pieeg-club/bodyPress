import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'local_db_service.dart';
import 'notification_service.dart';

/// Manages the persistent foreground service that keeps BodyPress alive
/// and visible in the Android notification shade.
///
/// This solves two critical problems:
/// 1. **Reliable background execution** — Android cannot kill a foreground
///    service the way it kills plain background WorkManager tasks.
/// 2. **Persistent taskbar presence** — the user always sees BodyPress in
///    their notification shade, keeping them "connected to their body".
class ForegroundTaskService {
  ForegroundTaskService({LocalDbService? dbService})
    : _dbService = dbService ?? LocalDbService();

  final LocalDbService _dbService;

  /// Initialise the foreground task plugin.
  ///
  /// Must be called once from `main()` after `WidgetsFlutterBinding`.
  void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: NotificationService.persistentChannelId,
        channelName: 'Body Monitoring',
        channelDescription: 'Keeps BodyPress connected to your body',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
        showBadge: false,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15 * 60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start the persistent foreground service.
  ///
  /// Shows a non-dismissible notification in the notification shade.
  /// The service survives app restarts, reboots, and battery optimization.
  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('[ForegroundTaskService] Already running — updating.');
      await _updateNotificationText();
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '🫀 BodyPress',
      notificationText: 'Connected to your body',
      callback: _foregroundTaskCallback,
    );

    debugPrint('[ForegroundTaskService] Foreground service started.');
  }

  /// Stop the foreground service (e.g. if the user disables it).
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('[ForegroundTaskService] Foreground service stopped.');
    }
  }

  /// Whether the foreground service is currently running.
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  /// Update the persistent notification text with latest data.
  Future<void> _updateNotificationText() async {
    try {
      final text = await _buildStatusText();
      await FlutterForegroundTask.updateService(
        notificationTitle: '🫀 BodyPress',
        notificationText: text,
      );
    } catch (e) {
      debugPrint('[ForegroundTask] Update notification error: $e');
    }
  }

  /// Build a status string from the latest capture data.
  Future<String> _buildStatusText() async {
    try {
      final lastCapture = await _dbService.getSetting(
        'last_background_capture',
      );
      final successes = await _dbService.getSetting('bg_capture_success_count');

      final parts = <String>['Connected to your body'];

      if (lastCapture != null && lastCapture.isNotEmpty) {
        final dt = DateTime.tryParse(lastCapture);
        if (dt != null) {
          final ago = DateTime.now().difference(dt);
          if (ago.inMinutes < 60) {
            parts[0] = 'Last check-in ${ago.inMinutes}m ago';
          } else if (ago.inHours < 24) {
            parts[0] = 'Last check-in ${ago.inHours}h ago';
          }
        }
      }

      if (successes != null) {
        final count = int.tryParse(successes) ?? 0;
        if (count > 0) {
          parts.add('$count captures today');
        }
      }

      return parts.join(' · ');
    } catch (_) {
      return 'Connected to your body';
    }
  }
}

// ── Foreground task callback & handler ─────────────────────────────────────

/// Top-level callback invoked by the foreground service.
///
/// Must be a **top-level** function (not a closure or instance method).
@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_BodyPressTaskHandler());
}

/// Handles periodic events from the foreground service.
///
/// Runs in the same isolate as the main app (unlike WorkManager).
/// Updates the persistent notification with fresh status info.
class _BodyPressTaskHandler extends TaskHandler {
  LocalDbService? _db;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTask] Started at $timestamp (starter: $starter)');
    _db = LocalDbService();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_updateNotification());
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundTask] Destroyed at $timestamp');
    _db = null;
  }

  Future<void> _updateNotification() async {
    try {
      final db = _db ?? LocalDbService();
      final lastCapture = await db.getSetting('last_background_capture');

      String text = 'Monitoring your body';

      if (lastCapture != null && lastCapture.isNotEmpty) {
        final dt = DateTime.tryParse(lastCapture);
        if (dt != null) {
          final ago = DateTime.now().difference(dt);
          if (ago.inMinutes < 2) {
            text = 'Just checked in · Monitoring active';
          } else if (ago.inMinutes < 60) {
            text = 'Last check-in ${ago.inMinutes}m ago · Monitoring active';
          } else if (ago.inHours < 24) {
            text = 'Last check-in ${ago.inHours}h ago · Monitoring active';
          }
        }
      }

      await FlutterForegroundTask.updateService(
        notificationTitle: '🫀 BodyPress',
        notificationText: text,
      );
    } catch (e) {
      debugPrint('[ForegroundTask] Notification update error: $e');
    }
  }
}
