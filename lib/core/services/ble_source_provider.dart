import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core signal models — generic multi-channel data shared by all sources.
// ─────────────────────────────────────────────────────────────────────────────

/// A single timestamped multi-channel sample from any signal source.
class SignalSample {
  final DateTime time;

  /// One value per channel (µV, mV, BPM — whatever the source unit is).
  final List<double> channels;

  const SignalSample({required this.time, required this.channels});

  Map<String, dynamic> toJson() => {
    't': time.microsecondsSinceEpoch,
    'ch': channels,
  };

  factory SignalSample.fromJson(Map<String, dynamic> j) => SignalSample(
    time: DateTime.fromMicrosecondsSinceEpoch(j['t'] as int),
    channels: (j['ch'] as List).map((e) => (e as num).toDouble()).toList(),
  );
}

/// Metadata describing a signal source's channel layout.
class ChannelDescriptor {
  final String label; // e.g. "Ch 1", "Fp1", "O2"
  final String unit; // e.g. "µV", "mV", "BPM"
  final double? defaultScale; // suggested ±range for autoscale

  const ChannelDescriptor({
    required this.label,
    this.unit = 'µV',
    this.defaultScale,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'unit': unit,
    'default_scale': defaultScale,
  };

  factory ChannelDescriptor.fromJson(Map<String, dynamic> j) =>
      ChannelDescriptor(
        label: j['label'] as String,
        unit: (j['unit'] as String?) ?? 'µV',
        defaultScale: (j['default_scale'] as num?)?.toDouble(),
      );
}

/// A recorded session of multi-channel signal data (persisted with captures).
class SignalSession {
  /// Which source type produced this session (matches [BleSourceProvider.id]).
  final String sourceId;

  /// Human-readable source name (e.g. "ADS1299 8-Ch EEG").
  final String sourceName;

  /// BLE device name that provided the data.
  final String? deviceName;

  /// Channel layout descriptors.
  final List<ChannelDescriptor> channels;

  /// All recorded samples (may be decimated for storage).
  final List<SignalSample> samples;

  /// Sample rate in Hz (nominal).
  final double sampleRateHz;

  const SignalSession({
    required this.sourceId,
    required this.sourceName,
    this.deviceName,
    required this.channels,
    required this.samples,
    this.sampleRateHz = 250,
  });

  Duration get duration => samples.length < 2
      ? Duration.zero
      : samples.last.time.difference(samples.first.time);

  int get channelCount => channels.length;

  String encode() => jsonEncode({
    'source_id': sourceId,
    'source_name': sourceName,
    'device': deviceName,
    'channels': channels.map((c) => c.toJson()).toList(),
    'sample_rate_hz': sampleRateHz,
    'samples': samples.map((s) => s.toJson()).toList(),
  });

