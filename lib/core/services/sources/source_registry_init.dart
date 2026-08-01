import '../ble_source_provider.dart';
import 'ads1299_source.dart';
import 'ironbci_source.dart';
import 'octopus16_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Source registry initialisation
//
// Every community source provider should be registered here.
// This file is the single entry point — just add a line for your source.
// ─────────────────────────────────────────────────────────────────────────────

/// Populates [registry] with all built-in and community source providers.
///
/// Called once at app startup from [service_providers.dart].
///
/// ### How to add a new source
/// 1. Create `lib/core/services/sources/my_source.dart`
///    implementing [BleSourceProvider].
/// 2. Import it here.
/// 3. Add `registry.register(MySource());` below.
void registerAllSources(BleSourceRegistry registry) {
  // ── Built-in sources ────────────────────────────────────────────────
  registry.register(Ads1299Source());
  registry.register(IronBciSource()); // IronBCI-8 (ADS1299)
  registry.register(IronBciSource(channels: 16)); // IronBCI-16 (dual ADS1299)
  registry.register(PiEegXrSource()); // PiEEG-XR 8-ch (EAREEG firmware)
  registry.register(PiEegXrSource(channels: 16)); // PiEEG-XR 16-ch
  registry.register(Octopus16Source()); // Octopus 16 (ESP32-C3 + ADS131M08)

  // ── Community sources ───────────────────────────────────────────────
  // registry.register(MuseSSource());
  // registry.register(OpenBciCytonSource());
  // registry.register(GanglionSource());
}
