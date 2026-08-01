import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ble_source_provider.dart';
import '../theme/app_theme.dart';

/// Per-channel colour palette — visually distinct on dark backgrounds.
const _channelColors = [
  Color(0xFF00E676), // green
  Color(0xFF40C4FF), // blue
  Color(0xFFFF5252), // red
  Color(0xFFFFD740), // amber
  Color(0xFFE040FB), // purple
  Color(0xFF00E5FF), // cyan
  Color(0xFFFF6E40), // deep orange
  Color(0xFF69F0AE), // light green
];

/// Real-time multi-channel signal chart driven by a [SignalSample] stream.
///
/// Renders 1–N channels as stacked waveform strips with autoscale,
/// channel labels, unit readout, and a dark "oscilloscope" aesthetic
/// consistent with the existing [LiveHrWaveform].
///
/// ```dart
/// LiveSignalChart(
///   signalStream: bleSourceService.signalStream,
///   channelDescriptors: provider.channelDescriptors,
///   deviceName: 'EAREEG',
///   onDisconnect: () => bleSourceService.disconnect(),
/// )
/// ```
class LiveSignalChart extends StatefulWidget {
  /// Emits [SignalSample] values in real time.
  final Stream<SignalSample> signalStream;

  /// Channel layout (labels, units, default scales).
  final List<ChannelDescriptor> channelDescriptors;

  /// Optional device name shown in the header.
  final String? deviceName;

  /// Source display name shown in the subtitle.
  final String? sourceName;

  /// Called when user taps disconnect.
  final VoidCallback? onDisconnect;

  /// Number of samples to keep in the ring buffer per channel.
  final int bufferSize;

  /// Nominal sample rate (Hz) advertised by the source, shown as a fallback
  /// until enough samples arrive to measure the live rate.
  final double? sampleRateHz;

  const LiveSignalChart({
    super.key,
    required this.signalStream,
    required this.channelDescriptors,
    this.deviceName,
    this.sourceName,
    this.onDisconnect,
    this.bufferSize = 250,
    this.sampleRateHz,
  });

  @override
  State<LiveSignalChart> createState() => _LiveSignalChartState();
}