  static SignalSession? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SignalSession(
        sourceId: m['source_id'] as String,
        sourceName: m['source_name'] as String,
        deviceName: m['device'] as String?,
        channels: (m['channels'] as List)
            .map((e) => ChannelDescriptor.fromJson(e as Map<String, dynamic>))
            .toList(),
        sampleRateHz: (m['sample_rate_hz'] as num?)?.toDouble() ?? 250,
        samples: (m['samples'] as List)
            .map((e) => SignalSample.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      debugPrint('[SignalSession] decode error: $e');
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract BLE source provider — the interface every community source
// must implement to plug into BodyPress.
// ─────────────────────────────────────────────────────────────────────────────

/// Connection lifecycle for any BLE source.
enum BleSourceState { idle, scanning, connecting, streaming, error }

/// A discovered BLE device matching a specific source provider.
class BleSourceDevice {
  final ScanResult scanResult;
  final String sourceId;

  String get name => scanResult.device.platformName.isNotEmpty
      ? scanResult.device.platformName
      : 'Device (${scanResult.device.remoteId.str.substring(0, 8)})';

  int get rssi => scanResult.rssi;
  BluetoothDevice get device => scanResult.device;

  const BleSourceDevice({required this.scanResult, required this.sourceId});
}

/// Abstract interface for a BLE signal source.
///
/// Community contributors implement this to add support for new hardware.
/// Each provider:
/// 1. Declares which BLE service/characteristic UUIDs it needs
/// 2. Knows how to parse raw BLE notification bytes into channel voltages
/// 3. Describes its channel layout (count, labels, units, default scale)
///
/// Example: see `Ads1299Source` for a complete implementation.
abstract class BleSourceProvider {
  // ── Identity ────────────────────────────────────────────────────────

  /// Unique machine identifier, e.g. 'ads1299', 'polar_h10', 'muse_s'.
  String get id;

  /// Human-readable display name, e.g. "ADS1299 8-Ch EEG".
  String get displayName;

  /// Short description shown in the source browser.
  String get description;

  /// Icon name (Material icon) for the source tile.
  IconData get icon;

  /// Expected BLE advertised device name(s) for auto-discovery.
  /// Empty list means "match any device that exposes [serviceUuid]".
  List<String> get advertisedNames;

  // ── BLE identifiers ────────────────────────────────────────────────

  /// Primary GATT service UUID to scan for / discover.
  String get serviceUuid;

  /// The notification characteristic UUID that delivers signal data.
  String get notifyCharacteristicUuid;

  // ── Channel layout ─────────────────────────────────────────────────

  /// Describes each channel this source provides.
  List<ChannelDescriptor> get channelDescriptors;

  int get channelCount => channelDescriptors.length;

  /// Nominal sample rate in Hz.
  double get sampleRateHz;

  // ── Data parsing ───────────────────────────────────────────────────

  /// Parse a raw BLE notification [data] into one or more [SignalSample]s.
  ///
  /// A single notification may carry multiple batched samples (e.g. 120 bytes
  /// = 5 × 24-byte samples for ADS1299). Return an empty list if the data is
  /// malformed or too short.
  /// Each returned sample should have exactly [channelCount] values.
  List<SignalSample> parseNotification(List<int> data);

  // ── Lifecycle (optional overrides) ─────────────────────────────────

  /// Called after GATT service discovery, before subscribing to the
  /// notify characteristic. Override if the device needs a startup
  /// command / configuration write.
  Future<void> onConnected(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {}

  /// Called when disconnecting. Override for cleanup commands.
  Future<void> onDisconnecting(BluetoothDevice device) async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Source registry — singleton that holds all registered source providers.
// ─────────────────────────────────────────────────────────────────────────────

/// Central registry of available BLE signal source providers.
///
/// Sources register themselves at app startup. The registry provides:
/// - A list of all available sources for the source browser UI
/// - Lookup by id for routing / session decoding
/// - A unified scan & connect flow that delegates to the right provider
class BleSourceRegistry {
  final Map<String, BleSourceProvider> _providers = {};

  /// All registered providers.
  List<BleSourceProvider> get providers => _providers.values.toList();

  /// Register a new source provider. Idempotent (re-registering same id
  /// replaces the previous provider).
  void register(BleSourceProvider provider) {
    _providers[provider.id] = provider;
    debugPrint(
      '[BleSourceRegistry] Registered: ${provider.id} '
      '(${provider.displayName})',
    );
  }

  /// Look up a provider by its id.
  BleSourceProvider? getById(String id) => _providers[id];

  /// Whether any providers are registered.
  bool get isEmpty => _providers.isEmpty;
  int get count => _providers.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic BLE source service — handles scan/connect/stream for any provider.
// ─────────────────────────────────────────────────────────────────────────────

/// A reusable BLE connection manager that works with any [BleSourceProvider].
///
/// Unlike [BleHeartRateService] which is hardcoded for HR Profile, this class
/// accepts a provider at connect-time and delegates parsing to it.
class BleSourceService {
  BluetoothDevice? _connectedDevice;
  BleSourceProvider? _activeProvider;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // Demo mode — synthetic signal generation at the service level.
  Timer? _demoTimer;
  int _demoTick = 0;
  bool _isDemoMode = false;

  final _devicesController =
      StreamController<List<BleSourceDevice>>.broadcast();
  final _signalController = StreamController<SignalSample>.broadcast();
  final _stateController = StreamController<BleSourceState>.broadcast();

  BleSourceState _state = BleSourceState.idle;

  /// Emits discovered devices matching the scanned provider.
  Stream<List<BleSourceDevice>> get devicesStream => _devicesController.stream;

  /// Emits live [SignalSample] values from the connected device.
  Stream<SignalSample> get signalStream => _signalController.stream;

  /// Emits [BleSourceState] whenever the lifecycle changes.
  Stream<BleSourceState> get stateStream => _stateController.stream;

  BleSourceState get state => _state;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BleSourceProvider? get activeProvider => _activeProvider;
  bool get isStreaming => _state == BleSourceState.streaming;
  bool get isDemoMode => _isDemoMode;

  void _setState(BleSourceState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  // ── Scanning ──────────────────────────────────────────────────────────

  /// Scan for devices matching [provider]'s service UUID.
  Future<void> startScan(
    BleSourceProvider provider, {
    int timeoutSeconds = 12,
  }) async {
    if (_state == BleSourceState.streaming) return;
    _activeProvider = provider;
    _setState(BleSourceState.scanning);

    final found = <String, BleSourceDevice>{};

    // Many boards (e.g. IronBCI / EAREEG / PiEEG_XR) advertise only their
    // name and do NOT include the GATT service UUID in the advertisement
    // packet. Filtering the scan by [withServices] would therefore hide them
    // entirely. Mirror the working Web Bluetooth transport: when the provider
    // declares advertised names, scan broadly and match by name; the service
    // UUID is only needed after connecting. Fall back to the service-UUID scan
    // filter only when no names are declared.
    final hasNames = provider.advertisedNames.isNotEmpty;

    try {
      await FlutterBluePlus.startScan(
        withServices: hasNames ? const [] : [Guid(provider.serviceUuid)],
        timeout: Duration(seconds: timeoutSeconds),
      );

      final scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          // Name filter when the provider specifies advertised names. Match
          // against both the GATT platform name and the advertised local name
          // (some firmware only exposes the name in the advertisement).
          if (hasNames) {
            final names = <String>[
              r.device.platformName,
              r.advertisementData.advName,
            ].where((n) => n.isNotEmpty).map((n) => n.toUpperCase()).toList();
            final matches = provider.advertisedNames.any(
              (n) => names.any((dn) => dn.contains(n.toUpperCase())),
            );
            if (!matches) continue;
          }
          found[r.device.remoteId.str] = BleSourceDevice(
            scanResult: r,
            sourceId: provider.id,
          );
        }
        if (!_devicesController.isClosed) {
          _devicesController.add(found.values.toList());
        }
      });

      await FlutterBluePlus.isScanning
          .where((s) => !s)
          .first
          .timeout(Duration(seconds: timeoutSeconds + 3));

      await scanSub.cancel();
    } catch (e) {
      debugPrint('[BleSource] Scan error: $e');
    } finally {
      if (_state == BleSourceState.scanning) {
        _setState(BleSourceState.idle);
      }
    }
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  // ── Connection ────────────────────────────────────────────────────────

  /// Connect to [device] using [provider] to parse incoming data.
  Future<void> connectAndStream(
    BluetoothDevice device,
    BleSourceProvider provider,
  ) async {
    _activeProvider = provider;
    _setState(BleSourceState.connecting);

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );
      _connectedDevice = device;

      _connectionSubscription = device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected) {
          _setState(BleSourceState.idle);
          _connectedDevice = null;
          _activeProvider = null;
        }
      });

      final services = await device.discoverServices();

      // Let the provider run any setup commands.
      await provider.onConnected(device, services);

      // Find the notification characteristic.
      BluetoothCharacteristic? notifyChar;
      for (final svc in services) {
        for (final ch in svc.characteristics) {
          if (ch.uuid.str128.toLowerCase() ==
              provider.notifyCharacteristicUuid.toLowerCase()) {
            notifyChar = ch;
            break;
          }
        }
        if (notifyChar != null) break;
      }

      if (notifyChar == null) {
        throw Exception(
          'Notify characteristic ${provider.notifyCharacteristicUuid} '
          'not found on ${device.platformName}',
        );
      }

      await notifyChar.setNotifyValue(true);
      _setState(BleSourceState.streaming);

      _notifySubscription = notifyChar.lastValueStream.listen((data) {
        if (data.isEmpty) return;
        final samples = provider.parseNotification(data);
        for (final sample in samples) {
          if (!_signalController.isClosed) {
            _signalController.add(sample);
          }
        }
      });
    } catch (e) {
      debugPrint('[BleSource] Connect error: $e');
      _setState(BleSourceState.error);
      rethrow;
    }
  }

