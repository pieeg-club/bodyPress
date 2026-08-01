// ignore_for_file: directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_provider_config.dart';
import 'ai_config_service.dart';
import 'ai_service.dart';
import 'ambient_scan_service.dart';
import 'app_update_service.dart';
import 'background_capture_service.dart';
import 'ble_heart_rate_service.dart';
import 'ble_source_provider.dart';
import 'body_blog_service.dart';
import 'body_dialogue_service.dart';
import 'calendar_service.dart';
import 'capture_metadata_service.dart';
import 'capture_service.dart';
import 'context_window_service.dart';
import 'foreground_task_service.dart';
import 'gps_metrics_service.dart';
import 'health_service.dart';
import 'journal_ai_service.dart';
import 'local_db_service.dart';
import 'location_service.dart';
import 'notification_content_service.dart';
import 'notification_service.dart';
import 'nutrition_service.dart';
import 'permission_service.dart';
import 'sources/source_registry_init.dart';

export '../models/ai_provider_config.dart'
    show AiProviderConfig, AiProviderType;
// Re-export so callers only need to import this one file.
export 'ai_config_service.dart' show AiConfigNotifier, AiConfigService;

// ── Infrastructure ──────────────────────────────────────────────────────────

/// Single SQLite connection shared across the whole app.
///
/// Using [keepAlive] ensures the database is never closed while the app
/// lives inside a [ProviderScope], eliminating multiple-connection bugs.
final localDbServiceProvider = Provider<LocalDbService>((ref) {
  final service = LocalDbService();
  // No explicit dispose needed — sqflite manages the connection lifecycle.
  return service;
}, dependencies: []);

// ── AI configuration (depends on DB) ────────────────────────────────────────

/// Singleton service for reading/writing the AI config to SQLite.
final aiConfigServiceProvider = Provider<AiConfigService>((ref) {
  return AiConfigService(db: ref.read(localDbServiceProvider));
});

/// Reactive state of the active AI provider configuration.
///
/// Watch this from widgets to react to provider changes. The [aiServiceProvider]
/// watches this internally so all AI calls route through the selected provider.
final aiConfigProvider =
    StateNotifierProvider<AiConfigNotifier, AiProviderConfig>((ref) {
      final service = ref.read(aiConfigServiceProvider);
      return AiConfigNotifier(service);
    });

/// Global AI service provider.
///
/// Automatically rebuilds when the user changes the active AI provider
/// in the AI Settings screen (via [aiConfigProvider]).
final aiServiceProvider = Provider<AiService>((ref) {
  final config = ref.watch(aiConfigProvider);
  final service = AiService(config: config.isDefault ? null : config);
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Leaf services (no inter-service dependencies) ───────────────────────────

final healthServiceProvider = Provider<HealthService>((_) => HealthService());

/// Open Food Facts barcode lookup service.
final nutritionServiceProvider = Provider<NutritionService>((ref) {
  final svc = NutritionService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Singleton BLE Heart Rate service — keeps the Bluetooth connection alive
/// across rebuild cycles.  Disposed when the ProviderScope is torn down.
final bleHeartRateServiceProvider = Provider<BleHeartRateService>((ref) {
  final svc = BleHeartRateService();
  ref.onDispose(svc.dispose);
  return svc;
});

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

final calendarServiceProvider = Provider<CalendarService>(
  (_) => CalendarService(),
);

final ambientScanServiceProvider = Provider<AmbientScanService>(
  (_) => AmbientScanService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
);

/// Play Store in-app update checker.
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (_) => AppUpdateService(),
);

/// Central registry of all available BLE signal source providers.
///
/// Community sources register here at startup via [registerAllSources].
final bleSourceRegistryProvider = Provider<BleSourceRegistry>((ref) {
  final registry = BleSourceRegistry();
  registerAllSources(registry);
  return registry;
});

/// Reusable BLE connection management for any source provider.
final bleSourceServiceProvider = Provider<BleSourceService>((ref) {
  final svc = BleSourceService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Whether the EEG Lab is currently recording a live signal session.
/// Toggled by the live signal screen; watched by the Lab home status dot.
final isRecordingSignalProvider = StateProvider<bool>((_) => false);

/// [NotificationService] ships its own internal singleton; the provider just
/// surfaces it so it can be injected / overridden in tests.
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

/// Generates data-driven notification content from real captures & blog data.
final notificationContentServiceProvider = Provider<NotificationContentService>(
  (ref) {
    return NotificationContentService(db: ref.read(localDbServiceProvider));
  },
);

final gpsMetricsServiceProvider = Provider<GpsMetricsService>((ref) {
  final service = GpsMetricsService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Composite services ──────────────────────────────────────────────────────

final journalAiServiceProvider = Provider<JournalAiService>((ref) {
  return JournalAiService(ai: ref.read(aiServiceProvider));
});

final contextWindowServiceProvider = Provider<ContextWindowService>((ref) {
  return ContextWindowService(db: ref.read(localDbServiceProvider));
});

final captureServiceProvider = Provider<CaptureService>((ref) {
  return CaptureService(
    healthService: ref.read(healthServiceProvider),
    ambientService: ref.read(ambientScanServiceProvider),
    locationService: ref.read(locationServiceProvider),
    calendarService: ref.read(calendarServiceProvider),
    dbService: ref.read(localDbServiceProvider),
    metadataService: ref.read(captureMetadataServiceProvider),
  );
});

final captureMetadataServiceProvider = Provider<CaptureMetadataService>((ref) {
  return CaptureMetadataService(
    ai: ref.read(aiServiceProvider),
    db: ref.read(localDbServiceProvider),
  );
});

final backgroundCaptureServiceProvider = Provider<BackgroundCaptureService>((
  ref,
) {
  return BackgroundCaptureService(dbService: ref.read(localDbServiceProvider));
});

/// Persistent foreground service that keeps the app alive and visible.
final foregroundTaskServiceProvider = Provider<ForegroundTaskService>((ref) {
  return ForegroundTaskService(dbService: ref.read(localDbServiceProvider));
});

final bodyBlogServiceProvider = Provider<BodyBlogService>((ref) {
  return BodyBlogService(
    health: ref.read(healthServiceProvider),
    location: ref.read(locationServiceProvider),
    calendar: ref.read(calendarServiceProvider),
    ambient: ref.read(ambientScanServiceProvider),
    db: ref.read(localDbServiceProvider),
    ai: ref.read(journalAiServiceProvider),
  );
});

/// Conversational body-dialogue service.  Widgets can grab this via
/// `ref.read(bodyDialogueServiceProvider)` to start a chat session.
final bodyDialogueServiceProvider = Provider<BodyDialogueService>((ref) {
  return BodyDialogueService(ai: ref.read(aiServiceProvider));
});

// ── Health permission reactive status ───────────────────────────────────────

/// A [FutureProvider] that resolves to whether health permissions are granted.
/// Invalidate this provider after a permission change to force a refresh:
///   ref.invalidate(healthPermissionStatusProvider);
final healthPermissionStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(healthServiceProvider).hasPermissionsProbe();
});

/// A [FutureProvider] that resolves to whether the health platform is available
/// on this device (HealthKit on iOS, Health Connect installed on Android).
final healthAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(healthServiceProvider).isHealthAvailable();
});