class _LiveSignalChartState extends State<LiveSignalChart>
    with SingleTickerProviderStateMixin {
  /// Ring buffers — one deque per channel.
  late final List<ListQueue<double>> _buffers;

  /// Running statistics per channel for autoscale.
  late final List<_ChannelStats> _stats;

  int _sampleCount = 0;
  bool _connected = false;

  /// Measured throughput (Hz), derived from arrival timestamps over ~1 s.
  double _measuredRateHz = 0;

  /// Latency (ms) between a sample's timestamp and its arrival.
  int _latencyMs = 0;

  /// Rolling window of sample arrival times used to measure the live rate.
  final ListQueue<DateTime> _rateWindow = ListQueue<DateTime>();

  late final Ticker _ticker;
  StreamSubscription<SignalSample>? _sub;

  /// Which channels are enabled (visible).
  late final List<bool> _channelEnabled;

  /// If non-null, show a single channel full-width.
  int? _soloChannel;

  @override
  void initState() {
    super.initState();
    final n = widget.channelDescriptors.length;
    _buffers = List.generate(
      n,
      (_) =>
          ListQueue<double>.from(List<double>.filled(widget.bufferSize, 0.0)),
    );
    _stats = List.generate(n, (_) => _ChannelStats());
    _channelEnabled = List.filled(n, true);

    _sub = widget.signalStream.listen(_onSample);
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _onSample(SignalSample sample) {
    _connected = true;
    _sampleCount++;

    // Latency: how stale the sample is by the time it reaches the UI.
    final now = DateTime.now();
    _latencyMs = now.difference(sample.time).inMilliseconds.abs();

    // Measured rate: count arrivals within a 1 s sliding window.
    _rateWindow.addLast(now);
    while (_rateWindow.isNotEmpty &&
        now.difference(_rateWindow.first).inMilliseconds > 1000) {
      _rateWindow.removeFirst();
    }
    _measuredRateHz = _rateWindow.length.toDouble();

    for (var i = 0; i < sample.channels.length && i < _buffers.length; i++) {
      final v = sample.channels[i];
      _buffers[i].removeFirst();
      _buffers[i].addLast(v);
      _stats[i].push(v);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final descriptors = widget.channelDescriptors;
    final visibleIndices = _soloChannel != null
        ? [_soloChannel!]
        : List.generate(
            descriptors.length,
            (i) => i,
          ).where((i) => _channelEnabled[i]).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060B0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.glow.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildChannelChips(descriptors),
          Expanded(
            child: visibleIndices.isEmpty
                ? Center(
                    child: Text(
                      'Enable at least one channel',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: AppTheme.fog,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: visibleIndices.length,
                    itemBuilder: (_, idx) {
                      final ch = visibleIndices[idx];
                      return _buildChannelStrip(
                        ch,
                        descriptors[ch],
                        solo: _soloChannel != null,
                      );
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _connected ? AppTheme.glow : Colors.red,
              boxShadow: _connected
                  ? [
                      BoxShadow(
                        color: AppTheme.glow.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deviceName ?? 'BLE Source',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: AppTheme.glow.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                if (widget.sourceName != null)
                  Text(
                    widget.sourceName!,
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      color: AppTheme.fog.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          _buildMetrics(),
          const SizedBox(width: 12),
          if (widget.onDisconnect != null)
            GestureDetector(
              onTap: widget.onDisconnect,
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // ── Header metrics ────────────────────────────────────────────────────

  /// LIVE pill + rate / samples / latency read-outs.
  Widget _buildMetrics() {
    final rate = _measuredRateHz > 0
        ? _measuredRateHz
        : (widget.sampleRateHz ?? 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LIVE / OFFLINE pill.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (_connected ? AppTheme.glow : Colors.red).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _connected ? 'LIVE' : 'OFFLINE',
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _connected ? AppTheme.glow : Colors.red,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _metric('${rate.toStringAsFixed(0)} Hz'),
        const SizedBox(width: 10),
        _metric('${_formatCount(_sampleCount)} samples'),
        const SizedBox(width: 10),
        _metric('$_latencyMs ms'),
      ],
    );
  }

  /// A single compact monospace read-out.
  Widget _metric(String text) {
    return Text(
      text,
      style: GoogleFonts.robotoMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.glow.withValues(alpha: 0.85),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Group thousands with commas, e.g. 1861 → "1,861".
  String _formatCount(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── Channel toggle chips ──────────────────────────────────────────────

  Widget _buildChannelChips(List<ChannelDescriptor> descriptors) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: descriptors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final color = _channelColors[i % _channelColors.length];
          final enabled = _channelEnabled[i];
          final isSolo = _soloChannel == i;

          return GestureDetector(
            onTap: () => setState(() {
              if (_soloChannel != null) {
                _soloChannel = null; // un-solo
              } else {
                _channelEnabled[i] = !_channelEnabled[i];
              }
            }),
            onLongPress: () => setState(() {
              _soloChannel = _soloChannel == i ? null : i;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSolo
                    ? color.withValues(alpha: 0.25)
                    : enabled
                    ? color.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: enabled
                      ? color.withValues(alpha: 0.5)
                      : AppTheme.fog.withValues(alpha: 0.2),
                  width: isSolo ? 1.5 : 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  descriptors[i].label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: isSolo ? FontWeight.w700 : FontWeight.w500,
                    color: enabled
                        ? color
                        : AppTheme.fog.withValues(alpha: 0.4),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Individual channel strip ──────────────────────────────────────────

  Widget _buildChannelStrip(
    int chIndex,
    ChannelDescriptor desc, {
    bool solo = false,
  }) {
    final color = _channelColors[chIndex % _channelColors.length];
    final data = _buffers[chIndex].toList();
    final stats = _stats[chIndex];
    final scale = desc.defaultScale ?? 100;

    // Autoscale: center around running mean, ± scale.
    final mean = stats.mean;
    final yMin = mean - scale;
    final yMax = mean + scale;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: solo ? 300 : 80,
        child: Stack(
          children: [
            // Waveform canvas
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _ChannelPainter(
                  data: data,
                  yMin: yMin,
                  yMax: yMax,
                  lineColor: color,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // Overlay labels
            Positioned(
              left: 6,
              top: 4,
              child: Text(
                desc.label,
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 4,
              child: Text(
                '${data.isNotEmpty ? data.last.toStringAsFixed(1) : "--"} ${desc.unit}',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tap ch to toggle · Long-press to solo',
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Text(
            '${widget.bufferSize} smp window',
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Channel waveform painter
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelPainter extends CustomPainter {
  final List<double> data;
  final double yMin;
  final double yMax;
  final Color lineColor;

  const _ChannelPainter({
    required this.data,
    required this.yMin,
    required this.yMax,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    if (data.length < 2) return;
    _drawTrace(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    // Horizontal center line.
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);

    // Quarter lines.
    for (final f in [0.25, 0.75]) {
      final y = size.height * f;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..color = Colors.white.withValues(alpha: 0.015),
      );
    }
  }

  void _drawTrace(Canvas canvas, Size size) {
    final n = data.length;
    final range = yMax - yMin;
    if (range == 0) return;
    final dx = size.width / (n - 1);

    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = dx * i;
      final normalized = (data[i] - yMin) / range;
      final y = size.height * (1.0 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow pass.
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.25)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Crisp pass.
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChannelPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Running stats helper for autoscale
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelStats {
  static const int _window = 250;
  final _values = ListQueue<double>();
  double _sum = 0;

  void push(double v) {
    _values.addLast(v);
    _sum += v;
    while (_values.length > _window) {
      _sum -= _values.removeFirst();
    }
  }

  double get mean => _values.isEmpty ? 0 : _sum / _values.length;
}