  /// Disconnect and reset state.
  Future<void> disconnect() async {
    if (_isDemoMode) {
      stopDemo();
      return;
    }
    if (_activeProvider != null && _connectedDevice != null) {
      try {
        await _activeProvider!.onDisconnecting(_connectedDevice!);
      } catch (_) {}
    }
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _activeProvider = null;
    _setState(BleSourceState.idle);
  }

  // ── Demo mode ───────────────────────────────────────────────────────

  /// Start synthetic multi-channel signal generation at the service level.
  ///
  /// Emits realistic multi-frequency data on [signalStream] exactly like
  /// real hardware would, so all downstream consumers (live signal screen,
  /// Lab recording) receive the data transparently.
  void startDemo({int channelCount = 8, double sampleRateHz = 250}) {
    if (_isDemoMode) return;
    _isDemoMode = true;
    _demoTick = 0;
    final rng = math.Random();

    // ~60 Hz frame rate — fast enough for smooth visualisation.
    _demoTimer = Timer.periodic(Duration(milliseconds: (1000 / 60).round()), (
      _,
    ) {
      _demoTick++;
      final t = _demoTick / sampleRateHz;
      final channels = List<double>.generate(channelCount, (ch) {
        final base = 10.0 * math.sin(2 * math.pi * (3 + ch * 0.7) * t);
        final alpha =
            8.0 * math.sin(2 * math.pi * (10 + ch) * t) * (ch.isEven ? 1 : 0.6);
        final noise = (rng.nextDouble() - 0.5) * 4;
        return double.parse((base + alpha + noise).toStringAsFixed(2));
      });
      if (!_signalController.isClosed) {
        _signalController.add(
          SignalSample(time: DateTime.now(), channels: channels),
        );
      }
    });
    _setState(BleSourceState.streaming);
  }

  /// Stop synthetic signal generation.
  void stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _isDemoMode = false;
    _setState(BleSourceState.idle);
  }

  void dispose() {
    stopDemo();
    disconnect();
    _devicesController.close();
    _signalController.close();
    _stateController.close();
  }
}
