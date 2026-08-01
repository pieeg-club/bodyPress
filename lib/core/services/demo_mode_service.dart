import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_source_provider.dart';
import 'local_db_service.dart';
import 'service_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Demo Mode Service — hardware simulation toggle for the EEG Lab.
//
// When enabled, the BLE signal source emits synthetic multi-channel data
// through its normal stream so the entire Lab pipeline (live signal screen,
// recording, replay) works identically to real hardware — no board required.
//
// Isolated to the signal source only; it does not touch any other subsystem.
// Toggle from any screen via `ref.read(demoModeProvider.notifier).toggle()`.
// ─────────────────────────────────────────────────────────────────────────────

/// Persisted key in the settings table.
const _kDemoModeKey = 'eeg_demo_mode';

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier({
    required LocalDbService db,
    required BleSourceService bleSource,
  })  : _db = db,
        _bleSource = bleSource,
        super(false) {
    _loadPersisted();
  }

  final LocalDbService _db;
  final BleSourceService _bleSource;

  Future<void> _loadPersisted() async {
    final raw = await _db.getSetting(_kDemoModeKey);
    state = raw == 'true';
  }

  /// Toggle demo mode on/off.
  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _db.setSetting(_kDemoModeKey, next.toString());
    if (next) {
      _startServices();
    } else {
      _stopServices();
    }
  }

  /// Enable demo mode programmatically.
  Future<void> enable() async {
    if (state) return;
    state = true;
    await _db.setSetting(_kDemoModeKey, 'true');
    _startServices();
  }

  /// Disable demo mode programmatically (e.g. when real hardware pairs).
  Future<void> disable() async {
    if (!state) return;
    state = false;
    await _db.setSetting(_kDemoModeKey, 'false');
    _stopServices();
  }

  void _startServices() {
    if (!_bleSource.isStreaming) {
      _bleSource.startDemo();
      debugPrint('[DemoMode] EEG synthetic stream started');
    }
  }

  void _stopServices() {
    if (_bleSource.isDemoMode) {
      _bleSource.stopDemo();
      debugPrint('[DemoMode] EEG synthetic stream stopped');
    }
  }
}

/// Global reactive demo-mode state. `true` when demo mode is active.
final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  return DemoModeNotifier(
    db: ref.read(localDbServiceProvider),
    bleSource: ref.read(bleSourceServiceProvider),
  );
});
