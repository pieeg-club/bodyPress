import 'package:flutter/material.dart';

import '../ble_source_provider.dart';

/// Octopus 16 (ESP32-C3 + dual ADS131M08) 16-channel EEG source provider.
///
/// Ported from the browser-native Web Bluetooth transport in
/// `PiEEG-server-cloud/cloud/src/lib/octopus16Ble.ts`, verified against the
/// pieeg-club/Octopus_16 ESP32 firmware.
///
/// ### Protocol
/// - BLE service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
/// - Notification characteristic: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
/// - Each notification: one 51-byte packet @ 250 Hz
///   - `[0]`      = `0xA0` start marker
///   - `[1]`      = sample counter (0..255, wraps)
///   - `[2..25]`  = ADC1 ch 0..7  (8 × 3 bytes, big-endian signed 24-bit)
///   - `[26..49]` = ADC2 ch 8..15 (8 × 3 bytes, big-endian signed 24-bit)
///   - `[50]`     = `0xC0` end marker
/// - Voltage formula: `µV = raw_signed × (1.2 / 4.0 / 8388607) × 1e6`
///   (1.2 V internal Vref, gain 4.0 from GAIN=0x2222, 2^23-1 full-scale)
class Octopus16Source extends BleSourceProvider {
  // ── Identity ────────────────────────────────────────────────────────

  @override
  String get id => 'octopus16';

  @override
  String get displayName => 'Octopus 16-Ch EEG';

  @override
  String get description =>
      'PiEEG Octopus 16 — ESP32-C3 + dual ADS131M08, 16 channels, '
      '24-bit, 250 SPS over BLE.';

  @override
  IconData get icon => Icons.hub;

  @override
  List<String> get advertisedNames => [
    'PiEEG',
    'bioron',
    'Octopos',
    'Octopus',
  ];

  // ── BLE identifiers ────────────────────────────────────────────────

  @override
  String get serviceUuid => '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  @override
  String get notifyCharacteristicUuid =>
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  // ── Channel layout ─────────────────────────────────────────────────

  @override
  List<ChannelDescriptor> get channelDescriptors => List.generate(
    _numChannels,
    (i) => ChannelDescriptor(
      label: 'Ch ${i + 1}',
      unit: 'µV',
      defaultScale: 100,
    ),
  );

  @override
  double get sampleRateHz => 250;

  // ── Data parsing ───────────────────────────────────────────────────

  static const int _numChannels = 16;

  /// (1.2 / 4.0 / 8388607) × 1e6 µV per LSB.
  static const double _uvScale = (1.2 / 4.0 / 8388607.0) * 1000000.0;

  /// 2^23 sign bit.
  static const int _signBit = 0x800000;

  /// 2^24 - 1 full-scale code.
  static const int _fullScale = 0xffffff;

  static const int _bytesPerChannel = 3;
  static const int _packetSize = 51;
  static const int _startMarker = 0xa0;
  static const int _endMarker = 0xc0;

  /// First channel byte within a packet (after start marker + counter).
  static const int _dataOffset = 2;

  @override
  List<SignalSample> parseNotification(List<int> data) {
    if (data.length < _packetSize) return const [];

    final now = DateTime.now();
    final periodMicros = 1000000 ~/ sampleRateHz.round();

    // Tolerate several concatenated packets; validate 0xA0/0xC0 framing so a
    // partial or misaligned notification is skipped rather than decoded as
    // garbage.
    final channelBatches = <List<double>>[];
    for (var base = 0; base + _packetSize <= data.length; base += _packetSize) {
      if (data[base] != _startMarker ||
          data[base + _packetSize - 1] != _endMarker) {
        break;
      }

      final channels = <double>[];
      for (var ch = 0; ch < _numChannels; ch++) {
        final p = base + _dataOffset + ch * _bytesPerChannel;
        int raw = (data[p] << 16) | (data[p + 1] << 8) | data[p + 2];
        if (raw >= _signBit) raw -= _fullScale + 1;
        final uv = raw * _uvScale;
        channels.add(double.parse(uv.toStringAsFixed(2)));
      }
      channelBatches.add(channels);
    }

    // Space timestamps evenly across the accepted batch based on sample rate.
    final count = channelBatches.length;
    return List.generate(
      count,
      (s) => SignalSample(
        time: now.subtract(Duration(microseconds: (count - 1 - s) * periodMicros)),
        channels: channelBatches[s],
      ),
    );
  }
}
