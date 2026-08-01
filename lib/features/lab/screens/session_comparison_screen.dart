import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/capture_entry.dart';
import '../../../core/services/ble_source_provider.dart';
import '../../../core/services/fft_engine.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Session comparison — overlay two sessions' spectral profiles side by side
// ─────────────────────────────────────────────────────────────────────────────

class SessionComparisonScreen extends ConsumerStatefulWidget {
  final CaptureEntry entryA;
  final CaptureEntry entryB;

  const SessionComparisonScreen({
    super.key,
    required this.entryA,
    required this.entryB,
  });

  @override
  ConsumerState<SessionComparisonScreen> createState() =>
      _SessionComparisonScreenState();
}

class _SessionComparisonScreenState
    extends ConsumerState<SessionComparisonScreen> {
  late final SignalSession _sessionA = widget.entryA.signalSession!;
  late final SignalSession _sessionB = widget.entryB.signalSession!;

  int _selectedChannel = 0;
  FftEngine? _fftA;
  FftEngine? _fftB;

  String _label(CaptureEntry e) {
    final note = e.userNote;
    if (note != null && note.isNotEmpty) {
      return note.split('\n').first.trim();
    }
    return DateFormat('MMM d, HH:mm').format(e.timestamp);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (d.inHours > 0) return '${d.inHours}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, double> _computeBandPower(
    SignalSession session,
    int channelIndex,
    FftEngine? fft,
    void Function(FftEngine) setFft,
  ) {
    if (session.samples.length < 4) {
      return {'Delta': 0, 'Theta': 0, 'Alpha': 0, 'Beta': 0, 'Gamma': 0};
    }

    final values = session.samples
        .map(
          (s) =>
              s.channels.length > channelIndex ? s.channels[channelIndex] : 0.0,
        )
        .toList();

    int fftSize = 1;
    while (fftSize * 2 <= values.length) {
      fftSize *= 2;
    }
    if (fftSize < 8) {
      return {'Delta': 0, 'Theta': 0, 'Alpha': 0, 'Beta': 0, 'Gamma': 0};
    }

    if (fft == null || fft.n != fftSize) {
      fft = FftEngine(n: fftSize, sampleRateHz: session.sampleRateHz);
      setFft(fft);
    }

    final result = fft.analyse(values.sublist(values.length - fftSize));

    return {
      'Delta': result.bandPowers[FrequencyBand.delta] ?? 0,
      'Theta': result.bandPowers[FrequencyBand.theta] ?? 0,
      'Alpha': result.bandPowers[FrequencyBand.alpha] ?? 0,
      'Beta': result.bandPowers[FrequencyBand.beta] ?? 0,
      'Gamma': result.bandPowers[FrequencyBand.gamma] ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final powerA = _computeBandPower(
      _sessionA,
      _selectedChannel,
      _fftA,
      (f) => _fftA = f,
    );
    final powerB = _computeBandPower(
      _sessionB,
      _selectedChannel,
      _fftB,
      (f) => _fftB = f,
    );

    // Shared max for normalisation.
    final allVals = [...powerA.values, ...powerB.values];
    final maxVal = allVals
        .fold<double>(0, (p, v) => v > p ? v : p)
        .clamp(0.001, double.infinity);

    final maxChannels = _sessionA.channelCount < _sessionB.channelCount
        ? _sessionA.channelCount
        : _sessionB.channelCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.void_,
        body: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.moonbeam,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Compare Sessions',
                      style: AppTheme.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.moonbeam,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Session summary cards ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _SessionSummary(
                    label: _label(widget.entryA),
                    duration: _formatDuration(_sessionA.duration),
                    color: AppTheme.glow,
                    tag: 'A',
                  ),
                  const SizedBox(width: 8),
                  _SessionSummary(
                    label: _label(widget.entryB),
                    duration: _formatDuration(_sessionB.duration),
                    color: AppTheme.aurora,
                    tag: 'B',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Channel selector ────────────────────────────────────
            if (maxChannels > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: maxChannels,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final isActive = _selectedChannel == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedChannel = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.glow.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.glow
                                  : AppTheme.shimmer,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _sessionA.channels.length > i
                                ? _sessionA.channels[i].label
                                : 'Ch $i',
                            style: AppTheme.geistMono(
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive ? AppTheme.glow : AppTheme.mist,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // ── Band power comparison bars ──────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _ComparisonBars(
                  powerA: powerA,
                  powerB: powerB,
                  maxVal: maxVal,
                ),
              ),
            ),

            // ── Legend ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                    color: AppTheme.glow,
                    label: 'A: ${_label(widget.entryA)}',
                  ),
                  const SizedBox(width: 16),
                  _LegendDot(
                    color: AppTheme.aurora,
                    label: 'B: ${_label(widget.entryB)}',
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SessionSummary extends StatelessWidget {
  final String label;
  final String duration;
  final Color color;
  final String tag;

  const _SessionSummary({
    required this.label,
    required this.duration,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tag,
                    style: AppTheme.geistMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.geist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.moonbeam,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: AppTheme.geistMono(fontSize: 11, color: AppTheme.fog),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comparison bars — side-by-side band power
// ─────────────────────────────────────────────────────────────────────────────

const _bandColors = {
  'Delta': Color(0xFF7C3AED),
  'Theta': Color(0xFF2563EB),
  'Alpha': Color(0xFF10B981),
  'Beta': Color(0xFFF59E0B),
  'Gamma': Color(0xFFEF4444),
};

class _ComparisonBars extends StatelessWidget {
  final Map<String, double> powerA;
  final Map<String, double> powerB;
  final double maxVal;

  const _ComparisonBars({
    required this.powerA,
    required this.powerB,
    required this.maxVal,
  });

  @override
  Widget build(BuildContext context) {
    final bands = powerA.keys.toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bands.map((band) {
        final a = (powerA[band]! / maxVal).clamp(0.0, 1.0);
        final b = (powerB[band]! / maxVal).clamp(0.0, 1.0);
        final color = _bandColors[band] ?? AppTheme.glow;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Session A bar
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: a.clamp(0.05, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.glow.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Session B bar
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: b.clamp(0.05, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.aurora.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  band,
                  style: AppTheme.geist(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.fog,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.geist(fontSize: 11, color: AppTheme.fog),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
