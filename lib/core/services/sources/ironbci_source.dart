import 'package:flutter/material.dart';

import '../ble_source_provider.dart';

/// IronBCI (ADS1299-based) EEG source provider.
///
/// Ported from the browser-native Web Bluetooth transport in
/// `PiEEG-server-cloud/cloud/src/lib/ironbciBle.ts`, verified against the
/// EAREEG / IronBCI STM32 firmware family.
///
/// Supports both variants of the same firmware:
///   - IronBCI-8  (1 × ADS1299): 24-byte samples, ch1..ch8.
///   - IronBCI-16 (2 × ADS1299): 48-byte samples, ch1..ch16.
/// Both share the same BLE service/characteristic and 24-bit conversion, so
/// only the channel count differs.
///
/// ### Protocol
/// - BLE service UUID: `0000fe40-cc7a-482a-984a-7f2ed5b3e58f`
/// - Notification characteristic: `0000fe42-8e22-4541-9d4c-21edae82ed19`
/// - Each notification: one or more batched `numChannels × 3`-byte samples
///   (big-endian, 24-bit two's complement)
/// - Voltage formula: `µV = 1_000_000 × 4.5 × (raw_signed / 16_777_215)`
class IronBciSource extends BleSourceProvider {
  /// Channel count: 8 (single ADS1299) or 16 (dual ADS1299).
  final int channels;

  IronBciSource({this.channels = 8})
    : assert(channels == 8 || channels == 16);

  // ── Identity ────────────────────────────────────────────────────────

  @override
  String get id => channels == 16 ? 'ironbci16' : 'ironbci';

  @override
  String get displayName => 'IronBCI $channels-Ch EEG';

  @override
  String get description =>
      'IronBCI ADS1299 EEG front-end — $channels channels, 24-bit, 250 SPS. '
      'Also covers PiEEG_XR retail units running the same EAREEG firmware.';

  @override
  IconData get icon => Icons.memory;

  @override
  List<String> get advertisedNames => const [
    'EAREEG',
    'IronBCI',
    'IRONBCI',
    'PiEEG',
    'PIEEG',
  ];

  // ── BLE identifiers ────────────────────────────────────────────────

  @override
  String get serviceUuid => '0000fe40-cc7a-482a-984a-7f2ed5b3e58f';

  @override
  String get notifyCharacteristicUuid =>
      '0000fe42-8e22-4541-9d4c-21edae82ed19';

  // ── Channel layout ─────────────────────────────────────────────────

  @override
  List<ChannelDescriptor> get channelDescriptors => List.generate(
    channels,
    (i) => ChannelDescriptor(
      label: 'Ch ${i + 1}',
      unit: 'µV',
      defaultScale: 100,
    ),
  );

  @override
  double get sampleRateHz => 250;

  // ── Data parsing ───────────────────────────────────────────────────

  /// Reference voltage (V) of the ADS1299.
  static const double _vRef = 4.5;

  /// Full-scale positive value for 24-bit ADC.
  static const int _fullScale = 16777215; // 2^24 - 1

  /// Midpoint for unsigned→signed conversion (bit 23 set).
  static const int _signBit = 0x800000; // 2^23

  static const int _bytesPerChannel = 3;

  @override
  List<SignalSample> parseNotification(List<int> data) {
    final bytesPerSample = channels * _bytesPerChannel;
    if (data.length < bytesPerSample) return const [];

    final sampleCount = data.length ~/ bytesPerSample;
    final now = DateTime.now();
    final periodMicros = 1000000 ~/ sampleRateHz.round();
    final samples = <SignalSample>[];

    for (var s = 0; s < sampleCount; s++) {
      final base = s * bytesPerSample;
      final ch = <double>[];
      for (var c = 0; c < channels; c++) {
        final offset = base + c * _bytesPerChannel;
        int raw =
            (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2];
        if (raw >= _signBit) raw -= _fullScale + 1;
        final uv = 1000000.0 * _vRef * (raw / _fullScale);
        ch.add(double.parse(uv.toStringAsFixed(2)));
      }

      samples.add(
        SignalSample(
          time: now.subtract(
            Duration(microseconds: (sampleCount - 1 - s) * periodMicros),
          ),
          channels: ch,
        ),
      );
    }

    return samples;
  }
}

/// PiEEG-XR EEG source provider (8 or 16 channel).
///
/// PiEEG-XR retail units ship the same ADS1299 hardware and EAREEG firmware
/// as [IronBciSource] — identical BLE service/characteristic and 24-bit wire
/// format — but advertise under the "PiEEG_XR" brand. In the PiEEG cloud app
/// it is surfaced as its own device, so it gets a dedicated tile here too. The
/// full decoder is inherited from [IronBciSource]; only the identity/branding
/// differs.
class PiEegXrSource extends IronBciSource {
  PiEegXrSource({super.channels = 8});

  @override
  String get id => channels == 16 ? 'pieeg_xr16' : 'pieeg_xr';

  @override
  String get displayName => 'PiEEG-XR $channels-Ch';

  @override
  String get description =>
      'PiEEG-XR — wearable ADS1299 EEG, $channels channels, 24-bit, 250 SPS. '
      'Same firmware as IronBCI, branded for the XR face/head interface.';

  @override
  IconData get icon => Icons.visibility;

  @override
  List<String> get advertisedNames => const ['PiEEG', 'PIEEG'];
}
